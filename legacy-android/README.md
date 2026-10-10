# Parin Litner — Android 4.0 native compatibility edition

This directory is a separate Java/Android implementation for Android 4.0 (API 14). It does not replace or modify the Flutter edition in the repository root.

## Compatibility design

- Minimum SDK: **14 (Android 4.0 / Ice Cream Sandwich)**.
- Native Android Views and platform APIs only; no Flutter engine, AndroidX, Kotlin runtime, or external Android library is required.
- The app reads/writes the Flutter SharedPreferences file and the `parin_litner_v4_data` deck JSON key, so the deck model remains compatible when the Android package/signing identity permits an in-place migration.
- Imports existing `.plbackup` (binary format `PLITBK01`) and legacy JSON deck backups, preserving text and front/back images.
- Includes 50 theme palettes, the current 21 language choices, four appearance modes, cards/decks, Leitner review ratings, tags/favorites/images, focus timer and three generated looping audio tracks, XP/streak/reward counters, achievements, settings and about/repository page.

## Build

A CI job builds the release APK and checks its manifest declares `minSdkVersion=14`. Run `python3 legacy-android/scripts/prepare_assets.py` before building locally; it creates the three raw WAV resources from deterministic formulas used by the main workflow. Build with Gradle 8.7 and JDK 17:

```sh
python3 legacy-android/scripts/prepare_assets.py
gradle -p legacy-android assembleRelease
```

The CI APK is a validation artifact, not a production signing release. Public updates must use the same stable signing key as the distributed app.

## Validation status

A successful Gradle build plus a manifest/API-level check proves that the APK is packaged with API 14 declared; it does **not**, on its own, prove correct runtime behavior on physical Android 4.0 hardware. Runtime verification should include an API 14 emulator/device and regression tests for backup import/export, image selection, audio playback, local persistence and the Leitner review flow.