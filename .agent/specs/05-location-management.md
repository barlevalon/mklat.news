# Location Management Specification

## Overview

Users can save multiple locations with custom labels. One location is designated as "primary" and drives the main status display. Location management is accessed via a modal/bottom sheet from the Status Screen.

## Saved Locations Model

```dart
class SavedLocation {
  final String id;              // UUID
  final String orefName;        // Exact OREF location name (matches label_he)
  final String customLabel;     // User's label (e.g., "בית")
  final bool isPrimary;
  final int? shelterTimeSec;    // Cached from OrefLocation.shelterTimeSec
}
```

> **Canonical definition**: See `01-data-layer.md` for the authoritative model. `shelterTimeSec` is nullable because the fallback location list may not include shelter times.

## Location Management Modal

### Layout

```
┌─────────────────────────────────────┐
│  המיקומים שלי                  [+]  │  ← Header + Add button
│ ─────────────────────────────────── │
│  ┌─────────────────────────────────┐│
│  │ ⭐ בית                          ││  ← Primary indicator + label
│  │    תל אביב - מרכז               ││  ← OREF name
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ ○ עבודה                         ││
│  │    הרצליה - מערב                ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ ○ הורים                         ││
│  │    באר שבע - דרום               ││
│  └─────────────────────────────────┘│
│ ─────────────────────────────────── │
│  [ הוסף מיקום ]                     │  ← Add button (alternative)
└─────────────────────────────────────┘
```

### Interactions

**Tap Location**:
- Sets as primary location
- Updates ⭐ indicator
- Closes modal
- Resets alert state to ALL_CLEAR

**Long Press / Swipe Location**:
- Reveals edit/delete options
- Or: Opens edit modal

**Tap [+] or "הוסף מיקום"**:
- Opens Add Location flow

### Empty State

If no saved locations:
```
┌─────────────────────────────────────┐
│  המיקומים שלי                       │
│ ─────────────────────────────────── │
│                                     │
│     אין מיקומים שמורים              │
│                                     │
│  [ הוסף מיקום ראשון ]               │
│                                     │
└─────────────────────────────────────┘
```

## Add Location Flow

### Layout

```
┌─────────────────────────────────────┐
│  הוסף מיקום                    [✕]  │  ← Header + Close
│ ─────────────────────────────────── │
│                                     │
│  שם מותאם (לא חובה)                 │  ← Label (optional)
│  ┌─────────────────────────────────┐│
│  │ בית                             ││  ← Text input
│  └─────────────────────────────────┘│
│                                     │
│  בחר אזור                           │  ← Required
│  ┌─────────────────────────────────┐│
│  │ 🔍 חיפוש...                     ││  ← Search input
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ תל אביב - דרום                  ││
│  │ תל אביב - מזרח                  ││
│  │ תל אביב - מרכז            [✓]  ││  ← Selected
│  │ תל אביב - עבר הירקון            ││
│  │ ...                             ││
│  └─────────────────────────────────┘│
│                                     │
│  [ ] הגדר כמיקום ראשי               │  ← Checkbox
│                                     │
│  [ שמור ]                           │  ← Save button
└─────────────────────────────────────┘
```

### Search Functionality

- Search filters the OREF location list
- Case-insensitive Hebrew search
- Shows matching locations as user types
- Selected locations stay visible at top

### Validation

- OREF location is required
- Custom label is optional (defaults to OREF name)
- Cannot add duplicate OREF locations

### Save Behavior

1. Create SavedLocation object
2. If "set as primary" checked, update primary
3. Persist to local storage
4. Close modal
5. Update UI

## Edit Location Flow

### Access
- Long press on location in list
- Or swipe to reveal edit button
- Or tap "..." menu on location

### Layout

```
┌─────────────────────────────────────┐
│  ערוך מיקום                    [✕]  │
│ ─────────────────────────────────── │
│                                     │
│  שם מותאם                           │
│  ┌─────────────────────────────────┐│
│  │ בית                             ││
│  └─────────────────────────────────┘│
│                                     │
│  אזור                               │
│  תל אביב - מרכז                     │  ← Read-only display
│                                     │
│  [ ] מיקום ראשי                     │
│                                     │
│  [ שמור ]          [ מחק ]          │
└─────────────────────────────────────┘
```

### Delete Confirmation

When delete tapped:
- Show confirmation dialog: "למחוק את 'בית'?"
- Options: "ביטול" / "מחק"
- If deleted location was primary, set next location as primary (or none)

## Location List Data

### Source
- Fetch from OREF Districts API on app start
- Cache locally for offline access
- ~1,486 locations (validated 2026-03-04)

### Fallback
- If Districts API fails, try `cities_heb.json` backup (split pipe-separated labels)
- If both fail, use hardcoded fallback list (~1,486 location names)
- See `01-data-layer.md` for full fallback chain

### Sorting
- Alphabetical by Hebrew name
- Selected/saved locations shown first in search

## Deep Linking

Support deep links to pre-select a location:
- Format: `mklat://location/{encoded_location_name}`
- Example: `mklat://location/%D7%AA%D7%9C%20%D7%90%D7%91%D7%99%D7%91`
- Behavior: Opens app, opens Add Location with location pre-selected

## Persistence

### Storage Format
```json
{
  "locations": [
    {
      "id": "uuid-1",
      "orefName": "תל אביב - מרכז",
      "customLabel": "בית",
      "isPrimary": true,
      "shelterTimeSec": 90
    }
  ]
}
```

### Storage Key
- SharedPreferences: `mklat_saved_locations`

## Acceptance Criteria

- [ ] Location management modal displays all saved locations
- [ ] Primary location indicated with ⭐
- [ ] Tap location sets it as primary
- [ ] Add location flow allows search and selection from OREF list
- [ ] Custom label is optional, defaults to OREF name
- [ ] Edit location allows changing label
- [ ] Delete location shows confirmation
- [ ] Locations persist across app restarts
- [ ] Deep linking pre-selects location in add flow
- [ ] Empty state shows when no locations saved
- [ ] Search filters location list correctly

## References

Existing web app implementation:
- `public/script.js` - Location management (lines 549-741)
- `src/config/constants.js` - Fallback location list
