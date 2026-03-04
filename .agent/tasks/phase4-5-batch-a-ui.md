# Phase 4+5 Batch A: UI Widgets + Screens

## Context

Implement all UI widgets and the two main screens (Status and News). The backend is complete: models, services, state machine, and providers are all wired up in main.dart with MultiProvider.

Read these before starting:
- `.agent/specs/03-status-screen.md` — status screen layout, components, interactions
- `.agent/specs/04-news-screen.md` — news screen layout, news items, interactions
- `lib/presentation/providers/alerts_provider.dart` — alert state, active alerts, history
- `lib/presentation/providers/location_provider.dart` — saved locations, primary
- `lib/presentation/providers/news_provider.dart` — news items
- `lib/presentation/providers/connectivity_provider.dart` — offline status
- `lib/domain/alert_state.dart` — AlertState enum with extensions (hebrewTitle, instruction, icon, etc.)
- `lib/data/models/alert.dart` — Alert model
- `lib/data/models/news_item.dart` — NewsItem model with NewsSource enum

## Architecture

```
lib/presentation/
├── providers/          # Already exists
├── screens/
│   ├── status_screen.dart
│   └── news_screen.dart
├── widgets/
│   ├── primary_status_card.dart
│   ├── location_selector_button.dart
│   ├── secondary_locations_row.dart
│   ├── nationwide_summary.dart
│   ├── alert_list_item.dart
│   ├── news_list_item.dart
│   └── page_indicator.dart
└── app_shell.dart      # PageView with two screens
```

---

## Task 1: Theme & Colors

**File:** `lib/core/app_theme.dart` (create)

Define the color scheme for different alert states and general styling.

```dart
import 'package:flutter/material.dart';
import '../domain/alert_state.dart';

class AppTheme {
  // Alert state colors
  static Color colorForAlertState(AlertState state) {
    switch (state) {
      case AlertState.allClear:
        return const Color(0xFF4CAF50); // Green
      case AlertState.alertImminent:
        return const Color(0xFFFFC107); // Amber
      case AlertState.redAlert:
        return const Color(0xFFF44336); // Red
      case AlertState.waitingClear:
        return const Color(0xFFFF9800); // Orange
      case AlertState.justCleared:
        return const Color(0xFF66BB6A); // Light Green
    }
  }

  // Background color for status card (lighter shade)
  static Color backgroundForAlertState(AlertState state) {
    switch (state) {
      case AlertState.allClear:
        return const Color(0xFFE8F5E9);
      case AlertState.alertImminent:
        return const Color(0xFFFFF8E1);
      case AlertState.redAlert:
        return const Color(0xFFFFEBEE);
      case AlertState.waitingClear:
        return const Color(0xFFFFF3E0);
      case AlertState.justCleared:
        return const Color(0xFFE8F5E9);
    }
  }

  // Secondary location status dot colors
  static const Color dotGreen = Color(0xFF4CAF50);
  static const Color dotRed = Color(0xFFF44336);
  static const Color dotYellow = Color(0xFFFFC107);

  // News source colors
  static Color colorForNewsSource(String sourceName) {
    switch (sourceName) {
      case 'Ynet': return const Color(0xFFE53935);
      case 'Maariv': return const Color(0xFF1565C0);
      case 'Walla': return const Color(0xFFE65100);
      case 'Haaretz': return const Color(0xFF2E7D32);
      default: return const Color(0xFF757575);
    }
  }
}
```

---

## Task 2: Primary Status Card Widget

**File:** `lib/presentation/widgets/primary_status_card.dart`

The dominant visual element showing current alert state for primary location.

Uses `Provider.of<AlertsProvider>` to get:
- `alertState` — current state enum
- `alertStartTime` — for elapsed timer
- `clearanceTime` — for "time since" display

Features:
- Large icon (use the emoji from `AlertState.icon` or Material icons)
- Hebrew title from `AlertState.hebrewTitle`
- Instruction text from `AlertState.instruction`
- Elapsed timer for RED_ALERT and WAITING_CLEAR (updates every second via `Timer.periodic`)
- "Time since" for JUST_CLEARED ("לפני X דקות")
- Background color based on state (from AppTheme)
- Rounded card with padding

**Timer logic:**
```dart
// For RED_ALERT and WAITING_CLEAR: show MM:SS since alertStartTime
// Use a periodic Timer that fires every second to update the display
// Dispose the timer in the widget's dispose()

String _formatElapsed(DateTime startTime) {
  final elapsed = DateTime.now().difference(startTime);
  final minutes = elapsed.inMinutes;
  final seconds = elapsed.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

// For JUST_CLEARED: show "לפני X דקות" since clearanceTime
String _formatTimeSince(DateTime clearanceTime) {
  final diff = DateTime.now().difference(clearanceTime);
  if (diff.inMinutes < 1) return 'עכשיו';
  return 'לפני ${diff.inMinutes} דקות';
}
```

The widget should be a `StatefulWidget` to manage the timer.

---

## Task 3: Location Selector Button

**File:** `lib/presentation/widgets/location_selector_button.dart`

A tappable button showing the current primary location name.

Uses `Provider.of<LocationProvider>` to get `primaryLocation`.

- Shows `primaryLocation.displayLabel` if set
- Shows "בחר אזור" if no location selected
- Has a dropdown arrow icon (▼)
- `onTap` callback (caller will open location management modal)

---

## Task 4: Secondary Locations Row

**File:** `lib/presentation/widgets/secondary_locations_row.dart`

Horizontal row of secondary locations with status dots.

Uses:
- `Provider.of<LocationProvider>` → `secondaryLocations`
- `Provider.of<AlertsProvider>` → `isLocationInActiveAlerts(name)`

Features:
- Horizontal `ListView` (scrollable if many)
- Each item: colored dot + custom label
- Dot color: green (no alert), red (active alert), yellow (imminent/waiting)
- Hidden when only 1 or 0 saved locations
- `onTap` callback per item (caller will open location modal)

---

## Task 5: Nationwide Summary Widget

**File:** `lib/presentation/widgets/nationwide_summary.dart`

Shows alert counts during active events.

Uses `Provider.of<AlertsProvider>`:
- `nationwideAlertCount` — total active locations
- `userLocationAlertCount(savedLocationNames)` — user's locations in alert

Display: `"X באזורים שלך • Y ברחבי הארץ"`

- Only visible when `nationwideAlertCount > 0`
- Uses `Visibility` or conditional rendering

---

## Task 6: Alert List Item Widget

**File:** `lib/presentation/widgets/alert_list_item.dart`

Displays a single alert in the history list.

Takes an `Alert` object as input (NOT from provider — parent passes it).

Shows:
- Category icon (use AlertCategory extension if it exists, else map category int)
- Title (alert title or category display name)
- Location name
- Time (formatted as HH:mm or relative)

Styling: Card-like, with subtle border/shadow.

---

## Task 7: News List Item Widget

**File:** `lib/presentation/widgets/news_list_item.dart`

Displays a single news item.

Takes a `NewsItem` object as input.

Shows:
- Source initial letter in colored circle (Y/M/W/H)
- Headline (up to 2 lines)
- Description (optional, truncated to ~100 chars)
- Source name + relative time ("Ynet • לפני 5 דקות")
- `onTap` opens URL in browser via `url_launcher`

**Relative time formatting:**
```dart
String formatRelativeTime(DateTime pubDate) {
  final diff = DateTime.now().difference(pubDate);
  if (diff.inMinutes < 1) return 'עכשיו';
  if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דקות';
  if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
  // Beyond 24h, show date
  return '${pubDate.day}/${pubDate.month} ${pubDate.hour.toString().padLeft(2, '0')}:${pubDate.minute.toString().padLeft(2, '0')}';
}
```

**Source display name from NewsSource enum:**
```dart
String get displayName {
  switch (this) {
    case NewsSource.ynet: return 'Ynet';
    case NewsSource.maariv: return 'Maariv';
    case NewsSource.walla: return 'Walla';
    case NewsSource.haaretz: return 'Haaretz';
  }
}
```
Check if this extension exists on NewsSource. If not, add it.

---

## Task 8: Page Indicator

**File:** `lib/presentation/widgets/page_indicator.dart`

Simple dot indicator showing which page is active (Status/News).

Takes `currentIndex` and `pageCount` as parameters.

Two dots, active one is filled, inactive is outline.

---

## Task 9: App Shell

**File:** `lib/presentation/app_shell.dart`

The root widget with PageView for swipe navigation between Status and News screens.

```dart
class AppShell extends StatefulWidget {
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: const [
                  StatusScreen(),
                  NewsScreen(),
                ],
              ),
            ),
            PageIndicator(
              currentIndex: _currentPage,
              pageCount: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
```

---

## Task 10: Status Screen

**File:** `lib/presentation/screens/status_screen.dart`

Assembles all status components.

```dart
class StatusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AlertsProvider, LocationProvider>(
      builder: (context, alertsProvider, locationProvider, child) {
        return Column(
          children: [
            // Primary status card with location selector
            PrimaryStatusCard(),
            
            // Secondary locations row (if >1 saved location)
            if (locationProvider.secondaryLocations.isNotEmpty)
              SecondaryLocationsRow(),
            
            // Nationwide summary (if active alerts)
            NationwideSummary(),
            
            // Recent alerts list header
            // ...
            
            // Alerts list (scrollable)
            Expanded(
              child: _buildAlertsList(alertsProvider, locationProvider),
            ),
          ],
        );
      },
    );
  }
}
```

The alerts list should:
- Show "הוסף מיקום כדי לראות התרעות" if no locations saved
- Show "אין התרעות באזורים שלך" if locations saved but no alerts
- Show filtered alert history (alerts for saved locations only)
- Initially show 20 items
- "טען עוד" button at bottom to load more (simple in-memory pagination — increase the displayed count)

Use `Provider.of` or `Consumer` for reactivity.

---

## Task 11: News Screen

**File:** `lib/presentation/screens/news_screen.dart`

Assembles the news list.

```dart
class NewsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        return Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('מבזקי חדשות', style: Theme.of(context).textTheme.headlineSmall),
            ),
            
            // News list or empty/error state
            Expanded(
              child: _buildNewsList(newsProvider),
            ),
          ],
        );
      },
    );
  }
}
```

States:
- Loading: show `CircularProgressIndicator` centered
- Error (no items): show "שגיאה בטעינת חדשות"
- Empty: show "אין מבזקים חדשים"
- Normal: `ListView.builder` of `NewsListItem` widgets

Pull-to-refresh: Wrap list in `RefreshIndicator`. On refresh, call the polling manager's refresh method. Since the polling manager isn't directly accessible from the widget, either:
- Add a `refresh` method to `NewsProvider` that triggers through the polling manager (requires wiring)
- Or: skip pull-to-refresh for now (auto-polling handles it)

For MVP: skip manual pull-to-refresh. The 30s polling handles freshness.

---

## Task 12: Update main.dart

**File:** `lib/main.dart` (modify)

Replace the placeholder `Scaffold(body: Center(child: Text('mklat.news')))` with `AppShell()`:

```dart
home: const Directionality(
  textDirection: TextDirection.rtl,
  child: AppShell(),
),
```

---

## Task 13: Widget Tests

Create basic widget tests for the key widgets. Don't aim for 100% coverage on UI — focus on:

### `test/widget/primary_status_card_test.dart`
- Renders correct text for each AlertState
- Shows timer when in RED_ALERT
- Shows "time since" when in JUST_CLEARED

### `test/widget/news_list_item_test.dart`
- Renders headline and source name
- Renders description when present
- Handles null description

### `test/widget/app_shell_test.dart`
- Renders both screens in PageView
- Page indicator shows correct active page

For widget tests, wrap in `MaterialApp` + `MultiProvider` with mock/test providers.

---

## Verification

```bash
flutter analyze
flutter test
```

Both must pass with zero errors.

## Files to create

1. `lib/core/app_theme.dart`
2. `lib/presentation/widgets/primary_status_card.dart`
3. `lib/presentation/widgets/location_selector_button.dart`
4. `lib/presentation/widgets/secondary_locations_row.dart`
5. `lib/presentation/widgets/nationwide_summary.dart`
6. `lib/presentation/widgets/alert_list_item.dart`
7. `lib/presentation/widgets/news_list_item.dart`
8. `lib/presentation/widgets/page_indicator.dart`
9. `lib/presentation/app_shell.dart`
10. `lib/presentation/screens/status_screen.dart`
11. `lib/presentation/screens/news_screen.dart`
12. `test/widget/primary_status_card_test.dart`
13. `test/widget/news_list_item_test.dart`
14. `test/widget/app_shell_test.dart`

## Files to modify

15. `lib/main.dart` — swap placeholder with AppShell
16. `lib/data/models/news_item.dart` — add `displayName` extension on NewsSource if missing
