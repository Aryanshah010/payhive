import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/core/services/notifications/notification_deeplink_handler.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';
import 'package:payhive/features/request_money/domain/usecases/request_money_usecase.dart';
import 'package:payhive/features/request_money/presentation/pages/request_money_info_page.dart';
import 'package:payhive/features/statement/presentation/pages/statement_detail_page.dart';
import 'package:payhive/features/statement/presentation/pages/undo_request_action_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGetMoneyRequestDetailUsecase extends Mock
    implements GetMoneyRequestDetailUsecase {}

class MockRespondMoneyRequestUsecase extends Mock
    implements RespondMoneyRequestUsecase {}

class _RecordingNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastPushedRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushedRoute = route;
    super.didPush(route, previousRoute);
  }
}

void main() {
  late NotificationDeepLinkHandler handler;
  late _RecordingNavigatorObserver observer;
  late SharedPreferences prefs;
  late MockGetMoneyRequestDetailUsecase mockGetDetailUsecase;
  late MockRespondMoneyRequestUsecase mockRespondUsecase;

  setUpAll(() {
    registerFallbackValue(const GetMoneyRequestDetailParams(requestId: 'mr-1'));
    registerFallbackValue(
      const RespondMoneyRequestParams(
        requestId: 'mr-1',
        action: MoneyRequestAction.reject,
      ),
    );
  });

  MoneyRequestEntity request({required String id}) {
    return MoneyRequestEntity(
      id: id,
      requester: const RecipientEntity(
        id: 'req',
        fullName: 'Requester',
        phoneNumber: '9800000001',
      ),
      receiver: const RecipientEntity(
        id: 'receiver',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      amount: 100,
      remark: 'Rent',
      status: 'PENDING',
      expiresAt: DateTime(2026, 1, 20),
      respondedAt: null,
      transactionId: null,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  Future<void> pumpHarness(WidgetTester tester) async {
    observer = _RecordingNavigatorObserver();
    mockGetDetailUsecase = MockGetMoneyRequestDetailUsecase();
    mockRespondUsecase = MockRespondMoneyRequestUsecase();
    when(
      () => mockGetDetailUsecase(any()),
    ).thenAnswer((_) async => Right(request(id: 'mr-1')));
    when(
      () => mockRespondUsecase(any()),
    ).thenAnswer((_) async => Right(request(id: 'mr-1')));

    SharedPreferences.setMockInitialValues({'user_phone_number': '9800000002'});
    prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          getMoneyRequestDetailUsecaseProvider.overrideWithValue(
            mockGetDetailUsecase,
          ),
          respondMoneyRequestUsecaseProvider.overrideWithValue(
            mockRespondUsecase,
          ),
        ],
        child: MaterialApp(
          navigatorKey: AppRoutes.navigatorKey,
          navigatorObservers: [observer],
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    handler = NotificationDeepLinkHandler();
  }

  RequestMoneyInfoPage expectRequestInfoRoute() {
    final route = observer.lastPushedRoute;
    expect(route, isA<MaterialPageRoute<dynamic>>());
    final page = (route as MaterialPageRoute<dynamic>).builder(
      AppRoutes.navigatorKey.currentContext!,
    );
    expect(page, isA<RequestMoneyInfoPage>());
    return page as RequestMoneyInfoPage;
  }

  dynamic pushedPage() {
    final route = observer.lastPushedRoute;
    expect(route, isA<MaterialPageRoute<dynamic>>());
    return (route as MaterialPageRoute<dynamic>).builder(
      AppRoutes.navigatorKey.currentContext!,
    );
  }

  testWidgets('REQUEST_MONEY with requestId routes to request info page', (
    tester,
  ) async {
    await pumpHarness(tester);

    handler.handlePayload({
      'type': 'REQUEST_MONEY',
      'moneyRequestId': 'mr-1',
      'requesterPhoneNumber': '9800000001',
      'amount': '120.50',
      'remark': 'Rent split',
    });
    await tester.pumpAndSettle();

    final page = expectRequestInfoRoute();
    expect(page.requestId, 'mr-1');
    expect(page.fallbackData.phoneNumber, '9800000001');
    expect(page.fallbackData.amountInput, '120.50');
    expect(page.fallbackData.remark, 'Rent split');
  });

  testWidgets('nested REQUEST_MONEY payload in data map/string is flattened', (
    tester,
  ) async {
    await pumpHarness(tester);

    handler.handlePayload({
      'type': 'REQUEST_MONEY',
      'data': jsonEncode({
        'requestId': 'mr-2',
        'requesterPhone': '+977-9800000002',
        'amount': '99.999',
        'remark': 'Lunch',
      }),
    });
    await tester.pumpAndSettle();

    final page = expectRequestInfoRoute();
    expect(page.requestId, 'mr-2');
    expect(page.fallbackData.phoneNumber, '9800000002');
    expect(page.fallbackData.amountInput, '99.99');
    expect(page.fallbackData.remark, 'Lunch');
  });

  testWidgets('missing request id still routes to request info page', (
    tester,
  ) async {
    await pumpHarness(tester);

    handler.handlePayload({
      'type': 'REQUEST_MONEY',
      '__title': 'Request',
      '__body': 'Send money',
      'amount': '10',
    });
    await tester.pumpAndSettle();

    final page = expectRequestInfoRoute();
    expect(page.requestId, isNull);
    expect(page.fallbackData.amountInput, '10');
  });

  testWidgets('UNDO_REQUEST CREATED routes to undo action page', (
    tester,
  ) async {
    await pumpHarness(tester);

    handler.handlePayload({
      'type': 'UNDO_REQUEST',
      'action': 'CREATED',
      'undoRequestId': 'undo-1',
      'originalTxId': 'tx-1001',
      'amount': '120.50',
    });
    await tester.pump();

    final page = pushedPage();
    expect(page, isA<UndoRequestActionPage>());
    final undoPage = page as UndoRequestActionPage;
    expect(undoPage.fallbackData.undoRequestId, 'undo-1');
    expect(undoPage.fallbackData.originalTxId, 'tx-1001');
    expect(undoPage.fallbackData.action, 'CREATED');
  });

  testWidgets(
    'UNDO_REQUEST ACCEPTED routes to statement detail using refundTxId',
    (tester) async {
      await pumpHarness(tester);

      handler.handlePayload({
        'type': 'UNDO_REQUEST',
        'action': 'ACCEPTED',
        'undoRequestId': 'undo-1',
        'originalTxId': 'tx-1001',
        'refundTxId': 'refund-tx-1',
        'transactionId': 'mongo-object-id',
      });
      await tester.pump();

      final page = pushedPage();
      expect(page, isA<StatementDetailPage>());
      expect((page as StatementDetailPage).txId, 'refund-tx-1');
    },
  );

  testWidgets(
    'UNDO_REQUEST DENIED routes to statement detail using originalTxId',
    (tester) async {
      await pumpHarness(tester);

      handler.handlePayload({
        'type': 'UNDO_REQUEST',
        'action': 'DENIED',
        'undoRequestId': 'undo-1',
        'originalTxId': 'tx-1001',
        'transactionId': 'mongo-object-id',
      });
      await tester.pump();

      final page = pushedPage();
      expect(page, isA<StatementDetailPage>());
      expect((page as StatementDetailPage).txId, 'tx-1001');
    },
  );
}
