# Status Screen Specification

## Overview

The Status Screen is the primary screen of the app. It provides a glanceable view of:
1. Primary location alert status (large, prominent)
2. Secondary locations status (compact row)
3. Nationwide summary (during large events)
4. Recent alerts list (scrollable, paginated)

## Layout

```
┌─────────────────────────────────────┐
│ ┌─────────────────────────────────┐ │
│ │  [📍 בית ▼]                     │ │  ← Location selector button
│ │                                 │ │
│ │       🟢 אין התרעות             │ │  ← Primary status (large)
│ │                                 │ │
│ │   (or: 🚨 צבע אדום              │ │
│ │    היכנסו למרחב המוגן           │ │
│ │    02:34)                       │ │  ← Elapsed timer
│ └─────────────────────────────────┘ │
│                                     │
│  🟢 עבודה  🔴 הורים                 │  ← Secondary locations
│                                     │
│  15 באזורים שלך • 1,200 ארצי       │  ← Nationwide summary
│                                     │
│  ──── התרעות אחרונות ────           │
│  ┌─────────────────────────────────┐│
│  │ 🚨 צבע אדום                     ││
│  │ באר שבע - דרום                  ││
│  │ 10:32                           ││
│  └─────────────────────────────────┘│
│  ...                                │
│  [ טען עוד ]                        │  ← Load more button
│                                     │
│              ● ○                    │  ← Page indicator
└─────────────────────────────────────┘
```

## Components

### Primary Status Card

The dominant visual element. Displays:

| State | Icon | Text | Instruction | Timer |
|-------|------|------|-------------|-------|
| ALL_CLEAR | 🟢 (or ●) | אין התרעות | — | — |
| ALERT_IMMINENT | ⚠️ | התרעה צפויה | התרעות צפויות בדקות הקרובות | — |
| RED_ALERT | 🚨 | צבע אדום | היכנסו למרחב המוגן | MM:SS elapsed |
| WAITING_CLEAR | ◷ | המתינו במרחב המוגן | ממתינים לאישור יציאה | MM:SS elapsed |
| JUST_CLEARED | ✅ | האירוע הסתיים | ניתן לצאת מהמרחב המוגן | "לפני X דקות" |

**Visual Treatment**:
- ALL_CLEAR: Calm colors (green/blue)
- ALERT_IMMINENT: Warning colors (yellow/orange)
- RED_ALERT: Urgent colors (red), possibly pulsing animation
- WAITING_CLEAR: Caution colors (orange/yellow)
- JUST_CLEARED: Relief colors (green)

**Location Selector Button**:
- Shows current primary location label (custom name or OREF name)
- Tap opens Location Management modal
- If no location selected: "בחר אזור"

### Secondary Locations Row

Compact horizontal display of non-primary saved locations:

```
🟢 עבודה  🔴 הורים  🟢 סבתא
```

- Icon indicates alert status for that location
- Show location's custom label
- Scrollable horizontally if many locations
- Tap opens Location Management modal
- Hidden if user has only one saved location

**Status Icons**:
- 🟢 (green dot): No alert
- 🔴 (red dot): Active alert
- 🟡 (yellow dot): Alert imminent or waiting clear

### Nationwide Summary

Shows during active events:

```
15 התרעות באזורים שלך • 1,200 ברחבי הארץ
```

- Only visible when there are active alerts
- "באזורים שלך" = alerts in user's saved locations
- "ברחבי הארץ" = total active alerts nationwide
- Hidden when no active alerts

### Recent Alerts List

Scrollable list of recent alerts:

**Alert Item Structure**:
```
┌─────────────────────────────────────┐
│ 🚨 צבע אדום                         │  ← Type with icon
│ באר שבע - דרום                      │  ← Location
│ 10:32                               │  ← Time (relative or absolute)
└─────────────────────────────────────┘
```

**Alert Types & Icons**:
- 🚨 צבע אדום (red alert)
- ⚠️ התרעה צפויה (imminent)
- ✅ האירוע הסתיים (cleared)
- 📍 (historical, no specific type)

**Filtering**:
- Show alerts for user's saved locations only
- Plus nationwide summary count for context

**Pagination**:
- Load 20-50 items initially
- "טען עוד" button at bottom
- Load next batch on tap

**Empty State**:
- If no saved locations: "הוסף מיקום כדי לראות התרעות"
- If no alerts for saved locations: "✅ אין התרעות באזורים שלך"

## Interactions

### Tap Primary Status Card
- Opens Location Management modal (same as tapping location button)

### Tap Secondary Location
- Opens Location Management modal

### Pull to Refresh
- Triggers immediate data fetch
- Shows refresh indicator
- Optional: Can rely on auto-polling instead

### Swipe Left
- Navigates to News Screen

## Acceptance Criteria

- [ ] Primary status card displays correct state, icon, text, instruction
- [ ] Timer updates every second during RED_ALERT and WAITING_CLEAR
- [ ] Location selector button shows primary location label
- [ ] Secondary locations row shows all non-primary locations with status
- [ ] Nationwide summary shows during active events, hidden otherwise
- [ ] Alerts list shows only alerts for saved locations
- [ ] Alerts list paginates with "load more" button
- [ ] Empty states display appropriate messages
- [ ] Swipe left navigates to News Screen
- [ ] Screen is fully RTL compatible

## References

Existing web app implementation:
- `public/index.html` - UI structure (lines 27-83)
- `public/script.js` - State display logic (lines 903-980)
- `public/style.css` - Visual styling
