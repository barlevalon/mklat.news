# Error Handling Specification

## Overview

The app must gracefully handle various error states while ensuring users are never misled about the currency of safety-critical information.

## Guiding Principle

**Never show stale data as current.** If data cannot be verified as fresh, clearly indicate uncertainty to the user.

## Error States

### Offline State

**Detection**:
- Use connectivity_plus package to monitor network status
- Also detect via failed API calls

**Display**:
- Prominent banner at top of screen: "אין חיבור לאינטרנט"
- Banner color: Orange/yellow warning color
- Do NOT show cached alert data (safety risk)
- Show cached news items with "לא מעודכן" indicator (optional)

**Recovery**:
- Automatically retry when connection restored
- Remove banner when data successfully fetched

### API Errors

**OREF Current Alerts Failure**:
- Show error indicator in status area
- Message: "שגיאה בטעינת התרעות"
- Continue polling, auto-recover when successful
- Do NOT show cached data as current

**OREF Historical Alerts Failure**:
- Show alerts list with reduced data
- Message in list: "היסטוריה לא זמינה"
- Primary status still works if current alerts succeed

**OREF Districts Failure**:
- Use cached/fallback location list
- No user-visible error (silent fallback)
- Log error for debugging

**RSS Feed Failures**:
- Show news from successful feeds
- If all feeds fail: "שגיאה בטעינת חדשות"
- If some feeds fail: Show available news, no error message

### Loading States

**Initial Load**:
- Show loading spinner: "טוען..."
- Centered in content area
- Disable interactions until loaded

**App Resume**:
- Show overlay: "מתעדכן..."
- Semi-transparent overlay over previous content
- Remove when fresh data arrives

**Pull to Refresh**:
- Standard pull-to-refresh indicator
- Platform-native behavior

**Load More (Pagination)**:
- Show loading indicator at bottom of list
- Keep existing items visible

### No Data States

**No Saved Locations**:
- Status screen: "הוסף מיקום כדי לראות התרעות רלוונטיות"
- Show "הוסף מיקום" button prominently

**No Alerts for Saved Locations**:
- "✅ אין התרעות באזורים שלך"
- Positive/calm styling

**No News**:
- "אין מבזקים חדשים"
- Neutral styling

## Error Banner Component

```
┌─────────────────────────────────────┐
│ ⚠️  אין חיבור לאינטרנט              │
└─────────────────────────────────────┘
```

- Fixed position at top of screen
- Does not push content down (overlays)
- Dismissable: No (auto-dismisses on recovery)
- Color: Warning (orange/yellow background)

## Error Messages (Hebrew)

| Condition | Message |
|-----------|---------|
| Offline | אין חיבור לאינטרנט |
| Alerts fetch failed | שגיאה בטעינת התרעות |
| History fetch failed | היסטוריה לא זמינה |
| News fetch failed | שגיאה בטעינת חדשות |
| Location list failed | (silent, use fallback) |
| General error | שגיאה, נסה שוב |

## Retry Logic

### Automatic Retry
- Network errors: Retry on next poll cycle (2s for alerts, 30s for news)
- No exponential backoff needed (polling handles it)

### Manual Retry
- Pull to refresh triggers immediate retry
- "נסה שוב" button in error states (optional)

## Logging

- Log all errors with context (endpoint, status code, message)
- Use print/debugPrint for development
- Consider crash reporting integration (deferred)

## Acceptance Criteria

- [ ] Offline state clearly indicated with banner
- [ ] Offline state does NOT show cached alert data
- [ ] API errors show appropriate error messages
- [ ] Partial failures (some feeds down) handled gracefully
- [ ] Loading states shown during data fetches
- [ ] App resume shows "מתעדכן..." overlay
- [ ] Empty states shown when no data available
- [ ] Errors auto-recover when conditions improve
- [ ] All error messages are in Hebrew
- [ ] Errors are logged for debugging

## References

Existing web app implementation:
- `public/script.js` - Error handling (lines 449-458, 160-180)
- `src/websocket/websocket.handler.js` - Connection error handling
