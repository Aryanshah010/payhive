import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/presentation/pages/flight_list_page.dart';
import 'package:payhive/features/services/presentation/state/flight_booking_state.dart';
import 'package:payhive/features/services/presentation/state/flight_list_state.dart';
import 'package:payhive/features/services/presentation/view_model/flight_booking_view_model.dart';
import 'package:payhive/features/services/presentation/view_model/flight_list_view_model.dart';

class FakeFlightListViewModel extends FlightListViewModel {
  static String? lastAppliedFrom;
  static String? lastAppliedTo;
  static String? lastAppliedDate;

  @override
  FlightListState build() {
    return FlightListState(
      status: FlightListViewStatus.loaded,
      flights: [
        FlightEntity(
          id: 'flight-1',
          airline: 'Buddha Air',
          flightNumber: 'U4-201',
          from: 'Kathmandu',
          to: 'Pokhara',
          departure: DateTime(2026, 3, 15, 8, 0),
          arrival: DateTime(2026, 3, 15, 9, 0),
          durationMinutes: 60,
          flightClass: 'Economy',
          price: 4500,
          seatsTotal: 70,
          seatsAvailable: 30,
        ),
      ],
      from: '',
      to: '',
      date: '',
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
    required String from,
    required String to,
    String? date,
  }) async {
    lastAppliedFrom = from;
    lastAppliedTo = to;
    lastAppliedDate = date;
  }

  @override
  Future<void> clearFilters() async {}
}

class FakeFlightBookingViewModel extends FlightBookingViewModel {
  @override
  FlightBookingState build() {
    return FlightBookingState.initial();
  }

  @override
  void setFlight(FlightEntity flight) {
    state = state.copyWith(
      status: FlightBookingViewStatus.loaded,
      flight: flight,
      action: FlightBookingAction.none,
      quantity: 1,
      createdBooking: null,
      paymentResult: null,
      errorMessage: null,
      payIdempotencyKey: null,
      payLocked: false,
    );
  }

  @override
  Future<void> createBooking() async {}

  @override
  Future<void> payBooking() async {}
}

void main() {
  setUp(() {
    FakeFlightListViewModel.lastAppliedFrom = null;
    FakeFlightListViewModel.lastAppliedTo = null;
    FakeFlightListViewModel.lastAppliedDate = null;
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flightListViewModelProvider.overrideWith(
            () => FakeFlightListViewModel(),
          ),
          flightBookingViewModelProvider.overrideWith(
            () => FakeFlightBookingViewModel(),
          ),
        ],
        child: const MaterialApp(home: FlightListPage()),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('renders filters and flight card', (tester) async {
    await pumpScreen(tester);

    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Date (YYYY-MM-DD)'), findsOneWidget);
    expect(find.textContaining('Buddha Air'), findsOneWidget);
    expect(find.text('Kathmandu -> Pokhara'), findsOneWidget);
    expect(find.text('Book'), findsOneWidget);
  });

  testWidgets('book action navigates to detail page', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Book'));
    await tester.pumpAndSettle();

    expect(find.text('Flight Detail'), findsOneWidget);
    expect(find.text('Create Booking'), findsOneWidget);
  });

  testWidgets('selected date remains in field and is sent in search', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(TextField).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final dateField = tester.widget<TextField>(find.byType(TextField).at(2));
    final selectedDate = dateField.controller?.text ?? '';
    expect(selectedDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));

    await tester.tap(find.text('Search'));
    await tester.pump();

    expect(FakeFlightListViewModel.lastAppliedDate, selectedDate);
  });
}
