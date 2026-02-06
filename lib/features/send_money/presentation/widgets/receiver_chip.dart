import 'package:flutter/material.dart';
import 'package:payhive/app/theme/colors.dart';

class ReceiverChip extends StatelessWidget {
  const ReceiverChip({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 14,
        vertical: isTablet ? 10 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: isTablet ? 16 : 12,
          fontWeight: FontWeight.w500,
          color: AppColors.darkText,
        ),
      ),
    );
  }
}
