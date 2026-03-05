import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/news_list_item.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NewsProvider, ConnectivityProvider>(
      builder: (context, newsProvider, connectivityProvider, child) {
        final isOffline = connectivityProvider.isOffline;

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'מבזקי חדשות',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // News list or empty/error state
            Expanded(child: _buildNewsList(newsProvider, isOffline)),
          ],
        );
      },
    );
  }

  Widget _buildNewsList(NewsProvider newsProvider, bool isOffline) {
    if (newsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (newsProvider.errorMessage != null && newsProvider.newsItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              newsProvider.errorMessage!,
              style: TextStyle(color: Colors.red.shade600),
            ),
          ],
        ),
      );
    }

    // Offline and empty: show offline-specific message
    if (isOffline && newsProvider.newsItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'אין חיבור לאינטרנט',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (newsProvider.newsItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'אין מבזקים חדשים',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: newsProvider.newsItems.length,
      itemBuilder: (context, index) {
        return NewsListItem(newsItem: newsProvider.newsItems[index]);
      },
    );
  }
}
