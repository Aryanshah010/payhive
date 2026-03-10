import 'package:flutter/material.dart';

class ResponsiveLayout {
  const ResponsiveLayout._();

  static const double tabletBreakpoint = 600;
  static const double defaultTabletMaxWidth = 920;
  static const double defaultSheetMaxWidth = 620;
  static const double defaultDialogMaxWidth = 520;

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= tabletBreakpoint;
  }

  static double horizontalPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
  }) {
    return isTablet(context) ? tablet : mobile;
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double mobileHorizontal = 16,
    double tabletHorizontal = 24,
    double top = 12,
    double bottom = 24,
  }) {
    final horizontal = horizontalPadding(
      context,
      mobile: mobileHorizontal,
      tablet: tabletHorizontal,
    );
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  static Widget constrainedContent(
    BuildContext context, {
    required Widget child,
    double tabletMaxWidth = defaultTabletMaxWidth,
  }) {
    final maxWidth = isTablet(context) ? tabletMaxWidth : double.infinity;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  static BoxConstraints bottomSheetConstraints(
    BuildContext context, {
    double tabletMaxWidth = defaultSheetMaxWidth,
  }) {
    return BoxConstraints(
      maxWidth: isTablet(context) ? tabletMaxWidth : double.infinity,
    );
  }

  static EdgeInsets bottomSheetPadding(
    BuildContext context, {
    double mobileHorizontal = 20,
    double tabletHorizontal = 28,
    double top = 16,
    double bottom = 20,
  }) {
    final horizontal = horizontalPadding(
      context,
      mobile: mobileHorizontal,
      tablet: tabletHorizontal,
    );

    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      MediaQuery.viewInsetsOf(context).bottom + bottom,
    );
  }

  static BoxConstraints dialogConstraints(
    BuildContext context, {
    double tabletMaxWidth = defaultDialogMaxWidth,
  }) {
    return BoxConstraints(
      maxWidth: isTablet(context) ? tabletMaxWidth : double.infinity,
    );
  }

  static EdgeInsets dialogInsetPadding(
    BuildContext context, {
    double mobileHorizontal = 24,
    double tabletHorizontal = 140,
    double vertical = 24,
  }) {
    final horizontal = horizontalPadding(
      context,
      mobile: mobileHorizontal,
      tablet: tabletHorizontal,
    );
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  static double adaptiveFont(
    BuildContext context, {
    required double mobile,
    required double tablet,
  }) {
    return isTablet(context) ? tablet : mobile;
  }
}
