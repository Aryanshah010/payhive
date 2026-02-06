import 'package:flutter/material.dart';
import 'package:payhive/app/theme/colors.dart';

class AmountKeypadWidget extends StatelessWidget {
  const AmountKeypadWidget({
    super.key,
    this.onKeyTap,
    this.onBackspace,
    this.maxWidth,
  });

  final ValueChanged<String>? onKeyTap;
  final VoidCallback? onBackspace;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final colorScheme = Theme.of(context).colorScheme;

    final keys = [
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'back',
    ];

    final double spacing = isTablet ? 30 : 14;
    const int crossAxisCount = 3;
    final double capWidth = maxWidth ?? (isTablet ? 480 : width.clamp(0, 260));
    final double availableWidth = capWidth - spacing * (crossAxisCount + 1);
    final double keySize = (availableWidth / crossAxisCount)
        .clamp(44.0, isTablet ? 85.0 : 52.0);
    final double fontSize = keySize * 0.32;

    Widget grid = GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: 1,
      children: keys.map((key) {
        final bool isBack = key == 'back';
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isBack
                ? onBackspace
                : onKeyTap != null ? () => onKeyTap!(key) : null,
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              ),
              child: Center(
                child: isBack
                    ? Icon(
                        Icons.backspace_outlined,
                        color: colorScheme.onPrimary,
                        size: fontSize * 1.25,
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
          ),
        );
      }).toList(),
    );

    final bool constrainWidth = width > capWidth + 24;
    if (constrainWidth) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: capWidth),
          child: grid,
        ),
      );
    }
    return grid;
  }
}
