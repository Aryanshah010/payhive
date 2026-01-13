import 'package:flutter/material.dart';
import 'package:payhive/app/theme/app_theme.dart';
import 'package:payhive/features/splash/presentation/pages/splash_page.dart';


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: SplashPage(),
    );
  }
}