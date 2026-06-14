# mklat.news — developer README

mklat.news is a Hebrew-first Flutter mobile app for Israeli emergency-alert status and nearby news context.

> **Safety notice**
>
> This project is not an official emergency-alert system. Do not use it as a primary life-safety source.

User-facing download and install docs live in GitHub Pages:

- [mklat.news user docs](https://barlevalon.github.io/mklat.news/)
- [GitHub Releases](https://github.com/barlevalon/mklat.news/releases)

The legacy web app remains in this repository for reference only. Active development is the Flutter mobile app under `lib/`, `test/`, `integration_test/`, `android/`, and `ios/`.

## Repo map

```text
lib/
├── application/        # App session and polling orchestration
├── core/               # Endpoints, constants, theme, strings, utility seams
├── data/               # Models, codecs, mappers, services
├── domain/             # Alert state machine and domain rules
└── presentation/       # Providers, screens, widgets, presentation models

test/                   # Unit, widget, and fixture-based integration tests
integration_test/       # Emulator-backed Flutter integration tests
tool/                   # Fixture generation and maintenance scripts
docs/                   # User-facing GitHub Pages docs
.agent/                 # Product specs and implementation notes
```

## Tooling

Tool versions are managed by [`mise`](https://mise.jdx.dev/):

```bash
mise install
flutter --version
flutter doctor
flutter pub get
```

Current expected versions:

- Flutter `3.38.7` stable
- Dart `3.10.7`
- Java 21 for Android builds

Android SDK is not managed by `mise`. Install Android Studio or Android command-line tools and accept licenses:

```bash
flutter doctor --android-licenses
```

## Run locally

```bash
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

## Validate changes

Fast release gate, no emulator:

```bash
make release-check
```

Full local check, including emulator integration tests:

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

Regenerate Mockito mocks:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Regenerate fixture constants after changing raw fixture bytes:

```bash
make fixtures
```

## Build APK locally

```bash
make release-apk
```

Override build metadata:

```bash
make release-apk BUILD_NAME=1.0.1 BUILD_NUMBER=2
```

Outputs:

```text
dist/mklat-news-<version>+<build>.apk
build/app/outputs/flutter-apk/app-release.apk
```

## Cut a release

GitHub Actions publishes an APK to a GitHub Release when a tag matching `v*` or `android-v*` is pushed.

```bash
git tag -a android-v1.0.0 -m "mklat.news android v1.0.0"
git push origin android-v1.0.0
```

The `Android APK` workflow validates, builds, uploads an Actions artifact, and attaches the APK to the release.

Manual publishing is also available from **Actions → Android APK → Run workflow** with `publish_release` enabled.

Current caveat: Android release builds use the debug signing config. That is acceptable for internal sideloading, but stable public distribution should move to a real release keystore stored in GitHub Actions secrets.

## CI workflows

- `Android APK`: validates and builds APKs on relevant `main` pushes and release tags. Uses per-ref concurrency.
- GitHub Pages publishes `docs/` as the user-facing site.
- Legacy web deployment workflows still exist for historical web-app infrastructure.

## Architecture boundaries

- Data services fetch and parse remote data; they do not own polling timers.
- Mappers/codecs translate OREF/RSS/cache shapes into app values.
- Domain code owns alert-state rules.
- Presentation models own Hebrew display copy and UI projection.
- Providers expose app state to widgets through `provider` / `ChangeNotifier`.
- `AppSession` wires services, providers, and polling together.

## Data sources

Configured in `lib/core/api_endpoints.dart`:

- OREF current alerts
- OREF alert history
- OREF districts and shelter times
- OREF cities fallback
- RSS news from Ynet, Maariv, and Haaretz

OREF requests require browser-like headers. Check `HttpClient` and OREF service tests before changing API behavior.

## Testing strategy

1. Unit and widget tests under `test/unit/` and `test/widget/`.
2. Fixture-based integration tests under `test/integration/`, using captured HTTP response bytes and mocked `http.Client`.
3. Emulator-backed Flutter integration tests under `integration_test/`.

Fixture bytes live under `test/fixtures/responses/`. Keep raw bytes when testing decoding, charset, BOM, or Hebrew mojibake behavior.

## Legacy web app

Legacy web code is in `src/`, `public/`, `landing/`, and related Node/Vite files. Treat it as reference-only for mobile development.

Useful reference files:

- `src/utils/alert-state-machine.js`
- `src/utils/location-matcher.js`
- `src/services/oref.service.js`
- `src/utils/html-parser.util.js`
- `src/config/constants.js`

## License

MIT. See [`LICENSE`](LICENSE).
