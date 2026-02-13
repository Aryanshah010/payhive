import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/statement/domain/entity/statement_entity.dart';
import 'package:payhive/features/statement/domain/usecases/statement_usecases.dart';
import 'package:payhive/features/statement/presentation/state/statement_state.dart';
import 'package:payhive/features/statement/presentation/view_model/statement_view_model.dart';

class MockGetTransactionHistoryUsecase extends Mock
    implements GetTransactionHistoryUsecase {}

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
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const HistoryParams(page: 1, limit: 10));
  });

  setUp(() {
    mockUsecase = MockGetTransactionHistoryUsecase();
    container = ProviderContainer(
      overrides: [
        getTransactionHistoryUsecaseProvider.overrideWithValue(mockUsecase),
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

      verify(
        () => mockUsecase(
          const HistoryParams(page: 1, limit: 10, search: '', direction: 'all'),
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
  });
}
