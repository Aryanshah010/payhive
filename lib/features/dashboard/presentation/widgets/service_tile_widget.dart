import 'package:flutter/material.dart';
import 'package:payhive/app/theme/colors.dart';

class ServiceTile extends StatelessWidget {
  const ServiceTile({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    final double horizontalPadding = isTablet ? 24 : 12;
    final double verticalPadding = isTablet ? 24 : 12;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(icon, size: isTablet ? 36 : 24, color: AppColors.primary),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 24 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
