import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/app_theme.dart';
import 'package:payhive/app/theme/theme_notifier.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
import 'package:payhive/features/splash/presentation/pages/splash_page.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRoutes.navigatorKey,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final isTablet =
            media.size.shortestSide >= ResponsiveLayout.tabletBreakpoint;

        if (!isTablet) {
          return child ?? const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final appBarTitleBase =
            theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge;

        final scaledTheme = theme.copyWith(
          appBarTheme: theme.appBarTheme.copyWith(
            toolbarHeight: 62,
            titleTextStyle: appBarTitleBase?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

        return MediaQuery(
          data: media.copyWith(textScaler: const TextScaler.linear(1.18)),
          child: Theme(
            data: scaledTheme,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const SplashPage(),
    );
  }
}
