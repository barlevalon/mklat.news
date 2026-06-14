import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../models/status_presentation_model.dart';

class NationwideSummary extends StatelessWidget {
  final NationwideSummaryModel? summary;

  const NationwideSummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.nationwideSummaryBackground(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.nationwideSummaryBorder(context),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber,
            size: 16,
            color: AppTheme.nationwideSummaryIcon(context),
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.nationwideAlertSummary(
              summary.userLocationCount,
              summary.nationwideCount,
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.nationwideSummaryText(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
