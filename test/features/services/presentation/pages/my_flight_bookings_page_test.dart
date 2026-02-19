import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/presentation/pages/my_flight_bookings_page.dart';
import 'package:payhive/features/services/presentation/state/flight_bookings_state.dart';
import 'package:payhive/features/services/presentation/view_model/flight_bookings_view_model.dart';

class FakeFlightBookingsViewModel extends FlightBookingsViewModel {
  @override
  FlightBookingsState build() {
    return FlightBookingsState(
      status: FlightBookingsViewStatus.loaded,
      bookings: [
        FlightBookingItemEntity(
          id: 'booking-created',
          status: 'created',
          quantity: 1,
          price: 4500,
          airline: 'Buddha Air',
          flightNumber: 'U4-201',
          from: 'Kathmandu',
          to: 'Pokhara',
          departure: DateTime.now().add(const Duration(days: 2)),
        ),
        FlightBookingItemEntity(
          id: 'booking-paid',
          status: 'paid',
          quantity: 1,
          price: 5000,
          airline: 'Yeti Air',
          flightNumber: 'YT-301',
          from: 'Kathmandu',
          to: 'Biratnagar',
          departure: DateTime.now().add(const Duration(days: 3)),
        ),
      ],
      filter: FlightBookingFilter.all,
      errorMessage: null,
      page: 1,
      totalPages: 1,
      isLoadingMore: false,
      payingBookingIds: const [],
      lastPaidBookingId: null,
    );
  }

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> payBooking(String bookingId) async {}
}

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flightBookingsViewModelProvider.overrideWith(
            () => FakeFlightBookingsViewModel(),
          ),
        ],
        child: const MaterialApp(home: MyFlightBookingsPage()),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('renders bookings without filter action and keeps pay states', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.filter_alt_outlined), findsNothing);
    expect(find.text('Pay Booking'), findsOneWidget);
    expect(find.text('Paid / Not Payable'), findsOneWidget);
  });
}
