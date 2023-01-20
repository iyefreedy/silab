import 'package:silab/services/auth/auth_user.dart';

abstract class AuthProvider {
  AuthUser? get currentUser;
  Future<void> initialize();
  Future<AuthUser> login({
    required String email,
    required String password,
  });
  Future<AuthUser> createUser({
    // required String? role,
    // required String uniqueNumber,
    required String email,
    required String password,
  });
  Future<void> sendEmailVerification();
  Future<void> logout();
}
