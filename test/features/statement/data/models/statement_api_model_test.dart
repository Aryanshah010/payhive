import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/statement/data/models/statement_api_model.dart';

void main() {
  group('UndoRequestApiModel', () {
    test('fromJson parses undo request payload', () {
      final model = UndoRequestApiModel.fromJson({
        'id': 'undo-1',
        'transactionId': 'txn-mongo-id',
        'originalTxId': 'tx-1001',
        'requester': {
          'id': 'u-1',
          'fullName': 'Sender',
          'phoneNumber': '9800000001',
        },
        'receiver': {
          'id': 'u-2',
          'fullName': 'Receiver',
          'phoneNumber': '9800000002',
        },
        'amount': 125.5,
        'status': 'PENDING',
        'refundTransactionId': null,
        'respondedAt': null,
        'createdAt': '2026-02-01T12:00:00.000Z',
        'updatedAt': '2026-02-01T12:00:00.000Z',
      });

      final entity = model.toEntity();
      expect(entity.id, 'undo-1');
      expect(entity.transactionId, 'txn-mongo-id');
      expect(entity.originalTxId, 'tx-1001');
      expect(entity.requester.fullName, 'Sender');
      expect(entity.receiver.fullName, 'Receiver');
      expect(entity.amount, 125.5);
      expect(entity.status, 'PENDING');
      expect(entity.refundTransactionId, isNull);
      expect(entity.respondedAt, isNull);
    });
  });

  group('AcceptUndoResultApiModel', () {
    test('fromJson parses request and receipt payloads', () {
      final model = AcceptUndoResultApiModel.fromJson({
        'request': {
          'id': 'undo-1',
          'transactionId': 'txn-mongo-id',
          'originalTxId': 'tx-1001',
          'requester': {
            'id': 'u-1',
            'fullName': 'Sender',
            'phoneNumber': '9800000001',
          },
          'receiver': {
            'id': 'u-2',
            'fullName': 'Receiver',
            'phoneNumber': '9800000002',
          },
          'amount': 125.5,
          'status': 'ACCEPTED',
          'refundTransactionId': 'txn-refund-mongo-id',
          'respondedAt': '2026-02-01T12:03:00.000Z',
          'createdAt': '2026-02-01T12:00:00.000Z',
          'updatedAt': '2026-02-01T12:03:00.000Z',
        },
        'receipt': {
          'txId': 'refund-tx-1',
          'status': 'SUCCESS',
          'amount': 125.5,
          'remark': 'Undo refund for tx-1001',
          'paymentType': 'TRANSFER',
          'meta': {'reason': 'UNDO_REFUND', 'originalTxId': 'tx-1001'},
          'from': {
            'id': 'u-2',
            'fullName': 'Receiver',
            'phoneNumber': '9800000002',
          },
          'to': {
            'id': 'u-1',
            'fullName': 'Sender',
            'phoneNumber': '9800000001',
          },
          'createdAt': '2026-02-01T12:03:00.000Z',
        },
      });

      final entity = model.toEntity();
      expect(entity.request.status, 'ACCEPTED');
      expect(entity.request.refundTransactionId, 'txn-refund-mongo-id');
      expect(entity.receipt.txId, 'refund-tx-1');
      expect(entity.receipt.meta?['reason'], 'UNDO_REFUND');
      expect(entity.receipt.meta?['originalTxId'], 'tx-1001');
    });
  });
}
