import 'package:flutter/material.dart';
import 'package:payhive/theme/colors.dart';

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.greyText;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: isTablet ? 84 : 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isTablet ? 36 : 22, color: color),
            SizedBox(height: isTablet ? 4 : 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 18 : 11,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
