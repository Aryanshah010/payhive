import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/usecases/flight_usecases.dart';
import 'package:payhive/features/services/presentation/state/flight_list_state.dart';
import 'package:payhive/features/services/presentation/view_model/flight_list_view_model.dart';

class MockGetFlightsUsecase extends Mock implements GetFlightsUsecase {}

void main() {
  late MockGetFlightsUsecase mockUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const GetFlightsParams(page: 1, limit: 10));
  });

  setUp(() {
    mockUsecase = MockGetFlightsUsecase();
    container = ProviderContainer(
      overrides: [getFlightsUsecaseProvider.overrideWithValue(mockUsecase)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  FlightEntity flight({
    required String id,
    required String from,
    required String to,
  }) {
    return FlightEntity(
      id: id,
      airline: 'Buddha Air',
      flightNumber: 'U4-201',
      from: from,
      to: to,
      departure: DateTime(2026, 3, 15, 8, 0),
      arrival: DateTime(2026, 3, 15, 9, 0),
      durationMinutes: 60,
      flightClass: 'Economy',
      price: 4500,
      seatsTotal: 70,
      seatsAvailable: 30,
    );
  }

  PagedResultEntity<FlightEntity> paged({
    required List<FlightEntity> items,
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

  group('FlightListViewModel', () {
    test('initial load success updates flights and pagination', () async {
      when(() => mockUsecase(any())).thenAnswer(
        (_) async => Right(
          paged(
            items: [flight(id: 'f1', from: 'Kathmandu', to: 'Pokhara')],
            page: 1,
            totalPages: 1,
          ),
        ),
      );

      await container.read(flightListViewModelProvider.notifier).loadInitial();
      final state = container.read(flightListViewModelProvider);

      expect(state.status, FlightListViewStatus.loaded);
      expect(state.flights.length, 1);
      expect(state.page, 1);
      expect(state.totalPages, 1);

      verify(
        () => mockUsecase(
          const GetFlightsParams(
            page: 1,
            limit: 10,
            from: '',
            to: '',
            date: null,
          ),
        ),
      ).called(1);
    });

    test('apply filters trims values and reloads page one', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as GetFlightsParams;
        expect(params.page, 1);
        expect(params.from, 'Kathmandu');
        expect(params.to, 'Pokhara');
        expect(params.date, '2026-03-15');

        return Right(
          paged(
            items: [flight(id: 'f2', from: 'Kathmandu', to: 'Pokhara')],
            page: 1,
            totalPages: 1,
          ),
        );
      });

      await container
          .read(flightListViewModelProvider.notifier)
          .applyFilters(
            from: ' Kathmandu ',
            to: ' Pokhara ',
            date: ' 2026-03-15 ',
          );

      final state = container.read(flightListViewModelProvider);
      expect(state.from, 'Kathmandu');
      expect(state.to, 'Pokhara');
      expect(state.date, '2026-03-15');
      expect(state.flights.first.id, 'f2');
    });

    test('retry after failure succeeds', () async {
      var callCount = 0;
      when(() => mockUsecase(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return const Left(ApiFalilure(message: 'Load failed'));
        }

        return Right(
          paged(
            items: [flight(id: 'f3', from: 'KTM', to: 'BWA')],
            page: 1,
            totalPages: 1,
          ),
        );
      });

      final vm = container.read(flightListViewModelProvider.notifier);
      await vm.loadInitial();

      var state = container.read(flightListViewModelProvider);
      expect(state.status, FlightListViewStatus.error);
      expect(state.errorMessage, 'Load failed');

      await vm.loadInitial();
      state = container.read(flightListViewModelProvider);

      expect(state.status, FlightListViewStatus.loaded);
      expect(state.flights.length, 1);
      expect(state.errorMessage, isNull);
    });

    test('pagination appends next page items', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as GetFlightsParams;
        if (params.page == 1) {
          return Right(
            paged(
              items: [flight(id: 'f1', from: 'KTM', to: 'PKR')],
              page: 1,
              totalPages: 2,
            ),
          );
        }

        return Right(
          paged(
            items: [flight(id: 'f2', from: 'KTM', to: 'BWA')],
            page: 2,
            totalPages: 2,
          ),
        );
      });

      final vm = container.read(flightListViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.loadMore();

      final state = container.read(flightListViewModelProvider);
      expect(state.flights.length, 2);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);
    });
  });
}
