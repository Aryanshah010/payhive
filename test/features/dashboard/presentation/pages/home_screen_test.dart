import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/dashboard/presentation/pages/home_screen.dart';
import 'package:payhive/features/dashboard/presentation/widgets/quick_action_btn_widgets.dart';
import 'package:payhive/features/dashboard/presentation/widgets/service_tile_widget.dart';

void main() {
  testWidgets('HomeScreen renders core UI without images', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

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
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.byType(QuickActionBtn), findsNWidgets(3));
  });

  testWidgets('HomeScreen shows 4 service tiles', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.byType(ServiceTile), findsNWidgets(4));
  });

  testWidgets('HomeScreen shows notification icon', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
  });

  testWidgets('HomeScreen uses tablet layout on large screens', (tester) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Your Balance'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('HomeScreen has no overflow or render errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping Send Money button works', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.text('Send\nMoney'));
    await tester.pump();
  });
}
