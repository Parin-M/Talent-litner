# Talent Litner 3.0 – build fix

This build fixes the previous Android/Flutter workflow and startup crash handling.

- Regenerates a clean Android platform in GitHub Actions.
- Uses Java 17 and current GitHub Actions versions.
- Generates the launcher icon from `assets/parin_litner_icon.png`.
- Uses the butterfly logo inside the app.
- Uses a new `decks_v3` storage key and safely falls back to seed data if old local JSON is corrupted.
- App version: 3.0.0+3
