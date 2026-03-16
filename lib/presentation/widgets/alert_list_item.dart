import 'package:flutter/material.dart';
import '../../data/models/alert.dart';

class AlertListItem extends StatelessWidget {
  final Alert alert;

  const AlertListItem({super.key, required this.alert});

  String _getCategoryIcon(AlertCategory category) {
    switch (category) {
      case AlertCategory.rockets:
      case AlertCategory.uav:
        return '🚨';
      case AlertCategory.imminent:
        return '⚠️';
      case AlertCategory.clearance:
        return '✅';
      case AlertCategory.other:
        return '📍';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'עכשיו';
    } else if (diff.inMinutes == 1) {
      return 'לפני דקה';
    } else if (diff.inMinutes < 60) {
      return 'לפני ${diff.inMinutes} דקות';
    } else if (diff.inHours == 1) {
      return 'לפני שעה';
    } else if (diff.inHours < 24) {
      return 'לפני ${diff.inHours} שעות';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _metadataColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getCategoryIcon(alert.type),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title.isNotEmpty
                        ? alert.title
                        : alert.type.hebrewTitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Text(
                alert.location,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _metadataColor(context),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Text(
                _formatTime(alert.time),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: _metadataColor(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
