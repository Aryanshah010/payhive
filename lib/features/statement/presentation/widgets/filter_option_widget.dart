import 'package:flutter/material.dart';
import 'package:payhive/features/statement/presentation/state/statement_state.dart';

class FilterOption extends StatelessWidget {
  const FilterOption({
    super.key,
    required this.context,
    required this.value,
    required this.groupValue,
    required this.label,
  });

  final BuildContext context;
  final StatementDirectionFilter value;
  final StatementDirectionFilter groupValue;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<StatementDirectionFilter>(
      value: value,
      groupValue: groupValue,
      title: Text(label),
      onChanged: (next) {
        if (next == null) return;
        Navigator.pop(context, next);
      },
    );
  }
}
