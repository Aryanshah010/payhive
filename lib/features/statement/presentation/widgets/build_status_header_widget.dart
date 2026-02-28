import 'package:flutter/material.dart';
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

    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(shape: BoxShape.circle, color: statusBg),
          child: Icon(statusUi.icon, color: statusUi.color, size: 44),
        ),
        const SizedBox(height: 10),
        Text(
          'Transaction Details',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: statusUi.color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusUi.icon, color: statusUi.color, size: 16),
              const SizedBox(width: 6),
              Text(
                statusUi.label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
