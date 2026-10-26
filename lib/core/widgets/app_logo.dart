// Flutter Imports
import 'package:flutter/material.dart';

enum LogoVariant {
  full, // Full logo with box + BorrowBox + Share More. Own Less.
  iconOnly, // Just the box icon with rotating arrows
}

class AppLogo extends StatelessWidget {
  final double? size;
  final double? width;
  final double? height;
  final LogoVariant variant;
  final double borderRadius;
  final BoxBorder? border;

  const AppLogo({
    super.key,
    this.size,
    this.width,
    this.height,
    this.variant = LogoVariant.full,
    this.borderRadius = 16.0,
    this.border,
  });

  const AppLogo.icon({
    super.key,
    this.size = 40.0,
    this.width,
    this.height,
    this.borderRadius = 10.0,
    this.border,
  }) : variant = LogoVariant.iconOnly;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;

    final assetPath = variant == LogoVariant.iconOnly
        ? 'assets/images/app_logo_icon.png'
        : 'assets/images/app_logo.png';

    Widget imageWidget = Image.asset(
      assetPath,
      width: effectiveWidth,
      height: effectiveHeight,
      fit: BoxFit.contain,
    );

    if (borderRadius > 0) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    if (border != null) {
      imageWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
