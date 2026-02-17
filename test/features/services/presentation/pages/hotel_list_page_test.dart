import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/presentation/pages/hotel_list_page.dart';
import 'package:payhive/features/services/presentation/state/hotel_booking_state.dart';
import 'package:payhive/features/services/presentation/state/hotel_list_state.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_booking_view_model.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_list_view_model.dart';

class FakeHotelListViewModel extends HotelListViewModel {
  @override
  HotelListState build() {
    return const HotelListState(
      status: HotelListViewStatus.loaded,
      hotels: [
        HotelEntity(
          id: 'hotel-1',
          name: 'Thamel Boutique Residency',
          city: 'Kathmandu',
          roomType: 'Deluxe',
          roomsTotal: 45,
          roomsAvailable: 12,
          pricePerNight: 4800,
          amenities: ['wifi'],
          images: [],
        ),
      ],
      city: '',
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
  Future<void> applyCityFilter(String city) async {}

  @override
  Future<void> clearFilter() async {}
}

class FakeHotelBookingViewModel extends HotelBookingViewModel {
  @override
  HotelBookingState build() {
    return HotelBookingState.initial();
  }

  @override
  void setHotel(HotelEntity hotel) {
    state = state.copyWith(
      status: HotelBookingViewStatus.loaded,
      hotel: hotel,
      action: HotelBookingAction.none,
      rooms: 1,
      nights: 1,
      checkin: '',
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
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hotelListViewModelProvider.overrideWith(
            () => FakeHotelListViewModel(),
          ),
          hotelBookingViewModelProvider.overrideWith(
            () => FakeHotelBookingViewModel(),
          ),
        ],
        child: const MaterialApp(home: HotelListPage()),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('renders city filter and hotel card', (tester) async {
    await pumpScreen(tester);

    expect(find.text('City'), findsOneWidget);
    expect(find.text('Thamel Boutique Residency'), findsOneWidget);
    expect(find.text('Kathmandu • Deluxe'), findsOneWidget);
    expect(find.text('Book Hotel'), findsOneWidget);
  });

  testWidgets('book action navigates to hotel detail page', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Book Hotel'));
    await tester.pumpAndSettle();

    expect(find.text('Hotel Detail'), findsOneWidget);
    expect(find.text('Create Booking'), findsOneWidget);
  });
}
