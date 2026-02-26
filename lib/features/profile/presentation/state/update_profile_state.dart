import 'package:equatable/equatable.dart';

enum UpdateProfileStatus { initial, loading, loaded, submitting, success, error }

class UpdateProfileState extends Equatable {
  static const Object _unset = Object();

  final UpdateProfileStatus status;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String initialFullName;
  final String initialEmail;
  final String initialPhoneNumber;
  final String? errorMessage;
  final String? infoMessage;

  const UpdateProfileState({
    required this.status,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.initialFullName,
    required this.initialEmail,
    required this.initialPhoneNumber,
    this.errorMessage,
    this.infoMessage,
  });

  factory UpdateProfileState.initial() {
    return const UpdateProfileState(
      status: UpdateProfileStatus.initial,
      fullName: '',
      email: '',
      phoneNumber: '',
      initialFullName: '',
      initialEmail: '',
      initialPhoneNumber: '',
    );
  }

  UpdateProfileState copyWith({
    UpdateProfileStatus? status,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? initialFullName,
    String? initialEmail,
    String? initialPhoneNumber,
    Object? errorMessage = _unset,
    Object? infoMessage = _unset,
  }) {
    return UpdateProfileState(
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      initialFullName: initialFullName ?? this.initialFullName,
      initialEmail: initialEmail ?? this.initialEmail,
      initialPhoneNumber: initialPhoneNumber ?? this.initialPhoneNumber,
      errorMessage: errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      infoMessage: infoMessage == _unset ? this.infoMessage : infoMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    fullName,
    email,
    phoneNumber,
    initialFullName,
    initialEmail,
    initialPhoneNumber,
    errorMessage,
    infoMessage,
  ];
}
