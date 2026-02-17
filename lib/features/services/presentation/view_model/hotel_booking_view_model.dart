import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/domain/usecases/hotel_usecases.dart';
import 'package:payhive/features/services/presentation/state/hotel_booking_state.dart';
import 'package:uuid/uuid.dart';

final hotelBookingViewModelProvider =
    NotifierProvider<HotelBookingViewModel, HotelBookingState>(
      HotelBookingViewModel.new,
    );

class HotelBookingViewModel extends Notifier<HotelBookingState> {
  late final CreateHotelBookingUsecase _createHotelBookingUsecase;
  late final PayHotelBookingUsecase _payHotelBookingUsecase;
  final Uuid _uuid = const Uuid();

  @override
  HotelBookingState build() {
    _createHotelBookingUsecase = ref.read(createHotelBookingUsecaseProvider);
    _payHotelBookingUsecase = ref.read(payHotelBookingUsecaseProvider);
    return HotelBookingState.initial();
  }

  void setHotel(HotelEntity hotel) {
    final currentHotel = state.hotel;
    if (currentHotel != null && currentHotel.id == hotel.id) {
      state = state.copyWith(hotel: hotel);
      return;
    }

    state = state.copyWith(
      status: HotelBookingViewStatus.loaded,
      action: HotelBookingAction.none,
      hotel: hotel,
      rooms: 1,
      nights: 1,
      checkin: '',
      createdBooking: null,
      paymentResult: null,
      errorMessage: null,
      payIdempotencyKey: null,
      payLocked: false,
    );
  }

  void setRooms(int value) {
    final next = _clampRooms(value);
    if (next == state.rooms) return;

    state = state.copyWith(
      rooms: next,
      createdBooking: null,
      paymentResult: null,
      payIdempotencyKey: null,
      payLocked: false,
      errorMessage: null,
      status: HotelBookingViewStatus.loaded,
      action: HotelBookingAction.none,
    );
  }

  void incrementRooms() {
    setRooms(state.rooms + 1);
  }

  void decrementRooms() {
    setRooms(state.rooms - 1);
  }

  void setNights(int value) {
    final next = value < 1 ? 1 : value;
    if (next == state.nights) return;

    state = state.copyWith(
      nights: next,
      createdBooking: null,
      paymentResult: null,
      payIdempotencyKey: null,
      payLocked: false,
      errorMessage: null,
      status: HotelBookingViewStatus.loaded,
      action: HotelBookingAction.none,
    );
  }

  void incrementNights() {
    setNights(state.nights + 1);
  }

  void decrementNights() {
    setNights(state.nights - 1);
  }

  void setCheckin(String value) {
    final next = value.trim();
    if (next == state.checkin) return;

    state = state.copyWith(
      checkin: next,
      createdBooking: null,
      paymentResult: null,
      payIdempotencyKey: null,
      payLocked: false,
      errorMessage: null,
      status: HotelBookingViewStatus.loaded,
      action: HotelBookingAction.none,
    );
  }

  Future<void> createBooking() async {
    if (state.status == HotelBookingViewStatus.loading) return;

    final hotel = state.hotel;
    if (hotel == null) {
      state = state.copyWith(
        status: HotelBookingViewStatus.error,
        action: HotelBookingAction.none,
        errorMessage: 'Hotel details are missing.',
      );
      return;
    }

    if (hotel.roomsAvailable > 0 && state.rooms > hotel.roomsAvailable) {
      state = state.copyWith(
        status: HotelBookingViewStatus.error,
        action: HotelBookingAction.none,
        errorMessage: 'Selected rooms are more than available rooms.',
      );
      return;
    }

    if (state.checkin.trim().isEmpty) {
      state = state.copyWith(
        status: HotelBookingViewStatus.error,
        action: HotelBookingAction.none,
        errorMessage: 'Please select checkin date.',
      );
      return;
    }

    state = state.copyWith(
      status: HotelBookingViewStatus.loading,
      action: HotelBookingAction.createBooking,
      errorMessage: null,
    );

    final result = await _createHotelBookingUsecase(
      CreateHotelBookingParams(
        hotelId: hotel.id,
        rooms: state.rooms,
        nights: state.nights,
        checkin: state.checkin,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: HotelBookingViewStatus.error,
          action: HotelBookingAction.none,
          errorMessage: failure.message,
          payLocked: false,
        );
      },
      (booking) {
        state = state.copyWith(
          status: HotelBookingViewStatus.loaded,
          action: HotelBookingAction.none,
          createdBooking: booking,
          paymentResult: null,
          errorMessage: null,
          payIdempotencyKey: null,
          payLocked: false,
        );
      },
    );
  }

  Future<void> payBooking() async {
    if (state.status == HotelBookingViewStatus.loading) return;

    final createdBooking = state.createdBooking;
    if (createdBooking == null) {
      state = state.copyWith(
        status: HotelBookingViewStatus.error,
        errorMessage: 'Create booking first to continue payment.',
      );
      return;
    }

    final currentStatus = _resolvedBookingStatus();
    if (currentStatus == 'paid') {
      state = state.copyWith(payLocked: true);
      return;
    }

    if (state.payLocked) {
      state = state.copyWith(
        status: HotelBookingViewStatus.error,
        errorMessage: 'Payment already submitted for this booking.',
      );
      return;
    }

    final idempotencyKey =
        (state.payIdempotencyKey == null ||
            state.payIdempotencyKey!.trim().isEmpty)
        ? _uuid.v4()
        : state.payIdempotencyKey!.trim();

    state = state.copyWith(
      status: HotelBookingViewStatus.loading,
      action: HotelBookingAction.payBooking,
      errorMessage: null,
      payIdempotencyKey: idempotencyKey,
      payLocked: true,
    );

    final result = await _payHotelBookingUsecase(
      PayHotelBookingParams(
        bookingId: createdBooking.bookingId,
        idempotencyKey: idempotencyKey,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: HotelBookingViewStatus.error,
          action: HotelBookingAction.none,
          errorMessage: failure.message,
          payIdempotencyKey: idempotencyKey,
          payLocked: false,
        );
      },
      (payment) {
        final updatedStatus = payment.booking.status.isEmpty
            ? 'paid'
            : payment.booking.status;

        state = state.copyWith(
          status: HotelBookingViewStatus.loaded,
          action: HotelBookingAction.none,
          paymentResult: payment,
          createdBooking: CreateHotelBookingResultEntity(
            bookingId: createdBooking.bookingId,
            status: updatedStatus,
            price: createdBooking.price,
            payUrl: createdBooking.payUrl,
          ),
          errorMessage: null,
          payIdempotencyKey: idempotencyKey,
          payLocked: true,
        );
      },
    );
  }

  void clearError() {
    if (state.errorMessage == null) return;

    state = state.copyWith(
      errorMessage: null,
      status: state.hotel == null
          ? HotelBookingViewStatus.initial
          : HotelBookingViewStatus.loaded,
      action: HotelBookingAction.none,
    );
  }

  String _resolvedBookingStatus() {
    final paymentStatus = state.paymentResult?.booking.status.trim();
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      return paymentStatus;
    }

    final createStatus = state.createdBooking?.status.trim();
    return createStatus == null || createStatus.isEmpty
        ? 'created'
        : createStatus;
  }

  int _clampRooms(int value) {
    final min = 1;
    final max = state.hotel?.roomsAvailable ?? 1;

    if (max < min) {
      return min;
    }

    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
