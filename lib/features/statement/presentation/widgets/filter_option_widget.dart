import 'package:flutter/material.dart';
import 'package:payhive/core/utils/responsive_layout.dart';
import 'package:payhive/features/statement/presentation/state/statement_state.dart';

class FilterOption extends StatelessWidget {
  const FilterOption({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
  });

  final StatementDirectionFilter value;
  final StatementDirectionFilter groupValue;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return RadioListTile<StatementDirectionFilter>(
      value: value,
      groupValue: groupValue,
      dense: !isTablet,
      contentPadding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 0),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: isTablet ? 18 : 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      visualDensity: isTablet ? const VisualDensity(vertical: 0.5) : null,
      onChanged: (next) {
        if (next == null) return;
        Navigator.pop(context, next);
      },
    );
  }
}
