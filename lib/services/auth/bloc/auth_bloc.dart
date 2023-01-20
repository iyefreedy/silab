import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:silab/services/auth/auth_provider.dart';
import 'package:silab/services/auth/auth_user.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthProvider provider;
  AuthBloc(this.provider)
      : super(const AuthStateUninitialized(isLoading: true)) {
    on<AuthEventInitialize>((event, emit) async {
      await provider.initialize();

      final user = provider.currentUser;

      if (user == null) {
        emit(const AuthStateLoggedOut(
          exception: null,
          isLoading: false,
        ));
      } else if (!user.isEmailVerified) {
        emit(const AuthStateNeedsVerification(isLoading: false));
      } else {
        emit(AuthStateLoggedIn(
          user: user,
          isLoading: false,
        ));
      }
    });

    // Event : Go to register view
    on<AuthEventShouldRegister>((event, emit) {
      emit(const AuthStateRegistering(
        exception: null,
        isLoading: false,
      ));
    });

    // Event : Register process
    on<AuthEventRegister>((event, emit) async {
      final role = event.role;
      final uniqueNumber = event.uniqueNumber;
      final email = event.email;
      final password = event.password;
      final FirebaseCloudStorage cloudStorage = FirebaseCloudStorage();

      emit(const AuthStateRegistering(exception: null, isLoading: true));

      try {
        final authUser = await provider.createUser(
          // role: role,
          // uniqueNumber: uniqueNumber,
          email: email,
          password: password,
        );

        final cloudUser = await cloudStorage.getUserByRole(
          role: '$role',
          uniqueNumber: uniqueNumber,
        );

        final user = AuthUser.fromJson({
          'userId': authUser.id,
          'email': authUser.email,
          'isEmailVerified': authUser.isEmailVerified,
          'tanggalLahir': cloudUser['tanggalLahir'],
          'fakultas': cloudUser['fakultas'],
          'jenisKelamin': cloudUser['jenisKelamin'],
          'nama': cloudUser['nama'],
          'role': role,
          'programStudi': cloudUser['programStudi'],
        });

        await cloudStorage.usersCollection.doc(authUser.id).set(user);

        await provider.sendEmailVerification();
        emit(const AuthStateNeedsVerification(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(
          exception: e,
          isLoading: false,
        ));
      }
    });

    // Event: Logout
    on<AuthEventLogout>((event, emit) async {
      try {
        await provider.logout();

        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ),
        );
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ),
        );
      }
    });

    // Login event
    on<AuthEventLogin>((event, emit) async {
      emit(
        const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
          loadingText: 'Please wait while I log you in',
        ),
      );
      final email = event.email;
      final password = event.password;
      try {
        final user = await provider.login(
          email: email,
          password: password,
        );

        if (!user.isEmailVerified) {
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
          emit(const AuthStateNeedsVerification(isLoading: false));
        } else {
          emit(AuthStateLoggedIn(
            user: user,
            isLoading: false,
          ));
        }
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ),
        );
      }
    });

    on<AuthEventSendEmailVerification>((event, emit) async {
      try {
        await provider.sendEmailVerification();
        emit(const AuthStateNeedsVerification(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      }
    });
  }
}
