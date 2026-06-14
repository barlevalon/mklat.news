import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';

class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int pageCount;
  final ValueChanged<int>? onPageSelected;

  const PageIndicator({
    super.key,
    required this.currentIndex,
    required this.pageCount,
    this.onPageSelected,
  });

  static const _labels = [AppStrings.statusTab, AppStrings.newsTab];
  static const _icons = [Icons.shield_outlined, Icons.article_outlined];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.statusCardSurface(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.dividerColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: List.generate(pageCount, (index) {
            final isActive = index == currentIndex;
            final label = index < _labels.length ? _labels[index] : '$index';
            final icon = index < _icons.length ? _icons[index] : Icons.circle;
            final foreground = isActive
                ? AppTheme.brandBlue
                : AppTheme.mutedTextColor(context);

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onPageSelected == null
                    ? null
                    : () => onPageSelected!(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.brandBlue.withAlpha(22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20, color: foreground),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
