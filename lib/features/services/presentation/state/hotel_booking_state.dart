import 'package:equatable/equatable.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';

enum HotelBookingViewStatus { initial, loading, loaded, error }

enum HotelBookingAction { none, createBooking, payBooking }

class HotelBookingState extends Equatable {
  static const Object _unset = Object();

  final HotelBookingViewStatus status;
  final HotelBookingAction action;
  final HotelEntity? hotel;
  final int rooms;
  final int nights;
  final String checkin;
  final CreateHotelBookingResultEntity? createdBooking;
  final PayHotelBookingResultEntity? paymentResult;
  final String? errorMessage;
  final String? payIdempotencyKey;
  final bool payLocked;

  const HotelBookingState({
    required this.status,
    required this.action,
    this.hotel,
    required this.rooms,
    required this.nights,
    required this.checkin,
    this.createdBooking,
    this.paymentResult,
    this.errorMessage,
    this.payIdempotencyKey,
    required this.payLocked,
  });

  factory HotelBookingState.initial() {
    return const HotelBookingState(
      status: HotelBookingViewStatus.initial,
      action: HotelBookingAction.none,
      rooms: 1,
      nights: 1,
      checkin: '',
      payLocked: false,
    );
  }

  HotelBookingState copyWith({
    HotelBookingViewStatus? status,
    HotelBookingAction? action,
    Object? hotel = _unset,
    int? rooms,
    int? nights,
    String? checkin,
    Object? createdBooking = _unset,
    Object? paymentResult = _unset,
    Object? errorMessage = _unset,
    Object? payIdempotencyKey = _unset,
    bool? payLocked,
  }) {
    return HotelBookingState(
      status: status ?? this.status,
      action: action ?? this.action,
      hotel: hotel == _unset ? this.hotel : hotel as HotelEntity?,
      rooms: rooms ?? this.rooms,
      nights: nights ?? this.nights,
      checkin: checkin ?? this.checkin,
      createdBooking: createdBooking == _unset
          ? this.createdBooking
          : createdBooking as CreateHotelBookingResultEntity?,
      paymentResult: paymentResult == _unset
          ? this.paymentResult
          : paymentResult as PayHotelBookingResultEntity?,
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
    hotel,
    rooms,
    nights,
    checkin,
    createdBooking,
    paymentResult,
    errorMessage,
    payIdempotencyKey,
    payLocked,
  ];
}
