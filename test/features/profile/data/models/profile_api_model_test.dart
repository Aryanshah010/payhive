import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/profile/data/models/profile_api_model.dart';
import 'package:payhive/features/profile/domain/enitity/profile_entity.dart';

void main() {
  group('ProfileApiModel', () {
    test('fromJson parses numeric balance', () {
      final model = ProfileApiModel.fromJson({
        '_id': 'user-1',
        'fullName': 'Aryan Shah',
        'phoneNumber': '9800000000',
        'email': 'aryan@example.com',
        'imageUrl': '/uploads/me.png',
        'hasPin': true,
        'balance': 2450.75,
      });

      expect(model.id, 'user-1');
      expect(model.balance, 2450.75);
      expect(model.hasPin, isTrue);
    });

    test('fromJson parses string balance', () {
      final model = ProfileApiModel.fromJson({
        '_id': 'user-1',
        'fullName': 'Aryan Shah',
        'phoneNumber': '9800000000',
        'email': 'aryan@example.com',
        'balance': '1325.40',
      });

      expect(model.balance, 1325.40);
    });

    test('toEntity/fromEntity preserves balance', () {
      const entity = ProfileEntity(
        id: 'user-2',
        fullName: 'Test User',
        phoneNumber: '9812345678',
        email: 'test@payhive.com',
        imageUrl: '/uploads/test.jpg',
        hasPin: false,
        balance: 999.99,
      );

      final model = ProfileApiModel.fromEntity(entity);
      final mappedBack = model.toEntity();

      expect(model.balance, 999.99);
      expect(mappedBack.balance, 999.99);
      expect(mappedBack, entity);
    });
  });
}
