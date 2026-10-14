import 'package:flutter/material.dart';

/// Palette used across every devtool surface.
abstract final class DevtoolColors {
  static const primary = Color(0xFF6366F1);
  static const background = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const border = Color(0xFF334155);
  static const hover = Color(0xFF293548);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFF43F5E);
  static const info = Color(0xFF38BDF8);
}

/// Spacing and radius constants shared by the devtool widgets.
abstract final class DevtoolSpacing {
  static const double gap = 12;
  static const double padding = 16;
  static const double radius = 12;
}

/// Theme applied to the devtool panel.
abstract final class DevtoolTheme {
  static const fontFamily = 'packages/another_flutter_devtool/Inter';

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: DevtoolColors.primary,
      onPrimary: Colors.white,
      secondary: DevtoolColors.primary,
      onSecondary: Colors.white,
      surface: DevtoolColors.surface,
      onSurface: DevtoolColors.textPrimary,
      error: DevtoolColors.error,
      onError: Colors.white,
      outline: DevtoolColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DevtoolColors.background,
      canvasColor: DevtoolColors.background,
      cardColor: DevtoolColors.surface,
      dividerColor: DevtoolColors.border,
      dividerTheme: const DividerThemeData(color: DevtoolColors.border, thickness: 1, space: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: DevtoolColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: DevtoolColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: DevtoolColors.textPrimary,
        ),
      ),
      iconTheme: const IconThemeData(color: DevtoolColors.textSecondary),
      textTheme: _textTheme,
      dialogTheme: DialogThemeData(
        backgroundColor: DevtoolColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DevtoolSpacing.radius),
          side: const BorderSide(color: DevtoolColors.border),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : DevtoolColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? DevtoolColors.primary : DevtoolColors.hover,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(DevtoolColors.border),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static const _textTheme = TextTheme(
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DevtoolColors.textPrimary),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DevtoolColors.textPrimary),
    bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: DevtoolColors.textPrimary),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: DevtoolColors.textSecondary),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: DevtoolColors.textSecondary),
  );
}
