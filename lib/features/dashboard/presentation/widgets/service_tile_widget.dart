import 'package:flutter/material.dart';
import 'package:payhive/app/theme/colors.dart';
import 'package:payhive/core/utils/responsive_layout.dart';

class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tileHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : (isTablet ? 82.0 : 66.0);
            final isCompact = tileHeight < (isTablet ? 74 : 60);

            final iconSize = isTablet
                ? (isCompact ? 24.0 : 30.0)
                : (isCompact ? 19.0 : 22.0);
            final labelFontSize = isTablet
                ? (isCompact ? 16.0 : 18.0)
                : (isCompact ? 13.0 : 14.0);
            final horizontalPadding = isTablet ? 14.0 : 10.0;
            final verticalPadding = isTablet ? 10.0 : 8.0;
            final contentGap = isTablet ? 10.0 : 8.0;

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(icon, size: iconSize, color: AppColors.primary),
                  SizedBox(width: contentGap),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: labelFontSize,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
