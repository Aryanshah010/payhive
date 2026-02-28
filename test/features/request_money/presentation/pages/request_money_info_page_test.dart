import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/services/storage/user_session_service.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/request_money/domain/entity/request_money_entity.dart';
import 'package:payhive/features/request_money/domain/usecases/request_money_usecase.dart';
import 'package:payhive/features/request_money/presentation/pages/request_money_info_page.dart';
import 'package:payhive/features/request_money/presentation/state/request_money_info_state.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_initial_page.dart';
import 'package:payhive/features/send_money/presentation/state/send_money_state.dart';
import 'package:payhive/features/send_money/presentation/view_model/send_money_view_model.dart';
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

class _NoopSendMoneyViewModel extends SendMoneyViewModel {
  @override
  SendMoneyState build() {
    return SendMoneyState.initial();
  }

  @override
  Future<void> lookupBeneficiary() async {}
}

class _FakeProfileViewModel extends ProfileViewModel {
  @override
  ProfileState build() {
    return const ProfileState(
      status: ProfileStatus.loaded,
      fullName: 'User',
      phoneNumber: '9800000002',
      email: 'u@example.com',
      balance: 1200,
      hasPin: true,
    );
  }
}

void main() {
  late MockGetMoneyRequestDetailUsecase mockGetDetailUsecase;
  late MockRespondMoneyRequestUsecase mockRespondUsecase;
  late SharedPreferences prefs;
  late _RecordingNavigatorObserver observer;

  setUpAll(() {
    registerFallbackValue(const GetMoneyRequestDetailParams(requestId: 'mr-1'));
    registerFallbackValue(
      const RespondMoneyRequestParams(
        requestId: 'mr-1',
        action: MoneyRequestAction.reject,
      ),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'user_phone_number': '9800000002'});
    prefs = await SharedPreferences.getInstance();
    mockGetDetailUsecase = MockGetMoneyRequestDetailUsecase();
    mockRespondUsecase = MockRespondMoneyRequestUsecase();
    observer = _RecordingNavigatorObserver();
  });

  MoneyRequestEntity request({required String status}) {
    return MoneyRequestEntity(
      id: 'mr-1',
      requester: const RecipientEntity(
        id: 'requester',
        fullName: 'Requester',
        phoneNumber: '9800000001',
      ),
      receiver: const RecipientEntity(
        id: 'receiver',
        fullName: 'Receiver',
        phoneNumber: '9800000002',
      ),
      amount: 120,
      remark: 'Please send',
      status: status,
      expiresAt: DateTime(2026, 1, 20),
      respondedAt: status == 'PENDING' ? null : DateTime(2026, 1, 2),
      transactionId: null,
      createdAt: DateTime(2026, 1, 1, 12, 0),
      updatedAt: DateTime(2026, 1, 2, 12, 0),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    String? requestId = 'mr-1',
    RequestMoneyInfoFallbackData fallbackData =
        const RequestMoneyInfoFallbackData(),
  }) async {
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
          sendMoneyViewModelProvider.overrideWith(
            () => _NoopSendMoneyViewModel(),
          ),
          profileViewModelProvider.overrideWith(() => _FakeProfileViewModel()),
        ],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: RequestMoneyInfoPage(
            requestId: requestId,
            fallbackData: fallbackData,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('shows accept and reject for pending receiver request', (
    tester,
  ) async {
    when(
      () => mockGetDetailUsecase(any()),
    ).thenAnswer((_) async => Right(request(status: 'PENDING')));

    await pumpPage(tester);

    expect(find.text('ACCEPT'), findsOneWidget);
    expect(find.text('REJECT'), findsOneWidget);
  });

  testWidgets('accept opens send money page with request linkage', (
    tester,
  ) async {
    when(
      () => mockGetDetailUsecase(any()),
    ).thenAnswer((_) async => Right(request(status: 'PENDING')));

    await pumpPage(tester);

    await tester.tap(find.text('ACCEPT'));
    await tester.pumpAndSettle();

    final route = observer.lastPushedRoute;
    expect(route, isA<MaterialPageRoute<dynamic>>());
    final page = (route as MaterialPageRoute<dynamic>).builder(
      tester.element(find.byType(MaterialApp)),
    );
    expect(page, isA<SendMoneyInitialPage>());
    final sendMoneyPage = page as SendMoneyInitialPage;
    expect(sendMoneyPage.prefill?.phoneNumber, '9800000001');
    expect(sendMoneyPage.prefill?.sourceMoneyRequestId, 'mr-1');
  });

  testWidgets('read-only for canceled request with no action buttons', (
    tester,
  ) async {
    when(
      () => mockGetDetailUsecase(any()),
    ).thenAnswer((_) async => Right(request(status: 'CANCELED')));

    await pumpPage(tester);

    expect(find.text('ACCEPT'), findsNothing);
    expect(find.text('REJECT'), findsNothing);
    expect(find.textContaining('already canceled'), findsOneWidget);
  });

  testWidgets('missing request id shows read-only fallback', (tester) async {
    await pumpPage(
      tester,
      requestId: null,
      fallbackData: const RequestMoneyInfoFallbackData(
        phoneNumber: '9800000001',
        amountInput: '100',
      ),
    );

    expect(find.text('ACCEPT'), findsNothing);
    expect(find.text('REJECT'), findsNothing);
    expect(
      find.text(
        'Request ID is unavailable. Actions are disabled for this notification.',
      ),
      findsOneWidget,
    );
  });
}
