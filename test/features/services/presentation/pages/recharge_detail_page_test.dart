import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';
import 'package:payhive/features/services/presentation/pages/recharge_detail_page.dart';
import 'package:payhive/features/services/presentation/state/recharge_payment_state.dart';
import 'package:payhive/features/services/presentation/view_model/recharge_payment_view_model.dart';

class FakeProfileViewModel extends ProfileViewModel {
  @override
  ProfileState build() {
    return const ProfileState(
      status: ProfileStatus.loaded,
      fullName: 'Test User',
      phoneNumber: '9800000000',
      email: 'test@payhive.com',
      balance: 5000,
    );
  }

  @override
  Future<void> refreshProfile() async {}
}

class FakeRechargePaymentViewModel extends RechargePaymentViewModel {
  int payCallCount = 0;
  bool keepLoading = false;

  @override
  RechargePaymentState build() {
    return RechargePaymentState.initial();
  }

  @override
  void setService(RechargeServiceEntity service) {
    state = state.copyWith(
      status: RechargePaymentViewStatus.loaded,
      action: RechargePaymentAction.none,
      service: service,
      phoneNumber: '',
      paymentResult: null,
      errorMessage: null,
      payIdempotencyKey: null,
      payLocked: false,
    );
  }

  @override
  void setPhoneNumber(String value) {
    state = state.copyWith(phoneNumber: value.trim(), paymentResult: null);
  }

  @override
  Future<void> payService() async {
    payCallCount += 1;

    state = state.copyWith(
      status: RechargePaymentViewStatus.loading,
      action: RechargePaymentAction.pay,
      payLocked: true,
      errorMessage: null,
    );

    if (keepLoading) return;
    finishPayment();
  }

  void finishPayment() {
    state = state.copyWith(
      status: RechargePaymentViewStatus.loaded,
      action: RechargePaymentAction.none,
      payLocked: false,
      paymentResult: PayRechargeResultEntity(
        transactionId: 'txn-1',
        receipt: RechargePaymentReceiptEntity(
          receiptNo: 'RCP-1',
          serviceType: 'topup',
          serviceId: 'service-1',
          carrier: 'NTC',
          packageLabel: '2GB Daily',
          phoneMasked: '98******78',
          amount: 299,
          createdAt: DateTime(2026, 3, 10, 10, 30),
        ),
        idempotentReplay: false,
      ),
    );
  }
}

void main() {
  final sampleService = RechargeServiceEntity(
    id: 'service-1',
    type: 'topup',
    provider: 'NTC',
    name: 'Data Pack',
    packageLabel: '2GB Daily',
    amount: 299,
    validationRegex: r'^\d{10}$',
    isActive: true,
    meta: const {},
  );

  Future<FakeRechargePaymentViewModel> pumpScreen(
    WidgetTester tester, {
    bool keepLoading = false,
  }) async {
    final fakePaymentVm = FakeRechargePaymentViewModel()
      ..keepLoading = keepLoading;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(() => FakeProfileViewModel()),
          rechargePaymentViewModelProvider.overrideWith(() => fakePaymentVm),
        ],
        child: MaterialApp(home: RechargeDetailPage(service: sampleService)),
      ),
    );
    await tester.pumpAndSettle();
    return fakePaymentVm;
  }

  testWidgets('phone input and pay shows receipt', (tester) async {
    final fakeVm = await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), '9812345678');
    await tester.tap(find.text('Pay Recharge'));
    await tester.pumpAndSettle();

    expect(fakeVm.payCallCount, 1);
    expect(find.textContaining('Transaction ID:'), findsOneWidget);
    expect(find.textContaining('Phone:'), findsOneWidget);
  });

  testWidgets('pay button shows loading and prevents repeated tap', (
    tester,
  ) async {
    final fakeVm = await pumpScreen(tester, keepLoading: true);

    await tester.enterText(find.byType(TextField), '9812345678');
    await tester.tap(find.text('Pay Recharge'));
    await tester.pump();

    expect(fakeVm.payCallCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);

    fakeVm.finishPayment();
    await tester.pumpAndSettle();

    expect(find.textContaining('Transaction ID:'), findsOneWidget);
  });
}
