import 'package:flutter/material.dart';
import 'package:payhive/app/routes/app_routes.dart';

class SendMoneyHeader extends StatelessWidget {
  const SendMoneyHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Row(
      children: [
        IconButton(
          onPressed: () => AppRoutes.pop(context),
          icon: const Icon(Icons.arrow_back),
          iconSize: isTablet ? 32 : 22,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 24 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: isTablet ? 40 : 36),
      ],
    );
  }
}
