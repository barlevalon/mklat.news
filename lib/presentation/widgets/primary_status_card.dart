import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../domain/alert_state.dart';
import '../providers/alerts_provider.dart';
import '../providers/connectivity_provider.dart';
import 'location_selector_button.dart';

class PrimaryStatusCard extends StatefulWidget {
  const PrimaryStatusCard({super.key});

  @override
  State<PrimaryStatusCard> createState() => _PrimaryStatusCardState();
}

class _PrimaryStatusCardState extends State<PrimaryStatusCard> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureTimer(AlertState state) {
    if (state.showElapsedTimer) {
      if (_timer == null || !_timer!.isActive) {
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
      }
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  String _formatElapsed(DateTime startTime) {
    final elapsed = DateTime.now().difference(startTime);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AlertsProvider, ConnectivityProvider>(
      builder: (context, alertsProvider, connectivityProvider, child) {
        final isOffline = connectivityProvider.isOffline;
        final state = alertsProvider.alertState;

        // Only run timer when online
        if (!isOffline) {
          _ensureTimer(state);
        } else {
          _timer?.cancel();
          _timer = null;
        }

        final startTime = alertsProvider.alertStartTime;

        // Determine display values based on connectivity
        final displayColor = isOffline
            ? AppTheme.offlineColor
            : AppTheme.colorForAlertState(state);
        final displayBg = isOffline
            ? AppTheme.offlineBackground
            : AppTheme.backgroundForAlertState(state);
        final displayIcon = isOffline ? '📡' : state.icon;
        final displayTitle = isOffline ? 'אין חיבור' : state.hebrewTitle;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: displayBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: displayColor.withAlpha(77), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LocationSelectorButton(),
              const SizedBox(height: 24),
              Text(displayIcon, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                displayTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: displayColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Only show instruction when online
              if (!isOffline && state.instruction != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.instruction!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ],
              // Only show timer when online
              if (!isOffline &&
                  state.showElapsedTimer &&
                  startTime != null) ...[
                const SizedBox(height: 16),
                Text(
                  _formatElapsed(startTime),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: displayColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
