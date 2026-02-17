import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/usecases/flight_usecases.dart';
import 'package:payhive/features/services/presentation/state/flight_bookings_state.dart';
import 'package:payhive/features/services/presentation/view_model/flight_bookings_view_model.dart';

class MockGetFlightBookingsUsecase extends Mock
    implements GetFlightBookingsUsecase {}

class MockPayBookingUsecase extends Mock implements PayBookingUsecase {}

void main() {
  late MockGetFlightBookingsUsecase mockGetBookingsUsecase;
  late MockPayBookingUsecase mockPayBookingUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const GetFlightBookingsParams(page: 1, limit: 10));
    registerFallbackValue(const PayBookingParams(bookingId: 'booking-1'));
  });

  setUp(() {
    mockGetBookingsUsecase = MockGetFlightBookingsUsecase();
    mockPayBookingUsecase = MockPayBookingUsecase();

    container = ProviderContainer(
      overrides: [
        getFlightBookingsUsecaseProvider.overrideWithValue(
          mockGetBookingsUsecase,
        ),
        payBookingUsecaseProvider.overrideWithValue(mockPayBookingUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  FlightBookingItemEntity booking({
    required String id,
    required String status,
  }) {
    return FlightBookingItemEntity(
      id: id,
      status: status,
      quantity: 1,
      price: 4500,
      airline: 'Buddha Air',
      flightNumber: 'U4-201',
      from: 'Kathmandu',
      to: 'Pokhara',
      createdAt: DateTime(2026, 3, 10),
    );
  }

  PagedResultEntity<FlightBookingItemEntity> paged({
    required List<FlightBookingItemEntity> items,
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

  group('FlightBookingsViewModel', () {
    test(
      'status filter change resets list and fetches selected status',
      () async {
        when(() => mockGetBookingsUsecase(any())).thenAnswer((
          invocation,
        ) async {
          final params =
              invocation.positionalArguments.first as GetFlightBookingsParams;

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

        final vm = container.read(flightBookingsViewModelProvider.notifier);
        await vm.loadInitial();
        await vm.applyFilter(FlightBookingFilter.paid);

        final state = container.read(flightBookingsViewModelProvider);
        expect(state.filter, FlightBookingFilter.paid);
        expect(state.bookings.length, 1);
        expect(state.bookings.first.status, 'paid');

        verify(
          () => mockGetBookingsUsecase(
            const GetFlightBookingsParams(page: 1, limit: 10, status: 'paid'),
          ),
        ).called(1);
      },
    );

    test('load more appends items and stops at last page', () async {
      when(() => mockGetBookingsUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as GetFlightBookingsParams;

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

      final vm = container.read(flightBookingsViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.loadMore();
      await vm.loadMore();

      final state = container.read(flightBookingsViewModelProvider);
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
          PayBookingResultEntity(
            booking: FlightBookingItemEntity(
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

      final vm = container.read(flightBookingsViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.payBooking('booking-1');

      final state = container.read(flightBookingsViewModelProvider);
      expect(state.bookings.first.status, 'paid');
      expect(state.bookings.first.paymentTxnId, 'txn-1');
      expect(state.lastPaidBookingId, 'booking-1');
      expect(state.isBookingPaying('booking-1'), isFalse);
    });
  });
}
