import 'package:flutter/material.dart';
import '../domain/alert_state.dart';

class AppTheme {
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

  // Secondary location status dot colors
  static const Color dotGreen = Color(0xFF4CAF50);
  static const Color dotRed = Color(0xFFF44336);
  static const Color dotYellow = Color(0xFFFFC107);

  // News source colors
  static Color colorForNewsSource(String sourceName) {
    switch (sourceName) {
      case 'Ynet':
        return const Color(0xFFE53935);
      case 'Maariv':
        return const Color(0xFF1565C0);
      case 'Walla':
        return const Color(0xFFE65100);
      case 'Haaretz':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF757575);
    }
  }
}
