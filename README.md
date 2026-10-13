# 2048 — Flutter for Android and Web

An offline 4×4 puzzle game you can play with swipes, arrow keys or on-screen buttons.
The same Dart game engine and Flutter interface run on Android **and in a browser**.

## Play in a browser

**Hosted preview (once GitHub Pages is enabled):**
https://bluebird-studio.github.io/2048/

On the page, use arrow keys, drag/swipe the board, or tap the direction buttons.
If the keyboard isn't controlling the game, click or tap the board once to give it focus.
Your best score is stored in this browser using `shared_preferences`.

To run locally with Flutter installed:

```sh
flutter pub get
flutter run -d chrome
```

Alternatively, to test a locally served production build:

```sh
flutter build web --release
cd build/web
python3 -m http.server 8000
```

Then open http://localhost:8000/. Don't open `index.html` with a `file://` URL.

The GitHub Actions `Publish playable 2048 browser preview` workflow builds
with `--base-href /2048/` and deploys to GitHub Pages on changes to `main`.
The repository's **Settings → Pages → Build and deployment → Source** must be
set to **GitHub Actions**. The web build is additionally verified and uploaded
as artifact `2048-web-static` by regular CI on every PR.

## Play on Android

Install Flutter, then run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

The `Flutter checks` workflow runs the analyzer, tests, Android APK build
and browser build. It uploads `2048-android-debug-apk` (debug, not signed for
Play Store) and `2048-web-static` as artifacts.

## Rules

- Equal adjacent tiles combine **once per move**. Each merge adds its new value to your score.
- A new 2 or 4 appears after a successful move; ineffective moves don't spawn tiles.
- Reach 2048 to win and optionally keep playing.
- Restart with **New game**.
- Best score is kept locally per device/browser.

## Structure

- `lib/game/game_2048.dart`: Flutter-independent 2048 rules.
- `lib/widgets/game_board.dart`: responsive, accessible 4×4 board with swipe/keyboard input.
- `lib/main.dart`: gameplay screen, score and best-score persistence.
- `web/`: Flutter browser launch page, web app manifest and favicon.
- `test/`: deterministic game, directional invariant, board and screen tests.
