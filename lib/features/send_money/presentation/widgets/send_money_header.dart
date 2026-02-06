import 'package:flutter/material.dart';
import 'package:payhive/app/routes/app_routes.dart';

class SendMoneyHeader extends StatelessWidget {
  const SendMoneyHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        IconButton(
          onPressed: () => AppRoutes.pop(context),
          icon: const Icon(Icons.arrow_back),
          color: colorScheme.onSurface,
          iconSize: isTablet ? 32 : 22,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontSize: isTablet ? 24 : 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(width: isTablet ? 40 : 36),
      ],
    );
  }
}
