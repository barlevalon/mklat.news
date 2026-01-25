# News Screen Specification

## Overview

The News Screen displays aggregated breaking news from multiple Israeli news sources. It is the secondary screen, accessible by swiping left from the Status Screen.

## Layout

```
┌─────────────────────────────────────┐
│  מבזקי חדשות                        │  ← Header
│ ─────────────────────────────────── │
│  ┌─────────────────────────────────┐│
│  │ [Y] פיצוץ נשמע באזור הדרום...   ││  ← Source icon + headline
│  │ תקציר קצר של הכתבה אם קיים...   ││  ← Description (truncated)
│  │ Ynet • לפני 5 דקות              ││  ← Source name + time
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ [M] צה"ל: יירטנו רקטות שנורו... ││
│  │ Maariv • לפני 12 דקות           ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ [W] דיווח ראשוני: נזק קל...     ││
│  │ Walla • לפני 18 דקות            ││
│  └─────────────────────────────────┘│
│  ...                                │
│                                     │
│              ○ ●                    │  ← Page indicator (News active)
└─────────────────────────────────────┘
```

## Components

### Header

Simple header with title:
- "מבזקי חדשות" (Breaking News)
- No back button (swipe right to return)
- Optional: Refresh button

### News List

Scrollable list of news items, sorted by publication date (newest first).

**News Item Structure**:
```
┌─────────────────────────────────────┐
│ [icon] Headline text here           │
│ Description preview text truncated  │
│ Source • לפני X דקות                │
└─────────────────────────────────────┘
```

**Fields**:
- **Source Icon**: Favicon or letter icon (Y, M, W, H)
- **Headline**: Full title, may wrap to 2 lines
- **Description**: Optional, truncated to ~100 chars with "..."
- **Source Name**: Ynet, Maariv, Walla, Haaretz
- **Time**: Relative time ("לפני 5 דקות", "לפני שעה")

**Source Icons**:
- Use favicons fetched from: `https://www.google.com/s2/favicons?domain={domain}&sz=16`
- Fallback: First letter of source name in colored circle

### Empty State

If no news available:
- "אין מבזקים חדשים"

### Error State

If news fetch failed:
- "שגיאה בטעינת חדשות"
- Still show cached items if available

## Interactions

### Tap News Item
- Opens news link in system browser
- Use `url_launcher` package

### Swipe Right
- Navigates back to Status Screen

### Pull to Refresh
- Triggers immediate news fetch
- Shows refresh indicator

## News Aggregation Logic

### Sorting
- All news items from all sources combined
- Sorted by `pubDate` descending (newest first)

### Deduplication
- Optional: Detect similar headlines across sources
- For MVP: Show all items, allow duplicates

### Filtering (Deferred)
- Future: Filter by keywords (security, alerts, etc.)
- MVP: Show all news without filtering

## Time Formatting

```dart
String formatRelativeTime(DateTime pubDate) {
  final diff = DateTime.now().difference(pubDate);
  
  if (diff.inMinutes < 1) return 'עכשיו';
  if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דקות';
  if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
  
  return pubDate.toLocal().format('dd/MM HH:mm');
}
```

## Acceptance Criteria

- [ ] News list displays items from all 4 sources
- [ ] Items sorted by date (newest first)
- [ ] Each item shows source icon, headline, description, source name, time
- [ ] Tap item opens link in system browser
- [ ] Swipe right returns to Status Screen
- [ ] Pull to refresh triggers news fetch
- [ ] Empty state displays when no news
- [ ] Error state displays on fetch failure
- [ ] Screen is fully RTL compatible

## References

Existing web app implementation:
- `public/script.js` - News rendering (lines 273-326)
- `public/index.html` - News panel structure (lines 85-101)
