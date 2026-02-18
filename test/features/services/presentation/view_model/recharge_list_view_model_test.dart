import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/services/domain/entity/paged_result_entity.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';
import 'package:payhive/features/services/domain/usecases/recharge_usecases.dart';
import 'package:payhive/features/services/presentation/state/recharge_list_state.dart';
import 'package:payhive/features/services/presentation/view_model/recharge_list_view_model.dart';

class MockGetRechargeServicesUsecase extends Mock
    implements GetRechargeServicesUsecase {}

void main() {
  late MockGetRechargeServicesUsecase mockUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const GetRechargeServicesParams(page: 1, limit: 10));
  });

  setUp(() {
    mockUsecase = MockGetRechargeServicesUsecase();
    container = ProviderContainer(
      overrides: [
        getRechargeServicesUsecaseProvider.overrideWithValue(mockUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  RechargeServiceEntity service({
    required String id,
    required String provider,
    required String name,
  }) {
    return RechargeServiceEntity(
      id: id,
      type: 'topup',
      provider: provider,
      name: name,
      packageLabel: '2GB Daily',
      amount: 299,
      validationRegex: r'^\d{10}$',
      isActive: true,
      meta: const {},
    );
  }

  PagedResultEntity<RechargeServiceEntity> paged({
    required List<RechargeServiceEntity> items,
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

  group('RechargeListViewModel', () {
    test('initial load success updates services and pagination', () async {
      when(() => mockUsecase(any())).thenAnswer(
        (_) async => Right(
          paged(
            items: [service(id: 'topup-1', provider: 'NTC', name: 'Data Pack')],
            page: 1,
            totalPages: 1,
          ),
        ),
      );

      await container
          .read(rechargeListViewModelProvider.notifier)
          .loadInitial();
      final state = container.read(rechargeListViewModelProvider);

      expect(state.status, RechargeListViewStatus.loaded);
      expect(state.services.length, 1);
      expect(state.page, 1);
      expect(state.totalPages, 1);
    });

    test('apply filters trims provider and search then reloads', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as GetRechargeServicesParams;
        expect(params.page, 1);
        expect(params.provider, 'NTC');
        expect(params.search, 'Data');

        return Right(
          paged(
            items: [service(id: 'topup-2', provider: 'NTC', name: 'Data')],
            page: 1,
            totalPages: 1,
          ),
        );
      });

      await container
          .read(rechargeListViewModelProvider.notifier)
          .applyFilters(provider: ' NTC ', search: ' Data ');

      final state = container.read(rechargeListViewModelProvider);
      expect(state.provider, 'NTC');
      expect(state.search, 'Data');
      expect(state.services.first.id, 'topup-2');
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
              service(id: 'topup-3', provider: 'Ncell', name: 'Voice Pack'),
            ],
            page: 1,
            totalPages: 1,
          ),
        );
      });

      final vm = container.read(rechargeListViewModelProvider.notifier);
      await vm.loadInitial();

      var state = container.read(rechargeListViewModelProvider);
      expect(state.status, RechargeListViewStatus.error);
      expect(state.errorMessage, 'Load failed');

      await vm.loadInitial();
      state = container.read(rechargeListViewModelProvider);

      expect(state.status, RechargeListViewStatus.loaded);
      expect(state.services.length, 1);
      expect(state.errorMessage, isNull);
    });

    test('pagination appends next page items', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as GetRechargeServicesParams;

        if (params.page == 1) {
          return Right(
            paged(
              items: [service(id: 'topup-1', provider: 'NTC', name: 'Data')],
              page: 1,
              totalPages: 2,
            ),
          );
        }

        return Right(
          paged(
            items: [service(id: 'topup-2', provider: 'Ncell', name: 'Voice')],
            page: 2,
            totalPages: 2,
          ),
        );
      });

      final vm = container.read(rechargeListViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.loadMore();

      final state = container.read(rechargeListViewModelProvider);
      expect(state.services.length, 2);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);
    });
  });
}
