import 'package:equatable/equatable.dart';

enum PinStatus { initial, loading, success, error }

class PinState extends Equatable {
  final PinStatus status;
  final String? errorMessage;

  const PinState({
    this.status = PinStatus.initial,
    this.errorMessage,
  });

  static const _unset = Object();

  PinState copyWith({
    PinStatus? status,
    Object? errorMessage = _unset,
  }) {
    return PinState(
      status: status ?? this.status,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
