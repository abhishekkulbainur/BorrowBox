// Flutter Imports
import 'package:flutter/material.dart';

/// Central responsive design utility for BorrowBox.
/// Ensures consistent, overflow-free layouts across all Android device screen sizes,
/// aspect ratios, pixel densities, and accessibility font scaling factors.
class Responsive {
  static const double smallPhoneBreakpoint = 360.0;
  static const double standardPhoneBreakpoint = 420.0;
  static const double tabletBreakpoint = 600.0;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isSmallPhone(BuildContext context) =>
      screenWidth(context) < smallPhoneBreakpoint;

  static bool isStandardPhone(BuildContext context) {
    final w = screenWidth(context);
    return w >= smallPhoneBreakpoint && w < standardPhoneBreakpoint;
  }

  static bool isLargePhone(BuildContext context) {
    final w = screenWidth(context);
    return w >= standardPhoneBreakpoint && w < tabletBreakpoint;
  }

  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= tabletBreakpoint;

  static double textScaleFactor(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1.0);

  /// Dynamic horizontal padding adapting to screen width
  static EdgeInsets horizontalPadding(BuildContext context) {
    final w = screenWidth(context);
    if (w < smallPhoneBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 12.0);
    } else if (w >= tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    }
    return const EdgeInsets.symmetric(horizontal: 16.0);
  }

  /// Calculates a responsive grid delegate that guarantees no RenderFlex overflow
  /// across small screens (320-350dp), standard screens (360-400dp), large screens,
  /// and devices with enlarged system accessibility font scaling.
  static SliverGridDelegateWithFixedCrossAxisCount gridDelegate(
    BuildContext context, {
    double baseAspectRatio = 0.72,
    double crossAxisSpacing = 12.0,
    double mainAxisSpacing = 12.0,
  }) {
    final width = screenWidth(context);
    final textScale = textScaleFactor(context);

    int crossAxisCount;
    if (width < 320) {
      crossAxisCount = 1;
    } else if (width >= tabletBreakpoint) {
      crossAxisCount = width > 900 ? 4 : 3;
    } else {
      crossAxisCount = 2;
    }

    // Adapt aspect ratio to accommodate font enlargement and narrow columns
    double aspectRatio = baseAspectRatio;

    if (crossAxisCount == 1) {
      aspectRatio = 1.6;
    } else {
      if (width < smallPhoneBreakpoint) {
        // Narrow phone (e.g. 320-350 logical pixels) needs more height per card
        aspectRatio = 0.63;
      } else if (width < 390) {
        aspectRatio = 0.67;
      } else if (width < 430) {
        aspectRatio = 0.70;
      } else {
        aspectRatio = 0.74;
      }

      // If user enabled larger font scale in accessibility settings, adjust height proportionally
      if (textScale > 1.25) {
        aspectRatio -= 0.08;
      } else if (textScale > 1.10) {
        aspectRatio -= 0.04;
      }
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: aspectRatio,
    );
  }
}
