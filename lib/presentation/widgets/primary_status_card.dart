import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../models/primary_status_model.dart';
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
        final model = PrimaryStatusModel.build(
          isOffline: connectivityProvider.isOffline,
          alertErrorMessage: alertsProvider.errorMessage,
          alertState: alertsProvider.alertState,
          alertStartTime: alertsProvider.alertStartTime,
        );

        final displayColor = model.visual == PrimaryStatusVisual.normal
            ? AppTheme.colorForAlertState(model.alertState)
            : AppTheme.offlineColor;
        final displayBg = model.visual == PrimaryStatusVisual.normal
            ? AppTheme.alertBackgroundFor(context, model.alertState)
            : AppTheme.offlineBackground;

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
              Text(model.icon, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                model.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: displayColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (model.showInstruction) ...[
                const SizedBox(height: 8),
                Text(
                  model.instruction!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (model.showElapsedTimer) ...[
                const SizedBox(height: 16),
                ElapsedTimeText(
                  startTime: model.elapsedStartTime!,
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
