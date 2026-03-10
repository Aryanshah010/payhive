import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/services/notifications/notification_push_service.dart';
import 'package:payhive/features/dashboard/presentation/pages/home_screen.dart';
import 'package:payhive/features/qr/presentation/pages/qr_scan_page.dart';
import 'package:payhive/features/statement/presentation/pages/statement_screen.dart';
import 'package:payhive/features/dashboard/presentation/pages/support_screen.dart';
import 'package:payhive/features/dashboard/presentation/widgets/nav_item_widgets.dart';
import 'package:payhive/features/profile/presentation/pages/profile_page.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  static const Duration _resumeRefreshThrottle = Duration(seconds: 3);

  int _selectedIndex = 0;
  DateTime? _lastResumeRefreshAt;

  List<Widget> lstBottomScreen = [
    const HomeScreen(),
    const StatementScreen(),
    const SupportScreen(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      if (!mounted) return;
      await ref.read(profileViewModelProvider.notifier).ensureLoaded();
      if (!mounted) return;
      await ref.read(notificationPushServiceProvider).init();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed || !mounted) return;

    final now = DateTime.now();
    final lastRefreshAt = _lastResumeRefreshAt;
    if (lastRefreshAt != null &&
        now.difference(lastRefreshAt) < _resumeRefreshThrottle) {
      return;
    }
    _lastResumeRefreshAt = now;

    unawaited(ref.read(profileViewModelProvider.notifier).refreshProfile());
    unawaited(ref.read(notificationPushServiceProvider).onAppResumed());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: lstBottomScreen[_selectedIndex],

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isTablet
          ? FloatingActionButton.large(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QrScanPage()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.qr_code, size: 52),
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QrScanPage()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.qr_code, size: 26),
            ),

      bottomNavigationBar: BottomAppBar(
        height: isTablet ? 90 : 70,
        elevation: 1,
        shape: const CircularNotchedRectangle(),
        notchMargin: isTablet ? 8 : 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: _selectedIndex == 0,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            NavItem(
              icon: Icons.text_snippet,
              label: 'Statement',
              isSelected: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
            ),

            const SizedBox(width: 48),

            NavItem(
              icon: Icons.contact_support_outlined,
              label: 'Support',
              isSelected: _selectedIndex == 2,
              onTap: () => setState(() => _selectedIndex = 2),
            ),

            NavItem(
              icon: Icons.person,
              label: 'Profile',
              isSelected: _selectedIndex == 3,
              onTap: () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}
