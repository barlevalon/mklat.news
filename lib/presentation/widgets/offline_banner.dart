import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

/// Persistent neutral banner shown at the top of the screen when connectivity is lost.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        final isOffline = connectivityProvider.isOffline;
        final foreground = AppTheme.offlineBannerForeground(context);

        return AnimatedSlide(
          offset: isOffline ? Offset.zero : const Offset(0, -1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.offlineBannerBackground(context),
              border: Border(
                bottom: BorderSide(color: foreground.withAlpha(35)),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_outlined, color: foreground, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.noInternetConnection,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
