import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';
import 'package:payhive/features/services/presentation/pages/internet_detail_page.dart';
import 'package:payhive/features/services/presentation/state/internet_payment_state.dart';
import 'package:payhive/features/services/presentation/view_model/internet_payment_view_model.dart';

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

class FakeInternetPaymentViewModel extends InternetPaymentViewModel {
  int payCallCount = 0;
  bool keepLoading = false;

  @override
  InternetPaymentState build() {
    return InternetPaymentState.initial();
  }

  @override
  void setService(InternetServiceEntity service) {
    state = state.copyWith(
      status: InternetPaymentViewStatus.loaded,
      action: InternetPaymentAction.none,
      service: service,
      customerId: '',
      paymentResult: null,
      errorMessage: null,
      payIdempotencyKey: null,
      payLocked: false,
    );
  }

  @override
  void setCustomerId(String value) {
    state = state.copyWith(customerId: value.trim(), paymentResult: null);
  }

  @override
  Future<void> payService() async {
    payCallCount += 1;

    state = state.copyWith(
      status: InternetPaymentViewStatus.loading,
      action: InternetPaymentAction.pay,
      payLocked: true,
      errorMessage: null,
    );

    if (keepLoading) return;
    finishPayment();
  }

  void finishPayment() {
    state = state.copyWith(
      status: InternetPaymentViewStatus.loaded,
      action: InternetPaymentAction.none,
      payLocked: false,
      paymentResult: PayInternetResultEntity(
        transactionId: 'txn-1',
        receipt: InternetPaymentReceiptEntity(
          receiptNo: 'RCP-1',
          serviceType: 'internet',
          serviceId: 'service-1',
          provider: 'Airtel Xstream',
          planName: 'Fiber 100 Mbps',
          customerIdMasked: 'AB****34',
          amount: 999,
          createdAt: DateTime(2026, 3, 10, 10, 30),
        ),
        idempotentReplay: false,
      ),
    );
  }
}

void main() {
  final sampleService = InternetServiceEntity(
    id: 'service-1',
    type: 'internet',
    provider: 'Airtel Xstream',
    name: 'Fiber 100 Mbps',
    packageLabel: 'Monthly',
    amount: 999,
    validationRegex: r'^[A-Z0-9]{6,16}$',
    isActive: true,
    meta: const {},
  );

  Future<FakeInternetPaymentViewModel> pumpScreen(
    WidgetTester tester, {
    bool keepLoading = false,
  }) async {
    final fakePaymentVm = FakeInternetPaymentViewModel()
      ..keepLoading = keepLoading;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(() => FakeProfileViewModel()),
          internetPaymentViewModelProvider.overrideWith(() => fakePaymentVm),
        ],
        child: MaterialApp(home: InternetDetailPage(service: sampleService)),
      ),
    );
    await tester.pumpAndSettle();
    return fakePaymentVm;
  }

  testWidgets('customer id input and pay shows receipt', (tester) async {
    final fakeVm = await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'ABCD1234');
    await tester.tap(find.text('Pay Internet'));
    await tester.pumpAndSettle();

    expect(fakeVm.payCallCount, 1);
    expect(find.textContaining('Transaction ID:'), findsOneWidget);
    expect(find.textContaining('Customer ID:'), findsOneWidget);
  });

  testWidgets('pay button shows loading and prevents repeated tap', (
    tester,
  ) async {
    final fakeVm = await pumpScreen(tester, keepLoading: true);

    await tester.enterText(find.byType(TextField), 'ABCD1234');
    await tester.tap(find.text('Pay Internet'));
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
