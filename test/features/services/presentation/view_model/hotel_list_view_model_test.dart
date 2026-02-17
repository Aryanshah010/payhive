import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/usecases/hotel_usecases.dart';
import 'package:payhive/features/services/presentation/state/hotel_list_state.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_list_view_model.dart';

class MockGetHotelsUsecase extends Mock implements GetHotelsUsecase {}

void main() {
  late MockGetHotelsUsecase mockUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const GetHotelsParams(page: 1, limit: 10));
  });

  setUp(() {
    mockUsecase = MockGetHotelsUsecase();
    container = ProviderContainer(
      overrides: [getHotelsUsecaseProvider.overrideWithValue(mockUsecase)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  HotelEntity hotel({required String id, required String city}) {
    return HotelEntity(
      id: id,
      name: 'Hotel $id',
      city: city,
      roomType: 'Deluxe',
      roomsTotal: 50,
      roomsAvailable: 12,
      pricePerNight: 4800,
      amenities: const ['wifi'],
      images: const [],
    );
  }

  PagedResultEntity<HotelEntity> paged({
    required List<HotelEntity> items,
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

  group('HotelListViewModel', () {
    test('initial load success updates hotels and pagination', () async {
      when(() => mockUsecase(any())).thenAnswer(
        (_) async => Right(
          paged(
            items: [hotel(id: 'h1', city: 'Kathmandu')],
            page: 1,
            totalPages: 1,
          ),
        ),
      );

      await container.read(hotelListViewModelProvider.notifier).loadInitial();
      final state = container.read(hotelListViewModelProvider);

      expect(state.status, HotelListViewStatus.loaded);
      expect(state.hotels.length, 1);
      expect(state.page, 1);
      expect(state.totalPages, 1);
    });

    test('apply city filter trims value and reloads page one', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as GetHotelsParams;
        expect(params.page, 1);
        expect(params.city, 'Pokhara');

        return Right(
          paged(
            items: [hotel(id: 'h2', city: 'Pokhara')],
            page: 1,
            totalPages: 1,
          ),
        );
      });

      await container
          .read(hotelListViewModelProvider.notifier)
          .applyCityFilter(' Pokhara ');

      final state = container.read(hotelListViewModelProvider);
      expect(state.city, 'Pokhara');
      expect(state.hotels.first.id, 'h2');
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
            items: [hotel(id: 'h3', city: 'Chitwan')],
            page: 1,
            totalPages: 1,
          ),
        );
      });

      final vm = container.read(hotelListViewModelProvider.notifier);
      await vm.loadInitial();

      var state = container.read(hotelListViewModelProvider);
      expect(state.status, HotelListViewStatus.error);
      expect(state.errorMessage, 'Load failed');

      await vm.loadInitial();
      state = container.read(hotelListViewModelProvider);

      expect(state.status, HotelListViewStatus.loaded);
      expect(state.hotels.length, 1);
      expect(state.errorMessage, isNull);
    });

    test('pagination appends next page items', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as GetHotelsParams;
        if (params.page == 1) {
          return Right(
            paged(
              items: [hotel(id: 'h1', city: 'Kathmandu')],
              page: 1,
              totalPages: 2,
            ),
          );
        }

        return Right(
          paged(
            items: [hotel(id: 'h2', city: 'Pokhara')],
            page: 2,
            totalPages: 2,
          ),
        );
      });

      final vm = container.read(hotelListViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.loadMore();

      final state = container.read(hotelListViewModelProvider);
      expect(state.hotels.length, 2);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);
    });
  });
}
