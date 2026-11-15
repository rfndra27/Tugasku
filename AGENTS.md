# Agent Rules

- Flutter app. Main entrypoint: `lib/main.dart`; Firebase setup: `lib/firebase_options.dart`.
- Get dependencies first: `flutter pub get`.
- Verify Dart changes with `flutter analyze`, then `flutter test`.
- Run one focused test with `flutter test test/<file>`, for example `flutter test test/smart_input_ai_test.dart`.
- Run web locally with `flutter run -d chrome`; use `flutter clean` only when stale build output causes trouble.
- App code lives in `lib/`; tests live in `test/`; Firebase Cloud Functions live in `functions/index.js`.
- Functions use Node 18. From `functions/`, run `npm install`; deploy only with `npm run deploy` when explicitly requested.
- Firebase rules/indexes are `firestore.rules` and `firestore.indexes.json`; `firebase.json` points to them and to `functions/`.
- Do not commit API keys or tokens. Pass Gemini keys with `--dart-define=GEMINI_API_KEY=...`; rotate any exposed key.
- `.dart_tool/`, `build/`, and dependency folders are generated or ignored; do not edit or commit them.
- GitHub Actions runs `flutter pub get`, `flutter test`, and release APK build on pushes to `main`.
