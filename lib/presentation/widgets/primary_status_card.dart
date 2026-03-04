import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../domain/alert_state.dart';
import '../providers/alerts_provider.dart';
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
    if (state.showElapsedTimer || state.showTimeSince) {
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

  String _formatTimeSince(DateTime? clearanceTime) {
    if (clearanceTime == null) return '';
    final diff = DateTime.now().difference(clearanceTime);
    if (diff.inMinutes < 1) return 'עכשיו';
    return 'לפני ${diff.inMinutes} דקות';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertsProvider>(
      builder: (context, alertsProvider, child) {
        final state = alertsProvider.alertState;
        _ensureTimer(state);
        final startTime = alertsProvider.alertStartTime;
        final clearanceTime = alertsProvider.clearanceTime;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.backgroundForAlertState(state),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.colorForAlertState(state).withAlpha(77),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LocationSelectorButton(),
              const SizedBox(height: 24),
              Text(state.icon, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                state.hebrewTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.colorForAlertState(state),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.instruction != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.instruction!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ],
              if (state.showElapsedTimer && startTime != null) ...[
                const SizedBox(height: 16),
                Text(
                  _formatElapsed(startTime),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.colorForAlertState(state),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              if (state.showTimeSince && clearanceTime != null) ...[
                const SizedBox(height: 16),
                Text(
                  _formatTimeSince(clearanceTime),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
