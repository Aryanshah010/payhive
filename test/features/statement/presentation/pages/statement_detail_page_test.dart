import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/services/storage/undo_status_storage_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/pages/statement_detail_page.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';

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
  late MockGetTransactionDetailUsecase mockUsecase;

  setUpAll(() {
    registerFallbackValue(const DetailParams(txId: 'fallback'));
  });

  setUp(() {
    mockUsecase = MockGetTransactionDetailUsecase();
  });

  ReceiptEntity receipt() {
    return ReceiptEntity(
      txId: 'tx-1',
      status: 'SUCCESS',
      amount: 250,
      remark: 'Rent',
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
      createdAt: DateTime(2026, 1, 1, 12, 0),
      direction: 'DEBIT',
    );
  }

  testWidgets('renders detail content with status chip and actions', (
    tester,
  ) async {
    final data = receipt();
    when(() => mockUsecase(any())).thenAnswer((_) async => Right(data));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getTransactionDetailUsecaseProvider.overrideWithValue(mockUsecase),
          userSessionServiceProvider.overrideWithValue(
            FakeUserSessionService(),
          ),
          undoStatusStorageServiceProvider.overrideWithValue(
            FakeUndoStatusStorageService(),
          ),
        ],
        child: MaterialApp(
          home: StatementDetailPage(
            txId: data.txId,
            initialReceipt: data,
            initialUndoStatus: acceptedUndoStatus,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Transaction Detail'), findsOneWidget);
    expect(find.text('Transaction Details'), findsOneWidget);
    expect(find.text('Complete'), findsWidgets);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Transaction ID'), findsOneWidget);
    expect(find.text('Undo Status'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
  });
}
