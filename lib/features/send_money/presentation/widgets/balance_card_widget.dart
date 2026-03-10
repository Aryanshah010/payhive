import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/features/profile/presentation/state/balance_visibility_provider.dart';
import 'package:payhive/features/profile/presentation/state/profile_state.dart';
import 'package:payhive/features/profile/presentation/view_model/profile_view_model.dart';

class BalanceCardWidget extends ConsumerWidget {
  const BalanceCardWidget({super.key, required this.balance});

  final String balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final colorScheme = Theme.of(context).colorScheme;
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);
    final isRefreshing = ref.watch(
      profileViewModelProvider.select(
        (state) => state.status == ProfileStatus.loading,
      ),
    );
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: isTablet ? 28 : 18,
      vertical: isTablet ? 22 : 14,
    );
    final double labelFont = isTablet ? 20 : 14;
    final double valueFont = isTablet ? 32 : 20;
    final double iconSize = isTablet ? 30 : 22;
    final balanceDisplay = isBalanceVisible ? balance : "XXXXX";

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(balanceVisibilityProvider.notifier).toggle();
        },
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Balance",
                    style: TextStyle(
                      fontSize: labelFont,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: isTablet ? 8 : 4),
                  Text(
                    balanceDisplay,
                    style: TextStyle(
                      fontSize: valueFont,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: isRefreshing
                    ? null
                    : () {
                        ref
                            .read(profileViewModelProvider.notifier)
                            .refreshProfile();
                      },
                icon: isRefreshing
                    ? SizedBox(
                        height: iconSize,
                        width: iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: AppColors.primary,
                        size: iconSize,
                      ),
                tooltip: "Refresh balance",
                splashRadius: isTablet ? 22 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
