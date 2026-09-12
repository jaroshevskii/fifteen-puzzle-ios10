# fifteen-puzzle-ios10

The [fifteen-puzzle](https://github.com/jaroshevskii/fifteen-puzzle) desktop game ported to iOS 10 (32-bit iPad 4) — same `PuzzleCore`, same raylib look, UIKit UI instead of raylib. Built with [Theos](https://theos.dev). System font (SF UI) everywhere, per Apple HIG.

## Status — iterations 1–2

### Iteration 1 — board screen with basic play

- `PuzzleCore.{c,h}` — pure C port of the original `PuzzleCore.cppm`: same scramble rules (`grid*grid*10` legal slides from solved, no immediate undo), same slide/solved/adjacency logic, deterministic splitmix64 PRNG seeded per game (bit-for-bit same board as the desktop build for the same seed).
- `PuzzleBoardView` — raylib-style tiles: black cell frames, `DARKPURPLE (112,31,126)` empty cell, `ORANGE (255,161,0)` numbered tiles with black SF-bold digits; sliding tiles ease toward their cell (~0.12s ease-out, matches the raylib glide).
- `FifteenPuzzleViewController` — tile taps, running timer (`hh:mm:ss`), victory detection + overlay, on-screen Shuffle / Restart / board-size − / + controls. Boards 4×4 … 13×13.

### Iteration 2 — persistence, local DB, sound, confetti

- `AppSettings` — `{isSoundEnabled, lastBoardSize, playerName, autoResume}` persisted to `Documents/settings.json`. (Fullscreen/resolution settings are desktop-only and skipped on iPad.)
- `SavedGame` — `Game{grid, tiles, moveHistory, secondsElapsed}` autosaved (throttled by grid/history/seconds signature while playing) to `Documents/saved_game.json`, restored on launch with the timer back-dated, cleared on win. `autoResume` jumps straight back in; otherwise a "Continue game?" prompt offers Resume / New game.
- `DatabaseClient` — SQLite (`-lsqlite3`): `migrate`, `saveGame` (recorded on every win), `fetchBestScores` / `fetchStats` for the upcoming leaderboard screen.
- `AudioPlayerClient` — a short `tick.wav` (SystemSoundID) played each second while Sound is on.
- `ConfettiView` — victory rain of 160 particles in the raylib palette (ORANGE, GREEN, SKYBLUE, GOLD, PINK, VIOLET), recycled while the overlay is up; subtitle shows `mm:ss   N moves` like the original Game Over screen.
- `SettingsViewController` — native grouped rows: Sound, Board size (− / +), Player name, Auto-resume game; opened via the **Settings** button on the game screen (the original's Esc-menu comes with the menu feature in a later iteration).

Not yet ported: menu/navigation, leaderboard screen, network API client, auto-solver, multi-player.

## Build (Theos)

```sh
export THEOS=$HOME/theos
make
```

Build notes: `ARCHS = armv7 armv7s`, iOS 10.3 SDK, `USE_MODULES = 0`, `-Wl,-U,_memset`, links `-lsqlite3` + AudioToolbox.

## Install

Jailbroken device + AppSync Unified:

```sh
ideviceinstaller install FifteenPuzzle.ipa    # over USB, no Apple ID
```

## Credits

Game rules, layout and raylib color scheme from the [fifteen-puzzle](https://github.com/jaroshevskii/fifteen-puzzle) project. Font is the system SF UI font (Apple HIG) instead of the original's embedded raylib bitmap atlas.