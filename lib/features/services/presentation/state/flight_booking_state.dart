import 'package:equatable/equatable.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';

enum FlightBookingViewStatus { initial, loading, loaded, error }

enum FlightBookingAction { none, createBooking, payBooking }

class FlightBookingState extends Equatable {
  static const Object _unset = Object();

  final FlightBookingViewStatus status;
  final FlightBookingAction action;
  final FlightEntity? flight;
  final int quantity;
  final CreateBookingResultEntity? createdBooking;
  final PayBookingResultEntity? paymentResult;
  final String? errorMessage;
  final String? payIdempotencyKey;
  final bool payLocked;

  const FlightBookingState({
    required this.status,
    required this.action,
    this.flight,
    required this.quantity,
    this.createdBooking,
    this.paymentResult,
    this.errorMessage,
    this.payIdempotencyKey,
    required this.payLocked,
  });

  factory FlightBookingState.initial() {
    return const FlightBookingState(
      status: FlightBookingViewStatus.initial,
      action: FlightBookingAction.none,
      quantity: 1,
      payLocked: false,
    );
  }

  FlightBookingState copyWith({
    FlightBookingViewStatus? status,
    FlightBookingAction? action,
    Object? flight = _unset,
    int? quantity,
    Object? createdBooking = _unset,
    Object? paymentResult = _unset,
    Object? errorMessage = _unset,
    Object? payIdempotencyKey = _unset,
    bool? payLocked,
  }) {
    return FlightBookingState(
      status: status ?? this.status,
      action: action ?? this.action,
      flight: flight == _unset ? this.flight : flight as FlightEntity?,
      quantity: quantity ?? this.quantity,
      createdBooking: createdBooking == _unset
          ? this.createdBooking
          : createdBooking as CreateBookingResultEntity?,
      paymentResult: paymentResult == _unset
          ? this.paymentResult
          : paymentResult as PayBookingResultEntity?,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      payIdempotencyKey: payIdempotencyKey == _unset
          ? this.payIdempotencyKey
          : payIdempotencyKey as String?,
      payLocked: payLocked ?? this.payLocked,
    );
  }

  @override
  List<Object?> get props => [
    status,
    action,
    flight,
    quantity,
    createdBooking,
    paymentResult,
    errorMessage,
    payIdempotencyKey,
    payLocked,
  ];
}
