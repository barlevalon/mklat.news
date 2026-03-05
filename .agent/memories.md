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

## HTTP encoding (2026-03-04)

- Dart's `http` package defaults to Latin-1 when Content-Type omits charset. OREF Alerts, History, and Ynet RSS all omit charset — causes mojibake on Hebrew text.
- Fix: always use `utf8.decode(response.bodyBytes, allowMalformed: true)` instead of `response.body`.
- OREF Alerts response has BOM (EF BB BF) — must strip before JSON parsing.
- OREF Districts uses non-standard `charset=UTF8` (missing hyphen) — works fine since we decode from bytes.
- Cities fallback (`cities_heb.json`) uses `\uXXXX` Unicode escapes in JSON, not raw UTF-8 bytes.

## Cities fallback API format (2026-03-04)

- Real field names: `cityAlId` (not `value`), `areaid`, `id`, `label`, `rashut`, `color`
- No `areaname` field — area is embedded in `label` after `|` separator: `"אבו גוש | אזור שפלת יהודה"`
- Some entries have no `|` separator (e.g., `"אזור תעשייה שחורת"`)

## Testing (2026-03-04)

- Unit tests that mock our `HttpClient` miss encoding bugs — they bypass the bytes→string decode pipeline.
- Fixture-based tests (mock `http.Client`, feed real response bytes) catch what unit tests miss.
- Integration tests on emulator: use `tester.pump(Duration)` not `pumpAndSettle()` — polling timers prevent settling.
- SharedPreferences key is `mklat_saved_locations` (not `saved_locations`).
- RTL PageView: positive drag offset (`Offset(300, 0)`) swipes to next page.
- `adb shell input text` does NOT support Hebrew — use integration test framework for Hebrew input testing.

## Android permissions (2026-03-05)

- `INTERNET` and `ACCESS_NETWORK_STATE` must be declared in AndroidManifest.xml
- `connectivity_plus` silently fails without `ACCESS_NETWORK_STATE` on real devices — offline state never detected
- Emulators don't enforce permissions strictly, so integration tests on emulator won't catch missing permissions
- Always check manifest permissions when adding new plugins that need platform access

## Development practices

- Red/green TDD for all implementation. Write failing test first, then minimum code to pass, then refactor.
- All new work must pass `make check` (format + analyze + unit tests + integration tests) before committing.
- When adding new API endpoints: capture real response with curl, add fixture-based integration test.
- When adding new screens/flows: add an integration test for the happy path.
