import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/notifications/domain/entity/notification_entity.dart';
import 'package:payhive/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/entity/statement_entity.dart';
import 'package:payhive/features/statement/domain/entity/undo_request_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/state/statement_state.dart';
import 'package:payhive/features/statement/presentation/view_model/statement_view_model.dart';

class MockGetTransactionHistoryUsecase extends Mock
    implements GetTransactionHistoryUsecase {}

class MockRequestUndoUsecase extends Mock implements RequestUndoUsecase {}

class MockGetNotificationsUsecase extends Mock
    implements GetNotificationsUsecase {}

class FakeUserSessionService implements UserSessionService {
  FakeUserSessionService(this.userId);
  final String? userId;

  @override
  String? getUserId() => userId;

  @override
  Future<void> clearUserSession() async {}

  @override
  String? getUserFullName() => null;

  @override
  String? getUserPhoneNumber() => null;

  @override
  bool isLoggedIn() => false;

  @override
  Future<void> saveUserSession({
    required String userId,
    required String fullName,
    required String phoneNumber,
  }) async {}
}

void main() {
  late MockGetTransactionHistoryUsecase mockUsecase;
  late MockRequestUndoUsecase mockRequestUndoUsecase;
  late MockGetNotificationsUsecase mockGetNotificationsUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const HistoryParams(page: 1, limit: 10));
    registerFallbackValue(const RequestUndoParams(txId: 'tx-1'));
    registerFallbackValue(const GetNotificationsParams(page: 1, limit: 10));
  });

  setUp(() {
    mockUsecase = MockGetTransactionHistoryUsecase();
    mockRequestUndoUsecase = MockRequestUndoUsecase();
    mockGetNotificationsUsecase = MockGetNotificationsUsecase();

    when(() => mockGetNotificationsUsecase(any())).thenAnswer(
      (_) async => const Right(
        NotificationListEntity(
          items: [],
          total: 0,
          page: 1,
          limit: 50,
          totalPages: 1,
          unreadCount: 0,
        ),
      ),
    );
    when(() => mockRequestUndoUsecase(any())).thenAnswer(
      (_) async => Right(
        UndoRequestEntity(
          id: 'undo-1',
          transactionId: 'mongo-txn-id',
          originalTxId: 'tx-1',
          requester: const RecipientEntity(
            id: 'me-user-id',
            fullName: 'Me',
            phoneNumber: '9800000001',
          ),
          receiver: const RecipientEntity(
            id: 'other-user',
            fullName: 'Other',
            phoneNumber: '9800000002',
          ),
          amount: 100,
          status: 'PENDING',
          refundTransactionId: null,
          respondedAt: null,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ),
    );

    container = ProviderContainer(
      overrides: [
        getTransactionHistoryUsecaseProvider.overrideWithValue(mockUsecase),
        requestUndoUsecaseProvider.overrideWithValue(mockRequestUndoUsecase),
        getNotificationsUsecaseProvider.overrideWithValue(
          mockGetNotificationsUsecase,
        ),
        userSessionServiceProvider.overrideWithValue(
          FakeUserSessionService('me-user-id'),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  ReceiptEntity receipt({
    required String txId,
    required String fromId,
    required String toId,
    String? remark,
    String? direction,
  }) {
    return ReceiptEntity(
      txId: txId,
      status: 'SUCCESS',
      amount: 100,
      remark: remark,
      from: RecipientEntity(
        id: fromId,
        fullName: fromId == 'me-user-id' ? 'Me' : 'Other',
        phoneNumber: '9800000001',
      ),
      to: RecipientEntity(
        id: toId,
        fullName: toId == 'me-user-id' ? 'Me' : 'Other',
        phoneNumber: '9800000002',
      ),
      createdAt: DateTime(2026, 1, 1),
      direction: direction,
    );
  }

  TransactionHistoryEntity history({
    required List<ReceiptEntity> items,
    required int page,
    required int totalPages,
  }) {
    return TransactionHistoryEntity(
      transactions: items,
      pagination: PaginationEntity(
        page: page,
        limit: 10,
        totalPages: totalPages,
      ),
    );
  }

  UndoRequestEntity undoRequest({required String status}) {
    return UndoRequestEntity(
      id: 'undo-1',
      transactionId: 'mongo-txn-id',
      originalTxId: 'tx-1',
      requester: const RecipientEntity(
        id: 'me-user-id',
        fullName: 'Me',
        phoneNumber: '9800000001',
      ),
      receiver: const RecipientEntity(
        id: 'other-user',
        fullName: 'Other',
        phoneNumber: '9800000002',
      ),
      amount: 100,
      status: status,
      refundTransactionId: null,
      respondedAt: null,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  group('StatementViewModel', () {
    test('initial load success updates list and pagination', () async {
      when(() => mockUsecase(any())).thenAnswer(
        (_) async => Right(
          history(
            items: [
              receipt(txId: 'tx-1', fromId: 'me-user-id', toId: 'other-user'),
            ],
            page: 1,
            totalPages: 2,
          ),
        ),
      );

      await container.read(statementViewModelProvider.notifier).loadInitial();
      final state = container.read(statementViewModelProvider);

      expect(state.status, StatementViewStatus.loaded);
      expect(state.transactions.length, 1);
      expect(state.transactions.first.direction, 'DEBIT');
      expect(state.page, 1);
      expect(state.totalPages, 2);
      expect(state.undoStatusByTxId, isEmpty);

      verify(
        () => mockUsecase(
          const HistoryParams(page: 1, limit: 10, search: '', direction: 'all'),
        ),
      ).called(1);
      verify(
        () => mockGetNotificationsUsecase(
          const GetNotificationsParams(
            page: 1,
            limit: 50,
            type: 'UNDO_REQUEST',
          ),
        ),
      ).called(1);
    });

    test('search change resets list and refetches page 1', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as HistoryParams;
        if (params.search == 'refund') {
          return Right(
            history(
              items: [
                receipt(
                  txId: 'tx-search',
                  fromId: 'other-user',
                  toId: 'me-user-id',
                  remark: 'refund',
                ),
              ],
              page: 1,
              totalPages: 1,
            ),
          );
        }
        return Right(
          history(
            items: [
              receipt(
                txId: 'tx-initial',
                fromId: 'me-user-id',
                toId: 'other-user',
              ),
            ],
            page: 1,
            totalPages: 2,
          ),
        );
      });

      final vm = container.read(statementViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.applySearch('refund');

      final state = container.read(statementViewModelProvider);
      expect(state.search, 'refund');
      expect(state.transactions.length, 1);
      expect(state.transactions.first.txId, 'tx-search');

      verify(
        () => mockUsecase(
          const HistoryParams(
            page: 1,
            limit: 10,
            search: 'refund',
            direction: 'all',
          ),
        ),
      ).called(1);
    });

    test('direction change resets list and refetches page 1', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as HistoryParams;
        if (params.direction == 'credit') {
          return Right(
            history(
              items: [
                receipt(
                  txId: 'tx-credit',
                  fromId: 'other-user',
                  toId: 'me-user-id',
                  direction: 'CREDIT',
                ),
              ],
              page: 1,
              totalPages: 1,
            ),
          );
        }
        return Right(
          history(
            items: [
              receipt(
                txId: 'tx-default',
                fromId: 'me-user-id',
                toId: 'other-user',
              ),
            ],
            page: 1,
            totalPages: 2,
          ),
        );
      });

      final vm = container.read(statementViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.applyDirection(StatementDirectionFilter.credit);

      final state = container.read(statementViewModelProvider);
      expect(state.direction, StatementDirectionFilter.credit);
      expect(state.transactions.first.txId, 'tx-credit');

      verify(
        () => mockUsecase(
          const HistoryParams(
            page: 1,
            limit: 10,
            search: '',
            direction: 'credit',
          ),
        ),
      ).called(1);
    });

    test('infinite scroll loads next page and stops at last page', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as HistoryParams;
        if (params.page == 1) {
          return Right(
            history(
              items: [
                receipt(txId: 'tx-1', fromId: 'me-user-id', toId: 'other-user'),
              ],
              page: 1,
              totalPages: 2,
            ),
          );
        }
        return Right(
          history(
            items: [
              receipt(txId: 'tx-2', fromId: 'other-user', toId: 'me-user-id'),
            ],
            page: 2,
            totalPages: 2,
          ),
        );
      });

      final vm = container.read(statementViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.loadMore();
      await vm.loadMore();

      final state = container.read(statementViewModelProvider);
      expect(state.transactions.length, 2);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);

      verify(() => mockUsecase(any())).called(2);
    });

    test('load-more failure keeps existing list and exposes error', () async {
      when(() => mockUsecase(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as HistoryParams;
        if (params.page == 1) {
          return Right(
            history(
              items: [
                receipt(txId: 'tx-1', fromId: 'me-user-id', toId: 'other-user'),
              ],
              page: 1,
              totalPages: 2,
            ),
          );
        }
        return const Left(ApiFalilure(message: 'Load more failed'));
      });

      final vm = container.read(statementViewModelProvider.notifier);
      await vm.loadInitial();
      await vm.loadMore();

      final state = container.read(statementViewModelProvider);
      expect(state.status, StatementViewStatus.loaded);
      expect(state.transactions.length, 1);
      expect(state.errorMessage, 'Load more failed');
      expect(state.isLoadingMore, isFalse);
    });

    test(
      'requestUndo success marks tx as pending and sets action message',
      () async {
        when(
          () => mockRequestUndoUsecase(any()),
        ).thenAnswer((_) async => Right(undoRequest(status: 'PENDING')));

        final vm = container.read(statementViewModelProvider.notifier);
        await vm.requestUndo('tx-1');

        final state = container.read(statementViewModelProvider);
        expect(state.undoStatusByTxId['tx-1']?.label, 'Pending');
        expect(state.requestingUndoTxIds.contains('tx-1'), isFalse);
        expect(state.actionMessage, 'Undo request submitted.');
      },
    );

    test('requestUndo duplicate response still marks tx as pending', () async {
      when(() => mockRequestUndoUsecase(any())).thenAnswer(
        (_) async => const Left(
          ApiFalilure(
            message: 'Undo already requested for this transaction',
            statusCode: 409,
          ),
        ),
      );

      final vm = container.read(statementViewModelProvider.notifier);
      await vm.requestUndo('tx-1');

      final state = container.read(statementViewModelProvider);
      expect(state.undoStatusByTxId['tx-1']?.label, 'Pending');
      expect(
        state.actionMessage,
        'Undo already requested for this transaction',
      );
      expect(state.errorMessage, isNull);
    });

    test('hydrates undo statuses from UNDO_REQUEST notifications', () async {
      when(() => mockUsecase(any())).thenAnswer(
        (_) async => Right(
          history(
            items: [
              receipt(txId: 'tx-1', fromId: 'me-user-id', toId: 'other-user'),
              receipt(txId: 'tx-2', fromId: 'me-user-id', toId: 'other-user'),
              receipt(txId: 'tx-3', fromId: 'me-user-id', toId: 'other-user'),
            ],
            page: 1,
            totalPages: 1,
          ),
        ),
      );

      when(() => mockGetNotificationsUsecase(any())).thenAnswer(
        (_) async => Right(
          NotificationListEntity(
            items: [
              NotificationEntity(
                id: 'n-accepted',
                userId: 'me-user-id',
                title: 'Undo Accepted',
                body: 'Accepted',
                type: 'UNDO_REQUEST',
                data: const {'action': 'ACCEPTED', 'originalTxId': 'tx-2'},
                isRead: false,
                createdAt: DateTime(2026, 2, 3),
                updatedAt: DateTime(2026, 2, 3),
              ),
              NotificationEntity(
                id: 'n-denied',
                userId: 'me-user-id',
                title: 'Undo Denied',
                body: 'Denied',
                type: 'UNDO_REQUEST',
                data: const {'action': 'DENIED', 'originalTxId': 'tx-3'},
                isRead: false,
                createdAt: DateTime(2026, 2, 2),
                updatedAt: DateTime(2026, 2, 2),
              ),
              NotificationEntity(
                id: 'n-created',
                userId: 'me-user-id',
                title: 'Undo Request',
                body: 'Created',
                type: 'UNDO_REQUEST',
                data: const {'action': 'CREATED', 'originalTxId': 'tx-1'},
                isRead: false,
                createdAt: DateTime(2026, 2, 1),
                updatedAt: DateTime(2026, 2, 1),
              ),
            ],
            total: 3,
            page: 1,
            limit: 50,
            totalPages: 1,
            unreadCount: 3,
          ),
        ),
      );

      await container.read(statementViewModelProvider.notifier).loadInitial();
      final state = container.read(statementViewModelProvider);

      expect(state.undoStatusByTxId['tx-1']?.label, 'Pending');
      expect(state.undoStatusByTxId['tx-2']?.label, 'Accepted');
      expect(state.undoStatusByTxId['tx-3']?.label, 'Rejected');
    });
  });
}
