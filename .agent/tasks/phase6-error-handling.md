# Phase 6: Error Handling & Polish

## Goal

Add offline banner, loading states, error states, and app resume overlay. The guiding principle: **never show stale data as current** for safety-critical alert information.

## Spec Reference

See `.agent/specs/06-error-handling.md` for full details.

## Implementation

### 1. Offline Banner Widget (`lib/presentation/widgets/offline_banner.dart`)

A persistent banner at the top of the screen when connectivity is lost.

```dart
class OfflineBanner extends StatelessWidget {
  // Consumes ConnectivityProvider
  // Shows orange/yellow banner: "⚠️ אין חיבור לאינטרנט"
  // Auto-hides when connectivity restored
  // Positioned at top, overlaying content (not pushing it down)
}
```

Design:
- Orange/amber background with white text
- Icon: `Icons.wifi_off` or `Icons.signal_wifi_off`
- Text: "אין חיבור לאינטרנט"
- Animates in/out (SlideTransition or AnimatedContainer)
- Uses `Consumer<ConnectivityProvider>` — renders nothing when online

### 2. Integrate Offline Banner into AppShell (`lib/presentation/app_shell.dart`)

Wrap the existing `Scaffold` body with a `Stack` that layers the offline banner on top:

```dart
Stack(
  children: [
    // Existing SafeArea + Column with PageView + PageIndicator
    SafeArea(child: Column(...)),
    // Overlay offline banner at top
    const Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: OfflineBanner(),
    ),
  ],
)
```

### 3. Status Screen Loading & Error States (`lib/presentation/screens/status_screen.dart`)

Currently the status screen doesn't check `AlertsProvider.isLoading` or `errorMessage`. Add:

**Initial loading** (isLoading == true, no data yet):
- Show `CircularProgressIndicator` with "טוען..." text in the alerts list area
- The PrimaryStatusCard can still show "אין התרעות" during loading (default state)

**Error state** (errorMessage != null):
- Show error icon + message in the alerts list area
- If we have stale data and error: show the data with a small warning indicator
- If no data and error: show full error state with "שגיאה בטעינת התרעות" and retry icon

### 4. Alert Error Indicator in Status Card

When `AlertsProvider.errorMessage != null`, show a small warning badge or text below the status card:

```dart
if (alertsProvider.errorMessage != null)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.warning_amber, size: 16, color: Colors.orange),
        SizedBox(width: 4),
        Text('שגיאה בטעינת התרעות',
          style: TextStyle(fontSize: 12, color: Colors.orange)),
      ],
    ),
  ),
```

This goes between the PrimaryStatusCard and the secondary locations row.

### 5. App Resume Overlay (`lib/presentation/widgets/resume_overlay.dart`)

When the app resumes from background, show a semi-transparent overlay with "מתעדכן..." for a brief period until fresh data arrives.

**Implementation approach:**
- Add a `bool _isResuming` flag to `_MklatAppState` in `main.dart`
- On `AppLifecycleState.resumed`: set `_isResuming = true`, then after first successful data callback: set `_isResuming = false`
- Pass `_isResuming` down via a simple `ValueNotifier<bool>` or add it to an existing provider

Simpler approach: Add `isResuming` state to `AlertsProvider`:
```dart
bool _isResuming = false;
bool get isResuming => _isResuming;

void setResuming(bool value) {
  _isResuming = value;
  notifyListeners();
}

void onAlertData(...) {
  // ... existing code ...
  _isResuming = false; // Clear resume state on fresh data
  notifyListeners();
}
```

In `main.dart`, on `AppLifecycleState.resumed`:
```dart
case AppLifecycleState.resumed:
  _alertsProvider.setResuming(true);
  _pollingManager.start();
  break;
```

The overlay widget:
```dart
class ResumeOverlay extends StatelessWidget {
  // Consumes AlertsProvider.isResuming
  // Shows semi-transparent dark overlay with "מתעדכן..." text + spinner
  // Covers entire screen
  // Ignores pointer events to let underlying content still be visible but not interactive
  // Renders nothing when not resuming
}
```

Add to AppShell's Stack (above offline banner):
```dart
const ResumeOverlay(),
```

### 6. Ensure offline state clears alert data

Per spec: "Do NOT show cached alert data" when offline. In the connectivity change handler or in the UI:

When `ConnectivityProvider.isOffline` is true:
- StatusScreen should show a message like "ממתין לחיבור..." instead of alert data
- OR: AlertsProvider should clear its data on connectivity loss

Simplest approach: In the StatusScreen, when offline, override the alerts list with an "offline" message:
```dart
if (connectivityProvider.isOffline) {
  return Center(child: Text('ממתין לחיבור לאינטרנט...'));
}
```

### 7. Tests

#### Widget tests (`test/widget/`)

**`test/widget/offline_banner_test.dart`**:
- Banner visible when ConnectivityProvider.isOffline == true
- Banner hidden when ConnectivityProvider.isOffline == false
- Banner shows correct Hebrew text "אין חיבור לאינטרנט"
- Banner has orange/amber background

**`test/widget/resume_overlay_test.dart`**:
- Overlay visible when AlertsProvider.isResuming == true
- Overlay hidden when AlertsProvider.isResuming == false
- Overlay shows "מתעדכן..." text
- Overlay has semi-transparent background

**`test/widget/status_screen_error_test.dart`**:
- Status screen shows loading spinner when AlertsProvider.isLoading == true
- Status screen shows error message when AlertsProvider.errorMessage != null
- Status screen shows "ממתין לחיבור..." when offline
- Error indicator appears below status card when errorMessage set

#### Unit tests (`test/unit/`)

**`test/unit/alerts_provider_resume_test.dart`**:
- `setResuming(true)` sets isResuming
- `onAlertData()` clears isResuming
- `onError()` does NOT clear isResuming (keep showing overlay until success)

### 8. Integration test addition

Add a test to `integration_test/app_test.dart`:

**`testWidgets('offline banner appears when offline')`**:
- This is tricky without real network control. Skip for now — the widget tests cover the banner behavior. Revisit when we add network simulation capability.

## Verification

```bash
make check   # format + analyze + unit + integration tests
```

All existing 280+ tests must still pass, plus new tests.

## Files to create:
- `lib/presentation/widgets/offline_banner.dart`
- `lib/presentation/widgets/resume_overlay.dart`
- `test/widget/offline_banner_test.dart`
- `test/widget/resume_overlay_test.dart`
- `test/widget/status_screen_error_test.dart`
- `test/unit/alerts_provider_resume_test.dart`

## Files to modify:
- `lib/presentation/app_shell.dart` — add Stack with offline banner + resume overlay
- `lib/presentation/screens/status_screen.dart` — loading/error/offline states
- `lib/presentation/providers/alerts_provider.dart` — add isResuming state
- `lib/main.dart` — set isResuming on app resume
