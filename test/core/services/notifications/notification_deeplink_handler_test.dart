import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/services/notifications/notification_deeplink_handler.dart';
import 'package:payhive/core/services/storage/undo_status_storage_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/pages/statement_detail_page.dart';

class MockGetTransactionDetailUsecase extends Mock
    implements GetTransactionDetailUsecase {}

class FakeUserSessionService implements UserSessionService {
  @override
  Future<void> clearUserSession() async {}

  @override
  String? getUserFullName() => 'Test User';

  @override
  String? getUserId() => 'user-1';

  @override
  String? getUserPhoneNumber() => '9800000000';

  @override
  bool isLoggedIn() => true;

  @override
  Future<void> saveUserSession({
    required String userId,
    required String fullName,
    required String phoneNumber,
  }) async {}
}

class FakeUndoStatusStorageService implements UndoStatusStorageService {
  @override
  Map<String, String> readStatuses({required String userId}) {
    return const <String, String>{};
  }

  @override
  String? readStatus({required String userId, required String txId}) {
    return null;
  }

  @override
  Future<void> saveStatus({
    required String userId,
    required String txId,
    required String status,
  }) async {}

  @override
  Future<void> saveStatuses({
    required String userId,
    required Map<String, String> statuses,
  }) async {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(const DetailParams(txId: 'fallback'));
  });

  ReceiptEntity receipt(String txId) {
    return ReceiptEntity(
      txId: txId,
      status: 'SUCCESS',
      amount: 100,
      remark: 'remark',
      from: const RecipientEntity(
        id: 'sender-id',
        fullName: 'Sender',
        phoneNumber: '9800000001',
      ),
      to: const RecipientEntity(
        id: 'receiver-id',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      createdAt: DateTime(2026, 3, 1),
      direction: 'DEBIT',
    );
  }

  testWidgets(
    'UNDO_REQUEST ACCEPTED deep link opens detail with Accepted undo status',
    (tester) async {
      final mockDetailUsecase = MockGetTransactionDetailUsecase();
      when(
        () => mockDetailUsecase(any()),
      ).thenAnswer((_) async => Right(receipt('refund-tx-1')));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getTransactionDetailUsecaseProvider.overrideWithValue(
              mockDetailUsecase,
            ),
            userSessionServiceProvider.overrideWithValue(
              FakeUserSessionService(),
            ),
            undoStatusStorageServiceProvider.overrideWithValue(
              FakeUndoStatusStorageService(),
            ),
          ],
          child: MaterialApp(
            navigatorKey: AppRoutes.navigatorKey,
            home: const Scaffold(body: SizedBox()),
          ),
        ),
      );

      NotificationDeepLinkHandler().handlePayload({
        'type': 'UNDO_REQUEST',
        'action': 'ACCEPTED',
        'originalTxId': 'tx-1',
        'refundTxId': 'refund-tx-1',
      });
      await tester.pumpAndSettle();

      expect(find.byType(StatementDetailPage), findsOneWidget);
      expect(find.text('Undo Status'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
    },
  );

  testWidgets(
    'UNDO_REQUEST DENIED deep link opens detail with Rejected undo status',
    (tester) async {
      final mockDetailUsecase = MockGetTransactionDetailUsecase();
      when(
        () => mockDetailUsecase(any()),
      ).thenAnswer((_) async => Right(receipt('tx-1')));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getTransactionDetailUsecaseProvider.overrideWithValue(
              mockDetailUsecase,
            ),
            userSessionServiceProvider.overrideWithValue(
              FakeUserSessionService(),
            ),
            undoStatusStorageServiceProvider.overrideWithValue(
              FakeUndoStatusStorageService(),
            ),
          ],
          child: MaterialApp(
            navigatorKey: AppRoutes.navigatorKey,
            home: const Scaffold(body: SizedBox()),
          ),
        ),
      );

      NotificationDeepLinkHandler().handlePayload({
        'type': 'UNDO_REQUEST',
        'action': 'DENIED',
        'originalTxId': 'tx-1',
      });
      await tester.pumpAndSettle();

      expect(find.byType(StatementDetailPage), findsOneWidget);
      expect(find.text('Undo Status'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    },
  );
}
