import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alerts_provider.dart';

/// Semi-transparent overlay shown when the app resumes from background.
///
/// Displays "מתעדכן..." text with a loading spinner until fresh data arrives.
/// Uses IgnorePointer when not showing to allow interaction with underlying content.
class ResumeOverlay extends StatelessWidget {
  const ResumeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertsProvider>(
      builder: (context, alertsProvider, child) {
        final isResuming = alertsProvider.isResuming;

        if (!isResuming) {
          return const SizedBox.shrink();
        }

        return IgnorePointer(
          ignoring: false,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'מתעדכן...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
