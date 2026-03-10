import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/usecases/hotel_usecases.dart';
import 'package:payhive/features/services/presentation/state/hotel_bookings_state.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_bookings_view_model.dart';

class MockGetHotelBookingsUsecase extends Mock
    implements GetHotelBookingsUsecase {}

class MockPayHotelBookingUsecase extends Mock
    implements PayHotelBookingUsecase {}

void main() {
  late MockGetHotelBookingsUsecase mockGetBookingsUsecase;
  late MockPayHotelBookingUsecase mockPayBookingUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const GetHotelBookingsParams(page: 1, limit: 10));
    registerFallbackValue(const PayHotelBookingParams(bookingId: 'booking-1'));
  });

  setUp(() {
    mockGetBookingsUsecase = MockGetHotelBookingsUsecase();
    mockPayBookingUsecase = MockPayHotelBookingUsecase();

    container = ProviderContainer(
      overrides: [
        getHotelBookingsUsecaseProvider.overrideWithValue(
          mockGetBookingsUsecase,
        ),
        payHotelBookingUsecaseProvider.overrideWithValue(mockPayBookingUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  HotelBookingItemEntity booking({required String id, required String status}) {
    return HotelBookingItemEntity(
      id: id,
      status: status,
      quantity: 1,
      nights: 2,
      price: 9600,
      name: 'Thamel Boutique Residency',
      city: 'Kathmandu',
      createdAt: DateTime(2026, 3, 10),
    );
  }

  PagedResultEntity<HotelBookingItemEntity> paged({
    required List<HotelBookingItemEntity> items,
    required int page,
    required int totalPages,
  }) {
    return PagedResultEntity(
      items: items,
      total: items.length,
      page: page,
      limit: 10,
      totalPages: totalPages,
    );
  }

  group('HotelBookingsViewModel', () {
    test(
      'status filter change resets list and fetches selected status',
      () async {
        when(() => mockGetBookingsUsecase(any())).thenAnswer((
          invocation,
        ) async {
          final params =
              invocation.positionalArguments.first as GetHotelBookingsParams;

          if (params.status == 'paid') {
            return Right(
              paged(
                items: [booking(id: 'b2', status: 'paid')],
                page: 1,
                totalPages: 1,
              ),
            );
          }

          return Right(
            paged(
              items: [booking(id: 'b1', status: 'created')],
              page: 1,
              totalPages: 2,
            ),
          );
        });

        final vm = container.read(hotelBookingsViewModelProvider.notifier);
        await vm.loadInitial();
        await vm.applyFilter(HotelBookingFilter.paid);

        final state = container.read(hotelBookingsViewModelProvider);
        expect(state.filter, HotelBookingFilter.paid);
        expect(state.bookings.length, 1);
        expect(state.bookings.first.status, 'paid');

        verify(
          () => mockGetBookingsUsecase(
            const GetHotelBookingsParams(page: 1, limit: 10, status: 'paid'),
          ),
        ).called(1);
      },
    );

    test('load more appends items and stops at last page', () async {
      when(() => mockGetBookingsUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as GetHotelBookingsParams;

        if (params.page == 1) {
          return Right(
            paged(
              items: [booking(id: 'b1', status: 'created')],
              page: 1,
              totalPages: 2,
            ),
          );
        }

        return Right(
          paged(
            items: [booking(id: 'b2', status: 'paid')],
            page: 2,
            totalPages: 2,
          ),
        );
      });

      final vm = container.read(hotelBookingsViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.loadMore();
      await vm.loadMore();

      final state = container.read(hotelBookingsViewModelProvider);
      expect(state.bookings.length, 2);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);
    });

    test('pay booking updates booking row and sets success signal', () async {
      when(() => mockGetBookingsUsecase(any())).thenAnswer(
        (_) async => Right(
          paged(
            items: [booking(id: 'booking-1', status: 'created')],
            page: 1,
            totalPages: 1,
          ),
        ),
      );

      when(() => mockPayBookingUsecase(any())).thenAnswer(
        (_) async => Right(
          PayHotelBookingResultEntity(
            booking: HotelBookingItemEntity(
              id: 'booking-1',
              status: 'paid',
              paymentTxnId: 'txn-1',
              paidAt: DateTime(2026, 3, 11),
            ),
            transactionId: 'txn-1',
            idempotentReplay: false,
          ),
        ),
      );

      final vm = container.read(hotelBookingsViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.payBooking('booking-1');

      final state = container.read(hotelBookingsViewModelProvider);
      expect(state.bookings.first.status, 'paid');
      expect(state.bookings.first.paymentTxnId, 'txn-1');
      expect(state.lastPaidBookingId, 'booking-1');
      expect(state.isBookingPaying('booking-1'), isFalse);
    });
  });
}
