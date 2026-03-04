# Phase 1 Review Fixes

## Context

Phase 1 (commit `92d702b`) implemented the Flutter project foundation: models, constants, alert state enum, and tests. This task fixes issues found during review.

## Task 1: Update .gitignore for Flutter/Dart

**File:** `.gitignore`

Append Flutter/Dart entries to the existing .gitignore (which currently only covers Node.js). Add AFTER the existing content:

```
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
.metadata

# Generated files
*.g.dart
*.freezed.dart
*.mocks.dart

# Platform-specific generated code
android/.gradle/
android/local.properties
android/app/debug/
android/app/profile/
android/app/release/
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec
ios/Runner.xcworkspace/
macos/Flutter/GeneratedPluginRegistrant.swift
linux/flutter/generated_plugin_registrant.cc
linux/flutter/generated_plugin_registrant.h
windows/flutter/generated_plugin_registrant.cc
windows/flutter/generated_plugin_registrant.h

# Pubspec lock - include for apps (not libraries)
# pubspec.lock

# Miscellaneous
*.iml
```

**Important:** Do NOT remove any existing entries. Only append.

Also: `pubspec.lock` should be committed for apps (Flutter convention), so do NOT gitignore it. The comment above is just a note.

---

## Task 2: Add `desc` field to Alert model

**File:** `lib/data/models/alert.dart`

Add a `desc` field (nullable String) to the `Alert` class. This captures the instruction text from the OREF Alerts.json `desc` field (e.g., "היכנסו למרחב המוגן").

### Changes:
1. Add field: `final String? desc;`
2. Add to constructor: `this.desc,`
3. Add to the existing `fromJson` (internal serialization): `desc: json['desc'] as String?,`
4. Add to `toJson`: `'desc': desc,`
5. Do NOT include `desc` in `==` or `hashCode` (identity is still id + location + time)

---

## Task 3: Add API factory constructors to Alert

**File:** `lib/data/models/alert.dart`

Add two factory constructors for mapping directly from raw OREF API JSON.

### `Alert.fromOrefActive(Map<String, dynamic> alertJson, String locationName)`

For creating an Alert from a single location entry in the Alerts.json response. The Alerts.json response is a single object like:
```json
{
  "id": "133721700000000000",
  "cat": 1,
  "title": "ירי רקטות וטילים",
  "desc": "היכנסו למרחב המוגן",
  "data": ["תל אביב - מרכז העיר", "חיפה - מערב"]
}
```

The caller iterates over `data[]` and calls this factory once per location. The factory receives:
- `alertJson`: the full alert JSON object
- `locationName`: one entry from the `data` array

Mapping:
- `id` = `"${alertJson['id']}_${locationName.hashCode}"` (synthesize unique per-location ID)
- `location` = `locationName`
- `title` = `alertJson['title']`
- `desc` = `alertJson['desc']` (nullable)
- `time` = `DateTime.now()` (Alerts.json has no timestamp)
- `category` = `alertJson['cat']`

### `Alert.fromOrefHistory(Map<String, dynamic> json)`

For creating an Alert from a single AlertsHistory.json array entry:
```json
{
  "alertDate": "2026-03-04 14:09:32",
  "title": "ירי רקטות וטילים",
  "data": "גבעת הראל",
  "category": 1
}
```

Mapping:
- `id` = synthesize from `"${json['alertDate']}_${json['data']}"` (no native id field)
- `location` = `json['data']` (single string, NOT array)
- `title` = `json['title']`
- `desc` = `null` (history entries don't have desc)
- `time` = parse `json['alertDate']` -- format is `"YYYY-MM-DD HH:MM:SS"` in Israel timezone. Parse it and store as-is for now (timezone-aware parsing is a Phase 2 concern when the service layer is built). Use `DateTime.parse(json['alertDate'])`.
- `category` = `json['category']`

---

## Task 4: Add API factory constructor to OrefLocation

**File:** `lib/data/models/oref_location.dart`

### `OrefLocation.fromDistricts(Map<String, dynamic> json)`

For parsing a GetDistricts.aspx response entry:
```json
{
  "label": "אבו גוש",
  "value": "6657AD46BF8FA430B022FF282B7A804B",
  "id": "511",
  "areaid": 5,
  "areaname": "בית שמש",
  "label_he": "אבו גוש",
  "migun_time": 90
}
```

Mapping:
- `name` = `json['label_he'] ?? json['label']` (prefer `label_he`, fallback to `label`)
- `id` = `json['id'].toString()` (may come as int or string)
- `hashId` = `json['value']`
- `areaId` = `json['areaid']` (lowercase in API)
- `areaName` = `json['areaname']` (lowercase in API)
- `shelterTimeSec` = `json['migun_time']` (nullable)

### `OrefLocation.fromCitiesFallback(Map<String, dynamic> json)`

For parsing cities_heb.json fallback entries. The format uses pipe-separated labels:
```json
{
  "label": "אבו גוש|Abu Ghosh|أبو غوش",
  "value": "6657AD46BF8FA430B022FF282B7A804B",
  "id": "511",
  "areaid": 5,
  "areaname": "בית שמש"
}
```

Mapping:
- `name` = `json['label'].toString().split('|').first` (Hebrew is first segment)
- `id` = `json['id'].toString()`
- `hashId` = `json['value']`
- `areaId` = `json['areaid']`
- `areaName` = `json['areaname']`
- `shelterTimeSec` = `null` (cities_heb.json doesn't have migun_time)

---

## Task 5: Fix OrefLocation.shelterTimeDisplay Hebrew grammar

**File:** `lib/data/models/oref_location.dart`

The current `shelterTimeDisplay` getter produces grammatically incorrect Hebrew:
- `60` → `"1 דקות"` (wrong, should be `"דקה"`)
- `90` → `"1:30 דקות"` (should be `"דקה וחצי"`)

Fix the getter to handle Hebrew singular/plural correctly:

```dart
String? get shelterTimeDisplay {
  if (shelterTimeSec == null) return null;
  if (shelterTimeSec == 0) return 'מיידי';
  if (shelterTimeSec! < 60) return '$shelterTimeSec שניות';
  if (shelterTimeSec == 60) return 'דקה';
  if (shelterTimeSec == 90) return 'דקה וחצי';
  if (shelterTimeSec! >= 120) {
    final minutes = shelterTimeSec! ~/ 60;
    return '$minutes דקות';
  }
  // Fallback for other values (unlikely given OREF data: 0, 15, 30, 45, 60, 90)
  final minutes = shelterTimeSec! ~/ 60;
  final seconds = shelterTimeSec! % 60;
  if (seconds == 0) return '$minutes דקות';
  return '$minutes:${seconds.toString().padLeft(2, '0')} דקות';
}
```

Also fix the `15 שניות` case -- in Hebrew 15 seconds is fine as-is since שניות is the general plural form used for all numbers > 1 in casual usage. Keep it.

---

## Task 6: Update existing tests and add new tests

### Update `test/unit/alert_test.dart`:

1. Add test for `desc` field in existing serialization tests
2. Add test group for `Alert.fromOrefActive`:
   - Test basic mapping from Alerts.json format
   - Test that `cat` maps to `category`
   - Test that `desc` is captured
   - Test that time is set (DateTime.now())
   - Test ID synthesis is unique per location
3. Add test group for `Alert.fromOrefHistory`:
   - Test basic mapping from AlertsHistory.json format
   - Test `alertDate` parsing
   - Test `data` (string) maps to `location`
   - Test `category` maps correctly
   - Test ID synthesis from alertDate + data
   - Test desc is null

### Update `test/unit/oref_location_test.dart`:

1. Add test group for `OrefLocation.fromDistricts`:
   - Test with complete Districts JSON entry
   - Test `label_he` → `name`, `value` → `hashId`, `areaid` → `areaId`, `areaname` → `areaName`, `migun_time` → `shelterTimeSec`
   - Test fallback when `label_he` is missing (use `label`)
   - Test `id` as int vs string
2. Add test group for `OrefLocation.fromCitiesFallback`:
   - Test pipe-separated label extraction (Hebrew first)
   - Test that `shelterTimeSec` is null
3. Update `shelterTimeDisplay` tests:
   - Fix expected values: `60` → `'דקה'`, `90` → `'דקה וחצי'`

---

## Verification

After all changes, run:
```bash
flutter analyze
flutter test
```

Both must pass with zero errors. Do NOT leave any failing tests.

---

## Files to modify (summary)

1. `.gitignore` - append Flutter entries
2. `lib/data/models/alert.dart` - add `desc` field, add `fromOrefActive`, add `fromOrefHistory`
3. `lib/data/models/oref_location.dart` - add `fromDistricts`, add `fromCitiesFallback`, fix `shelterTimeDisplay`
4. `test/unit/alert_test.dart` - update for `desc`, add API factory tests
5. `test/unit/oref_location_test.dart` - add API factory tests, fix shelterTimeDisplay assertions
