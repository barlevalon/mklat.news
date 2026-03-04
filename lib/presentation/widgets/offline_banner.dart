import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

/// Persistent banner shown at the top of the screen when connectivity is lost.
///
/// Shows an orange/amber banner with wifi-off icon and "אין חיבור לאינטרנט" text.
/// Auto-hides when connectivity is restored with animated slide in/out.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        final isOffline = connectivityProvider.isOffline;

        return AnimatedSlide(
          offset: isOffline ? Offset.zero : const Offset(0, -1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            width: double.infinity,
            color: Colors.orange.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'אין חיבור לאינטרנט',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
