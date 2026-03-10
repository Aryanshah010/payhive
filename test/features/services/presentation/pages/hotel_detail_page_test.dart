import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/presentation/pages/hotel_detail_page.dart';
import 'package:payhive/features/services/presentation/state/hotel_booking_state.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_booking_view_model.dart';

class FakeHotelBookingViewModel extends HotelBookingViewModel {
  @override
  HotelBookingState build() {
    return HotelBookingState(
      status: HotelBookingViewStatus.loaded,
      action: HotelBookingAction.none,
      hotel: _hotel,
      rooms: 1,
      nights: 1,
      checkin: '',
      checkout: '',
      createdBooking: null,
      paymentResult: null,
      errorMessage: null,
      payIdempotencyKey: null,
      payLocked: false,
    );
  }

  @override
  void setHotel(HotelEntity hotel) {
    state = state.copyWith(
      status: HotelBookingViewStatus.loaded,
      action: HotelBookingAction.none,
      hotel: hotel,
      rooms: 1,
      nights: 1,
      checkin: '',
      checkout: '',
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

const _hotel = HotelEntity(
  id: 'hotel-1',
  name: 'Nagarkot Sunrise Resort',
  city: 'Nagarkot',
  roomType: 'Mountain View',
  roomsTotal: 10,
  roomsAvailable: 5,
  pricePerNight: 5800,
  amenities: ['wifi'],
  images: [],
);

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        hotelBookingViewModelProvider.overrideWith(
          () => FakeHotelBookingViewModel(),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HotelDetailPage(hotel: _hotel)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows checkout field and no nights selector', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Checkin (YYYY-MM-DD)'), findsOneWidget);
    expect(find.text('Checkout (YYYY-MM-DD)'), findsOneWidget);
    expect(find.text('Nights'), findsNothing);
  });

  testWidgets('total updates from checkin-checkout date span', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Total: NPR 5,800.00'), findsOneWidget);

    final vm = container.read(hotelBookingViewModelProvider.notifier);
    vm.setCheckin('2030-01-01');
    vm.setCheckout('2030-01-04');
    await tester.pump();

    expect(find.text('Total: NPR 17,400.00'), findsOneWidget);
  });
}
