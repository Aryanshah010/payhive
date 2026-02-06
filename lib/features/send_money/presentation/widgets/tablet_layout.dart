import 'package:flutter/material.dart';

class TabletLayout extends StatelessWidget {
  const TabletLayout({
    super.key,
    required this.formContent,
    required this.keypadSection,
    required this.horizontalPadding,
    required this.bottomPadding,
  });

  /// width used for keypad on wide screens
  static const double tabletKeypadWidth = 320;

  final Widget formContent;
  final Widget keypadSection;
  final double horizontalPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    // The overall center + maxWidth keeps layout from stretching too wide.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: scrollable form (takes remaining width)
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: formContent,
                ),
              ),

              const SizedBox(width: 32),

              // Right: fixed-width keypad column. keypadSection is centered vertically.
              SizedBox(
                width: tabletKeypadWidth,
                // Make keypad scrollable vertically if necessary and center it
                child: SingleChildScrollView(
                  child: SizedBox(
                    // Give it full height so Center can align vertically inside viewport.
                    height:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.vertical -
                        40, // small guard
                    child: Center(child: keypadSection),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
