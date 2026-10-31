// Flutter Imports
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

// Package Imports
import "package:flex_color_scheme/flex_color_scheme.dart";

final light = FlexThemeData.light(
  scheme: FlexScheme.deepBlue,
  subThemesData: const FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    useM2StyleDividerInM3: false,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    alignedDropdown: true,
    navigationRailUseIndicator: true,
    navigationBarElevation: 0,
    navigationBarMutedUnselectedIcon: true,
    bottomSheetElevation: 0,
    cardElevation: 0,
  ),
  visualDensity: VisualDensity.standard,
  cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
).copyWith(
  appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 0),
  cardTheme: const CardThemeData(elevation: 0),
  dividerTheme: const DividerThemeData(
    space: 1,
    thickness: 1,
  ),
);

final dark = FlexThemeData.dark(
  scheme: FlexScheme.deepBlue,
  subThemesData: const FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    blendOnColors: true,
    useM2StyleDividerInM3: false,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    alignedDropdown: true,
    navigationRailUseIndicator: true,
    navigationBarElevation: 0,
    navigationBarMutedUnselectedIcon: true,
    bottomSheetElevation: 0,
    cardElevation: 0,
  ),
  visualDensity: VisualDensity.standard,
  cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
).copyWith(
  appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 0),
  cardTheme: const CardThemeData(elevation: 0),
  dividerTheme: const DividerThemeData(
    space: 1,
    thickness: 1,
  ),
);
