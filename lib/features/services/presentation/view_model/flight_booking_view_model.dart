import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/domain/usecases/flight_usecases.dart';
import 'package:payhive/features/services/presentation/state/flight_booking_state.dart';
import 'package:uuid/uuid.dart';

final flightBookingViewModelProvider =
    NotifierProvider<FlightBookingViewModel, FlightBookingState>(
      FlightBookingViewModel.new,
    );

class FlightBookingViewModel extends Notifier<FlightBookingState> {
  late final CreateFlightBookingUsecase _createFlightBookingUsecase;
  late final PayBookingUsecase _payBookingUsecase;
  final Uuid _uuid = const Uuid();

  @override
  FlightBookingState build() {
    _createFlightBookingUsecase = ref.read(createFlightBookingUsecaseProvider);
    _payBookingUsecase = ref.read(payBookingUsecaseProvider);
    return FlightBookingState.initial();
  }

  void setFlight(FlightEntity flight) {
    final currentFlight = state.flight;
    if (currentFlight != null && currentFlight.id == flight.id) {
      state = state.copyWith(flight: flight);
      return;
    }

    state = state.copyWith(
      status: FlightBookingViewStatus.loaded,
      action: FlightBookingAction.none,
      flight: flight,
      quantity: 1,
      createdBooking: null,
      paymentResult: null,
      errorMessage: null,
      payIdempotencyKey: null,
      payLocked: false,
    );
  }

  void setQuantity(int value) {
    final next = _clampQuantity(value);
    if (next == state.quantity) return;

    state = state.copyWith(
      quantity: next,
      createdBooking: null,
      paymentResult: null,
      payIdempotencyKey: null,
      payLocked: false,
      errorMessage: null,
      status: FlightBookingViewStatus.loaded,
      action: FlightBookingAction.none,
    );
  }

  void incrementQuantity() {
    setQuantity(state.quantity + 1);
  }

  void decrementQuantity() {
    setQuantity(state.quantity - 1);
  }

  Future<void> createBooking() async {
    if (state.status == FlightBookingViewStatus.loading) return;

    final flight = state.flight;
    if (flight == null) {
      state = state.copyWith(
        status: FlightBookingViewStatus.error,
        action: FlightBookingAction.none,
        errorMessage: 'Flight details are missing.',
      );
      return;
    }

    if (flight.seatsAvailable > 0 && state.quantity > flight.seatsAvailable) {
      state = state.copyWith(
        status: FlightBookingViewStatus.error,
        action: FlightBookingAction.none,
        errorMessage: 'Selected quantity is more than available seats.',
      );
      return;
    }

    state = state.copyWith(
      status: FlightBookingViewStatus.loading,
      action: FlightBookingAction.createBooking,
      errorMessage: null,
    );

    final result = await _createFlightBookingUsecase(
      CreateFlightBookingParams(flightId: flight.id, quantity: state.quantity),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: FlightBookingViewStatus.error,
          action: FlightBookingAction.none,
          errorMessage: failure.message,
          payLocked: false,
        );
      },
      (booking) {
        state = state.copyWith(
          status: FlightBookingViewStatus.loaded,
          action: FlightBookingAction.none,
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
    if (state.status == FlightBookingViewStatus.loading) return;

    final createdBooking = state.createdBooking;
    if (createdBooking == null) {
      state = state.copyWith(
        status: FlightBookingViewStatus.error,
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
        status: FlightBookingViewStatus.error,
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
      status: FlightBookingViewStatus.loading,
      action: FlightBookingAction.payBooking,
      errorMessage: null,
      payIdempotencyKey: idempotencyKey,
      payLocked: true,
    );

    final result = await _payBookingUsecase(
      PayBookingParams(
        bookingId: createdBooking.bookingId,
        idempotencyKey: idempotencyKey,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: FlightBookingViewStatus.error,
          action: FlightBookingAction.none,
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
          status: FlightBookingViewStatus.loaded,
          action: FlightBookingAction.none,
          paymentResult: payment,
          createdBooking: CreateBookingResultEntity(
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
      status: state.flight == null
          ? FlightBookingViewStatus.initial
          : FlightBookingViewStatus.loaded,
      action: FlightBookingAction.none,
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

  int _clampQuantity(int value) {
    final min = 1;
    final max = state.flight?.seatsAvailable ?? 1;

    if (max < min) {
      return min;
    }

    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
