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
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        elevation: 6,
        shape: const CircleBorder(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.darkText,
        child: const Icon(Icons.qr_code),
      ),

      bottomNavigationBar: BottomAppBar(
        height: 64, 
        elevation: 1,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
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
