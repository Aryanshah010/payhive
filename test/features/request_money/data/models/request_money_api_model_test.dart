import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/request_money/data/models/request_money_api_model.dart';

void main() {
  group('MoneyRequestApiModel', () {
    test('parses create response payload', () {
      final json = {
        'id': 'req-1',
        'requester': {
          'id': 'user-a',
          'fullName': 'Requester User',
          'phoneNumber': '9800000001',
        },
        'receiver': {
          'id': 'user-b',
          'fullName': 'Receiver User',
          'phoneNumber': '9800000002',
        },
        'amount': 175,
        'remark': 'rent due',
        'status': 'PENDING',
        'expiresAt': '2026-01-15T10:00:00.000Z',
        'respondedAt': null,
        'transactionId': null,
        'createdAt': '2026-01-08T10:00:00.000Z',
        'updatedAt': '2026-01-08T10:00:00.000Z',
      };

      final model = MoneyRequestApiModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity.id, 'req-1');
      expect(entity.requester.fullName, 'Requester User');
      expect(entity.receiver.phoneNumber, '9800000002');
      expect(entity.amount, 175);
      expect(entity.remark, 'rent due');
      expect(entity.status, 'PENDING');
      expect(entity.respondedAt, isNull);
      expect(entity.transactionId, isNull);
    });

    test('parses outgoing list payload with optional nullable fields', () {
      final payload = {
        'items': [
          {
            'id': 'req-1',
            'requester': {
              'id': 'user-a',
              'fullName': 'Requester User',
              'phoneNumber': '9800000001',
            },
            'receiver': {
              'id': 'user-b',
              'fullName': 'Receiver User',
              'phoneNumber': '9800000002',
            },
            'amount': 175,
            'remark': 'rent due',
            'status': 'PENDING',
            'expiresAt': '2026-01-15T10:00:00.000Z',
            'respondedAt': null,
            'transactionId': null,
            'createdAt': '2026-01-08T10:00:00.000Z',
            'updatedAt': '2026-01-08T10:00:00.000Z',
          },
          {
            'id': 'req-2',
            'requester': {
              'id': 'user-a',
              'fullName': 'Requester User',
              'phoneNumber': '9800000001',
            },
            'receiver': {
              'id': 'user-c',
              'fullName': 'Another User',
              'phoneNumber': '9800000003',
            },
            'amount': 99.5,
            'remark': null,
            'status': 'PENDING',
            'expiresAt': '2026-01-20T10:00:00.000Z',
            'respondedAt': null,
            'transactionId': null,
            'createdAt': '2026-01-09T10:00:00.000Z',
            'updatedAt': '2026-01-09T10:00:00.000Z',
          },
        ],
        'total': 2,
        'page': 1,
        'limit': 10,
        'totalPages': 1,
      };

      final model = MoneyRequestPageApiModel.fromJson(payload);
      final entity = model.toEntity();

      expect(entity.items.length, 2);
      expect(entity.total, 2);
      expect(entity.page, 1);
      expect(entity.limit, 10);
      expect(entity.totalPages, 1);

      expect(entity.items[1].remark, '');
      expect(entity.items[1].respondedAt, isNull);
      expect(entity.items[1].transactionId, isNull);
    });
  });
}
