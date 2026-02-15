import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, loaded, updated, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final String? imageUrl;
  final double? balance;
  final bool hasPin;
  final String? errorMessage;

  const ProfileState({
    required this.status,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.imageUrl,
    this.balance,
    this.hasPin = false,
    this.errorMessage,
  });

  factory ProfileState.initial() {
    return const ProfileState(status: ProfileStatus.initial);
  }

  ProfileState copyWith({
    ProfileStatus? status,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? imageUrl,
    double? balance,
    bool? hasPin,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      balance: balance ?? this.balance,
      hasPin: hasPin ?? this.hasPin,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    fullName,
    phoneNumber,
    email,
    imageUrl,
    balance,
    hasPin,
    errorMessage,
  ];
}
