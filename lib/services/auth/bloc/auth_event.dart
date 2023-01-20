part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

class AuthEventInitialize extends AuthEvent {}

class AuthEventShouldRegister extends AuthEvent {}

class AuthEventRegister extends AuthEvent {
  final String? role;
  final String uniqueNumber;
  final String email;
  final String password;

  AuthEventRegister({
    required this.role,
    required this.uniqueNumber,
    required this.email,
    required this.password,
  });
}

class AuthEventLogout extends AuthEvent {}

class AuthEventLogin extends AuthEvent {
  final String email;
  final String password;

  AuthEventLogin({required this.email, required this.password});
}

class AuthEventSendEmailVerification extends AuthEvent {}
