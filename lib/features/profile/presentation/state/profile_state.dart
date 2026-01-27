import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, loaded, updated, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final String? fullName;
  final String? phoneNumber;
  final String? imageUrl;
  final String? errorMessage;

  const ProfileState({
    required this.status,
    this.fullName,
    this.phoneNumber,
    this.imageUrl,
    this.errorMessage,
  });

  factory ProfileState.initial() {
    return const ProfileState(status: ProfileStatus.initial);
  }

  ProfileState copyWith({
    ProfileStatus? status,
    String? fullName,
    String? phoneNumber,
    String? imageUrl,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    fullName,
    phoneNumber,
    imageUrl,
    errorMessage,
  ];
}
