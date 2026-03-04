# Phase 3 Batch B: Providers (Location, Alerts, News, Connectivity)

## Context

Implement the four providers that wire the data layer (Phase 2) and domain logic (Batch A) to the UI layer. Uses the `provider` package (already in pubspec.yaml).

Read these before starting:
- `.agent/specs/02-state-management.md` — provider structure, data state, location state
- `.agent/specs/05-location-management.md` — location persistence, CRUD operations
- `.agent/specs/06-error-handling.md` — error/loading/offline states
- `lib/domain/alert_state_machine.dart` — state machine (from Batch A)
- `lib/data/services/polling_manager.dart` — polling manager
- `lib/data/services/oref_alerts_service.dart` — alerts service
- `lib/data/services/oref_history_service.dart` — history service
- `lib/data/services/rss_news_service.dart` — news service
- `lib/data/models/saved_location.dart` — SavedLocation model
- `lib/data/models/alert.dart` — Alert model
- `lib/data/models/news_item.dart` — NewsItem model
- `lib/core/app_constants.dart` — constants (storage keys, etc.)

## Architecture

```
lib/presentation/providers/
├── location_provider.dart       # SavedLocation CRUD + persistence
├── alerts_provider.dart         # Active alerts + history + state machine
├── news_provider.dart           # News items
└── connectivity_provider.dart   # Online/offline status
```

All providers extend `ChangeNotifier` and are provided via `provider` package.

---

## Task 1: Location Provider

**File:** `lib/presentation/providers/location_provider.dart`

Manages saved locations with SharedPreferences persistence.

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_constants.dart';
import '../../data/models/saved_location.dart';

class LocationProvider extends ChangeNotifier {
  List<SavedLocation> _locations = [];
  bool _isLoaded = false;

  List<SavedLocation> get locations => List.unmodifiable(_locations);
  bool get isLoaded => _isLoaded;

  SavedLocation? get primaryLocation {
    try {
      return _locations.firstWhere((l) => l.isPrimary);
    } catch (_) {
      return _locations.isNotEmpty ? _locations.first : null;
    }
  }

  List<SavedLocation> get secondaryLocations {
    final primary = primaryLocation;
    if (primary == null) return [];
    return _locations.where((l) => l.id != primary.id).toList();
  }

  /// Load saved locations from SharedPreferences.
  /// Call once on app start.
  Future<void> loadLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(AppConstants.savedLocationsKey);
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List;
        _locations = list
            .whereType<Map<String, dynamic>>()
            .map((e) => SavedLocation.fromJson(e))
            .toList();
      }
    } catch (e) {
      _locations = [];
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Add a new location.
  Future<void> addLocation(SavedLocation location) async {
    // Prevent duplicates by orefName
    if (_locations.any((l) => l.orefName == location.orefName)) return;

    // If setting as primary, clear other primaries
    if (location.isPrimary) {
      _locations = _locations
          .map((l) => l.isPrimary ? l.copyWith(isPrimary: false) : l)
          .toList();
    }

    // If first location, make it primary
    if (_locations.isEmpty) {
      location = location.copyWith(isPrimary: true);
    }

    _locations.add(location);
    await _persist();
    notifyListeners();
  }

  /// Update an existing location.
  Future<void> updateLocation(SavedLocation updated) async {
    final index = _locations.indexWhere((l) => l.id == updated.id);
    if (index == -1) return;

    // If setting as primary, clear other primaries
    if (updated.isPrimary) {
      _locations = _locations
          .map((l) => l.isPrimary ? l.copyWith(isPrimary: false) : l)
          .toList();
    }

    _locations[index] = updated;
    await _persist();
    notifyListeners();
  }

  /// Delete a location by ID.
  Future<void> deleteLocation(String id) async {
    final wasRrimary = _locations.any((l) => l.id == id && l.isPrimary);
    _locations.removeWhere((l) => l.id == id);

    // If deleted location was primary, promote the first remaining
    if (wasRrimary && _locations.isNotEmpty) {
      _locations[0] = _locations[0].copyWith(isPrimary: true);
    }

    await _persist();
    notifyListeners();
  }

  /// Set a location as primary by ID.
  Future<void> setPrimary(String id) async {
    _locations = _locations
        .map((l) => l.copyWith(isPrimary: l.id == id))
        .toList();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_locations.map((l) => l.toJson()).toList());
      await prefs.setString(AppConstants.savedLocationsKey, jsonStr);
    } catch (e) {
      // Persistence failure is non-fatal
    }
  }
}
```

### Key details:
- `primaryLocation` getter: returns first `isPrimary` location, falls back to first location if none marked
- `addLocation`: prevents duplicate orefNames, auto-promotes first location to primary
- `setPrimary`: clears all isPrimary flags, sets the target
- `deleteLocation`: if primary deleted, promotes first remaining
- `_persist`: saves to SharedPreferences as JSON array

### Storage key:
Check `AppConstants.savedLocationsKey` — it should be `'mklat_saved_locations'`. If it doesn't exist, add it to `lib/core/app_constants.dart`.

---

## Task 2: Alerts Provider

**File:** `lib/presentation/providers/alerts_provider.dart`

Manages alert data from polling and drives the state machine.

```dart
import 'package:flutter/foundation.dart';
import '../../data/models/alert.dart';
import '../../domain/alert_state.dart';
import '../../domain/alert_state_machine.dart';

class AlertsProvider extends ChangeNotifier {
  final AlertStateMachine _stateMachine = AlertStateMachine();

  List<Alert> _currentAlerts = [];
  List<Alert> _alertHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastUpdated;

  // Public getters
  AlertState get alertState => _stateMachine.currentState;
  DateTime? get alertStartTime => _stateMachine.alertStartTime;
  DateTime? get clearanceTime => _stateMachine.clearanceTime;
  List<Alert> get currentAlerts => List.unmodifiable(_currentAlerts);
  List<Alert> get alertHistory => List.unmodifiable(_alertHistory);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  /// Active alert locations (from current Alerts.json)
  Set<String> get activeAlertLocations =>
      _currentAlerts.map((a) => a.location).toSet();

  /// Nationwide alert count (distinct locations in active alerts)
  int get nationwideAlertCount => activeAlertLocations.length;

  /// Count of user's saved locations that are in active alerts
  int userLocationAlertCount(List<String> savedLocationNames) {
    return savedLocationNames.where((name) =>
        activeAlertLocations.any((alertLoc) =>
            AlertStateMachine.locationsMatch(alertLoc, name))
    ).length;
  }

  /// Get history alerts filtered for a specific location
  List<Alert> alertsForLocation(String locationName) {
    return _alertHistory
        .where((a) => AlertStateMachine.locationsMatch(a.location, locationName))
        .toList();
  }

  /// Set the primary location on the state machine.
  /// Called by the UI when the user changes primary location.
  void setPrimaryLocation(String? locationName) {
    _stateMachine.setPrimaryLocation(locationName);
    notifyListeners();
  }

  /// Called by polling manager with fresh alert data.
  void onAlertData(List<Alert> current, List<Alert> history) {
    _currentAlerts = current;
    _alertHistory = history;
    _isLoading = false;
    _errorMessage = null;
    _lastUpdated = DateTime.now();

    // Run state machine evaluation
    _evaluateState();
    notifyListeners();
  }

  /// Called by polling manager on error.
  void onError(String source, Object error) {
    _errorMessage = 'שגיאה בטעינת התרעות';
    notifyListeners();
  }

  void _evaluateState() {
    final primaryName = _stateMachine.primaryLocation;
    if (primaryName == null) return;

    // Filter history for primary location
    final historyForPrimary = _alertHistory
        .where((a) => AlertStateMachine.locationsMatch(a.location, primaryName))
        .toList();

    _stateMachine.evaluate(
      activeAlertLocations: activeAlertLocations,
      historyForPrimary: historyForPrimary,
    );
  }

  /// Check if a specific location is in active alerts
  bool isLocationInActiveAlerts(String locationName) {
    return activeAlertLocations.any(
      (alertLoc) => AlertStateMachine.locationsMatch(alertLoc, locationName),
    );
  }
}
```

### Key details:
- Owns an `AlertStateMachine` instance
- `onAlertData` is the callback for the polling manager
- `_evaluateState` filters history for primary location, then runs the state machine
- `setPrimaryLocation` delegates to state machine (which resets to ALL_CLEAR)
- Exposes computed properties: `nationwideAlertCount`, `userLocationAlertCount`, `alertsForLocation`
- `locationsMatch` is used for filtering — this is the public static from `AlertStateMachine`

---

## Task 3: News Provider

**File:** `lib/presentation/providers/news_provider.dart`

Simple provider wrapping news data from polling.

```dart
import 'package:flutter/foundation.dart';
import '../../data/models/news_item.dart';

class NewsProvider extends ChangeNotifier {
  List<NewsItem> _newsItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<NewsItem> get newsItems => List.unmodifiable(_newsItems);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNews => _newsItems.isNotEmpty;

  /// Called by polling manager with fresh news data.
  void onNewsData(List<NewsItem> items) {
    _newsItems = items;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Called by polling manager on error.
  void onError(String source, Object error) {
    if (_newsItems.isEmpty) {
      _errorMessage = 'שגיאה בטעינת חדשות';
    }
    // If we have existing news, keep showing them (don't show error)
    notifyListeners();
  }
}
```

---

## Task 4: Connectivity Provider

**File:** `lib/presentation/providers/connectivity_provider.dart`

Monitors network connectivity.

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;

  ConnectivityProvider({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  bool get isOffline => _isOffline;

  /// Start monitoring connectivity. Call once on app start.
  Future<void> initialize() async {
    // Check current status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOffline = _isOffline;
    _isOffline = results.every((r) => r == ConnectivityResult.none);
    if (wasOffline != _isOffline) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

### Key details:
- `connectivity_plus` returns `List<ConnectivityResult>` (can have multiple interfaces)
- Offline = ALL results are `none`
- Only notifies on actual change (debounce unnecessary notifications)
- Injectable `Connectivity` for testing

---

## Task 5: Wire Providers in main.dart

**File:** `lib/main.dart` (modify existing)

Update the existing main.dart to set up providers and wire the polling manager callbacks.

The main.dart should:
1. Create the service instances (HttpClient, OREF services, RSS service)
2. Create the PollingManager
3. Wrap the app in MultiProvider with all 4 providers
4. Wire polling callbacks to providers
5. Start polling on app start
6. Handle app lifecycle (start/stop polling on foreground/background)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/services/http_client.dart';
import 'data/services/oref_alerts_service.dart';
import 'data/services/oref_history_service.dart';
import 'data/services/rss_news_service.dart';
import 'data/services/polling_manager.dart';
import 'presentation/providers/location_provider.dart';
import 'presentation/providers/alerts_provider.dart';
import 'presentation/providers/news_provider.dart';
import 'presentation/providers/connectivity_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MklatApp());
}

class MklatApp extends StatefulWidget {
  const MklatApp({super.key});

  @override
  State<MklatApp> createState() => _MklatAppState();
}

class _MklatAppState extends State<MklatApp> with WidgetsBindingObserver {
  late final HttpClient _httpClient;
  late final PollingManager _pollingManager;
  late final LocationProvider _locationProvider;
  late final AlertsProvider _alertsProvider;
  late final NewsProvider _newsProvider;
  late final ConnectivityProvider _connectivityProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  void _initializeServices() {
    _httpClient = HttpClient();
    final alertsService = OrefAlertsService(_httpClient);
    final historyService = OrefHistoryService(_httpClient);
    final newsService = RssNewsService(_httpClient);

    _pollingManager = PollingManager(
      alertsService: alertsService,
      historyService: historyService,
      newsService: newsService,
    );

    _locationProvider = LocationProvider();
    _alertsProvider = AlertsProvider();
    _newsProvider = NewsProvider();
    _connectivityProvider = ConnectivityProvider();

    // Wire polling callbacks to providers
    _pollingManager.onAlertData = _alertsProvider.onAlertData;
    _pollingManager.onNewsData = _newsProvider.onNewsData;
    _pollingManager.onError = (source, error) {
      _alertsProvider.onError(source, error);
      _newsProvider.onError(source, error);
    };

    // Listen for location changes to update state machine
    _locationProvider.addListener(_onLocationChange);

    // Initialize
    _locationProvider.loadLocations();
    _connectivityProvider.initialize();
    _pollingManager.start();
  }

  void _onLocationChange() {
    final primary = _locationProvider.primaryLocation;
    _alertsProvider.setPrimaryLocation(primary?.orefName);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _pollingManager.start();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pollingManager.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationProvider.removeListener(_onLocationChange);
    _pollingManager.dispose();
    _httpClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _locationProvider),
        ChangeNotifierProvider.value(value: _alertsProvider),
        ChangeNotifierProvider.value(value: _newsProvider),
        ChangeNotifierProvider.value(value: _connectivityProvider),
      ],
      child: MaterialApp(
        title: 'mklat.news',
        debugShowCheckedModeBanner: false,
        locale: const Locale('he', 'IL'),
        supportedLocales: const [Locale('he', 'IL')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: Text('mklat.news'),
            ),
          ),
        ),
      ),
    );
  }
}
```

### Key wiring:
- `_pollingManager.onAlertData` → `_alertsProvider.onAlertData`
- `_pollingManager.onNewsData` → `_newsProvider.onNewsData`
- `_pollingManager.onError` → both providers' `onError`
- `_locationProvider.addListener` → syncs primary location to `_alertsProvider`
- `WidgetsBindingObserver` → start/stop polling on lifecycle

---

## Task 6: Add savedLocationsKey constant

**File:** `lib/core/app_constants.dart` (modify existing)

Check if `savedLocationsKey` exists. If not, add:
```dart
static const String savedLocationsKey = 'mklat_saved_locations';
```

---

## Task 7: Unit Tests

### `test/unit/location_provider_test.dart`
Test:
1. Initial state: empty locations, not loaded
2. loadLocations: loads from SharedPreferences
3. addLocation: adds and persists
4. addLocation: prevents duplicate orefNames
5. addLocation: first location auto-promoted to primary
6. addLocation with isPrimary: clears other primaries
7. updateLocation: updates and persists
8. deleteLocation: removes and persists
9. deleteLocation: if primary deleted, promotes first remaining
10. setPrimary: updates isPrimary flags
11. primaryLocation getter: returns primary, falls back to first
12. secondaryLocations: returns non-primary locations

### `test/unit/alerts_provider_test.dart`
Test:
1. Initial state: loading, no alerts
2. onAlertData: updates current/history, clears loading
3. onAlertData: runs state machine evaluation
4. setPrimaryLocation: delegates to state machine, notifies
5. nationwideAlertCount: correct count
6. userLocationAlertCount: filters saved locations against active alerts
7. alertsForLocation: filters history by location
8. isLocationInActiveAlerts: correct matching
9. onError: sets error message

### `test/unit/news_provider_test.dart`
Test:
1. Initial state: loading, no news
2. onNewsData: updates items, clears loading
3. onError with no existing news: sets error
4. onError with existing news: keeps news, no error message
5. hasNews: true when items exist

### `test/unit/connectivity_provider_test.dart`
Test:
1. Initial state: not offline
2. initialize: checks current status
3. Connectivity change to none: sets offline
4. Connectivity change from none: sets online
5. Only notifies on actual change

**Mock SharedPreferences**: Use `SharedPreferences.setMockInitialValues({})` from the test library.

**Mock Connectivity**: Use `@GenerateMocks([Connectivity])` from mockito.

---

## Verification

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

All must pass with zero errors.

## Files to create/modify

1. `lib/presentation/providers/location_provider.dart` (create)
2. `lib/presentation/providers/alerts_provider.dart` (create)
3. `lib/presentation/providers/news_provider.dart` (create)
4. `lib/presentation/providers/connectivity_provider.dart` (create)
5. `lib/main.dart` (modify — add providers, wiring, lifecycle)
6. `lib/core/app_constants.dart` (modify — add savedLocationsKey if missing)
7. `test/unit/location_provider_test.dart` (create)
8. `test/unit/alerts_provider_test.dart` (create)
9. `test/unit/news_provider_test.dart` (create)
10. `test/unit/connectivity_provider_test.dart` (create)
