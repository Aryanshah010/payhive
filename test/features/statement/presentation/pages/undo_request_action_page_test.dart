import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/services/storage/undo_status_storage_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/statement/domain/entity/undo_request_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/pages/undo_request_action_page.dart';
import 'package:payhive/features/statement/presentation/state/undo_request_action_state.dart';
import 'package:payhive/features/statement/presentation/view_model/undo_request_action_view_model.dart';

class MockAcceptUndoUsecase extends Mock implements AcceptUndoUsecase {}

class MockRejectUndoUsecase extends Mock implements RejectUndoUsecase {}

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

class InMemoryUndoStatusStorage implements UndoStatusStorageService {
  InMemoryUndoStatusStorage(this.seeded);

  final Map<String, Map<String, String>> seeded;

  @override
  Map<String, String> readStatuses({required String userId}) {
    return Map<String, String>.from(seeded[userId] ?? const <String, String>{});
  }

  @override
  String? readStatus({required String userId, required String txId}) {
    return seeded[userId]?[txId];
  }

  @override
  Future<void> saveStatus({
    required String userId,
    required String txId,
    required String status,
  }) async {
    final next = seeded.putIfAbsent(userId, () => <String, String>{});
    next[txId] = status;
  }

  @override
  Future<void> saveStatuses({
    required String userId,
    required Map<String, String> statuses,
  }) async {
    seeded[userId] = Map<String, String>.from(statuses);
  }
}

void main() {
  late MockAcceptUndoUsecase mockAcceptUndoUsecase;
  late MockRejectUndoUsecase mockRejectUndoUsecase;
  late InMemoryUndoStatusStorage undoStatusStorage;

  setUpAll(() {
    registerFallbackValue(
      const AcceptUndoParams(requestId: 'undo-1', pin: '1234'),
    );
    registerFallbackValue(const RejectUndoParams(requestId: 'undo-1'));
  });

  setUp(() {
    mockAcceptUndoUsecase = MockAcceptUndoUsecase();
    mockRejectUndoUsecase = MockRejectUndoUsecase();
    undoStatusStorage = InMemoryUndoStatusStorage({
      'user-1': <String, String>{},
    });

    final acceptedResult = AcceptUndoResultEntity(
      request: UndoRequestEntity(
        id: 'undo-1',
        transactionId: 'mongo-tx-id',
        originalTxId: 'tx-1001',
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
        amount: 120,
        status: 'ACCEPTED',
        refundTransactionId: 'refund-mongo-id',
        respondedAt: DateTime(2026, 2, 1, 13, 0),
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1, 13, 0),
      ),
      receipt: ReceiptEntity(
        txId: 'refund-tx-1',
        status: 'SUCCESS',
        amount: 120,
        remark: 'Undo refund for tx-1001',
        paymentType: 'TRANSFER',
        meta: const {'reason': 'UNDO_REFUND', 'originalTxId': 'tx-1001'},
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
        createdAt: DateTime(2026, 2, 1, 13, 0),
        direction: 'CREDIT',
      ),
    );

    final rejectedResult = UndoRequestEntity(
      id: 'undo-1',
      transactionId: 'mongo-tx-id',
      originalTxId: 'tx-1001',
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
      amount: 120,
      status: 'DENIED',
      refundTransactionId: null,
      respondedAt: DateTime(2026, 2, 1, 13, 0),
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 2, 1, 13, 0),
    );

    when(
      () => mockAcceptUndoUsecase(any()),
    ).thenAnswer((_) async => Right(acceptedResult));
    when(
      () => mockRejectUndoUsecase(any()),
    ).thenAnswer((_) async => Right(rejectedResult));
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    UndoRequestActionFallbackData fallbackData =
        const UndoRequestActionFallbackData(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          acceptUndoUsecaseProvider.overrideWithValue(mockAcceptUndoUsecase),
          rejectUndoUsecaseProvider.overrideWithValue(mockRejectUndoUsecase),
          userSessionServiceProvider.overrideWithValue(
            FakeUserSessionService(),
          ),
          undoStatusStorageServiceProvider.overrideWithValue(undoStatusStorage),
        ],
        child: MaterialApp(
          home: UndoRequestActionPage(fallbackData: fallbackData),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  UndoRequestActionState readState(WidgetTester tester) {
    final context = tester.element(find.byType(UndoRequestActionPage));
    final container = ProviderScope.containerOf(context);
    return container.read(undoRequestActionViewModelProvider);
  }

  testWidgets('pending created request shows accept and reject actions', (
    tester,
  ) async {
    await pumpPage(
      tester,
      fallbackData: const UndoRequestActionFallbackData(
        undoRequestId: 'undo-1',
        action: 'CREATED',
        originalTxId: 'tx-1001',
        amount: 120,
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final state = readState(tester);
    expect(state.requestId, 'undo-1');
    expect(state.status?.label, 'Pending');
    expect(state.canTakeAction, isTrue);

    expect(find.text('Pending', skipOffstage: false), findsOneWidget);
    expect(find.text('ACCEPT', skipOffstage: false), findsOneWidget);
    expect(find.text('REJECT', skipOffstage: false), findsOneWidget);
  });

  testWidgets('accept with pin updates page status to accepted', (
    tester,
  ) async {
    await pumpPage(
      tester,
      fallbackData: const UndoRequestActionFallbackData(
        undoRequestId: 'undo-1',
        action: 'CREATED',
        originalTxId: 'tx-1001',
        amount: 120,
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ACCEPT', skipOffstage: false));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.text('CONFIRM'));
    await tester.pumpAndSettle();

    final state = readState(tester);
    expect(state.status?.label, 'Accepted');
    expect(find.text('Accepted', skipOffstage: false), findsOneWidget);
    expect(find.text('ACCEPT', skipOffstage: false), findsNothing);
    expect(find.text('REJECT', skipOffstage: false), findsNothing);
  });

  testWidgets('reject updates page status to rejected', (tester) async {
    await pumpPage(
      tester,
      fallbackData: const UndoRequestActionFallbackData(
        undoRequestId: 'undo-1',
        action: 'CREATED',
        originalTxId: 'tx-1001',
        amount: 120,
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('REJECT', skipOffstage: false));
    await tester.pumpAndSettle();

    final state = readState(tester);
    expect(state.status?.label, 'Rejected');
    expect(find.text('Rejected', skipOffstage: false), findsOneWidget);
    expect(find.text('ACCEPT', skipOffstage: false), findsNothing);
    expect(find.text('REJECT', skipOffstage: false), findsNothing);
  });

  testWidgets('missing request id shows read-only fallback state', (
    tester,
  ) async {
    await pumpPage(
      tester,
      fallbackData: const UndoRequestActionFallbackData(
        action: 'CREATED',
        originalTxId: 'tx-1001',
        amount: 120,
      ),
    );

    expect(find.text('ACCEPT', skipOffstage: false), findsNothing);
    expect(find.text('REJECT', skipOffstage: false), findsNothing);
    expect(
      find.text(
        'Undo request ID is unavailable. Actions are disabled for this notification.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'reopening same notification keeps rejected state from local persistence',
    (tester) async {
      undoStatusStorage.seeded['user-1'] = {'tx-1001': 'REJECTED'};

      await pumpPage(
        tester,
        fallbackData: const UndoRequestActionFallbackData(
          undoRequestId: 'undo-1',
          action: 'CREATED',
          originalTxId: 'tx-1001',
          amount: 120,
        ),
      );

      final state = readState(tester);
      expect(state.status?.label, 'Rejected');
      expect(state.canTakeAction, isFalse);

      expect(find.text('ACCEPT', skipOffstage: false), findsNothing);
      expect(find.text('REJECT', skipOffstage: false), findsNothing);
      expect(find.text('Rejected', skipOffstage: false), findsOneWidget);
    },
  );
}
