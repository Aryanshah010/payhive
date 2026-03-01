import 'package:flutter/material.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
import 'package:payhive/core/utils/statement_status_mapper.dart';

class BuildStatusHeader extends StatelessWidget {
  const BuildStatusHeader({
    super.key,
    required this.context,
    required this.statusUi,
  });

  final BuildContext context;
  final StatementStatusUi statusUi;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusBg = statusUi.color.withOpacity(0.16);
    final isTablet = ResponsiveLayout.isTablet(context);
    final scale = isTablet ? 1.12 : 1.0;

    return Column(
      children: [
        Container(
          width: isTablet ? 92 : 82,
          height: isTablet ? 92 : 82,
          decoration: BoxDecoration(shape: BoxShape.circle, color: statusBg),
          child: Icon(
            statusUi.icon,
            color: statusUi.color,
            size: isTablet ? 50 : 44,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Transaction Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 24 * scale,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 14,
            vertical: isTablet ? 8 : 7,
          ),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: statusUi.color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusUi.icon,
                color: statusUi.color,
                size: isTablet ? 18 : 16,
              ),
              const SizedBox(width: 6),
              Text(
                statusUi.label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 14 : 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
