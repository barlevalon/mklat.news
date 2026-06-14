import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class LoadingStatePlaceholder extends StatelessWidget {
  final String? message;

  const LoadingStatePlaceholder({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 48,
              color: iconColor ?? AppTheme.placeholderIconColor(context),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor ?? AppTheme.placeholderColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          ...children,
        ],
      ),
    );
  }
}
