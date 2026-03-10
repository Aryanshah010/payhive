import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';
import 'package:payhive/features/request_money/domain/usecases/request_money_usecase.dart';
import 'package:payhive/features/request_money/presentation/pages/request_money_page.dart';
import 'package:payhive/features/request_money/presentation/state/request_money_state.dart';
import 'package:payhive/features/request_money/presentation/view_model/request_money_view_model.dart';

class MockCreateMoneyRequestUsecase extends Mock
    implements CreateMoneyRequestUsecase {}

class MockGetOutgoingMoneyRequestsUsecase extends Mock
    implements GetOutgoingMoneyRequestsUsecase {}

class MockRespondMoneyRequestUsecase extends Mock
    implements RespondMoneyRequestUsecase {}

class FakeLoadingMoreRequestMoneyViewModel extends RequestMoneyViewModel {
  @override
  RequestMoneyState build() {
    return RequestMoneyState.initial().copyWith(
      status: RequestMoneyStatus.loaded,
      pendingRequests: [
        MoneyRequestEntity(
          id: 'req-loading',
          requester: const RecipientEntity(
            id: 'requester-id',
            fullName: 'Requester',
            phoneNumber: '9800000001',
          ),
          receiver: const RecipientEntity(
            id: 'receiver-id',
            fullName: 'Receiver',
            phoneNumber: '9800000002',
          ),
          amount: 125,
          remark: 'test',
          status: 'PENDING',
          expiresAt: DateTime(2026, 1, 20),
          respondedAt: null,
          transactionId: null,
          createdAt: DateTime(2026, 1, 1, 12, 0),
          updatedAt: DateTime(2026, 1, 1, 12, 0),
        ),
      ],
      page: 1,
      totalPages: 2,
      isLoadingMore: true,
    );
  }

  @override
  Future<void> loadInitialPending() async {}

  @override
  Future<void> refreshPending() async {}

  @override
  Future<void> loadMorePending() async {}

  @override
  Future<void> submitRequest() async {}

  @override
  Future<void> cancelRequest(String requestId) async {}
}

void main() {
  late MockCreateMoneyRequestUsecase mockCreateUsecase;
  late MockGetOutgoingMoneyRequestsUsecase mockGetOutgoingUsecase;
  late MockRespondMoneyRequestUsecase mockRespondUsecase;

  setUpAll(() {
    registerFallbackValue(
      const CreateMoneyRequestParams(toPhoneNumber: '9800000001', amount: 100),
    );
    registerFallbackValue(
      const GetOutgoingMoneyRequestsParams(page: 1, limit: 10),
    );
    registerFallbackValue(
      const RespondMoneyRequestParams(
        requestId: 'req-1',
        action: MoneyRequestAction.cancel,
      ),
    );
  });

  setUp(() {
    mockCreateUsecase = MockCreateMoneyRequestUsecase();
    mockGetOutgoingUsecase = MockGetOutgoingMoneyRequestsUsecase();
    mockRespondUsecase = MockRespondMoneyRequestUsecase();
  });

  MoneyRequestEntity pendingRequest() {
    return MoneyRequestEntity(
      id: 'req-1',
      requester: const RecipientEntity(
        id: 'requester-id',
        fullName: 'Requester',
        phoneNumber: '9800000001',
      ),
      receiver: const RecipientEntity(
        id: 'receiver-id',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      amount: 125,
      remark: 'Rent split',
      status: 'PENDING',
      expiresAt: DateTime(2026, 1, 20),
      respondedAt: null,
      transactionId: null,
      createdAt: DateTime(2026, 1, 1, 12, 0),
      updatedAt: DateTime(2026, 1, 1, 12, 0),
    );
  }

  MoneyRequestPageEntity pendingPage(List<MoneyRequestEntity> items) {
    return MoneyRequestPageEntity(
      items: items,
      total: items.length,
      page: 1,
      limit: 10,
      totalPages: 1,
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createMoneyRequestUsecaseProvider.overrideWithValue(
            mockCreateUsecase,
          ),
          getOutgoingMoneyRequestsUsecaseProvider.overrideWithValue(
            mockGetOutgoingUsecase,
          ),
          respondMoneyRequestUsecaseProvider.overrideWithValue(
            mockRespondUsecase,
          ),
        ],
        child: const MaterialApp(home: RequestMoneyPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders fields, action button and pending section', (
    tester,
  ) async {
    when(
      () => mockGetOutgoingUsecase(any()),
    ).thenAnswer((_) async => Right(pendingPage([])));

    await pumpPage(tester);

    expect(find.text('Request Money'), findsOneWidget);
    expect(find.text('PayHive ID'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Request Message (optional)'), findsOneWidget);
    expect(find.text('REQUEST MONEY'), findsOneWidget);
    expect(find.text('Pending Requests'), findsOneWidget);
  });

  testWidgets('submit triggers create request usecase', (tester) async {
    when(
      () => mockGetOutgoingUsecase(any()),
    ).thenAnswer((_) async => Right(pendingPage([])));
    when(
      () => mockCreateUsecase(any()),
    ).thenAnswer((_) async => Right(pendingRequest()));

    await pumpPage(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '9800000002');
    await tester.enterText(fields.at(1), '150');
    await tester.enterText(fields.at(2), 'Lunch share');

    await tester.tap(find.text('REQUEST MONEY'));
    await tester.pumpAndSettle();

    verify(() => mockCreateUsecase(any())).called(1);
  });

  testWidgets(
    'tapping request money with empty fields shows inline validation',
    (tester) async {
      when(
        () => mockGetOutgoingUsecase(any()),
      ).thenAnswer((_) async => Right(pendingPage([])));

      await pumpPage(tester);

      await tester.tap(find.text('REQUEST MONEY'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your mobile number.'),
        findsOneWidget,
      );
      expect(find.text('Amount is required.'), findsOneWidget);
      verifyNever(() => mockCreateUsecase(any()));
    },
  );

  testWidgets('invalid submit does not trigger create usecase', (tester) async {
    when(
      () => mockGetOutgoingUsecase(any()),
    ).thenAnswer((_) async => Right(pendingPage([])));

    await pumpPage(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '123');
    await tester.enterText(fields.at(1), '0');

    await tester.tap(find.text('REQUEST MONEY'));
    await tester.pumpAndSettle();

    verifyNever(() => mockCreateUsecase(any()));
  });

  testWidgets('cancel opens confirmation and triggers cancel usecase', (
    tester,
  ) async {
    when(
      () => mockGetOutgoingUsecase(any()),
    ).thenAnswer((_) async => Right(pendingPage([pendingRequest()])));
    when(
      () => mockRespondUsecase(any()),
    ).thenAnswer((_) async => Right(pendingRequest()));

    await pumpPage(tester);

    expect(find.text('Cancel'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel request?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    verify(
      () => mockRespondUsecase(
        const RespondMoneyRequestParams(
          requestId: 'req-1',
          action: MoneyRequestAction.cancel,
        ),
      ),
    ).called(1);
  });

  testWidgets('shows empty pending state message', (tester) async {
    when(
      () => mockGetOutgoingUsecase(any()),
    ).thenAnswer((_) async => Right(pendingPage([])));

    await pumpPage(tester);

    expect(find.text('No pending requests yet.'), findsOneWidget);
  });

  testWidgets(
    'shows pending section error state when initial list load fails',
    (tester) async {
      when(
        () => mockGetOutgoingUsecase(any()),
      ).thenAnswer((_) async => const Left(ApiFalilure(message: 'Failed')));

      await pumpPage(tester);

      expect(find.text('Could not load pending requests.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  testWidgets('shows loading-more indicator when isLoadingMore is true', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestMoneyViewModelProvider.overrideWith(
            () => FakeLoadingMoreRequestMoneyViewModel(),
          ),
        ],
        child: const MaterialApp(home: RequestMoneyPage()),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
