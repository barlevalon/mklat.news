# Phase 2 Batch C: Polling Manager

## Context

Implement the polling manager that orchestrates periodic fetching of alerts and news. This depends on all services from Batch A and B being complete.

Read these files before starting:
- `.agent/specs/01-data-layer.md` — polling strategy section (line 178-196)
- `.agent/specs/06-error-handling.md` — error/resume handling
- `lib/core/app_constants.dart` — polling intervals
- `lib/data/services/oref_alerts_service.dart` — alerts service
- `lib/data/services/oref_history_service.dart` — history service
- `lib/data/services/rss_news_service.dart` — news service

## Architecture

```
lib/data/services/
└── polling_manager.dart     # Orchestrates periodic fetching
```

---

## Task 1: Polling Manager

**File:** `lib/data/services/polling_manager.dart`

The polling manager runs two independent polling loops:
1. **Alert poll** (every 2 seconds): Fetches both current alerts AND alert history in parallel
2. **News poll** (every 30 seconds): Fetches RSS news

It provides callbacks for data delivery and lifecycle management (start/stop for foreground/background).

```dart
import 'dart:async';
import '../models/alert.dart';
import '../models/news_item.dart';
import 'oref_alerts_service.dart';
import 'oref_history_service.dart';
import 'rss_news_service.dart';
import '../../core/app_constants.dart';

/// Callback types for polling results
typedef AlertPollCallback = void Function(
  List<Alert> currentAlerts,
  List<Alert> alertHistory,
);
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
  })  : _alertsService = alertsService,
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
      onAlertData?.call(
        results[0] as List<Alert>,
        results[1] as List<Alert>,
      );
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
    await Future.wait([
      _pollAlerts(),
      _pollNews(),
    ]);
  }

  /// Clean up resources.
  void dispose() {
    stop();
  }
}
```

Key design decisions:
- **Two independent timers**: Alerts at 2s, news at 30s. They don't block each other.
- **Immediate fetch on start**: When resuming from background, data is fetched immediately (not after the first interval).
- **Parallel alert + history fetch**: Both OREF endpoints are fetched simultaneously in each alert cycle.
- **Callback-based**: The polling manager doesn't hold state — it delivers data via callbacks. The state management layer (Phase 3 providers) will consume these callbacks.
- **`refresh()`**: For pull-to-refresh, triggers both polls immediately.
- **Never throws**: Errors are delivered via `onError` callback.

---

## Task 2: Unit Tests

**File:** `test/unit/polling_manager_test.dart`

Use mock services. Since all three services are concrete classes, mock them with `@GenerateMocks`.

Add to `test/mocks/mock_services.dart`:
```dart
import 'package:mockito/annotations.dart';
import 'package:mklat/data/services/oref_alerts_service.dart';
import 'package:mklat/data/services/oref_history_service.dart';
import 'package:mklat/data/services/rss_news_service.dart';

@GenerateMocks([OrefAlertsService, OrefHistoryService, RssNewsService])
export 'mock_services.mocks.dart';
```

### Test cases:

1. **start() triggers immediate fetch** — both alert and news callbacks fire immediately
2. **start() starts periodic timers** — after initial fetch, callbacks fire again at the correct intervals (use `fakeAsync` to advance time)
3. **stop() cancels timers** — no more callbacks after stop
4. **start() is idempotent** — calling start twice doesn't create duplicate timers
5. **Alert poll fetches current + history in parallel** — both services are called on each tick
6. **News poll fetches RSS** — news service is called on each tick
7. **refresh() triggers immediate poll** — both alert and news callbacks fire
8. **Error in one service doesn't crash** — if alerts service throws, onError is called, news continues
9. **dispose() stops polling** — equivalent to stop()

### Testing with fakeAsync:

```dart
import 'package:fake_async/fake_async.dart';

test('alert timer fires every 2 seconds', () {
  fakeAsync((async) {
    manager.start();
    // Initial fetch
    async.flushMicrotasks();
    verify(mockAlertsService.fetchCurrentAlerts()).called(1);

    // Advance 2 seconds
    async.elapse(Duration(milliseconds: 2000));
    verify(mockAlertsService.fetchCurrentAlerts()).called(2); // 1 initial + 1 timer
    
    manager.stop();
  });
});
```

**Note:** Add `fake_async` to dev_dependencies in `pubspec.yaml`:
```yaml
dev_dependencies:
  fake_async: ^1.3.1
```

Wait — `fake_async` is actually included in `flutter_test` via the `test` package. Use `import 'package:fake_async/fake_async.dart';` which is available transitively. If it's not available, use `flutter_test`'s `fakeAsync` and `tick()` instead:

```dart
import 'package:flutter_test/flutter_test.dart';

testWidgets('...', (tester) async {
  await tester.runAsync(() async {
    // ...
  });
});
```

Actually the simplest approach: use `flutter_test`'s built-in `fakeAsync`:

```dart
test('timer fires', () {
  fakeAsync((async) {
    // ...
    async.elapse(Duration(seconds: 2));
    // ...
  });
});
```

This is available from `package:flutter_test/flutter_test.dart` which re-exports `package:test/fake_async.dart`. No extra dependency needed.

---

## Verification

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

All must pass.

---

## Files to create/modify

1. `lib/data/services/polling_manager.dart` (create)
2. `test/mocks/mock_services.dart` (create)
3. `test/unit/polling_manager_test.dart` (create)

## Files that may need modification

4. `test/mocks/mock_http_client.dart` — ensure it exists from Batch B (if not, create it)
