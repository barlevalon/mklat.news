# Deferred Features Specification

> **STATUS: DEFERRED**
> These features are documented for future reference but are NOT part of the MVP.
> Do not implement these features until explicitly prioritized.

## GPS-Based Location Detection

### Description
Automatically detect user's current location and suggest matching OREF areas.

### Requirements (When Prioritized)
- Request location permission
- Reverse geocode coordinates to city name
- Fuzzy match city name to OREF location list
- Handle edge cases: city borders, GPS inaccuracy
- "Use my location" button in Add Location flow

### Complexity
Medium-high. Requires geocoding database or API, permission handling, accuracy considerations.

---

## Multi-Language Support

### Description
Support for Hebrew, English, Arabic, and Russian.

### Requirements (When Prioritized)
- Extract all strings to ARB files
- Implement language selector in settings
- Or: Auto-detect from system locale
- RTL/LTR layout switching for English

### Complexity
Medium if planned from start. Use Flutter's intl package.

---

## Analytics

### Description
Track usage patterns to understand user behavior.

### Requirements (When Prioritized)
- Anonymous usage events (screens viewed, features used)
- No personal data collection
- Crash reporting integration
- Options: Firebase Analytics, PostHog, Mixpanel

### Complexity
Low-medium. SDK integration, privacy policy update.

---

## Background Fetching

### Description
Continue polling for alerts when app is backgrounded.

### Requirements (When Prioritized)
- Background task scheduling (WorkManager on Android, BGTaskScheduler on iOS)
- Battery optimization considerations
- Local notifications when alert detected in background

### Complexity
High. Platform-specific implementations, OS restrictions, battery impact.

### Note
Conflicts with product vision of "not a push notification app."

---

## Family Mode / Multiple Primaries

### Description
Track multiple "primary" locations simultaneously, each with their own status display.

### Requirements (When Prioritized)
- Multiple cards on Status Screen, one per "family member"
- Each card has independent state machine
- Configurable names: "אני", "אמא", "אבא", etc.

### Complexity
Medium. State management complexity, UI layout challenges.

---

## News Filtering

### Description
Filter news to show only security-related items.

### Requirements (When Prioritized)
- Keyword filtering (התרעה, טיל, יירוט, etc.)
- Toggle to show all vs filtered
- Possibly: LLM-based relevance scoring

### Complexity
Low (keyword) to Medium (LLM-based).

---

## Alert Export / History

### Description
Export alert history to CSV or share functionality.

### Requirements (When Prioritized)
- Date range selector
- Export to CSV file
- Share via system share sheet

### Complexity
Low.

---

## Home Screen Widgets

### Description
iOS/Android home screen widgets showing current status.

### Requirements (When Prioritized)
- Native widget implementations (WidgetKit for iOS, App Widgets for Android)
- Background refresh for widget data
- Minimal battery impact

### Complexity
High. Platform-specific, separate from main app codebase.

---

## Dark Mode

### Description
Dark color theme option.

### Requirements (When Prioritized)
- Dark theme color palette
- Toggle in settings or follow system preference
- Ensure contrast ratios for accessibility

### Complexity
Low-medium. Theme definition, testing all screens.

---

## Accessibility Enhancements

### Description
Full VoiceOver/TalkBack support, dynamic font sizing.

### Requirements (When Prioritized)
- Semantic labels on all interactive elements
- Dynamic Type support (iOS) / Font scaling (Android)
- High contrast mode option
- Screen reader testing

### Complexity
Medium. Requires testing with actual assistive technologies.
