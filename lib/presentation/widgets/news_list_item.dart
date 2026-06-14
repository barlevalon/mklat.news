import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/relative_time_formatter.dart';
import '../../core/url_opener.dart';
import '../../data/models/news_item.dart';
import '../models/news_source_presentation.dart';

class NewsListItem extends StatelessWidget {
  final NewsItem newsItem;
  final UrlOpener urlOpener;
  final RelativeTimeFormatter timeFormatter;

  const NewsListItem({
    super.key,
    required this.newsItem,
    this.urlOpener = const UrlLauncherOpener(),
    this.timeFormatter = const RelativeTimeFormatter(),
  });

  String _getSourceInitial(String sourceName) {
    if (sourceName.isEmpty) return '?';
    return sourceName[0].toUpperCase();
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
    final sourceName = NewsSourcePresentation.fromSource(
      newsItem.source,
    ).displayName;
    final sourceColor = AppTheme.colorForNewsSource(newsItem.source);
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
                  padding: const EdgeInsetsDirectional.only(start: 44),
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
                padding: const EdgeInsetsDirectional.only(start: 44),
                child: Builder(
                  builder: (context) {
                    final timeStr = timeFormatter.formatPastOrNull(
                      newsItem.pubDate,
                      omitFuture: true,
                      omitYearsBefore: 2000,
                    );
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
