# 2048 for Android

A small, offline, touch-first Flutter version of the 4×4 puzzle.

## Play

- Swipe the board, use arrow keys, or tap the direction buttons to move all tiles.
- Equal adjacent tiles combine once per move. Every combination adds its value to your score.
- A new tile (2 or 4) appears after a successful move, never after an ineffective move.
- Reach 2048 to win, or continue to a higher score. Restart with **New game**.
- Your **best score** persists on your device through `shared_preferences`.

## Run and verify

Install Flutter, then run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

CI runs the checks and uploads the resulting `app-debug.apk` as the
`2048-android-debug-apk` GitHub Actions artifact after a successful build.
It is an installable **debug** APK, not a Play Store release.

## Structure

- `lib/game/game_2048.dart`: deterministic UI-independent 2048 rules.
- `lib/widgets/game_board.dart`: responsive, accessible 4×4 board.
- `lib/main.dart`: game screen, input wiring, score and best-score storage.
- `test/`: game rule, exhaustive line, board interaction and app-level tests.

Development should follow passing PR CI. Avoid merging unverified changes
or reporting a completed APK before the artifact is visible.
