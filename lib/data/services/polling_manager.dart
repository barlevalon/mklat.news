import 'dart:async';
import '../models/alert.dart';
import '../models/news_item.dart';
import 'oref_alerts_service.dart';
import 'oref_history_service.dart';
import 'rss_news_service.dart';
import '../../core/app_constants.dart';

/// Callback types for polling results
typedef AlertPollCallback =
    void Function(List<Alert> currentAlerts, List<Alert> alertHistory);
typedef NewsPollCallback = void Function(List<NewsItem> newsItems);
typedef ErrorCallback = void Function(String source, Object error);

class PollingManager {
  final OrefAlertsService _alertsService;
  final OrefHistoryService _historyService;
  final RssNewsService _newsService;

  Timer? _alertTimer;
  Timer? _newsTimer;
  bool _isPolling = false;

  /// Callbacks
  AlertPollCallback? onAlertData;
  NewsPollCallback? onNewsData;
  ErrorCallback? onError;

  PollingManager({
    required OrefAlertsService alertsService,
    required OrefHistoryService historyService,
    required RssNewsService newsService,
  }) : _alertsService = alertsService,
       _historyService = historyService,
       _newsService = newsService;

  bool get isPolling => _isPolling;

  /// Start polling. Called when app enters foreground.
  /// Immediately fetches fresh data, then starts periodic timers.
  void start() {
    if (_isPolling) return;
    _isPolling = true;

    // Fetch immediately on start
    _pollAlerts();
    _pollNews();

    // Then start periodic timers
    _alertTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.alertsPollingIntervalMs),
      (_) => _pollAlerts(),
    );
    _newsTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.newsPollingIntervalMs),
      (_) => _pollNews(),
    );
  }

  /// Stop polling. Called when app enters background.
  void stop() {
    _isPolling = false;
    _alertTimer?.cancel();
    _alertTimer = null;
    _newsTimer?.cancel();
    _newsTimer = null;
  }

  /// Perform a single alert poll cycle.
  /// Fetches current alerts and history in parallel.
  Future<void> _pollAlerts() async {
    try {
      final results = await Future.wait([
        _alertsService.fetchCurrentAlerts(),
        _historyService.fetchAlertHistory(),
      ]);
      onAlertData?.call(results[0], results[1]);
    } catch (e) {
      onError?.call('alerts', e);
    }
  }

  /// Perform a single news poll cycle.
  Future<void> _pollNews() async {
    try {
      final items = await _newsService.fetchAllNews();
      onNewsData?.call(items);
    } catch (e) {
      onError?.call('news', e);
    }
  }

  /// Force an immediate refresh (for pull-to-refresh).
  /// Triggers both alert and news polls immediately.
  Future<void> refresh() async {
    await Future.wait([_pollAlerts(), _pollNews()]);
  }

  /// Clean up resources.
  void dispose() {
    stop();
  }
}
