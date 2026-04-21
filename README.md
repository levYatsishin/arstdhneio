# arstdhneio

> This fork was created with LLM assistance because I wanted these input and layout features for real use, fast. It is maintained in a practical, functionality-first way. If it is useful to you, feel free to use it, open issues, or send pull requests.

> **A practical fork of _Asdfghjkl_.**

Named after the [Deadmau5 song Asdfghjkl](https://www.youtube.com/watch?v=1aP910O2774). And then adapted for Colemak layout

## Fork Notes

This repository is a personal fork of [dave1010/Asdfghjkl](https://github.com/dave1010/Asdfghjkl/).
All core credit for the original project, design, and implementation goes to
[Dave Hulbert](https://github.com/dave1010). This fork was derived from upstream commit
[`1daed86`](https://github.com/dave1010/Asdfghjkl/commit/1daed86b932b82c210e53ba8893de6a8618d366b).

## Changes In This Fork

Since upstream commit [`1daed86`](https://github.com/dave1010/Asdfghjkl/commit/1daed86b932b82c210e53ba8893de6a8618d366b), this fork adds:

- Command-layer key translation, so printable bindings follow the current macOS layout's Command-equivalent mapping instead of the plain typed layer.
- `Cmd+;` activation as the default path, using the active layout's command-layer mapping for `;`, with optional Double-Command activation retained as a configurable alternative.
- Configurable grid layouts via launch arguments or environment variables.
- Built-in `colemak` and `colemak5` presets.
- Custom grid-row definitions for both 4x10 and 4x5 layouts.
- Multi-display handling that keeps 5-column layouts intact on the screen under the mouse cursor instead of splitting them across displays.
- App-bundle packaging scripts and install targets for building `arstdhneio.app`.
- A menu-bar Launch at Login toggle backed by macOS `SMAppService` when the bundled app is installed and launched as `arstdhneio.app`.
- A menu-bar Configuration window backed by `UserDefaults`, so layout presets and custom rows can be managed in-app instead of only through launch flags.
- A local release-packaging flow that matches CI and produces `arstdhneio-macos-app.zip`.
- Additional tests covering command-layer translation, configurable layouts, partitioning rules, and overlay navigation behavior.

![banner](banner.jpg)

## What does it do?

1. Press `Cmd` plus the key that currently maps to `;` in your active layout's command layer to see the keyboard grid on your screen.
2. Tap a corresponding key to move the mouse to that area.
3. Tap again (and again) to drill down.
4. Tap `Space` at any point to click the mouse.

The overlay resolves printable bindings through the current macOS layout's Command-equivalent
mapping, so layouts that expose stable shortcut characters under `Cmd` keep the same arstdhneio
bindings even when their normal typing layer changes.

If you prefer the original interaction, the menu bar `Configuration...` window lets you switch the
activation mode back to Double-Command Tap.

You can also:

- Tap `Backspace` to zoom back out to the previous level
- Tap `Arrow Keys` to move the selected tile up/down/left/right by half its size
- Tap `'` (apostrophe) to middle-click at the current position
- Tap `\` (backslash) to right-click at the current position
- Tap `Esc` to cancel and hide the overlay

## Why?

Mice are slow and a long way away from the keyboard.

## Inspiration

- [mouseless](https://mouseless.click/)
- [mousemaster](https://github.com/petoncle/mousemaster)
- [warpd](https://github.com/rvaiya/warpd)
- [scoot](https://github.com/mjrusso/scoot)
- [shortcat](https://shortcat.app/)
- [superkey](https://superkey.app/)
- [homerow](https://www.homerow.app/)
- [httpsvimac](https://github.com/nchudleigh/vimac)

## Download & Install

1. Download the latest `arstdhneio.app.zip` archive from the [GitHub releases page](https://github.com/levYatsishin/arstdhneio/releases).
2. Unzip it and move `arstdhneio.app` into `/Applications` or `~/Applications`.
3. Remove the quarantine attribute since the app bundle is currently unsigned:
   ```sh
   xattr -cr /Applications/arstdhneio.app
   ```
4. Launch `arstdhneio.app`.
5. Grant Accessibility when prompted so the app can move and click the pointer.
6. If you enable the optional `Double-Command Tap` activation mode, also grant Input Monitoring.
7. If you want it to start automatically after login, open the menu bar item and enable `Launch at Login`.

### Updating the installed app

The current bundle is ad-hoc signed for local use. That means replacing `~/Applications/arstdhneio.app`
with a newly built copy can make macOS treat it like a changed app identity for TCC permissions.
In practice, after reinstalling the app you may need to remove and re-add that exact app bundle under
**System Settings > Privacy & Security > Accessibility**, and under **Input Monitoring** if you use
`Double-Command Tap`.

For faster development, prefer running the built executable directly when you are debugging behavior:

```sh
./dist/arstdhneio.app/Contents/MacOS/arstdhneio
```

Use `make install-app` only when you specifically want to test the packaged app bundle behavior.

## How does it work?

Read [ARCHITECTURE.md](ARCHITECTURE.md) for a deeper look at the current components and runtime flow.

![Architecture diagram](architecture.jpg)

### Multiple displays

On multi-display setups, the 4×10 grid is divided horizontally across all overlay windows so
the first keypress selects a screen by column range (e.g. `Q…T` on screen 1, `Y…P` on screen
2). Refinements after the first key keep using the per-screen slice, keeping labels and hit
testing aligned with the display that owns the tapped keys.

### Permissions

By default, `arstdhneio` activates via a registered `Cmd+;` hotkey. After activation, overlay keys
still flow through the global keyboard listener so click and refinement handling stay reliable.
That means the current `Cmd+;` path still needs both Input Monitoring and Accessibility.

The activation key follows the current layout's command-layer mapping for `;`, not just the US
physical semicolon key position. If you switch keyboard layouts, the app re-registers that hotkey.

If you switch the activation mode to Double-Command Tap, activation itself also comes from that same
global event tap instead of the hotkey registration.

The Launch at Login toggle is only available from the bundled `arstdhneio.app`. If you run the
raw executable with `swift run` or from `.build/debug`, the menu item stays disabled because
`SMAppService.mainApp` only applies to the app bundle.

The menu bar also exposes `Configuration...`, which lets you change the saved activation mode,
layout preset, or custom rows. Those settings are persisted in `UserDefaults`. If you launch the
app with `--grid-keymap`, `--grid-key-rows`, or `--activation-mode`, those launch-time overrides
still win for that session.

Printable bindings are resolved from the current keyboard layout's Command-equivalent translation
rather than the plain typed character, matching the same character mapping macOS uses for
shortcuts and custom layouts that provide a dedicated Command layer.

On first launch, macOS may ask for Accessibility permission. If you later switch to
Double-Command activation, the app will also need **System Settings > Privacy & Security > Input
Monitoring**. Because this repo currently builds an ad-hoc-signed local app bundle, macOS may ask
you to re-grant those permissions after reinstalling or rebuilding the app.

## Development

`arstdhneio` is built with Swift 6.2+ and targets macOS 13+.

For release prep and tagging, see [PUBLISHING.md](PUBLISHING.md).

### Grid layout parameters

You can choose a different overlay key layout either from the menu bar `Configuration...` window
or at launch time:

```sh
swift run arstdhneio --grid-keymap colemak5
```

Available presets:

- `qwerty` (default)
- `colemak`
- `colemak5`

`colemak5` uses a 4×5 grid with these rows:

```text
n e i u y
q w f p g
a r s t d
z x c v b
```

On multi-display setups, 5-column layouts stay intact on the screen under the mouse cursor instead
of being split across displays.

For custom variants, you can provide all four 10-key rows directly:

```sh
swift run arstdhneio --grid-key-rows "1234567890,qwfpgjluy;,arstdhneio,zxcvbkm,./"
```

or four 5-key rows if you want a 4×5 grid:

```sh
swift run arstdhneio --grid-key-rows "neiuy,qwfpg,arstd,zxcvb"
```

The same options can also be provided via environment variables:

```sh
ARSTDHNEIO_GRID_KEYMAP=colemak5
ARSTDHNEIO_GRID_KEY_ROWS="1234567890,qwfpgjluy;,arstdhneio,zxcvbkm,./"
```

You can also override the activation mode for a single launch:

```sh
swift run arstdhneio --activation-mode doubleCommandTap
```

Custom rows must contain four comma-separated rows with the same width and no duplicate
characters across the whole grid.

If you save a layout from the configuration window, the app reuses it on the next launch. Launch
arguments and environment variables temporarily override the saved value without deleting it.

You can build and run `arstdhneio` with the provided `Makefile`:

```sh
make build        # swift build
make test         # runs the package test suite
make run          # runs the executable from .build/debug
make app          # builds dist/arstdhneio.app
make install-app  # installs the app bundle into ~/Applications
make open-app     # opens dist/arstdhneio.app
make release-archive  # packages dist/arstdhneio-macos-app.zip
make publish-check    # local release sanity check
```

If you want the real menu-bar app flow during development, use:

```sh
make app
make open-app
```

or install it into `~/Applications`:

```sh
make install-app
open ~/Applications/arstdhneio.app
```

If your shell still resolves `swift` to an older toolchain, every `make` target also accepts a
`SWIFT=...` override:

```sh
SWIFT="$HOME/.swiftly/bin/swift" make test
SWIFT="$HOME/.swiftly/bin/swift" make app
```

### Continuous integration

GitHub Actions keep the package healthy and provide a downloadable app bundle:

* `Test` runs on pushes to `main` and all pull requests, setting up Swift 6.2 on macOS and executing `swift test --parallel`.
* `macOS App` is a manually triggered workflow that builds `dist/arstdhneio.app`, zips the bundle, and uploads that archive as an artifact.
