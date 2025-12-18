import 'package:flutter/material.dart';
import 'package:payhive/theme/colors.dart';

class QuickActionBtn extends StatelessWidget {
  const QuickActionBtn({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    final double circleHW = isTablet ? 72 : 46;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: circleHW,
            height: circleHW,
            decoration: BoxDecoration(
              color: AppColors.backgroundDarkSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: isTablet ? 36 : 24,
            ),
          ),
          SizedBox(height: isTablet?8:4),

          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet?16:12,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
