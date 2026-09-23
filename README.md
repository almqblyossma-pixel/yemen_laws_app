# Yemen Law

This repository contains the Android Flutter project for the "قوانين اليمن – Yemen Law" application.

## How to run locally

1. Install Flutter SDK.
2. Install Android Studio and Android SDK.
3. In the project folder run:

```bash
flutter pub get
flutter run
```

## Build a release APK

```bash
flutter build apk --release
```

The APK will be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Notes

- The app is designed to work offline for the main legal content.
- Local SQLite storage is used for laws, articles, favorites, notes, recent reads, and search.
- The design follows the requested visual identity: dark charcoal, soft gold, legal and formal style.
- This project is structured to support future expansion with more laws, references, court decisions, and legal templates.

## Important

This environment cannot build the APK directly, so the final APK must be generated on a machine with Flutter + Android SDK installed.
