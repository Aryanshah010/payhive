import 'package:flutter/material.dart';
import 'package:payhive/screens/dashboard_screen.dart';
// import 'package:payhive/screens/onboarding_screen.dart';
import 'package:payhive/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: DashboardScreen(),
    );
  }
}