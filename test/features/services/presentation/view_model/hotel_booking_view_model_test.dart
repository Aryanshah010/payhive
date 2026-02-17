import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/domain/usecases/hotel_usecases.dart';
import 'package:payhive/features/services/presentation/state/hotel_booking_state.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_booking_view_model.dart';

class MockCreateHotelBookingUsecase extends Mock
    implements CreateHotelBookingUsecase {}

class MockPayHotelBookingUsecase extends Mock
    implements PayHotelBookingUsecase {}

void main() {
  late MockCreateHotelBookingUsecase mockCreateUsecase;
  late MockPayHotelBookingUsecase mockPayUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const CreateHotelBookingParams(
        hotelId: 'hotel-1',
        rooms: 1,
        nights: 1,
        checkin: '2030-01-01',
      ),
    );
    registerFallbackValue(const PayHotelBookingParams(bookingId: 'booking-1'));
  });

  setUp(() {
    mockCreateUsecase = MockCreateHotelBookingUsecase();
    mockPayUsecase = MockPayHotelBookingUsecase();

    container = ProviderContainer(
      overrides: [
        createHotelBookingUsecaseProvider.overrideWithValue(mockCreateUsecase),
        payHotelBookingUsecaseProvider.overrideWithValue(mockPayUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  HotelEntity makeHotel() {
    return const HotelEntity(
      id: 'hotel-1',
      name: 'Thamel Boutique Residency',
      city: 'Kathmandu',
      roomType: 'Deluxe',
      roomsTotal: 45,
      roomsAvailable: 12,
      pricePerNight: 4800,
      amenities: ['wifi'],
      images: [],
    );
  }

  CreateHotelBookingResultEntity makeCreateResult() {
    return const CreateHotelBookingResultEntity(
      bookingId: 'booking-1',
      status: 'created',
      price: 9600,
      payUrl: '/api/bookings/booking-1/pay',
    );
  }

  PayHotelBookingResultEntity makePayResult({String status = 'paid'}) {
    return PayHotelBookingResultEntity(
      booking: HotelBookingItemEntity(
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

    final vm = container.read(hotelBookingViewModelProvider.notifier);
    vm.setHotel(makeHotel());
    vm.setCheckin('2030-01-01');
    await vm.createBooking();
  }

  group('HotelBookingViewModel', () {
    test('create booking success stores booking result', () async {
      when(
        () => mockCreateUsecase(any()),
      ).thenAnswer((_) async => Right(makeCreateResult()));

      final vm = container.read(hotelBookingViewModelProvider.notifier);
      vm.setHotel(makeHotel());
      vm.setCheckin('2030-01-01');
      await vm.createBooking();

      final state = container.read(hotelBookingViewModelProvider);
      expect(state.status, HotelBookingViewStatus.loaded);
      expect(state.createdBooking, isNotNull);
      expect(state.createdBooking?.bookingId, 'booking-1');
      expect(state.payLocked, isFalse);
    });

    test('pay booking success updates payment result and locks flow', () async {
      await prepareCreatedBooking();

      when(
        () => mockPayUsecase(any()),
      ).thenAnswer((_) async => Right(makePayResult()));

      await container.read(hotelBookingViewModelProvider.notifier).payBooking();
      final state = container.read(hotelBookingViewModelProvider);

      expect(state.status, HotelBookingViewStatus.loaded);
      expect(state.paymentResult?.transactionId, 'txn-1');
      expect(state.createdBooking?.status, 'paid');
      expect(state.payLocked, isTrue);
    });

    test('duplicate pay taps are ignored while request is in-flight', () async {
      await prepareCreatedBooking();

      final completer =
          Completer<Either<Failure, PayHotelBookingResultEntity>>();
      when(() => mockPayUsecase(any())).thenAnswer((_) => completer.future);

      final vm = container.read(hotelBookingViewModelProvider.notifier);
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
        final params =
            invocation.positionalArguments.first as PayHotelBookingParams;
        capturedKeys.add(params.idempotencyKey);
        callCount++;

        if (callCount == 1) {
          return const Left(ApiFalilure(message: 'Payment failed'));
        }

        return Right(makePayResult());
      });

      final vm = container.read(hotelBookingViewModelProvider.notifier);
      await vm.payBooking();

      var state = container.read(hotelBookingViewModelProvider);
      expect(state.status, HotelBookingViewStatus.error);
      expect(state.payLocked, isFalse);

      await vm.payBooking();
      state = container.read(hotelBookingViewModelProvider);

      expect(state.status, HotelBookingViewStatus.loaded);
      expect(state.paymentResult, isNotNull);
      expect(capturedKeys.length, 2);
      expect(capturedKeys.first, isNotNull);
      expect(capturedKeys.first, capturedKeys.last);
    });
  });
}
