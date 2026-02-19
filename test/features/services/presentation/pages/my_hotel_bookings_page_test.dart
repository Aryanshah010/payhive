import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/presentation/pages/my_hotel_bookings_page.dart';
import 'package:payhive/features/services/presentation/state/hotel_bookings_state.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_bookings_view_model.dart';

class FakeHotelBookingsViewModel extends HotelBookingsViewModel {
  @override
  HotelBookingsState build() {
    return HotelBookingsState(
      status: HotelBookingsViewStatus.loaded,
      bookings: [
        HotelBookingItemEntity(
          id: 'booking-created',
          status: 'created',
          quantity: 1,
          nights: 2,
          checkin: DateTime(2030, 1, 1),
          price: 4800,
          name: 'Thamel Boutique Residency',
          city: 'Kathmandu',
          roomType: 'Deluxe',
        ),
        HotelBookingItemEntity(
          id: 'booking-paid',
          status: 'paid',
          quantity: 1,
          nights: 3,
          checkin: DateTime(2030, 1, 2),
          price: 9600,
          name: 'Lakeside Horizon Hotel',
          city: 'Pokhara',
          roomType: 'Lake View',
        ),
      ],
      filter: HotelBookingFilter.all,
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
          hotelBookingsViewModelProvider.overrideWith(
            () => FakeHotelBookingsViewModel(),
          ),
        ],
        child: const MaterialApp(home: MyHotelBookingsPage()),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('renders bookings without filter action and without nights row', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.filter_alt_outlined), findsNothing);
    expect(find.textContaining('Nights:'), findsNothing);
    expect(find.text('Pay Booking'), findsOneWidget);
    expect(find.text('Paid / Not Payable'), findsOneWidget);
  });
}
