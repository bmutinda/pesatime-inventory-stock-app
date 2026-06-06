# Pesatime Inventory App

## API Base URL

The app reads its API base URL from the `BASE_URL` Dart define.

If `BASE_URL` is not provided, the app uses the default value in:

```text
lib/helpers/config/index.dart
```

Current default:

```text
http://10.0.2.2:3550/inventory-stock-app/v1/
```

## Run Debug

Use the development API when running locally:

```bash
flutter run --dart-define=BASE_URL=http://10.0.2.2:3550/inventory-stock-app/v1/
```

## Build Android Release

Use the production API for release builds:

```bash
flutter build apk --release --dart-define=BASE_URL=https://api.example.com/inventory-stock-app/v1/
```

For an Android App Bundle:

```bash
flutter build appbundle --release --dart-define=BASE_URL=https://api.example.com/inventory-stock-app/v1/
```

## Build iOS Release

```bash
flutter build ipa --release --dart-define=BASE_URL=https://api.example.com/inventory-stock-app/v1/
```