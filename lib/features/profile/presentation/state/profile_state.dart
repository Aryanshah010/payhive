import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, loaded, updated, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final String? imageUrl;
  final String? errorMessage;

  const ProfileState({required this.status, this.imageUrl, this.errorMessage});

  factory ProfileState.initial() {
    return const ProfileState(status: ProfileStatus.initial);
  }

  ProfileState copyWith({
    ProfileStatus? status,
    String? imageUrl,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, imageUrl, errorMessage];
}
