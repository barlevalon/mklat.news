# Memories

> Persistent learnings and context that should carry across sessions.

## API validation (2026-03-04)

- All OREF endpoints confirmed live. Required headers still enforced.
- **AlertsHistory.json** (`/WarningMessages/alert/History/AlertsHistory.json`) is the key discovery: structured JSON (~370 KB) replaces the legacy HTML endpoint (~10.5 MB). Fields: `alertDate`, `title`, `data` (location), `category`. No HTML parsing needed.
- **Categories**: 1=rockets, 2=UAV, 13=event ended (clearance), 14=imminent warning.
- **Districts** returns 1,486 unique locations (up from hardcoded 1,425) with `migun_time` (shelter seconds: 0/15/30/45/60/90). Cities backup has 1,350 entries in pipe-separated label format, missing migun_time.
- **Alerts.json** empty response is BOM + `\r\n` (5 bytes). Active response is `{id, cat, title, desc, data: [locations]}`.
- The Hebrew string `"ניתן לצאת מהמרחב המוגן"` does NOT appear in real alert data. WAITING_CLEAR state must be absence-based: alert dropped from active feed but no category 13 clearance received yet.
- **Maariv RSS** returns 308 redirect to lowercase URL. HTTP client must follow redirects.
- **Walla RSS** has a known timezone bug (carried over from web app).
- **Tzeva Adom fallback** (`api.tzevaadom.co.il/notifications`) returns `[]` — functional but possibly less reliable.
- **Alert translations** endpoint exists at `/alerts/alertsTranslation.json` — maps catId to multilingual text. Useful for future i18n.

## Development practices

- Red/green TDD for all implementation. Write failing test first, then minimum code to pass, then refactor.
