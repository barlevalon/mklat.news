import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../domain/alert_state.dart';
import '../providers/alerts_provider.dart';
import '../providers/connectivity_provider.dart';
import 'location_selector_button.dart';

DateTime _defaultNow() => DateTime.now();

class PrimaryStatusCard extends StatelessWidget {
  final DateTime Function() now;

  const PrimaryStatusCard({super.key, this.now = _defaultNow});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AlertsProvider, ConnectivityProvider>(
      builder: (context, alertsProvider, connectivityProvider, child) {
        final isOffline = connectivityProvider.isOffline;
        final hasAlertError = alertsProvider.errorMessage != null;
        final state = alertsProvider.alertState;

        final startTime = alertsProvider.alertStartTime;

        // Determine display values based on connectivity and data freshness.
        final displayColor = isOffline || hasAlertError
            ? AppTheme.offlineColor
            : AppTheme.colorForAlertState(state);
        final displayBg = isOffline || hasAlertError
            ? AppTheme.offlineBackground
            : AppTheme.alertBackgroundFor(context, state);
        final displayIcon = isOffline
            ? '📡'
            : hasAlertError
            ? '⚠️'
            : state.icon;
        final displayTitle = isOffline
            ? 'אין חיבור'
            : hasAlertError
            ? 'מצב לא ידוע'
            : state.hebrewTitle;
        final instruction = hasAlertError
            ? 'לא ניתן לאמת התרעות כרגע'
            : state.instruction;

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
              if (!isOffline && instruction != null) ...[
                const SizedBox(height: 8),
                Text(
                  instruction,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              // Only show timer when online
              if (!isOffline &&
                  !hasAlertError &&
                  state.showElapsedTimer &&
                  startTime != null) ...[
                const SizedBox(height: 16),
                ElapsedTimeText(
                  startTime: startTime,
                  color: displayColor,
                  now: now,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ElapsedTimeText extends StatefulWidget {
  final DateTime startTime;
  final Color color;
  final DateTime Function() now;

  const ElapsedTimeText({
    super.key,
    required this.startTime,
    required this.color,
    this.now = _defaultNow,
  });

  @override
  State<ElapsedTimeText> createState() => _ElapsedTimeTextState();
}

class _ElapsedTimeTextState extends State<ElapsedTimeText> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatElapsed() {
    final elapsed = widget.now().difference(widget.startTime);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatElapsed(),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: widget.color,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
      ),
    );
  }
}
