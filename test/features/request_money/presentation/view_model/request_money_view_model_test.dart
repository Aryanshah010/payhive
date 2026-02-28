import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';
import 'package:payhive/features/request_money/domain/usecases/request_money_usecase.dart';
import 'package:payhive/features/request_money/presentation/state/request_money_state.dart';
import 'package:payhive/features/request_money/presentation/view_model/request_money_view_model.dart';

class MockCreateMoneyRequestUsecase extends Mock
    implements CreateMoneyRequestUsecase {}

class MockGetOutgoingMoneyRequestsUsecase extends Mock
    implements GetOutgoingMoneyRequestsUsecase {}

class MockRespondMoneyRequestUsecase extends Mock
    implements RespondMoneyRequestUsecase {}

void main() {
  late MockCreateMoneyRequestUsecase mockCreateUsecase;
  late MockGetOutgoingMoneyRequestsUsecase mockGetOutgoingUsecase;
  late MockRespondMoneyRequestUsecase mockRespondUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const CreateMoneyRequestParams(toPhoneNumber: '9800000001', amount: 100),
    );
    registerFallbackValue(
      const GetOutgoingMoneyRequestsParams(page: 1, limit: 10),
    );
    registerFallbackValue(
      const RespondMoneyRequestParams(
        requestId: 'req-1',
        action: MoneyRequestAction.cancel,
      ),
    );
  });

  setUp(() {
    mockCreateUsecase = MockCreateMoneyRequestUsecase();
    mockGetOutgoingUsecase = MockGetOutgoingMoneyRequestsUsecase();
    mockRespondUsecase = MockRespondMoneyRequestUsecase();

    container = ProviderContainer(
      overrides: [
        createMoneyRequestUsecaseProvider.overrideWithValue(mockCreateUsecase),
        getOutgoingMoneyRequestsUsecaseProvider.overrideWithValue(
          mockGetOutgoingUsecase,
        ),
        respondMoneyRequestUsecaseProvider.overrideWithValue(
          mockRespondUsecase,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  MoneyRequestEntity request({required String id}) {
    return MoneyRequestEntity(
      id: id,
      requester: const RecipientEntity(
        id: 'requester-id',
        fullName: 'Requester',
        phoneNumber: '9800000001',
      ),
      receiver: const RecipientEntity(
        id: 'receiver-id',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      amount: 100,
      remark: 'Rent',
      status: 'PENDING',
      expiresAt: DateTime(2026, 1, 10),
      respondedAt: null,
      transactionId: null,
      createdAt: DateTime(2026, 1, 1, 12, 0),
      updatedAt: DateTime(2026, 1, 1, 12, 0),
    );
  }

  MoneyRequestPageEntity page({
    required List<MoneyRequestEntity> items,
    required int page,
    required int totalPages,
  }) {
    return MoneyRequestPageEntity(
      items: items,
      total: items.length,
      page: page,
      limit: 10,
      totalPages: totalPages,
    );
  }

  group('RequestMoneyViewModel', () {
    test('initial load success updates pending list', () async {
      when(() => mockGetOutgoingUsecase(any())).thenAnswer(
        (_) async =>
            Right(page(items: [request(id: 'req-1')], page: 1, totalPages: 1)),
      );

      await container
          .read(requestMoneyViewModelProvider.notifier)
          .loadInitialPending();

      final state = container.read(requestMoneyViewModelProvider);
      expect(state.status, RequestMoneyStatus.loaded);
      expect(state.pendingRequests.length, 1);
      expect(state.page, 1);
      expect(state.totalPages, 1);
    });

    test('initial load failure sets error state', () async {
      when(() => mockGetOutgoingUsecase(any())).thenAnswer(
        (_) async => const Left(ApiFalilure(message: 'Failed to load')),
      );

      await container
          .read(requestMoneyViewModelProvider.notifier)
          .loadInitialPending();

      final state = container.read(requestMoneyViewModelProvider);
      expect(state.status, RequestMoneyStatus.error);
      expect(state.pendingErrorMessage, 'Failed to load');
    });

    test(
      'create success clears amount/message and reloads pending list',
      () async {
        var getOutgoingCalls = 0;
        when(() => mockGetOutgoingUsecase(any())).thenAnswer((_) async {
          getOutgoingCalls += 1;
          if (getOutgoingCalls == 1) {
            return Right(page(items: const [], page: 1, totalPages: 1));
          }
          return Right(
            page(items: [request(id: 'req-2')], page: 1, totalPages: 1),
          );
        });
        when(
          () => mockCreateUsecase(any()),
        ).thenAnswer((_) async => Right(request(id: 'req-created')));

        final vm = container.read(requestMoneyViewModelProvider.notifier);
        await vm.loadInitialPending();
        vm.setPhoneNumber('9800000001');
        vm.setAmountInput('250');
        vm.setRemark('Monthly rent');

        await vm.submitRequest();

        final state = container.read(requestMoneyViewModelProvider);
        expect(state.amountInput, '');
        expect(state.remark, isNull);
        expect(state.pendingRequests.length, 1);
        expect(state.pendingRequests.first.id, 'req-2');
        verify(() => mockCreateUsecase(any())).called(1);
      },
    );

    test('create failure keeps entered form values and sets error', () async {
      when(() => mockGetOutgoingUsecase(any())).thenAnswer(
        (_) async => Right(page(items: const [], page: 1, totalPages: 1)),
      );
      when(() => mockCreateUsecase(any())).thenAnswer(
        (_) async =>
            const Left(ApiFalilure(message: 'Unable to create request')),
      );

      final vm = container.read(requestMoneyViewModelProvider.notifier);
      await vm.loadInitialPending();
      vm.setPhoneNumber('9800000001');
      vm.setAmountInput('500');
      vm.setRemark('Dinner split');

      await vm.submitRequest();

      final state = container.read(requestMoneyViewModelProvider);
      expect(state.status, RequestMoneyStatus.initial);
      expect(state.errorMessage, 'Unable to create request');
      expect(state.phoneNumber, '9800000001');
      expect(state.amountInput, '500');
      expect(state.remark, 'Dinner split');
    });

    test(
      'invalid submit sets inline errors and skips create usecase',
      () async {
        final vm = container.read(requestMoneyViewModelProvider.notifier);

        vm.setPhoneNumber('123');
        vm.setAmountInput('0');
        await vm.submitRequest();

        final state = container.read(requestMoneyViewModelProvider);
        expect(state.showValidationErrors, isTrue);
        expect(state.phoneError, isNotNull);
        expect(state.amountError, isNotNull);
        verifyNever(() => mockCreateUsecase(any()));
      },
    );

    test('pending load error does not alter form validation state', () async {
      when(() => mockGetOutgoingUsecase(any())).thenAnswer(
        (_) async => const Left(ApiFalilure(message: 'Pending list failed')),
      );

      final vm = container.read(requestMoneyViewModelProvider.notifier);
      vm.setPhoneNumber('9800000001');
      vm.setAmountInput('120');
      vm.setRemark('hello');

      await vm.loadInitialPending();

      final state = container.read(requestMoneyViewModelProvider);
      expect(state.pendingErrorMessage, 'Pending list failed');
      expect(state.phoneError, isNull);
      expect(state.amountError, isNull);
      expect(state.remarkError, isNull);
      expect(state.showValidationErrors, isFalse);
    });

    test('cancel success refreshes pending list', () async {
      var getOutgoingCalls = 0;
      when(() => mockGetOutgoingUsecase(any())).thenAnswer((_) async {
        getOutgoingCalls += 1;
        if (getOutgoingCalls == 1) {
          return Right(
            page(items: [request(id: 'req-1')], page: 1, totalPages: 1),
          );
        }
        return Right(page(items: const [], page: 1, totalPages: 1));
      });
      when(
        () => mockRespondUsecase(any()),
      ).thenAnswer((_) async => Right(request(id: 'req-1')));

      final vm = container.read(requestMoneyViewModelProvider.notifier);
      await vm.loadInitialPending();
      await vm.cancelRequest('req-1');

      final state = container.read(requestMoneyViewModelProvider);
      expect(state.pendingRequests, isEmpty);
      expect(state.activeCancelRequestId, isNull);
      verify(
        () => mockRespondUsecase(
          const RespondMoneyRequestParams(
            requestId: 'req-1',
            action: MoneyRequestAction.cancel,
          ),
        ),
      ).called(1);
    });

    test('pagination appends next page and stops at last page', () async {
      when(() => mockGetOutgoingUsecase(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first
                as GetOutgoingMoneyRequestsParams;

        if (params.page == 1) {
          return Right(
            page(items: [request(id: 'req-1')], page: 1, totalPages: 2),
          );
        }

        return Right(
          page(items: [request(id: 'req-2')], page: 2, totalPages: 2),
        );
      });

      final vm = container.read(requestMoneyViewModelProvider.notifier);
      await vm.loadInitialPending();
      await vm.loadMorePending();
      await vm.loadMorePending();

      final state = container.read(requestMoneyViewModelProvider);
      expect(state.pendingRequests.length, 2);
      expect(state.pendingRequests[0].id, 'req-1');
      expect(state.pendingRequests[1].id, 'req-2');

      verify(() => mockGetOutgoingUsecase(any())).called(2);
    });

    test(
      'initial and refresh top-level loads are deduped when overlapping',
      () async {
        final completer = Completer<Either<Failure, MoneyRequestPageEntity>>();
        when(
          () => mockGetOutgoingUsecase(any()),
        ).thenAnswer((_) => completer.future);

        final vm = container.read(requestMoneyViewModelProvider.notifier);
        final first = vm.loadInitialPending();
        final second = vm.refreshPending();

        verify(() => mockGetOutgoingUsecase(any())).called(1);

        completer.complete(
          Right(page(items: [request(id: 'req-1')], page: 1, totalPages: 1)),
        );
        await Future.wait([first, second]);
      },
    );
  });
}
