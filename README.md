# Yemen Law

This repository contains the Android Flutter project for the "قوانين اليمن – Yemen Law" app.

## Project structure

- `lib/main.dart` – app logic, screens, theming, local SQLite database, search, favorites, notes.
- `android/` – Android configuration for building the APK.

## Run locally

```bash
flutter pub get
flutter run
```

## Release APK

```bash
flutter build apk --release
```

## Notes

- Works fully offline for core legal content.
- Local SQLite database stores laws, articles, favorites, notes, and recent reads.
- Search supports Arabic text, law names, article numbers, and body matching.
- Dark, light, and auto themes are supported.
