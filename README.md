# fifteen-puzzle-ios10

The [fifteen-puzzle](https://github.com/jaroshevskii/fifteen-puzzle) desktop game ported to iOS 10 (32-bit iPad 4) — same `PuzzleCore`, same raylib look, UIKit UI instead of raylib. Built with [Theos](https://theos.dev).

## Status — iteration 1

Board screen with basic play:

- `PuzzleCore.{c,h}` — pure C port of the original `PuzzleCore.cppm`: same scramble rules (`grid*grid*10` legal slides from solved, no immediate undo), same slide/solved/adjacency logic, deterministic splitmix64 PRNG seeded per game (bit-for-bit same board as the desktop build for the same seed).
- `PuzzleBoardView` — raylib-style tiles: black cell frames, `DARKPURPLE (112,31,126)` empty cell, `ORANGE (255,161,0)` numbered tiles with black text, monospace (Menlo-Bold) digits; sliding tiles ease toward their cell (`UIViewAnimationOptionCurveEaseOut`, ~0.12s — matches the raylib 1-exp(-dt·18) glide).
- `FifteenPuzzleViewController` — tile taps, running timer (`hh:mm:ss`), victory detection with the "Victory!" overlay, and on-screen Shuffle / Restart / board-size − / + controls.
- Boards 4×4 … 13×13, all orientations, Auto-Layout-free manual centering of the board (same `boardLayout` fit: `min(sw, sh−status−buttons)`, tile capped at 120).

Not yet ported (roadmap): settings/saved-game persistence, local SQLite + leaderboard, network API client, auto-solver, multi-player, sound, and the exact raylib bitmap font.

## Demo

Running on iPad 4 (iOS 10.3.4):

<video src="https://github.com/jaroshevskii/fifteen-puzzle-ios10/releases/download/v0.1.0/demo.mp4" width="75%" controls></video>

[Direct download: demo.mp4](https://github.com/jaroshevskii/fifteen-puzzle-ios10/releases/download/v0.1.0/demo.mp4)

## Screenshot

![Fifteen Puzzle on iPad 4](https://github.com/jaroshevskii/fifteen-puzzle-ios10/releases/download/v0.1.0/screenshot.png)

## Build (Theos)

```sh
export THEOS=$HOME/theos
make
```

Build notes: `ARCHS = armv7 armv7s`, iOS 10.3 SDK, `USE_MODULES = 0`, `-Wl,-U,_memset`.

## Install

Jailbroken device + AppSync Unified:

```sh
ideviceinstaller install FifteenPuzzle.ipa    # over USB, no Apple ID
```

## Credits

Game rules, layout and raylib color scheme from the [fifteen-puzzle](https://github.com/jaroshevskii/fifteen-puzzle) project.