import 'package:flutter/material.dart';

class PrimaryButtonWidget extends StatelessWidget {
  const PrimaryButtonWidget({
    super.key,
    required this.onPressed,
    required this.text,
  });

  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= 600;

        final double buttonHeight = isTablet ? 62 : 52;
        final double fontSize = isTablet ? 20 : 16;
        final double horizontalPadding = isTablet ? 40 : 20;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 107, 0),
              padding: EdgeInsets.symmetric(
                vertical: buttonHeight / 2 - 12,
                horizontal: horizontalPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              text,
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
