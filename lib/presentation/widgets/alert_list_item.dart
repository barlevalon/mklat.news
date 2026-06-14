import 'package:flutter/material.dart';
import '../../core/relative_time_formatter.dart';
import '../../data/models/alert.dart';
import '../models/alert_category_presentation.dart';

class AlertListItem extends StatelessWidget {
  final Alert alert;
  final RelativeTimeFormatter timeFormatter;

  const AlertListItem({
    super.key,
    required this.alert,
    this.timeFormatter = const RelativeTimeFormatter(),
  });

  Color _metadataColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final categoryPresentation = AlertCategoryPresentation.fromCategory(
      alert.type,
    );

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
                  categoryPresentation.icon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title.isNotEmpty
                        ? alert.title
                        : categoryPresentation.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24),
              child: Text(
                alert.location,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _metadataColor(context),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24),
              child: Text(
                timeFormatter.format(alert.time),
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
