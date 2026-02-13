import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/state/statement_detail_state.dart';
import 'package:payhive/features/statement/presentation/view_model/statement_detail_view_model.dart';

class MockGetTransactionDetailUsecase extends Mock
    implements GetTransactionDetailUsecase {}

void main() {
  late MockGetTransactionDetailUsecase mockUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const DetailParams(txId: 'fallback'));
  });

  setUp(() {
    mockUsecase = MockGetTransactionDetailUsecase();
    container = ProviderContainer(
      overrides: [
        getTransactionDetailUsecaseProvider.overrideWithValue(mockUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  ReceiptEntity makeReceipt({
    required String txId,
    required String status,
    double amount = 100,
  }) {
    return ReceiptEntity(
      txId: txId,
      status: status,
      amount: amount,
      remark: 'remark',
      from: const RecipientEntity(
        id: 'from-id',
        fullName: 'Sender',
        phoneNumber: '9800000001',
      ),
      to: const RecipientEntity(
        id: 'to-id',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      createdAt: DateTime(2026, 1, 1),
      direction: 'DEBIT',
    );
  }

  group('StatementDetailViewModel', () {
    test('success load transitions loading -> loaded', () async {
      final receipt = makeReceipt(txId: 'tx-1', status: 'SUCCESS');
      final completer = Completer<Either<Failure, ReceiptEntity>>();

      when(() => mockUsecase(any())).thenAnswer((_) => completer.future);

      final vm = container.read(statementDetailViewModelProvider.notifier);
      final loadFuture = vm.load(txId: 'tx-1');

      expect(
        container.read(statementDetailViewModelProvider).status,
        StatementDetailViewStatus.loading,
      );

      completer.complete(Right(receipt));
      await loadFuture;

      final state = container.read(statementDetailViewModelProvider);
      expect(state.status, StatementDetailViewStatus.loaded);
      expect(state.receipt, receipt);
      expect(state.errorMessage, isNull);
    });

    test('failure with fallback keeps fallback and surfaces error', () async {
      final fallback = makeReceipt(txId: 'tx-fallback', status: 'SUCCESS');
      when(() => mockUsecase(any())).thenAnswer(
        (_) async => const Left(ApiFalilure(message: 'Request failed')),
      );

      await container
          .read(statementDetailViewModelProvider.notifier)
          .load(txId: 'tx-fallback', fallback: fallback);

      final state = container.read(statementDetailViewModelProvider);
      expect(state.status, StatementDetailViewStatus.loaded);
      expect(state.receipt, fallback);
      expect(state.errorMessage, 'Request failed');
    });

    test('failure without fallback goes to error state', () async {
      when(() => mockUsecase(any())).thenAnswer(
        (_) async => const Left(ApiFalilure(message: 'Unable to load')),
      );

      await container
          .read(statementDetailViewModelProvider.notifier)
          .load(txId: 'tx-error');

      final state = container.read(statementDetailViewModelProvider);
      expect(state.status, StatementDetailViewStatus.error);
      expect(state.receipt, isNull);
      expect(state.errorMessage, 'Unable to load');
    });

    test('retry after failure can succeed', () async {
      final receipt = makeReceipt(txId: 'tx-retry', status: 'SUCCESS');
      var callCount = 0;
      when(() => mockUsecase(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return const Left(ApiFalilure(message: 'Temporary failure'));
        }
        return Right(receipt);
      });

      final vm = container.read(statementDetailViewModelProvider.notifier);
      await vm.load(txId: 'tx-retry');
      await vm.load(txId: 'tx-retry');

      final state = container.read(statementDetailViewModelProvider);
      expect(state.status, StatementDetailViewStatus.loaded);
      expect(state.receipt, receipt);
      expect(state.errorMessage, isNull);
      verify(() => mockUsecase(any())).called(2);
    });
  });
}
