import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';
import 'package:payhive/features/services/presentation/pages/internet_list_page.dart';
import 'package:payhive/features/services/presentation/state/internet_list_state.dart';
import 'package:payhive/features/services/presentation/state/internet_payment_state.dart';
import 'package:payhive/features/services/presentation/view_model/internet_list_view_model.dart';
import 'package:payhive/features/services/presentation/view_model/internet_payment_view_model.dart';

class FakeInternetListViewModel extends InternetListViewModel {
  @override
  InternetListState build() {
    return InternetListState(
      status: InternetListViewStatus.loaded,
      services: [
        InternetServiceEntity(
          id: 'service-1',
          type: 'internet',
          provider: 'Airtel Xstream',
          name: 'Fiber 100 Mbps',
          packageLabel: 'Monthly',
          amount: 999,
          validationRegex: r'^[A-Z0-9]{6,16}$',
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

class FakeInternetPaymentViewModel extends InternetPaymentViewModel {
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
    state = state.copyWith(customerId: value.trim());
  }

  @override
  Future<void> payService() async {}
}

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          internetListViewModelProvider.overrideWith(
            () => FakeInternetListViewModel(),
          ),
          internetPaymentViewModelProvider.overrideWith(
            () => FakeInternetPaymentViewModel(),
          ),
        ],
        child: const MaterialApp(home: InternetListPage()),
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
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Fiber 100 Mbps'), findsNWidgets(2));
    expect(find.text('Airtel Xstream'), findsNWidgets(2));
    expect(find.text('Package: Monthly'), findsOneWidget);
    expect(find.text('Pay Now'), findsOneWidget);
  });

  testWidgets('tap pay navigates to internet detail page', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Pay Now'));
    await tester.pumpAndSettle();

    expect(find.text('Internet Payment'), findsOneWidget);
    expect(find.text('Pay Internet'), findsOneWidget);
  });
}
