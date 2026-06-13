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
typedef PollErrorCallback = void Function(Object error);

class _PollResult<T> {
  final T? value;
  final Object? error;

  const _PollResult.value(this.value) : error = null;
  const _PollResult.error(this.error) : value = null;

  bool get hasError => error != null;
}

class PollingManager {
  final OrefAlertsService _alertsService;
  final OrefHistoryService _historyService;
  final RssNewsService _newsService;

  Timer? _alertTimer;
  Timer? _newsTimer;
  bool _isPolling = false;
  int? _alertPollInFlightEpoch;
  Future<void>? _alertPollInFlight;
  int? _newsPollInFlightEpoch;
  Future<void>? _newsPollInFlight;
  int _pollingEpoch = 0;

  /// Callbacks
  AlertPollCallback? onAlertData;
  NewsPollCallback? onNewsData;
  PollErrorCallback? onAlertError;
  PollErrorCallback? onAlertHistoryError;
  PollErrorCallback? onNewsError;

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
    final epoch = ++_pollingEpoch;

    // Fetch immediately on start
    _pollAlerts(epoch: epoch);
    _pollNews(epoch: epoch);

    // Then start periodic timers
    _alertTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.alertsPollingIntervalMs),
      (_) => _pollAlerts(epoch: epoch),
    );
    _newsTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.newsPollingIntervalMs),
      (_) => _pollNews(epoch: epoch),
    );
  }

  /// Stop polling. Called when app enters background.
  void stop() {
    _isPolling = false;
    _pollingEpoch++;
    _alertTimer?.cancel();
    _alertTimer = null;
    _newsTimer?.cancel();
    _newsTimer = null;
  }

  /// Perform a single alert poll cycle.
  /// Fetches current alerts and history in parallel.
  Future<void> _pollAlerts({required int epoch, bool requirePolling = true}) {
    if (_alertPollInFlightEpoch == epoch && _alertPollInFlight != null) {
      return _alertPollInFlight!;
    }

    final future = _runAlertPoll(epoch: epoch, requirePolling: requirePolling);
    _alertPollInFlightEpoch = epoch;
    _alertPollInFlight = future;
    return future.whenComplete(() {
      if (_alertPollInFlightEpoch == epoch &&
          identical(_alertPollInFlight, future)) {
        _alertPollInFlightEpoch = null;
        _alertPollInFlight = null;
      }
    });
  }

  Future<void> _runAlertPoll({
    required int epoch,
    required bool requirePolling,
  }) async {
    final results = await Future.wait([
      _capture(_alertsService.fetchCurrentAlerts),
      _capture(_historyService.fetchAlertHistory),
    ]);

    if (!_shouldDeliver(epoch, requirePolling: requirePolling)) return;

    final currentResult = results[0];
    final historyResult = results[1];

    if (currentResult.hasError) {
      onAlertError?.call(currentResult.error!);
      return;
    }

    final currentAlerts = currentResult.value!;
    if (historyResult.hasError) {
      onAlertData?.call(currentAlerts, const []);
      onAlertHistoryError?.call(historyResult.error!);
      return;
    }

    onAlertData?.call(currentAlerts, historyResult.value!);
  }

  /// Perform a single news poll cycle.
  Future<void> _pollNews({required int epoch, bool requirePolling = true}) {
    if (_newsPollInFlightEpoch == epoch && _newsPollInFlight != null) {
      return _newsPollInFlight!;
    }

    final future = _runNewsPoll(epoch: epoch, requirePolling: requirePolling);
    _newsPollInFlightEpoch = epoch;
    _newsPollInFlight = future;
    return future.whenComplete(() {
      if (_newsPollInFlightEpoch == epoch &&
          identical(_newsPollInFlight, future)) {
        _newsPollInFlightEpoch = null;
        _newsPollInFlight = null;
      }
    });
  }

  Future<void> _runNewsPoll({
    required int epoch,
    required bool requirePolling,
  }) async {
    try {
      final items = await _newsService.fetchAllNews();
      if (_shouldDeliver(epoch, requirePolling: requirePolling)) {
        onNewsData?.call(items);
      }
    } catch (e) {
      if (_shouldDeliver(epoch, requirePolling: requirePolling)) {
        onNewsError?.call(e);
      }
    }
  }

  Future<_PollResult<T>> _capture<T>(Future<T> Function() operation) async {
    try {
      return _PollResult.value(await Future.sync(operation));
    } catch (e) {
      return _PollResult.error(e);
    }
  }

  bool _shouldDeliver(int epoch, {required bool requirePolling}) {
    return epoch == _pollingEpoch && (!requirePolling || _isPolling);
  }

  /// Force an immediate refresh (for pull-to-refresh).
  /// Triggers both alert and news polls immediately.
  Future<void> refresh() async {
    final epoch = _pollingEpoch;
    await Future.wait([
      _pollAlerts(epoch: epoch, requirePolling: false),
      _pollNews(epoch: epoch, requirePolling: false),
    ]);
  }

  /// Clean up resources.
  void dispose() {
    stop();
  }
}
