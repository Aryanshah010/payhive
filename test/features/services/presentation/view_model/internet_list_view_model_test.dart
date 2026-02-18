import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/usecases/internet_usecases.dart';
import 'package:payhive/features/services/presentation/state/internet_list_state.dart';
import 'package:payhive/features/services/presentation/view_model/internet_list_view_model.dart';

class MockGetInternetServicesUsecase extends Mock
    implements GetInternetServicesUsecase {}

void main() {
  late MockGetInternetServicesUsecase mockUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const GetInternetServicesParams(page: 1, limit: 10));
  });

  setUp(() {
    mockUsecase = MockGetInternetServicesUsecase();
    container = ProviderContainer(
      overrides: [
        getInternetServicesUsecaseProvider.overrideWithValue(mockUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  InternetServiceEntity service({
    required String id,
    required String provider,
    required String name,
  }) {
    return InternetServiceEntity(
      id: id,
      type: 'internet',
      provider: provider,
      name: name,
      packageLabel: 'Monthly',
      amount: 999,
      validationRegex: r'^[A-Z0-9]{6,16}$',
      isActive: true,
      meta: const {},
    );
  }

  PagedResultEntity<InternetServiceEntity> paged({
    required List<InternetServiceEntity> items,
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

  group('InternetListViewModel', () {
    test('initial load success updates services and pagination', () async {
      when(() => mockUsecase(any())).thenAnswer(
        (_) async => Right(
          paged(
            items: [
              service(
                id: 'int-1',
                provider: 'Airtel Xstream',
                name: 'Fiber 100 Mbps',
              ),
            ],
            page: 1,
            totalPages: 1,
          ),
        ),
      );

      await container
          .read(internetListViewModelProvider.notifier)
          .loadInitial();
      final state = container.read(internetListViewModelProvider);

      expect(state.status, InternetListViewStatus.loaded);
      expect(state.services.length, 1);
      expect(state.page, 1);
      expect(state.totalPages, 1);
    });

    test('apply filters trims provider and search then reloads', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as GetInternetServicesParams;
        expect(params.page, 1);
        expect(params.provider, 'Airtel');
        expect(params.search, 'Fiber');

        return Right(
          paged(
            items: [service(id: 'int-2', provider: 'Airtel', name: 'Fiber')],
            page: 1,
            totalPages: 1,
          ),
        );
      });

      await container
          .read(internetListViewModelProvider.notifier)
          .applyFilters(provider: ' Airtel ', search: ' Fiber ');

      final state = container.read(internetListViewModelProvider);
      expect(state.provider, 'Airtel');
      expect(state.search, 'Fiber');
      expect(state.services.first.id, 'int-2');
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
            items: [
              service(
                id: 'int-3',
                provider: 'JioFiber',
                name: 'Fiber 150 Mbps',
              ),
            ],
            page: 1,
            totalPages: 1,
          ),
        );
      });

      final vm = container.read(internetListViewModelProvider.notifier);
      await vm.loadInitial();

      var state = container.read(internetListViewModelProvider);
      expect(state.status, InternetListViewStatus.error);
      expect(state.errorMessage, 'Load failed');

      await vm.loadInitial();
      state = container.read(internetListViewModelProvider);

      expect(state.status, InternetListViewStatus.loaded);
      expect(state.services.length, 1);
      expect(state.errorMessage, isNull);
    });

    test('pagination appends next page items', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as GetInternetServicesParams;

        if (params.page == 1) {
          return Right(
            paged(
              items: [
                service(
                  id: 'int-1',
                  provider: 'Airtel',
                  name: 'Fiber 100 Mbps',
                ),
              ],
              page: 1,
              totalPages: 2,
            ),
          );
        }

        return Right(
          paged(
            items: [
              service(
                id: 'int-2',
                provider: 'JioFiber',
                name: 'Fiber 150 Mbps',
              ),
            ],
            page: 2,
            totalPages: 2,
          ),
        );
      });

      final vm = container.read(internetListViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.loadMore();

      final state = container.read(internetListViewModelProvider);
      expect(state.services.length, 2);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);
    });
  });
}
