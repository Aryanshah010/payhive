import 'package:flutter/material.dart';
import 'package:payhive/theme/colors.dart';
import 'package:payhive/widgets/nav_item_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(fontSize: isTablet ? 30 : 20),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isTablet
          ? FloatingActionButton.large(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.darkText,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.qr_code, size: 52),
            )
          : FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.darkText,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.qr_code, size: 24),
            ),

      bottomNavigationBar: BottomAppBar(
        height: isTablet ? 90 : 64,
        elevation: 1,
        shape: const CircularNotchedRectangle(),
        notchMargin: isTablet?8:6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: selectedIndex == 0,
              onTap: () => setState(() => selectedIndex = 0),
            ),
            NavItem(
              icon: Icons.text_snippet,
              label: 'Statement',
              isSelected: selectedIndex == 1,
              onTap: () => setState(() => selectedIndex = 1),
            ),

            const SizedBox(width: 48),

            NavItem(
              icon: Icons.contact_support_outlined,
              label: 'Support',
              isSelected: selectedIndex == 2,
              onTap: () => setState(() => selectedIndex = 2),
            ),
            NavItem(
              icon: Icons.person,
              label: 'Profile',
              isSelected: selectedIndex == 3,
              onTap: () => setState(() => selectedIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}
