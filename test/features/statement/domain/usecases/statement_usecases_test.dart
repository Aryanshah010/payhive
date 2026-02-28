import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/entity/undo_request_entity.dart';
import 'package:payhive/features/statement/domain/repositories/statement_repositories.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';

class MockStatementRepository extends Mock implements IStatementRepository {}

void main() {
  late MockStatementRepository repository;

  setUp(() {
    repository = MockStatementRepository();
  });

  UndoRequestEntity undoRequestEntity({String status = 'PENDING'}) {
    return UndoRequestEntity(
      id: 'undo-1',
      transactionId: 'txn-id',
      originalTxId: 'tx-1',
      requester: const RecipientEntity(
        id: 'u-1',
        fullName: 'Sender',
        phoneNumber: '9800000001',
      ),
      receiver: const RecipientEntity(
        id: 'u-2',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      amount: 100,
      status: status,
      refundTransactionId: null,
      respondedAt: null,
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 2, 1),
    );
  }

  ReceiptEntity receiptEntity() {
    return ReceiptEntity(
      txId: 'refund-tx-1',
      status: 'SUCCESS',
      amount: 100,
      remark: 'Undo refund',
      paymentType: 'TRANSFER',
      meta: const {'reason': 'UNDO_REFUND'},
      from: const RecipientEntity(
        id: 'u-2',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      to: const RecipientEntity(
        id: 'u-1',
        fullName: 'Sender',
        phoneNumber: '9800000001',
      ),
      createdAt: DateTime(2026, 2, 1),
      direction: 'CREDIT',
    );
  }

  group('RequestUndoUsecase', () {
    test('returns validation failure for empty txId', () async {
      final usecase = RequestUndoUsecase(repository: repository);

      final result = await usecase(const RequestUndoParams(txId: '   '));

      expect(
        result,
        const Left(ValidationFailure(message: 'Transaction ID is required')),
      );
      verifyNever(() => repository.createUndoRequest(txId: any(named: 'txId')));
    });

    test('calls repository for valid txId', () async {
      final usecase = RequestUndoUsecase(repository: repository);
      when(
        () => repository.createUndoRequest(txId: any(named: 'txId')),
      ).thenAnswer((_) async => Right(undoRequestEntity()));

      final result = await usecase(const RequestUndoParams(txId: 'tx-1'));

      expect(result.isRight(), isTrue);
      verify(() => repository.createUndoRequest(txId: 'tx-1')).called(1);
    });
  });

  group('AcceptUndoUsecase', () {
    test('returns validation failure for empty requestId', () async {
      final usecase = AcceptUndoUsecase(repository: repository);

      final result = await usecase(
        const AcceptUndoParams(requestId: ' ', pin: '1234'),
      );

      expect(
        result,
        const Left(ValidationFailure(message: 'Request ID is required')),
      );
      verifyNever(
        () => repository.acceptUndoRequest(
          requestId: any(named: 'requestId'),
          pin: any(named: 'pin'),
        ),
      );
    });

    test('returns validation failure for invalid pin', () async {
      final usecase = AcceptUndoUsecase(repository: repository);

      final result = await usecase(
        const AcceptUndoParams(requestId: 'undo-1', pin: '12a4'),
      );

      expect(
        result,
        const Left(ValidationFailure(message: 'PIN must be exactly 4 digits.')),
      );
      verifyNever(
        () => repository.acceptUndoRequest(
          requestId: any(named: 'requestId'),
          pin: any(named: 'pin'),
        ),
      );
    });

    test('calls repository for valid requestId and pin', () async {
      final usecase = AcceptUndoUsecase(repository: repository);
      when(
        () => repository.acceptUndoRequest(
          requestId: any(named: 'requestId'),
          pin: any(named: 'pin'),
        ),
      ).thenAnswer(
        (_) async => Right(
          AcceptUndoResultEntity(
            request: undoRequestEntity(status: 'ACCEPTED'),
            receipt: receiptEntity(),
          ),
        ),
      );

      final result = await usecase(
        const AcceptUndoParams(requestId: 'undo-1', pin: '1234'),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => repository.acceptUndoRequest(requestId: 'undo-1', pin: '1234'),
      ).called(1);
    });
  });

  group('RejectUndoUsecase', () {
    test('returns validation failure for empty requestId', () async {
      final usecase = RejectUndoUsecase(repository: repository);

      final result = await usecase(const RejectUndoParams(requestId: '   '));

      expect(
        result,
        const Left(ValidationFailure(message: 'Request ID is required')),
      );
      verifyNever(
        () => repository.rejectUndoRequest(requestId: any(named: 'requestId')),
      );
    });

    test('calls repository for valid requestId', () async {
      final usecase = RejectUndoUsecase(repository: repository);
      when(
        () => repository.rejectUndoRequest(requestId: any(named: 'requestId')),
      ).thenAnswer((_) async => Right(undoRequestEntity(status: 'DENIED')));

      final result = await usecase(const RejectUndoParams(requestId: 'undo-1'));

      expect(result.isRight(), isTrue);
      verify(() => repository.rejectUndoRequest(requestId: 'undo-1')).called(1);
    });
  });

  group('Existing usecases regression', () {
    test('history usecase still validates allowed directions', () async {
      final usecase = GetTransactionHistoryUsecase(repository: repository);

      final result = await usecase(
        const HistoryParams(page: 1, limit: 10, direction: 'invalid'),
      );

      expect(
        result,
        const Left(ValidationFailure(message: 'Invalid direction filter')),
      );
    });

    test('detail usecase validates txId', () async {
      final usecase = GetTransactionDetailUsecase(repository: repository);

      final result = await usecase(const DetailParams(txId: '   '));

      expect(
        result,
        const Left(ValidationFailure(message: 'Transaction ID is required')),
      );
    });
  });
}
