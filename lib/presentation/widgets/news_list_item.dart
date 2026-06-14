import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/url_opener.dart';
import '../../data/models/news_item.dart';

class NewsListItem extends StatelessWidget {
  final NewsItem newsItem;
  final UrlOpener urlOpener;

  const NewsListItem({
    super.key,
    required this.newsItem,
    this.urlOpener = const UrlLauncherOpener(),
  });

  String _getSourceInitial(String sourceName) {
    if (sourceName.isEmpty) return '?';
    return sourceName[0].toUpperCase();
  }

  String? _formatRelativeTime(DateTime pubDate) {
    final diff = DateTime.now().difference(pubDate);
    // Future dates or epoch sentinel (unparsable) → no timestamp
    if (diff.isNegative || pubDate.year < 2000) return null;
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes == 1) return 'לפני דקה';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דקות';
    if (diff.inHours == 1) return 'לפני שעה';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    return '${pubDate.day}/${pubDate.month} ${pubDate.hour.toString().padLeft(2, '0')}:${pubDate.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openUrl() async {
    try {
      await urlOpener.openExternal(Uri.parse(newsItem.link));
    } catch (e) {
      // URL launching failed, ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceName = newsItem.source.displayName;
    final sourceColor = AppTheme.colorForNewsSource(sourceName);
    final sourceInitial = _getSourceInitial(sourceName);

    return InkWell(
      onTap: _openUrl,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: sourceColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        sourceInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      newsItem.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (newsItem.description != null &&
                  newsItem.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 44),
                  child: Text(
                    newsItem.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 44),
                child: Builder(
                  builder: (context) {
                    final timeStr = _formatRelativeTime(newsItem.pubDate);
                    // Show "Source • time" if time available, else just "Source"
                    final metadataText = timeStr != null
                        ? '$sourceName • $timeStr'
                        : sourceName;
                    return Text(
                      metadataText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
