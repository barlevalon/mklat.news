# Product Overview: mklat.news Mobile App

## Vision

**mklat.news** is a "situation room" companion app for Israeli emergency alerts. It is NOT a push notification app—users already have those. It's the app you open *after* being alerted to get:

1. **Immediate relevance check**: "Is this alert for my location?"
2. **Status tracking**: "Am I still in alert? Can I leave the shelter?"
3. **Context**: "What's happening? What are the news saying?"
4. **Clear signal**: "The event is over, you're clear"

## Why Mobile?

The existing web app at mklat.news is non-functional in production because OREF (Israeli Home Front Command) APIs block cloud server IPs. A mobile app polling directly from user devices (consumer IPs) bypasses this limitation entirely.

## Tech Stack

- **Framework**: Flutter (cross-platform iOS + Android)
- **Language**: Dart
- **Architecture**: Serverless—app polls APIs directly, no backend required
- **State Management**: Provider (or Riverpod)
- **Storage**: Local only (SharedPreferences or Hive)

## Design Principles

1. **Glanceable**: Primary status visible instantly, no scrolling required
2. **Simple**: Minimal UI, clear information hierarchy
3. **Reliable**: Graceful error handling, clear offline indication
4. **Fast**: 2-second polling for alerts, responsive UI
5. **Accessible**: Legible text, clear contrast, RTL support

## Constraints

- **Foreground only**: No background fetching, no push notifications
- **No server**: All API calls from device directly
- **Local storage**: No accounts, no sync, no cloud
- **Hebrew-first**: RTL layout, Hebrew default (multi-lang if feasible)

## Target Users

Israeli residents who:
- Already have official alert apps (Tzeva Adom, Pikud HaOref)
- Want a cleaner, faster way to check alert status for their specific locations
- Want aggregated news context during security events

## Success Criteria

The app is successful when a user can:
1. Open the app and immediately see if their location is under alert
2. Track the alert lifecycle from RED_ALERT to ALL_CLEAR
3. See relevant news about the situation
4. Trust the app to clearly indicate when data is stale or unavailable
