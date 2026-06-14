import 'package:flutter/material.dart';
import '../data/models/news_item.dart';
import '../domain/alert_state.dart';

/// App-level theme definitions for light and dark modes.
class AppTheme {
  static const Color brandBlue = Color(0xFF2F5F8F);
  static const Color appBackground = Color(0xFFF5F7FB);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color statusGreen = Color(0xFF2E7D57);
  static const Color statusAmber = Color(0xFFC47A00);
  static const Color statusRed = Color(0xFFC62828);
  static const Color connectivitySlate = Color(0xFF60717D);
  static const Color statusGreenTint = Color(0xFFEAF6EF);
  static const Color statusAmberTint = Color(0xFFFFF5DF);
  static const Color statusRedTint = Color(0xFFFFE9E9);
  static const Color connectivityTint = Color(0xFFE8EEF2);
  static const Color mutedText = Color(0xFF6B7780);
  static const Color hairline = Color(0xFFD7DEE5);

  /// Light theme configuration.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(seedColor: brandBlue);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: appBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: appBackground,
        foregroundColor: Color(0xFF18212A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: brandBlue, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// Dark theme configuration.
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.dark,
    ),
  );

  // Alert state colors
  static Color colorForAlertState(AlertState state) {
    switch (state) {
      case AlertState.allClear:
        return statusGreen;
      case AlertState.alertImminent:
        return statusAmber;
      case AlertState.redAlert:
        return statusRed;
      case AlertState.waitingClear:
        return const Color(0xFFE08A00);
      case AlertState.justCleared:
        return statusGreen;
    }
  }

  // Background color for status card (lighter shade)
  static Color backgroundForAlertState(AlertState state) {
    switch (state) {
      case AlertState.allClear:
        return statusGreenTint;
      case AlertState.alertImminent:
        return statusAmberTint;
      case AlertState.redAlert:
        return statusRedTint;
      case AlertState.waitingClear:
        return const Color(0xFFFFF1DE);
      case AlertState.justCleared:
        return statusGreenTint;
    }
  }

  // Background color for status card with automatic theme awareness
  static Color alertBackgroundFor(BuildContext context, AlertState state) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      switch (state) {
        case AlertState.allClear:
          return const Color(0xFF123A2A);
        case AlertState.alertImminent:
          return const Color(0xFF4A3208);
        case AlertState.redAlert:
          return const Color(0xFF4A1515);
        case AlertState.waitingClear:
          return const Color(0xFF4A3208);
        case AlertState.justCleared:
          return const Color(0xFF123A2A);
      }
    }
    return backgroundForAlertState(state);
  }

  static Color statusCardSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF162029)
        : cardSurface;
  }

  static Color offlineStatusBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF263238)
        : connectivityTint;
  }

  static Color neutralStatusColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB0BEC5)
        : connectivitySlate;
  }

  static Color offlineBannerBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF263238)
        : connectivityTint;
  }

  static Color offlineBannerForeground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFECEFF1)
        : const Color(0xFF455A64);
  }

  // Secondary location status dot colors
  static const Color dotGreen = statusGreen;
  static const Color dotRed = statusRed;
  static const Color dotYellow = Color(0xFFFFC107);

  // Offline state colors
  static const Color offlineColor = connectivitySlate;
  static const Color offlineBackground = connectivityTint;
  static const Color dotGrey = connectivitySlate;

  // News source colors
  static Color colorForNewsSource(NewsSource source) {
    switch (source) {
      case NewsSource.ynet:
        return const Color(0xFFE53935);
      case NewsSource.maariv:
        return const Color(0xFF1565C0);
      case NewsSource.haaretz:
        return const Color(0xFF2E7D32);
    }
  }

  /// Error indicator color that adapts to theme brightness.
  static Color errorIndicatorColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.orange.shade300 : statusAmber;
  }

  /// Muted text color that adapts to theme brightness.
  static Color mutedTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(153) // ~60% opacity white
        : mutedText;
  }

  /// Subtle text color for less important helper text.
  static Color subtleTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withAlpha(102) // ~40% opacity white
        : Colors.black38;
  }

  /// Divider color that adapts to theme brightness.
  static Color dividerColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.grey.shade700 : hairline;
  }

  /// Placeholder/supporting color for empty states, loading, and offline indicators.
  static Color placeholderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.grey.shade400 : mutedText;
  }

  /// Placeholder icon color for empty states.
  static Color placeholderIconColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade600
        : connectivitySlate.withAlpha(153);
  }

  /// Surface color for read-only fields (like the OREF name display).
  static Color readOnlySurfaceColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade50;
  }

  /// Border color for read-only fields.
  static Color readOnlyBorderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.grey.shade600 : hairline;
  }

  /// Text color for read-only field content.
  static Color readOnlyTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey.shade300
        : Colors.grey.shade700;
  }

  // Nationwide summary colors - theme aware orange warning palette

  /// Background color for nationwide summary alert banner.
  static Color nationwideSummaryBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF6D4C00)
        : Colors.orange.shade50;
  }

  /// Border color for nationwide summary alert banner.
  static Color nationwideSummaryBorder(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF8D6E63)
        : Colors.orange.shade200;
  }

  /// Icon color for nationwide summary warning icon.
  static Color nationwideSummaryIcon(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.orange.shade300
        : Colors.orange.shade700;
  }

  /// Text color for nationwide summary message.
  static Color nationwideSummaryText(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.orange.shade100
        : Colors.orange.shade900;
  }
}
