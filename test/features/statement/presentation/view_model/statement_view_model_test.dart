import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/services/storage/undo_status_storage_service.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';
import 'package:payhive/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/entity/statement_entity.dart';
import 'package:payhive/features/statement/domain/entity/undo_request_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/state/undo_status_ui.dart';
import 'package:payhive/features/statement/presentation/view_model/statement_view_model.dart';

class MockGetTransactionHistoryUsecase extends Mock
    implements GetTransactionHistoryUsecase {}

class MockRequestUndoUsecase extends Mock implements RequestUndoUsecase {}

class MockGetNotificationsUsecase extends Mock
    implements GetNotificationsUsecase {}

class FakeUserSessionService implements UserSessionService {
  FakeUserSessionService(this.userId);
  final String userId;

  @override
  Future<void> clearUserSession() async {}

  @override
  String? getUserFullName() => 'Test User';

  @override
  String? getUserId() => userId;

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
  late MockGetTransactionHistoryUsecase mockHistoryUsecase;
  late MockRequestUndoUsecase mockRequestUndoUsecase;
  late MockGetNotificationsUsecase mockNotificationsUsecase;
  late InMemoryUndoStatusStorage undoStorage;
  late ProviderContainer container;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(const HistoryParams(page: 1, limit: 10));
    registerFallbackValue(const RequestUndoParams(txId: 'fallback-tx'));
    registerFallbackValue(const GetNotificationsParams(page: 1, limit: 50));
  });

  setUp(() {
    mockHistoryUsecase = MockGetTransactionHistoryUsecase();
    mockRequestUndoUsecase = MockRequestUndoUsecase();
    mockNotificationsUsecase = MockGetNotificationsUsecase();
    undoStorage = InMemoryUndoStatusStorage(<String, Map<String, String>>{});

    container = ProviderContainer(
      overrides: [
        getTransactionHistoryUsecaseProvider.overrideWithValue(
          mockHistoryUsecase,
        ),
        requestUndoUsecaseProvider.overrideWithValue(mockRequestUndoUsecase),
        getNotificationsUsecaseProvider.overrideWithValue(
          mockNotificationsUsecase,
        ),
        userSessionServiceProvider.overrideWithValue(
          FakeUserSessionService(userId),
        ),
        undoStatusStorageServiceProvider.overrideWithValue(undoStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  ReceiptEntity receipt({required String txId}) {
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

  TransactionHistoryEntity history(List<ReceiptEntity> items) {
    return TransactionHistoryEntity(
      transactions: items,
      pagination: const PaginationEntity(
        page: 1,
        limit: 10,
        total: 1,
        totalPages: 1,
      ),
    );
  }

  NotificationListEntity notifications(List<NotificationEntity> items) {
    return NotificationListEntity(
      items: items,
      total: items.length,
      page: 1,
      limit: 50,
      totalPages: 1,
      unreadCount: 0,
    );
  }

  UndoRequestEntity undoRequest({
    required String txId,
    String status = 'PENDING',
  }) {
    return UndoRequestEntity(
      id: 'undo-1',
      transactionId: txId,
      originalTxId: txId,
      requester: const RecipientEntity(
        id: 'sender-id',
        fullName: 'Sender',
        phoneNumber: '9800000001',
      ),
      receiver: const RecipientEntity(
        id: 'receiver-id',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      amount: 100,
      status: status,
      refundTransactionId: null,
      respondedAt: null,
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 1),
    );
  }

  group('StatementViewModel undo state persistence', () {
    test('restores persisted pending undo status on initial load', () async {
      undoStorage.seeded[userId] = {'tx-1': 'PENDING'};
      when(
        () => mockHistoryUsecase(any()),
      ).thenAnswer((_) async => Right(history([receipt(txId: 'tx-1')])));
      when(() => mockNotificationsUsecase(any())).thenAnswer(
        (_) async => Right(notifications(const <NotificationEntity>[])),
      );

      await container.read(statementViewModelProvider.notifier).loadInitial();
      final state = container.read(statementViewModelProvider);

      expect(state.undoStatusByTxId['tx-1'], pendingUndoStatus);
    });

    test('requestUndo stores pending status for current user', () async {
      when(
        () => mockHistoryUsecase(any()),
      ).thenAnswer((_) async => Right(history([receipt(txId: 'tx-1')])));
      when(() => mockNotificationsUsecase(any())).thenAnswer(
        (_) async => Right(notifications(const <NotificationEntity>[])),
      );
      when(
        () => mockRequestUndoUsecase(any()),
      ).thenAnswer((_) async => Right(undoRequest(txId: 'tx-1')));

      final vm = container.read(statementViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.requestUndo('tx-1');

      final state = container.read(statementViewModelProvider);
      expect(state.undoStatusByTxId['tx-1'], pendingUndoStatus);
      expect(undoStorage.seeded[userId]?['tx-1'], 'PENDING');
    });

    test(
      'hydrated accepted status overrides pending and persists terminal state',
      () async {
        undoStorage.seeded[userId] = {'tx-1': 'PENDING'};
        when(
          () => mockHistoryUsecase(any()),
        ).thenAnswer((_) async => Right(history([receipt(txId: 'tx-1')])));
        when(() => mockNotificationsUsecase(any())).thenAnswer(
          (_) async => Right(
            notifications([
              NotificationEntity(
                id: 'notif-1',
                userId: userId,
                title: 'Undo Updated',
                body: 'Accepted',
                type: 'UNDO_REQUEST',
                data: const {'originalTxId': 'tx-1', 'action': 'ACCEPTED'},
                isRead: true,
                readAt: DateTime(2026, 3, 1, 12, 3),
                createdAt: DateTime(2026, 3, 1, 12, 3),
                updatedAt: DateTime(2026, 3, 1, 12, 3),
              ),
            ]),
          ),
        );

        await container.read(statementViewModelProvider.notifier).loadInitial();
        final state = container.read(statementViewModelProvider);

        expect(state.undoStatusByTxId['tx-1'], acceptedUndoStatus);
        expect(undoStorage.seeded[userId]?['tx-1'], 'ACCEPTED');
      },
    );
  });
}
