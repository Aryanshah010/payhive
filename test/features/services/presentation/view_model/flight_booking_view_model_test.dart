import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/domain/usecases/flight_usecases.dart';
import 'package:payhive/features/services/presentation/state/flight_booking_state.dart';
import 'package:payhive/features/services/presentation/view_model/flight_booking_view_model.dart';

class MockCreateFlightBookingUsecase extends Mock
    implements CreateFlightBookingUsecase {}

class MockPayBookingUsecase extends Mock implements PayBookingUsecase {}

void main() {
  late MockCreateFlightBookingUsecase mockCreateUsecase;
  late MockPayBookingUsecase mockPayUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const CreateFlightBookingParams(flightId: 'flight-1', quantity: 1),
    );
    registerFallbackValue(const PayBookingParams(bookingId: 'booking-1'));
  });

  setUp(() {
    mockCreateUsecase = MockCreateFlightBookingUsecase();
    mockPayUsecase = MockPayBookingUsecase();

    container = ProviderContainer(
      overrides: [
        createFlightBookingUsecaseProvider.overrideWithValue(mockCreateUsecase),
        payBookingUsecaseProvider.overrideWithValue(mockPayUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  FlightEntity makeFlight() {
    return FlightEntity(
      id: 'flight-1',
      airline: 'Buddha Air',
      flightNumber: 'U4-201',
      from: 'Kathmandu',
      to: 'Pokhara',
      departure: DateTime(2026, 3, 15, 8, 0),
      arrival: DateTime(2026, 3, 15, 9, 0),
      durationMinutes: 60,
      flightClass: 'Economy',
      price: 4500,
      seatsTotal: 70,
      seatsAvailable: 30,
    );
  }

  CreateBookingResultEntity makeCreateResult() {
    return const CreateBookingResultEntity(
      bookingId: 'booking-1',
      status: 'created',
      price: 4500,
      payUrl: '/api/bookings/booking-1/pay',
    );
  }

  PayBookingResultEntity makePayResult({String status = 'paid'}) {
    return PayBookingResultEntity(
      booking: FlightBookingItemEntity(
        id: 'booking-1',
        status: status,
        paymentTxnId: 'txn-1',
        paidAt: DateTime(2026, 3, 10),
      ),
      transactionId: 'txn-1',
      idempotentReplay: false,
    );
  }

  Future<void> prepareCreatedBooking() async {
    when(
      () => mockCreateUsecase(any()),
    ).thenAnswer((_) async => Right(makeCreateResult()));

    final vm = container.read(flightBookingViewModelProvider.notifier);
    vm.setFlight(makeFlight());
    await vm.createBooking();
  }

  group('FlightBookingViewModel', () {
    test('create booking success stores booking result', () async {
      when(
        () => mockCreateUsecase(any()),
      ).thenAnswer((_) async => Right(makeCreateResult()));

      final vm = container.read(flightBookingViewModelProvider.notifier);
      vm.setFlight(makeFlight());
      await vm.createBooking();

      final state = container.read(flightBookingViewModelProvider);
      expect(state.status, FlightBookingViewStatus.loaded);
      expect(state.createdBooking, isNotNull);
      expect(state.createdBooking?.bookingId, 'booking-1');
      expect(state.payLocked, isFalse);
    });

    test('pay booking success updates payment result and locks flow', () async {
      await prepareCreatedBooking();

      when(
        () => mockPayUsecase(any()),
      ).thenAnswer((_) async => Right(makePayResult()));

      await container
          .read(flightBookingViewModelProvider.notifier)
          .payBooking();
      final state = container.read(flightBookingViewModelProvider);

      expect(state.status, FlightBookingViewStatus.loaded);
      expect(state.paymentResult?.transactionId, 'txn-1');
      expect(state.createdBooking?.status, 'paid');
      expect(state.payLocked, isTrue);
    });

    test('duplicate pay taps are ignored while request is in-flight', () async {
      await prepareCreatedBooking();

      final completer = Completer<Either<Failure, PayBookingResultEntity>>();
      when(() => mockPayUsecase(any())).thenAnswer((_) => completer.future);

      final vm = container.read(flightBookingViewModelProvider.notifier);
      unawaited(vm.payBooking());
      unawaited(vm.payBooking());

      await Future<void>.delayed(const Duration(milliseconds: 10));
      verify(() => mockPayUsecase(any())).called(1);

      completer.complete(Right(makePayResult()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    test('pay failure unlocks and retries with same idempotency key', () async {
      await prepareCreatedBooking();

      final capturedKeys = <String?>[];
      var callCount = 0;

      when(() => mockPayUsecase(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as PayBookingParams;
        capturedKeys.add(params.idempotencyKey);
        callCount++;

        if (callCount == 1) {
          return const Left(ApiFalilure(message: 'Payment failed'));
        }

        return Right(makePayResult());
      });

      final vm = container.read(flightBookingViewModelProvider.notifier);
      await vm.payBooking();

      var state = container.read(flightBookingViewModelProvider);
      expect(state.status, FlightBookingViewStatus.error);
      expect(state.payLocked, isFalse);

      await vm.payBooking();
      state = container.read(flightBookingViewModelProvider);

      expect(state.status, FlightBookingViewStatus.loaded);
      expect(state.paymentResult, isNotNull);
      expect(capturedKeys.length, 2);
      expect(capturedKeys.first, isNotNull);
      expect(capturedKeys.first, capturedKeys.last);
    });
  });
}
