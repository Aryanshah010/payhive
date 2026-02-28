import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/routes/app_routes.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/currency_formatter.dart';
import 'package:payhive/features/bank_transfer/presentation/pages/bank_transfer_page.dart';
import 'package:payhive/features/dashboard/presentation/widgets/quick_action_btn_widgets.dart';
import 'package:payhive/features/dashboard/presentation/widgets/service_tile_widget.dart';
import 'package:payhive/features/notifications/presentation/pages/notifications_page.dart';
import 'package:payhive/features/notifications/presentation/view_model/notification_view_model.dart';
import 'package:payhive/features/profile/presentation/state/balance_visibility_provider.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';
import 'package:payhive/features/request_money/presentation/pages/request_money_page.dart';
import 'package:payhive/features/send_money/presentation/pages/send_money_initial_page.dart';
import 'package:payhive/features/services/presentation/pages/flight_list_page.dart';
import 'package:payhive/features/services/presentation/pages/hotel_list_page.dart';
import 'package:payhive/features/services/presentation/pages/internet_list_page.dart';
import 'package:payhive/features/services/presentation/pages/recharge_list_page.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profileState = ref.watch(profileViewModelProvider);
    final notificationState = ref.watch(notificationViewModelProvider);
    final balanceText = formatNpr(profileState.balance ?? 0);
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);
    final isRefreshingBalance = ref.watch(
      profileViewModelProvider.select(
        (state) => state.status == ProfileStatus.loading,
      ),
    );
    final balanceDisplay = isBalanceVisible ? balanceText : "XXXXX";
    final unreadCount = notificationState.unreadCount;

    final double horizontalPadding = isTablet ? 48 : 24;
    final double imageWidth = isTablet ? 220 : 120;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait<void>([
              ref.read(profileViewModelProvider.notifier).refreshProfile(),
              ref
                  .read(notificationViewModelProvider.notifier)
                  .refreshUnreadCount(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        "assets/images/inAppLogo.png",
                        width: imageWidth,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          AppRoutes.push(context, const NotificationsPage());
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.notifications_none_outlined,
                                size: isTablet ? 36 : 24,
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -6,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                    ),
                                    child: Text(
                                      unreadCount > 99
                                          ? '99+'
                                          : unreadCount.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 12 : 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isTablet ? 16 : 8),

                  Container(
                    height: isTablet ? 340 : 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.0),
                    ),

                    clipBehavior: Clip.antiAlias,

                    child: Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(balanceVisibilityProvider.notifier)
                                  .toggle();
                            },
                            child: Container(
                              color: AppColors.primary,
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: isTablet ? 10 : 6,
                                    right: isTablet ? 10 : 6,
                                    child: IconButton(
                                      onPressed: isRefreshingBalance
                                          ? null
                                          : () {
                                              ref
                                                  .read(
                                                    profileViewModelProvider
                                                        .notifier,
                                                  )
                                                  .refreshProfile();
                                            },
                                      icon: isRefreshingBalance
                                          ? SizedBox(
                                              width: isTablet ? 28 : 20,
                                              height: isTablet ? 28 : 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colorScheme.onPrimary,
                                              ),
                                            )
                                          : Icon(
                                              Icons.refresh_rounded,
                                              color: colorScheme.onPrimary,
                                              size: isTablet ? 34 : 24,
                                            ),
                                      splashRadius: isTablet ? 24 : 20,
                                      tooltip: "Refresh balance",
                                    ),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Your Balance",
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: isTablet ? 28 : 20,
                                                color: colorScheme.onPrimary,
                                              ),
                                        ),
                                        Text(
                                          balanceDisplay,
                                          style: textTheme.headlineMedium
                                              ?.copyWith(
                                                fontSize: isTablet ? 42 : 32,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.5,
                                                color: colorScheme.onPrimary,
                                                fontFamily: "Poppins",
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
                                  onTap: () {
                                    AppRoutes.push(
                                      context,
                                      const SendMoneyInitialPage(),
                                    );
                                  },
                                ),
                                QuickActionBtn(
                                  icon: Icons.arrow_downward,
                                  label: 'Request\nMoney',
                                  onTap: () {
                                    AppRoutes.push(
                                      context,
                                      const RequestMoneyPage(),
                                    );
                                  },
                                ),
                                QuickActionBtn(
                                  icon: Icons.account_balance,
                                  label: 'Bank\nTransfer',
                                  onTap: () {
                                    AppRoutes.push(
                                      context,
                                      const BankTransferPage(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isTablet ? 48 : 32),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.borderGrey.withOpacity(0.60)
                            : colorScheme.outline,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 32 : 16),
                      child: Column(
                        children: [
                          Text(
                            "Services",
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge?.copyWith(
                              fontSize: isTablet ? 32 : 20,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                              fontFamily: "Poppins",
                            ),
                          ),

                          SizedBox(height: isTablet ? 24 : 16),

                          GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 3.2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              ServiceTile(
                                icon: Icons.network_cell,
                                label: "Recharge",
                                onTap: () {
                                  AppRoutes.push(
                                    context,
                                    const RechargeListPage(),
                                  );
                                },
                              ),
                              ServiceTile(
                                icon: Icons.wifi,
                                label: "Internet",
                                onTap: () {
                                  AppRoutes.push(
                                    context,
                                    const InternetListPage(),
                                  );
                                },
                              ),
                              ServiceTile(
                                icon: Icons.flight,
                                label: "Flights",
                                onTap: () {
                                  AppRoutes.push(
                                    context,
                                    const FlightListPage(),
                                  );
                                },
                              ),
                              ServiceTile(
                                icon: Icons.hotel,
                                label: "Hotels",
                                onTap: () {
                                  AppRoutes.push(
                                    context,
                                    const HotelListPage(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
