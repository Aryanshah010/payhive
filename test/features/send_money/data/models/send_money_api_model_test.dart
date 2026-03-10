import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/send_money/data/models/send_money_api_model.dart';

void main() {
  group('ReceiptApiModel', () {
    test('parses paymentType and meta from nested receipt payload', () {
      final model = ReceiptApiModel.fromJson({
        'receipt': {
          'txId': 'tx-101',
          'status': 'SUCCESS',
          'amount': 123.45,
          'remark': 'Bank transfer test',
          'paymentType': 'BANK_TRANSFER',
          'meta': {'bankName': 'Nabil Bank', 'accountNumber': '123456789012'},
          'from': {
            '_id': 'me',
            'fullName': 'Sender',
            'phoneNumber': '9800000001',
          },
          'to': {
            '_id': 'receiver',
            'fullName': 'Receiver',
            'phoneNumber': '9800000002',
          },
          'createdAt': '2026-01-01T10:00:00.000Z',
          'direction': 'DEBIT',
        },
      });

      final entity = model.toEntity();

      expect(entity.txId, 'tx-101');
      expect(entity.paymentType, 'BANK_TRANSFER');
      expect(entity.meta, isNotNull);
      expect(entity.meta?['bankName'], 'Nabil Bank');
      expect(entity.meta?['accountNumber'], '123456789012');
    });

    test('parses paymentType and meta from flat payload', () {
      final model = ReceiptApiModel.fromJson({
        '_id': 'tx-202',
        'status': 'SUCCESS',
        'amount': 500,
        'paymentType': 'BANK_TRANSFER',
        'meta': {'bank': 'Global IME', 'accountNo': '9876543210'},
        'from': {'id': 'user-1', 'name': 'Sender', 'phoneNumber': '9800000001'},
        'to': {'id': 'user-2', 'name': 'Receiver', 'phoneNumber': '9800000002'},
        'createdAt': 1764547200000,
      });

      final entity = model.toEntity();

      expect(entity.txId, 'tx-202');
      expect(entity.paymentType, 'BANK_TRANSFER');
      expect(entity.meta?['bank'], 'Global IME');
      expect(entity.meta?['accountNo'], '9876543210');
    });
  });
}
