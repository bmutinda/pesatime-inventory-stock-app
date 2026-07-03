# AGENTS.md

## Project

This repository contains the Pesatime Inventory Stock Taking App, built with
Flutter and Dart.

- Package: `inventory_app`
- Dart SDK: `>=3.5.0 <4.0.0`
- App entrypoint: `lib/main.dart`
- Supported platform folders currently committed: Android, iOS, and Windows
- API base path: `/inventory-stock-app/v1/`

Run all commands from the repository root.

## Setup and Launch

Install packages:

```bash
flutter pub get
```

List available emulators and connected devices:

```bash
flutter emulators
flutter devices
```

Start an emulator when needed:

```bash
flutter emulators --launch <emulator-id>
```

Run the app against the local API from an Android emulator:

```bash
flutter run --dart-define=BASE_URL=http://10.0.2.2:3550/inventory-stock-app/v1/
```

Run on a specific device:

```bash
flutter run -d <device-id> --dart-define=BASE_URL=<api-base-url>
```

Useful API hosts:

- Android emulator to host machine:
  `http://10.0.2.2:3550/inventory-stock-app/v1/`
- iOS simulator to host machine:
  `http://127.0.0.1:3550/inventory-stock-app/v1/`
- Physical device: use the development machine's LAN IP; the API must listen on
  a reachable interface.
- Production:
  `https://api.pesatime.com/inventory-stock-app/v1/`

Always keep the trailing slash in `BASE_URL`, because service paths such as
`me` and `stock-sessions` are relative.

If `BASE_URL` is omitted, `lib/helpers/config/index.dart` supplies the Android
emulator development URL.

## Release Builds

Android APK:

```bash
flutter build apk --release --dart-define=BASE_URL=https://api.pesatime.com/inventory-stock-app/v1/
```

Android App Bundle:

```bash
flutter build appbundle --release --dart-define=BASE_URL=https://api.pesatime.com/inventory-stock-app/v1/
```

iOS archive:

```bash
flutter build ipa --release --dart-define=BASE_URL=https://api.pesatime.com/inventory-stock-app/v1/
```

Do not commit environment-specific API URLs into Dart files. Pass them with
`--dart-define`.

## Architecture

The app intentionally uses a lightweight layered structure:

```text
lib/
├── main.dart                 # startup, theme, navigator key, named routes
├── data/models/              # API response and domain JSON models
├── helpers/
│   ├── api/                  # shared Dio client and API parsing helpers
│   ├── config/               # compile-time environment configuration
│   ├── prefs/                # SharedPreferences wrapper
│   └── utils/                # display/date/money helpers
├── services/
│   ├── auth/                 # login, profile, token/session lifecycle
│   ├── device/               # persistent generated device identity
│   └── stock_sessions/       # stock-session API operations
├── screens/                  # route-level UI and local interaction state
└── widgets/                  # reusable presentation widgets
```

The normal dependency direction is:

```text
screens -> services -> ApiClient -> backend
   |          |
   +------> models
```

Keep HTTP calls out of widgets. Add backend operations to the relevant service,
map response data in `lib/data/models`, and let screens manage loading, errors,
and presentation with `StatefulWidget` and `setState`.

The app does not use Provider, Bloc, Riverpod, observables, or generated JSON
serialization. Do not introduce a new state-management or code-generation
framework for a small feature unless explicitly requested.

## App Flow and Routes

`lib/main.dart` is the source of truth for application routes.

- `/` -> splash and authentication check
- `/login` -> staff-code and PIN login
- `/home` -> active sessions, history, and profile tabs
- `/opening-stock` -> opening quantity capture
- `/closing-stock` -> closing quantity capture
- `/closing-review` -> closing count review
- `/history-detail` -> submitted session details
- `/submission-success` -> successful submission confirmation

Route arguments are passed as maps through `Navigator.pushNamed`. Preserve the
existing argument names used by each destination screen. When adding a new
route, register it in `lib/main.dart` and wire both the source interaction and
destination argument handling.

## API and Data Contracts

Use `ApiClient` from `lib/helpers/api/index.dart` for every request. It:

- reads the base URL from `AppConfig`;
- adds `Authorization: Bearer <token>` when a token exists;
- adds `device_id` to query parameters and map request bodies;
- applies the shared request timeouts and JSON headers.

The backend wraps responses in the shape represented by `ApiResponse`. Check
the wrapper's `success`, `message`, and `data` values before mapping domain
objects. Convert Dio failures with `ApiUtils.readDioError`.

Backend field names are authoritative. Current examples include `_id`,
`createdAt`, `openingQty`, `closingQty`, `expectedClosingQty`, and
`varianceQty`. Keep quantity fields as `double`; zero and values with up to two
decimal places are valid stock data. Do not truncate them to integers in the
model or UI.

Authentication is a two-step workflow in `AuthUtils`: validate the staff code,
then log in with the returned code hash and PIN. Tokens and login state are
stored through `SharedPreferencesManager`.

## Coding Conventions

- Follow the existing feature folders and `index.dart` naming convention.
- Prefer package imports using `package:inventory_app/...`.
- Keep screen-only state local and guard asynchronous UI updates with
  `if (!mounted) return`.
- Reuse `AppColors`, shared widgets, and existing typography before adding new
  visual primitives.
- Keep user-facing error messages clear and preserve backend messages when
  available.
- Use `const` constructors and widgets where practical.
- Keep changes focused; do not reorganize unrelated files while implementing a
  feature.
- Preserve the startup initialization in `main()`: Flutter bindings and intl
  date data must be initialized before `runApp`.

## Validation

Format changed Dart files:

```bash
dart format <changed-dart-files>
```

Run static analysis:

```bash
flutter analyze
```

Run tests when a `test/` directory or relevant tests exist:

```bash
flutter test
```

For launch-related changes, also run the app on the target platform with the
appropriate `BASE_URL`. Report analyzer/test failures separately from
pre-existing informational lints.

## Agent Guardrails

- Inspect the relevant screen, model, and service before changing a workflow.
- Keep mobile request and response fields aligned with the backend contract.
- Never add secrets, tokens, signing credentials, or production-only values to
  source control.
- Do not edit generated Flutter platform files unless the task specifically
  requires a platform configuration change.
- Do not remove Android's main-manifest `INTERNET` permission; release builds
  need it for API access.
- Avoid destructive Git operations and preserve unrelated local changes.
