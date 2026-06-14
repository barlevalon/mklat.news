# mklat.news — מקלט / emergency status companion

> **Important safety disclaimer**
>
> This app is for educational and development use. Do **not** rely on it as your primary source for life-safety alerts. Use official Israeli Home Front Command channels and approved emergency alert applications.

mklat.news is a Hebrew-first Flutter mobile app for checking Israeli emergency-alert status after you have already received an official alert. It tracks the current alert state for your primary location, shows alerts in your saved areas, and gives nearby news context.

The original web app is still present in this repository as legacy reference code. Active development is the Flutter mobile app under `lib/`, `test/`, `integration_test/`, `android/`, and `ios/`.

## What the app does

- Tracks active OREF / Home Front Command alerts.
- Lets you save locations and choose one primary location.
- Runs the alert state machine for the primary location.
- Shows secondary saved locations with active/inactive/offline status chips.
- Shows a recent alert-history feed and nationwide active-alert summary.
- Shows Hebrew news updates from RSS sources.
- Handles offline/error/degraded states explicitly.
- Uses RTL-first Hebrew UI.

## Downloading APK builds

GitHub Actions builds a release APK on every relevant push to `main`.

- For quick internal builds: open the latest **Mobile APK** workflow run and download the `mklat-news-apk-*` artifact.
- For phone-friendly downloads: use GitHub **Releases**. Release assets are accessible from mobile browsers.

### Cut a GitHub release

The workflow publishes an APK to a GitHub Release when a tag matching `v*` or `mobile-v*` is pushed.

Example:

```bash
git tag mobile-v1.0.0
git push origin mobile-v1.0.0
```

The `Mobile APK` workflow will validate, build, and attach the APK to the release.

You can also publish manually from GitHub Actions:

1. Open **Actions → Mobile APK**.
2. Choose **Run workflow**.
3. Enable `publish_release`.
4. Optionally set `release_tag`, for example `mobile-v1.0.0`.

> Note: Android release signing is currently configured with the debug signing config in `android/app/build.gradle.kts`. This is fine for internal sideloading, but public/stable distribution should use a real release keystore in GitHub secrets so future APKs install as updates instead of requiring uninstall/reinstall.

## Development setup

Tool versions are managed by [`mise`](https://mise.jdx.dev/) in `mise.toml`.

```bash
mise install
flutter --version
flutter doctor
flutter pub get
```

Required versions at time of writing:

- Flutter `3.38.7` stable
- Dart `3.10.7`
- Java 21 for Android builds

Android SDK is not managed by `mise`. For Android builds, install Android Studio or Android command-line tools, then run:

```bash
flutter doctor --android-licenses
```

## Running locally

```bash
flutter run
```

Run on a specific connected device:

```bash
flutter devices
flutter run -d <device-id>
```

## Building APKs locally

Build and copy a named APK into `dist/`:

```bash
make release-apk
```

Override version metadata:

```bash
make release-apk BUILD_NAME=1.0.1 BUILD_NUMBER=2
```

Raw Flutter build command:

```bash
flutter build apk --release
```

The raw APK is written to:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Validation

Fast host-side validation:

```bash
make release-check
```

Full pre-push validation, including emulator integration tests:

```bash
make check
```

Useful individual commands:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
make test-unit
make test-integration
```

Regenerate generated Mockito mocks when needed:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Regenerate fixture constants after changing binary fixtures:

```bash
make fixtures
```

## Emulator integration tests

An Android emulator configuration is expected locally for `make test-integration`.

```bash
make emulator
make test-integration
```

Expected AVD name: `mklat_test`.

## Architecture

```text
lib/
├── application/        # App session and polling orchestration
├── core/               # Constants, endpoints, theme, strings, utility seams
├── data/               # Models, codecs, mappers, services
├── domain/             # Alert state machine and domain rules
└── presentation/       # Providers, screens, widgets, presentation models
```

Key boundaries:

- Data services fetch and parse remote data; they do not own polling timers.
- Mappers/codecs translate OREF/RSS/cache shapes into app values.
- Domain code owns alert-state rules.
- Presentation models own Hebrew display copy and UI projection.
- Providers expose app state to widgets through `provider` / `ChangeNotifier`.
- `AppSession` wires services, providers, and polling together.

## Data sources

Configured sources are in `lib/core/api_endpoints.dart`.

- OREF current alerts: `https://www.oref.org.il/warningMessages/alert/Alerts.json`
- OREF alert history: `https://www.oref.org.il/WarningMessages/alert/History/AlertsHistory.json`
- OREF districts / shelter times: `https://alerts-history.oref.org.il/Shared/Ajax/GetDistricts.aspx?lang=he`
- OREF cities fallback: `https://www.oref.org.il/districts/cities_heb.json`
- RSS news: Ynet, Maariv, Haaretz

OREF requests require browser-like headers. See `HttpClient` and the OREF services before changing API calls.

## Testing strategy

The mobile app uses three test layers:

1. **Unit and widget tests** under `test/unit/` and `test/widget/`.
2. **Fixture-based integration tests** under `test/integration/`, using captured HTTP response bytes and mocked `http.Client`.
3. **Flutter integration tests** under `integration_test/`, running the app on an emulator with fixture-backed HTTP responses.

Fixtures live under `test/fixtures/responses/`. Keep raw response bytes when testing decoding, charset, BOM, or Hebrew mojibake behavior.

## CI

The `Mobile APK` GitHub Actions workflow:

- runs on relevant pushes to `main` and on `v*` / `mobile-v*` tags;
- can be run manually;
- installs Flutter and Java;
- runs `flutter pub get`;
- generates test mocks with `build_runner`;
- runs `make release-check-ci`;
- uploads the APK as a workflow artifact;
- publishes the APK to a GitHub Release on tag or manual release runs.

The workflow uses per-ref concurrency so a new `main` push cancels an older in-progress APK build for `main`.

## Legacy web app

Legacy web code remains in `src/`, `public/`, `landing/`, and related Node/Vite files. It is reference-only for the mobile rewrite and should not be treated as the active product.

Useful legacy reference files:

- `src/utils/alert-state-machine.js`
- `src/utils/location-matcher.js`
- `src/services/oref.service.js`
- `src/utils/html-parser.util.js`
- `src/config/constants.js`

## Repository notes

- Product specs and implementation notes live under `.agent/`.
- Scratch review outputs may appear under `reviews/`; they are not release artifacts.
- Local APK copies in `dist/` are ignored by git.

## License

MIT License. See [`LICENSE`](LICENSE).
