import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payhive/features/onboarding/presentation/pages/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders first page correctly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('Welcome to PayHive'), findsOneWidget);
    expect(find.text('Your smart and secure digital wallet.'), findsOneWidget);

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Tapping Next moves to next onboarding page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Send Money Instantly'), findsOneWidget);
  });

  testWidgets('Last page shows Get Started button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    await tester.fling(find.byType(PageView), const Offset(-1000, 0), 1000);
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-1000, 0), 1000);
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-1000, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('OnboardingScreen has no render errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(tester.takeException(), isNull);
  });
}
