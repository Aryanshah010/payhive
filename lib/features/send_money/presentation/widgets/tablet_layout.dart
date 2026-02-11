import 'package:flutter/material.dart';

class TabletLayout extends StatelessWidget {
  const TabletLayout({
    super.key,
    required this.formContent,
    required this.keypadSection,
    required this.horizontalPadding,
    required this.bottomPadding,
  });

  static const double tabletKeypadWidth = 420;

  final Widget formContent;
  final Widget keypadSection;
  final double horizontalPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: formContent,
                ),
              ),

              const SizedBox(width: 32),

              SizedBox(
                width: tabletKeypadWidth,
                child: SingleChildScrollView(
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.vertical -
                        40, 
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
