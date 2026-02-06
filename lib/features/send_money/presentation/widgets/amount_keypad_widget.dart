import 'package:flutter/material.dart';
class AmountKeypadWidget extends StatelessWidget {
  const AmountKeypadWidget({super.key, this.onKeyTap, this.onBackspace});

  final ValueChanged<String>? onKeyTap;
  final VoidCallback? onBackspace;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final colorScheme = Theme.of(context).colorScheme;

    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '.',
      '0',
      'back',
    ];

    final double keySize = isTablet ? 80 : 60;
    final double fontSize = isTablet ? 22 : 16;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: isTablet ? 18 : 12,
        crossAxisSpacing: isTablet ? 18 : 12,
        children: keys.map((key) {
          final bool isBack = key == 'back';
          return InkWell(
            onTap: isBack
                ? onBackspace
                : onKeyTap != null
                    ? () => onKeyTap!(key)
                    : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: keySize,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: isBack
                    ? Icon(
                        Icons.backspace_outlined,
                        color: colorScheme.onPrimary,
                        size: isTablet ? 26 : 20,
                      )
                    : Text(
                        key,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
