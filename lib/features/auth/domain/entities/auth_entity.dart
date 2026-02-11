import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String? authId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? password;

  const AuthEntity({
    this.authId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.password,
  });

  @override
  List<Object?> get props => [authId, fullName, phoneNumber, email, password];
}
