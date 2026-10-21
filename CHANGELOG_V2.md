# Talent Litner 7.3.0

- Added an Android home-screen Quick Review widget. It can reveal/hide a card's answer, advance to another card, and open the app; widget text follows Persian/English settings.
- Added a dedicated Quick Review screen across decks, with progress, optional auto-reveal, answer rating and image support.
- Added a multiple-choice test builder: create tests, add/edit questions, set the correct answer, and choose 2–20 answer options per question.
- Added test-taking flow with one-question-at-a-time navigation, score percentage, answer review, explanations and retry.
- Tests are included in the portable `.plbackup` file together with flashcard decks and card images; import can merge or replace tests and decks on another device.
- Updated the home screen with Metro-style Quick Review and Test Builder tiles, square surfaces, sharp color blocks and clearer section hierarchy.
- Preserved PDF export (printable flashcards, study worksheets, quiz sheets), multilingual creator attribution and Android 7.0+ (API 24) minimum.
- Pinned the image dependency to a Flutter/Dart 3.9-compatible version for the PDF release build.

## Talent Litner — Backup reliability and image-based tests

- Moved backup and restore controls from the dashboard into Settings and added a backup inventory summary.
- Added a restore preview with deck, card, test, image counts and export timestamp before choosing merge or replace.
- Introduced portable backup format v3. It stores flashcard images, test question images, and test answer images as binary assets, alongside test definitions, options, correct answers, and explanations.
- Kept compatibility with legacy JSON and binary backup formats v1/v2, including older product-name metadata.
- Added stricter validation for incomplete/corrupt backups, missing or duplicate image assets, invalid base64, and oversized assets/manifests/files.
- Added optional question and answer images in Test Builder, with preview, replace/remove controls, in-test question image display, and answer image display in results.
- Added model and full portable-backup round-trip tests for card and quiz image preservation.
