import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class LoadingStatePlaceholder extends StatelessWidget {
  final String? message;

  const LoadingStatePlaceholder({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        decoration: BoxDecoration(
          color: AppTheme.statusCardSurface(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.dividerColor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.placeholderColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ContentStatePlaceholder extends StatelessWidget {
  final IconData? icon;
  final String message;
  final Color? iconColor;
  final Color? textColor;
  final List<Widget> children;

  const ContentStatePlaceholder({
    super.key,
    this.icon,
    required this.message,
    this.iconColor,
    this.textColor,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        decoration: BoxDecoration(
          color: AppTheme.statusCardSurface(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.dividerColor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.placeholderIconColor(context))
                      .withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 38,
                  color: iconColor ?? AppTheme.placeholderIconColor(context),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textColor ?? AppTheme.placeholderColor(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
