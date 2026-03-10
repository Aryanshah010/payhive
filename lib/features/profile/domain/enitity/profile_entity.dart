import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String? id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String? imageUrl;
  final bool hasPin;
  final double balance;

  const ProfileEntity({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    this.imageUrl,
    this.hasPin = false,
    this.balance = 0,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    phoneNumber,
    email,
    imageUrl,
    hasPin,
    balance,
  ];
}
