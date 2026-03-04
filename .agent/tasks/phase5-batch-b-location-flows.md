# Phase 5 Batch B: Location Management Flows

## Context

Implement the location management modal, add location flow, and edit location flow. These are opened from the Status Screen's location selector button and secondary locations row.

Read these before starting:
- `.agent/specs/05-location-management.md` — full spec with layouts and interactions
- `lib/presentation/providers/location_provider.dart` — LocationProvider CRUD
- `lib/data/models/saved_location.dart` — SavedLocation model
- `lib/data/models/oref_location.dart` — OrefLocation model (from districts)
- `lib/data/services/oref_districts_service.dart` — districts service (fetches location list)
- `lib/presentation/widgets/location_selector_button.dart` — needs onTap wiring

## Architecture

```
lib/presentation/screens/
├── location_management_modal.dart   # Bottom sheet showing saved locations
├── add_location_screen.dart         # Search + select + save new location
└── edit_location_screen.dart        # Edit label, delete location
```

---

## Task 1: Location Management Modal

**File:** `lib/presentation/screens/location_management_modal.dart`

A bottom sheet showing the user's saved locations list.

```
┌─────────────────────────────────────┐
│  המיקומים שלי                  [+]  │
│ ─────────────────────────────────── │
│  ⭐ בית                             │
│     תל אביב - מרכז                  │
│  ○ עבודה                            │
│     הרצליה - מערב                   │
│  ○ הורים                            │
│     באר שבע - דרום                  │
│ ─────────────────────────────────── │
│  [ הוסף מיקום ]                     │
└─────────────────────────────────────┘
```

Design:
- Uses `showModalBottomSheet` with `DraggableScrollableSheet`
- Header: "המיקומים שלי" + add button [+]
- List of saved locations:
  - Primary: ⭐ icon + custom label (bold) + OREF name underneath
  - Others: ○ icon + custom label + OREF name
- **Tap location**: sets as primary via `locationProvider.setPrimary(id)`, pops modal
- **Long press location**: opens edit screen
- **Tap [+] or "הוסף מיקום"**: pushes add location screen
- **Empty state**: "אין מיקומים שמורים" + "הוסף מיקום ראשון" button

Show it as a helper function:
```dart
void showLocationManagementModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const LocationManagementModal(),
  );
}
```

---

## Task 2: Add Location Screen

**File:** `lib/presentation/screens/add_location_screen.dart`

Full-screen modal (pushed on Navigator) for adding a new location.

```
┌─────────────────────────────────────┐
│  הוסף מיקום                    [✕]  │
│ ─────────────────────────────────── │
│  שם מותאם (לא חובה)                 │
│  ┌─────────────────────────────────┐│
│  │ placeholder: בית, עבודה...      ││
│  └─────────────────────────────────┘│
│  בחר אזור                           │
│  ┌─────────────────────────────────┐│
│  │ 🔍 חיפוש...                     ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ list of matching locations      ││
│  │ tap to select (checkmark)       ││
│  └─────────────────────────────────┘│
│  [✓] הגדר כמיקום ראשי               │
│  [ שמור ]                           │
└─────────────────────────────────────┘
```

Design:
- Custom label: `TextField` with placeholder "בית, עבודה..."
- Search: `TextField` that filters the OREF location list
- Location list: `ListView` of OrefLocation items
  - Filtered by search query (case-insensitive Hebrew search on `name`)
  - Tap to select (show checkmark ✓)
  - Only one can be selected
- "הגדר כמיקום ראשי" checkbox
- "שמור" button: creates `SavedLocation.create(...)`, calls `locationProvider.addLocation()`, pops

**Loading the location list:**
The OREF districts list needs to be fetched. Since `OrefDistrictsService` requires `HttpClient`, and we don't have direct access from the widget, we need to either:
- (a) Add a districts fetch to a provider, or
- (b) Create the service instance locally

Best approach: Add a simple `DistrictsProvider` or just add a `List<OrefLocation> availableLocations` to the `LocationProvider` with a `loadDistricts()` method.

**Simpler approach:** Add to `LocationProvider`:
```dart
List<OrefLocation> _availableLocations = [];
List<OrefLocation> get availableLocations => _availableLocations;

Future<void> loadAvailableLocations(OrefDistrictsService districtsService) async {
  _availableLocations = await districtsService.fetchDistricts();
  notifyListeners();
}
```

Then call it from `main.dart`'s `_initializeServices()` after creating the districts service:
```dart
final districtsService = OrefDistrictsService(_httpClient);
_locationProvider.loadAvailableLocations(districtsService);
```

**Validation:**
- Cannot save without selecting an OREF location
- Cannot add duplicate (same orefName already saved) — `addLocation` handles this but show user feedback

---

## Task 3: Edit Location Screen

**File:** `lib/presentation/screens/edit_location_screen.dart`

Modal/screen for editing an existing saved location.

```
┌─────────────────────────────────────┐
│  ערוך מיקום                    [✕]  │
│ ─────────────────────────────────── │
│  שם מותאם                           │
│  ┌─────────────────────────────────┐│
│  │ בית                             ││
│  └─────────────────────────────────┘│
│  אזור                               │
│  תל אביב - מרכז (read-only)         │
│  [✓] מיקום ראשי                     │
│  [ שמור ]          [ מחק ]          │
└─────────────────────────────────────┘
```

Design:
- Pre-populated with existing SavedLocation data
- Label: editable `TextField`
- OREF name: read-only display
- Primary checkbox
- Save button: calls `locationProvider.updateLocation()`, pops
- Delete button: shows confirmation dialog, calls `locationProvider.deleteLocation()`, pops

**Delete confirmation:**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('מחק מיקום'),
    content: Text("למחוק את '${location.displayLabel}'?"),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
      TextButton(
        onPressed: () {
          locationProvider.deleteLocation(location.id);
          Navigator.pop(context); // close dialog
          Navigator.pop(context); // close edit screen
        },
        child: Text('מחק', style: TextStyle(color: Colors.red)),
      ),
    ],
  ),
);
```

---

## Task 4: Wire Location Selector Button

**File:** `lib/presentation/widgets/location_selector_button.dart` (modify)

Add `onTap` that opens the location management modal:
```dart
onTap: () => showLocationManagementModal(context),
```

Import the modal's helper function.

---

## Task 5: Wire Secondary Locations Row

**File:** `lib/presentation/widgets/secondary_locations_row.dart` (modify)

The `onLocationTap` callback is already wired but the caller (StatusScreen) doesn't pass it. Update the `SecondaryLocationsRow` to open the location modal on tap by default:

If `onLocationTap` is null, open the location management modal:
```dart
onTap: () {
  if (onLocationTap != null) {
    onLocationTap!.call(location.orefName);
  } else {
    showLocationManagementModal(context);
  }
},
```

---

## Task 6: Update LocationProvider

**File:** `lib/presentation/providers/location_provider.dart` (modify)

Add available locations support:
```dart
import '../../data/models/oref_location.dart';
import '../../data/services/oref_districts_service.dart';

// Add fields:
List<OrefLocation> _availableLocations = [];
List<OrefLocation> get availableLocations => List.unmodifiable(_availableLocations);

// Add method:
Future<void> loadAvailableLocations(OrefDistrictsService districtsService) async {
  try {
    _availableLocations = await districtsService.fetchDistricts();
    // Sort alphabetically by Hebrew name
    _availableLocations.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  } catch (e) {
    // Non-fatal, list stays empty
  }
}
```

---

## Task 7: Update main.dart

**File:** `lib/main.dart` (modify)

Add districts service creation and loading:
```dart
import 'data/services/oref_districts_service.dart';

// In _initializeServices():
final districtsService = OrefDistrictsService(_httpClient);
_locationProvider.loadAvailableLocations(districtsService);
```

---

## Task 8: Widget Tests

### `test/widget/location_management_modal_test.dart`
- Shows saved locations
- Empty state shows "אין מיקומים שמורים"
- Tap location calls setPrimary

### `test/widget/add_location_screen_test.dart`
- Renders search field
- Renders save button
- Search filters location list

Keep tests simple — use real providers with mock data (set up SharedPreferences.setMockInitialValues, then call provider methods to populate state).

---

## Verification

```bash
flutter analyze
flutter test
```

Both must pass.

## Files to create

1. `lib/presentation/screens/location_management_modal.dart`
2. `lib/presentation/screens/add_location_screen.dart`
3. `lib/presentation/screens/edit_location_screen.dart`
4. `test/widget/location_management_modal_test.dart`
5. `test/widget/add_location_screen_test.dart`

## Files to modify

6. `lib/presentation/widgets/location_selector_button.dart` — wire onTap
7. `lib/presentation/widgets/secondary_locations_row.dart` — default tap to open modal
8. `lib/presentation/providers/location_provider.dart` — add availableLocations
9. `lib/main.dart` — add districts service + loading
