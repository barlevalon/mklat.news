import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../domain/alert_state.dart';
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

        final colors = _StatusColors.from(context, model);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: AppTheme.statusCardSurface(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.dividerColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: colors.background)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LocationSelectorButton(),
                      const SizedBox(height: 28),
                      _StatusIcon(model: model, color: colors.foreground),
                      const SizedBox(height: 18),
                      Text(
                        model.title,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: colors.foreground,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      if (model.showInstruction) ...[
                        const SizedBox(height: 10),
                        Text(
                          model.instruction!,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(205),
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (model.showElapsedTimer) ...[
                        const SizedBox(height: 18),
                        ElapsedTimeText(
                          startTime: model.elapsedStartTime!,
                          color: colors.foreground,
                          now: now,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusColors {
  final Color foreground;
  final Color background;

  const _StatusColors({required this.foreground, required this.background});

  factory _StatusColors.from(BuildContext context, PrimaryStatusModel model) {
    switch (model.visual) {
      case PrimaryStatusVisual.normal:
        return _StatusColors(
          foreground: AppTheme.colorForAlertState(model.alertState),
          background: AppTheme.alertBackgroundFor(context, model.alertState),
        );
      case PrimaryStatusVisual.error:
        return _StatusColors(
          foreground: AppTheme.statusAmber,
          background: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF4A3208)
              : AppTheme.statusAmberTint,
        );
      case PrimaryStatusVisual.offline:
        return _StatusColors(
          foreground: AppTheme.neutralStatusColor(context),
          background: AppTheme.offlineStatusBackground(context),
        );
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final PrimaryStatusModel model;
  final Color color;

  const _StatusIcon({required this.model, required this.color});

  IconData get _icon {
    switch (model.visual) {
      case PrimaryStatusVisual.offline:
        return Icons.cloud_off_outlined;
      case PrimaryStatusVisual.error:
        return Icons.warning_amber_rounded;
      case PrimaryStatusVisual.normal:
        switch (model.alertState) {
          case AlertState.allClear:
            return Icons.check_rounded;
          case AlertState.alertImminent:
            return Icons.warning_amber_rounded;
          case AlertState.redAlert:
            return Icons.crisis_alert;
          case AlertState.waitingClear:
            return Icons.hourglass_top_rounded;
          case AlertState.justCleared:
            return Icons.verified_outlined;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        color: AppTheme.statusCardSurface(context).withAlpha(230),
        shape: BoxShape.circle,
      ),
      child: Icon(_icon, size: 64, color: color),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.statusCardSurface(context).withAlpha(210),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _formatElapsed(),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: widget.color,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
