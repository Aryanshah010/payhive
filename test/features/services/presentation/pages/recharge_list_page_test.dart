import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';
import 'package:payhive/features/services/presentation/pages/recharge_list_page.dart';
import 'package:payhive/features/services/presentation/state/recharge_list_state.dart';
import 'package:payhive/features/services/presentation/state/recharge_payment_state.dart';
import 'package:payhive/features/services/presentation/view_model/recharge_list_view_model.dart';
import 'package:payhive/features/services/presentation/view_model/recharge_payment_view_model.dart';

class FakeRechargeListViewModel extends RechargeListViewModel {
  @override
  RechargeListState build() {
    return RechargeListState(
      status: RechargeListViewStatus.loaded,
      services: [
        RechargeServiceEntity(
          id: 'service-1',
          type: 'topup',
          provider: 'NTC',
          name: 'Data Pack',
          packageLabel: '2GB Daily',
          amount: 299,
          validationRegex: r'^\d{10}$',
          isActive: true,
          meta: const {},
        ),
      ],
      provider: '',
      search: '',
      errorMessage: null,
      page: 1,
      totalPages: 1,
      isLoadingMore: false,
    );
  }

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> applyFilters({
    required String provider,
    required String search,
  }) async {}

  @override
  Future<void> clearFilters() async {}
}

class FakeRechargePaymentViewModel extends RechargePaymentViewModel {
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
    state = state.copyWith(phoneNumber: value.trim());
  }

  @override
  Future<void> payService() async {}
}

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rechargeListViewModelProvider.overrideWith(
            () => FakeRechargeListViewModel(),
          ),
          rechargePaymentViewModelProvider.overrideWith(
            () => FakeRechargePaymentViewModel(),
          ),
        ],
        child: const MaterialApp(home: RechargeListPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders provider/search filters and service card', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Search'), findsNWidgets(2));
    expect(find.text('Data Pack'), findsNWidgets(2));
    expect(find.text('NTC'), findsNWidgets(2));
    expect(find.text('Package: 2GB Daily'), findsOneWidget);
    expect(find.text('Pay Now'), findsOneWidget);
  });

  testWidgets('tap pay navigates to recharge detail page', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Pay Now'));
    await tester.pumpAndSettle();

    expect(find.text('Recharge Payment'), findsOneWidget);
    expect(find.text('Pay Recharge'), findsOneWidget);
  });
}
