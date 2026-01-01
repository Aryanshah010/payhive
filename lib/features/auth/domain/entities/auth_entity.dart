import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String? authId;
  final String fullName;
  final String phoneNumber;
  final String? password;

  const AuthEntity({
    this.authId,
    required this.fullName,
    this.password,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [authId,fullName,password,phoneNumber];
}
