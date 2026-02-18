import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/dashboard/presentation/pages/home_screen.dart';
import 'package:payhive/features/dashboard/presentation/widgets/quick_action_btn_widgets.dart';
import 'package:payhive/features/dashboard/presentation/widgets/service_tile_widget.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/services/domain/entity/flight_entity.dart';
import 'package:payhive/features/services/domain/entity/hotel_entity.dart';
import 'package:payhive/features/services/domain/entity/recharge_entity.dart';
import 'package:payhive/features/services/presentation/pages/flight_list_page.dart';
import 'package:payhive/features/services/presentation/pages/hotel_list_page.dart';
import 'package:payhive/features/services/presentation/pages/internet_list_page.dart';
import 'package:payhive/features/services/presentation/pages/recharge_list_page.dart';
import 'package:payhive/features/services/presentation/state/flight_list_state.dart';
import 'package:payhive/features/services/presentation/state/hotel_list_state.dart';
import 'package:payhive/features/services/presentation/state/internet_list_state.dart';
import 'package:payhive/features/services/presentation/state/recharge_list_state.dart';
import 'package:payhive/features/services/presentation/view_model/flight_list_view_model.dart';
import 'package:payhive/features/services/presentation/view_model/hotel_list_view_model.dart';
import 'package:payhive/features/services/presentation/view_model/internet_list_view_model.dart';
import 'package:payhive/features/services/presentation/view_model/recharge_list_view_model.dart';
import 'package:payhive/features/services/domain/entity/internet_entity.dart';

class FakeProfileViewModel extends ProfileViewModel {
  @override
  ProfileState build() {
    return const ProfileState(
      status: ProfileStatus.loaded,
      fullName: 'Test User',
      phoneNumber: '9800000000',
      email: 'test@payhive.com',
      balance: 12800,
    );
  }
}

class FakeFlightListViewModel extends FlightListViewModel {
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
}

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
}

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
}

class FakeRechargeListViewModel extends RechargeListViewModel {
  @override
  RechargeListState build() {
    return RechargeListState(
      status: RechargeListViewStatus.loaded,
      services: [
        RechargeServiceEntity(
          id: 'topup-1',
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
}

void main() {
  Future<void> pumpHomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(() => FakeProfileViewModel()),
          flightListViewModelProvider.overrideWith(
            () => FakeFlightListViewModel(),
          ),
          hotelListViewModelProvider.overrideWith(
            () => FakeHotelListViewModel(),
          ),
          internetListViewModelProvider.overrideWith(
            () => FakeInternetListViewModel(),
          ),
          rechargeListViewModelProvider.overrideWith(
            () => FakeRechargeListViewModel(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
  }

  testWidgets('HomeScreen renders core UI without images', (tester) async {
    await pumpHomeScreen(tester);

    expect(find.text('Your Balance'), findsOneWidget);
    expect(find.text('NPR 12,800.00'), findsOneWidget);

    expect(find.text('Send\nMoney'), findsOneWidget);
    expect(find.text('Request\nMoney'), findsOneWidget);
    expect(find.text('Bank\nTransfer'), findsOneWidget);

    // Services
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Recharge'), findsOneWidget);
    expect(find.text('Internet'), findsOneWidget);
    expect(find.text('Flights'), findsOneWidget);
    expect(find.text('Hotels'), findsOneWidget);
  });

  testWidgets('HomeScreen shows 3 quick action buttons', (tester) async {
    await pumpHomeScreen(tester);

    expect(find.byType(QuickActionBtn), findsNWidgets(3));
  });

  testWidgets('HomeScreen shows 4 service tiles', (tester) async {
    await pumpHomeScreen(tester);

    expect(find.byType(ServiceTile), findsNWidgets(4));
  });

  testWidgets('HomeScreen shows notification icon', (tester) async {
    await pumpHomeScreen(tester);

    expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
  });

  testWidgets('HomeScreen uses tablet layout on large screens', (tester) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1.0;

    await pumpHomeScreen(tester);

    expect(find.text('Your Balance'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('HomeScreen has no overflow or render errors', (tester) async {
    await pumpHomeScreen(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping Send Money button works', (tester) async {
    await pumpHomeScreen(tester);

    await tester.tap(find.text('Send\nMoney'));
  });

  testWidgets('Tapping Flights tile opens flight list page', (tester) async {
    await pumpHomeScreen(tester);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ServiceTile, 'Flights'));
    await tester.pumpAndSettle();

    expect(find.byType(FlightListPage), findsOneWidget);
    expect(find.text('My Bookings'), findsOneWidget);
  });

  testWidgets('Tapping Recharge tile opens recharge list page', (tester) async {
    await pumpHomeScreen(tester);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ServiceTile, 'Recharge'));
    await tester.pumpAndSettle();

    expect(find.byType(RechargeListPage), findsOneWidget);
    expect(find.text('Recharge Services'), findsOneWidget);
  });

  testWidgets('Tapping Hotels tile opens hotel list page', (tester) async {
    await pumpHomeScreen(tester);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ServiceTile, 'Hotels'));
    await tester.pumpAndSettle();

    expect(find.byType(HotelListPage), findsOneWidget);
    expect(find.text('My Bookings'), findsOneWidget);
  });

  testWidgets('Tapping Internet tile opens internet list page', (tester) async {
    await pumpHomeScreen(tester);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ServiceTile, 'Internet'));
    await tester.pumpAndSettle();

    expect(find.byType(InternetListPage), findsOneWidget);
    expect(find.text('Internet Services'), findsOneWidget);
  });
}
