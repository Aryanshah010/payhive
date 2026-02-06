import 'package:flutter/material.dart';
import 'package:payhive/app/theme/colors.dart';
class BalanceCardWidget extends StatelessWidget {
  const BalanceCardWidget({super.key, required this.balance});

  final String balance;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final colorScheme = Theme.of(context).colorScheme;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: isTablet ? 24 : 18,
      vertical: isTablet ? 20 : 14,
    );

    return Card(
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
                    fontSize: isTablet ? 18 : 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 4),
                Text(
                  balance,
                  style: TextStyle(
                    fontSize: isTablet ? 28 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.refresh,
              color: AppColors.primary,
              size: isTablet ? 28 : 22,
            ),
          ],
        ),
      ),
    );
  }
}
