# Fifteen Puzzle (iOS 10)

iOS 10 port of the [fifteen-puzzle](https://github.com/jaroshevskii/fifteen-puzzle) desktop game for the 32-bit iPad 4. Same `PuzzleCore` rules and raylib color scheme, UIKit UI instead of raylib. Built with [Theos](https://theos.dev).

![Fifteen Puzzle on iPad 4](https://github.com/jaroshevskii/fifteen-puzzle-ios10/releases/download/v0.1.0/screenshot.png)

## Demo

<video src="https://github.com/jaroshevskii/fifteen-puzzle-ios10/releases/download/v0.1.0/demo.mp4" width="75%" controls></video>

## Features

- Boards 4×4 to 13×13, all orientations
- Sliding-tile board with raylib-style colors (`DARKPURPLE` empty cell, `ORANGE` numbered tiles) and monospace digits
- Running timer, victory detection with overlay
- Shuffle, Restart, board-size − / +
- `PuzzleCore.{c,h}` — pure C port of the original `PuzzleCore.cppm`: same scramble rules (`grid*grid*10` legal slides from solved, no immediate undo), same slide/adjacency/solved logic, deterministic splitmix64 PRNG — bit-identical boards to the desktop build for the same seed

## Build

Jailbroken device with Theos and the iOS 10.3 SDK:

```sh
export THEOS=$HOME/theos
make
```

Notes: `ARCHS = armv7 armv7s`, iOS 10.3 SDK, `USE_MODULES = 0`, `-Wl,-U,_memset`.

## Install

Requires jailbreak + AppSync Unified:

```sh
ideviceinstaller install FifteenPuzzle.ipa   # over USB, no Apple ID
```

## Roadmap

- Settings and saved-game persistence
- Local SQLite leaderboard
- Network client, auto-solver, multi-player
- Sound
- Exact raylib bitmap font

## Credits

Game rules, layout and raylib color scheme from the [fifteen-puzzle](https://github.com/jaroshevskii/fifteen-puzzle) project.