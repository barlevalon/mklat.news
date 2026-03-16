import 'package:flutter/material.dart';
import '../domain/alert_state.dart';

/// App-level theme definitions for light and dark modes.
class AppTheme {
  // Seed color for the app's color scheme
  static const Color _seedColor = Colors.blue;

  /// Light theme configuration.
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
  );

  /// Dark theme configuration.
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
  );

  // Alert state colors
  static Color colorForAlertState(AlertState state) {
    switch (state) {
      case AlertState.allClear:
        return const Color(0xFF4CAF50); // Green
      case AlertState.alertImminent:
        return const Color(0xFFFFC107); // Amber
      case AlertState.redAlert:
        return const Color(0xFFF44336); // Red
      case AlertState.waitingClear:
        return const Color(0xFFFF9800); // Orange
      case AlertState.justCleared:
        return const Color(0xFF66BB6A); // Light Green
    }
  }

  // Background color for status card (lighter shade)
  static Color backgroundForAlertState(AlertState state) {
    switch (state) {
      case AlertState.allClear:
        return const Color(0xFFE8F5E9);
      case AlertState.alertImminent:
        return const Color(0xFFFFF8E1);
      case AlertState.redAlert:
        return const Color(0xFFFFEBEE);
      case AlertState.waitingClear:
        return const Color(0xFFFFF3E0);
      case AlertState.justCleared:
        return const Color(0xFFE8F5E9);
    }
  }

  // Background color for status card with automatic theme awareness
  static Color alertBackgroundFor(BuildContext context, AlertState state) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      switch (state) {
        case AlertState.allClear:
          return const Color(0xFF1B5E20); // Dark green
        case AlertState.alertImminent:
          return const Color(0xFF6D4C00); // Dark amber
        case AlertState.redAlert:
          return const Color(0xFFB71C1C); // Dark red
        case AlertState.waitingClear:
          return const Color(0xFF6D4C00); // Dark orange
        case AlertState.justCleared:
          return const Color(0xFF1B5E20); // Dark green
      }
    }
    return backgroundForAlertState(state);
  }

  // Secondary location status dot colors
  static const Color dotGreen = Color(0xFF4CAF50);
  static const Color dotRed = Color(0xFFF44336);
  static const Color dotYellow = Color(0xFFFFC107);

  // Offline state colors
  static const Color offlineColor = Color(0xFF9E9E9E); // Grey
  static const Color offlineBackground = Color(0xFFF5F5F5); // Light grey
  static const Color dotGrey = Color(0xFF9E9E9E); // Grey dot for offline

  // News source colors
  static Color colorForNewsSource(String sourceName) {
    switch (sourceName) {
      case 'Ynet':
        return const Color(0xFFE53935);
      case 'Maariv':
        return const Color(0xFF1565C0);
      case 'Mako':
        return const Color(0xFF00897B); // Mako teal
      case 'Haaretz':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF757575);
    }
  }

  /// Error indicator color that adapts to theme brightness.
  /// Returns orange.shade600 in light mode (preserves existing look),
  /// and orange.shade300 in dark mode (better contrast on dark backgrounds).
  static Color errorIndicatorColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.orange.shade300
        : Colors.orange.shade600;
  }

  /// Muted text color that adapts to theme brightness.
  /// Used for secondary/supporting text like section headers and helper text.
  /// Returns black54 in light mode, and a light muted color in dark mode.
  static Color mutedTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(153) // ~60% opacity white
        : Colors.black54;
  }

  /// Subtle text color for less important helper text.
  /// Returns black38 in light mode, and a subtler light color in dark mode.
  static Color subtleTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(102) // ~40% opacity white
        : Colors.black38;
  }

  /// Divider color that adapts to theme brightness.
  static Color dividerColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
  }

  /// Placeholder/supporting color for empty states, loading, and offline indicators.
  /// Used for icons and text in placeholder states (no locations, offline, loading, no alerts).
  /// Returns grey.shade600 in light mode, and grey.shade400 in dark mode.
  static Color placeholderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade400
        : Colors.grey.shade600;
  }

  /// Placeholder icon color for empty states.
  /// Returns grey.shade400 in light mode, and grey.shade600 in dark mode.
  static Color placeholderIconColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade600
        : Colors.grey.shade400;
  }

  /// Surface color for read-only fields (like the OREF name display).
  /// Light: grey.shade50 (subtle light background)
  /// Dark: grey.shade800 (dark surface that blends with dark theme)
  static Color readOnlySurfaceColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade50;
  }

  /// Border color for read-only fields.
  /// Light: grey.shade300, Dark: grey.shade600
  static Color readOnlyBorderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade600
        : Colors.grey.shade300;
  }

  /// Text color for read-only field content.
  /// Light: grey.shade700, Dark: grey.shade300
  static Color readOnlyTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade300
        : Colors.grey.shade700;
  }

  // Nationwide summary colors - theme aware orange warning palette

  /// Background color for nationwide summary alert banner.
  /// Light: orange.shade50, Dark: dark orange (0xFF6D4C00)
  static Color nationwideSummaryBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF6D4C00) // Dark amber/orange
        : Colors.orange.shade50;
  }

  /// Border color for nationwide summary alert banner.
  /// Light: orange.shade200, Dark: darker orange (0xFF8D6E63)
  static Color nationwideSummaryBorder(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF8D6E63) // Brown-orange for dark mode
        : Colors.orange.shade200;
  }

  /// Icon color for nationwide summary warning icon.
  /// Light: orange.shade700, Dark: orange.shade300
  static Color nationwideSummaryIcon(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.orange.shade300
        : Colors.orange.shade700;
  }

  /// Text color for nationwide summary message.
  /// Light: orange.shade900, Dark: orange.shade100
  static Color nationwideSummaryText(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.orange.shade100
        : Colors.orange.shade900;
  }
}
