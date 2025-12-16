import 'package:flutter/material.dart';
import 'package:payhive/theme/colors.dart';
import 'package:payhive/widgets/nav_item_widgets.dart';
import 'package:payhive/widgets/quick_action_btn_widgets.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset("assets/images/inAppLogo.png", width: 120),
                    Icon(Icons.notifications_none_outlined),
                  ],
                ),

                SizedBox(height: 8),

                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.0),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 4),
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ],
                  ),

                  clipBehavior: Clip.antiAlias,

                  child: Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          color: AppColors.primary,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Your Balance",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  "NPR 12,800.00",
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 4,
                        child: Container(
                          color: AppColors.primaryLight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              QuickActionBtn(
                                icon: Icons.arrow_upward,
                                label: 'Send\nMoney',
                              ),
                              QuickActionBtn(
                                icon: Icons.arrow_downward,
                                label: 'Request\nMoney',
                              ),
                              QuickActionBtn(
                                icon: Icons.account_balance,
                                label: 'Bank\nTransfer',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        notchMargin: isTablet ? 8 : 6,
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
