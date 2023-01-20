import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthUser {
  final String id;
  final bool isEmailVerified;
  final String email;
  final String? name;
  final String? faculty;
  final String? vocation;
  final String? gender;
  final String? role;
  final DateTime? birthDate;

  AuthUser({
    required this.id,
    required this.isEmailVerified,
    required this.email,
    this.name,
    this.faculty,
    this.vocation,
    this.gender,
    this.role,
    this.birthDate,
  });

  AuthUser.fromFirebase(User user)
      : this(
          id: user.uid,
          email: user.email!,
          isEmailVerified: user.emailVerified,
        );

  AuthUser.fromJson(Map<String, Object?> json)
      : this(
          id: json['userId'] as String,
          email: json['email'] as String,
          isEmailVerified: json['isEmailVerified'] as bool,
          birthDate: (json['tanggalLahir'] as Timestamp?)?.toDate(),
          faculty: json['fakultas'] as String?,
          gender: json['jenisKelamin'] as String?,
          name: json['nama'] as String?,
          role: json['role'] as String?,
          vocation: json['programStudi'] as String?,
        );

  Map<String, Object?> toJson() {
    return {
      'userId': id,
      'email': email,
      'isEmailVerified': isEmailVerified,
      'tanggalLahir': birthDate,
      'fakultas': faculty,
      'jenisKelamin': gender,
      'nama': name,
      'role': role,
      'programStudi': vocation,
    };
  }
}
