# arstdhneio

> This fork was created with LLM assistance because I wanted these input and layout features for real use, fast. It is maintained in a practical, functionality-first way. If it is useful to you, feel free to use it, open issues, or send pull requests.

> **A practical fork of _Asdfghjkl_.**

Named after the [Deadmau5 song Asdfghjkl](https://www.youtube.com/watch?v=1aP910O2774)

## Fork Notes

This repository is a personal fork of [dave1010/Asdfghjkl](https://github.com/dave1010/Asdfghjkl/).
All core credit for the original project, design, and implementation goes to
[Dave Hulbert](https://github.com/dave1010). This fork was derived from upstream commit
[`1daed86`](https://github.com/dave1010/Asdfghjkl/commit/1daed86b932b82c210e53ba8893de6a8618d366b).

## Changes In This Fork

Since upstream commit [`1daed86`](https://github.com/dave1010/Asdfghjkl/commit/1daed86b932b82c210e53ba8893de6a8618d366b), this fork adds:

- Command-layer key translation, so printable bindings follow the current macOS layout's Command-equivalent mapping instead of the plain typed layer.
- Automatic left-click on the third refinement, while still allowing `Space` to click earlier.
- Configurable grid layouts via launch arguments or environment variables.
- Built-in `colemak` and `colemak5` presets.
- Custom grid-row definitions for both 4x10 and 4x5 layouts.
- Multi-display handling that keeps 5-column layouts intact on the screen under the mouse cursor instead of splitting them across displays.
- Additional tests covering command-layer translation, configurable layouts, partitioning rules, and the auto-click behavior.
- Documentation updates for the fork-specific behavior and `.DS_Store` ignore housekeeping.

![banner](banner.jpg)

## What does it do?

1. Double tap `Cmd` to see a keyboard grid on your screen.
2. Tap a corresponding key to move the mouse to that area.
3. Tap again (and again) to drill down.
4. After the third refinement, arstdhneio automatically left-clicks the final target.

You can still tap `Space` earlier to click before reaching the auto-click depth.

The overlay resolves printable bindings through the current macOS layout's Command-equivalent
mapping, so layouts that expose stable shortcut characters under `Cmd` keep the same arstdhneio
bindings even when their normal typing layer changes.

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

1. Download the latest `arstdhneio` binary from the [GitHub releases page](https://github.com/levYatsishin/arstdhneio/releases).
2. Remove the quarantine attribute since the binary is currently unsigned:
   ```sh
   xattr -c arstdhneio
   ```
3. Grant the required macOS permissions (Input Monitoring and Accessibility) when prompted so the app can create its global event tap.

## How does it work?

Read [ARCHITECTURE.md](ARCHITECTURE.md) for a deeper look at the current components and runtime flow.

![Architecture diagram](architecture.jpg)

### Multiple displays

On multi-display setups, the 4×10 grid is divided horizontally across all overlay windows so
the first keypress selects a screen by column range (e.g. `Q…T` on screen 1, `Y…P` on screen
2). Refinements after the first key keep using the per-screen slice, keeping labels and hit
testing aligned with the display that owns the tapped keys.

### Permissions

The macOS app installs the global CGEvent tap on launch (requires Input Monitoring and
Accessibility permissions) and rebuilds overlay windows whenever displays change, keeping a
window on every attached screen. Quit the app to tear down the tap cleanly.

Printable bindings are resolved from the current keyboard layout's Command-equivalent translation
rather than the plain typed character, matching the same character mapping macOS uses for
shortcuts and custom layouts that provide a dedicated Command layer.

On first launch, macOS may block the event tap unless the app is allowed under **System Settings > Privacy & Security > Input Monitoring** and **Accessibility**. The app now surfaces a dialog when the tap cannot be created so you can grant the permissions and restart.

## Development

`arstdhneio` is built with Swift 6.2 and targets macOS 14+.

### Grid layout parameters

You can choose a different overlay key layout at launch time:

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

Custom rows must contain four comma-separated rows with the same width and no duplicate
characters across the whole grid.

You can build and run `arstdhneio` with the provided `Makefile`:

```sh
make build   # swift build + direct swiftc compile for quick iteration
make test    # runs the GridLayout and overlay state tests
make run     # runs the executable from .build/debug
```

### Continuous integration

GitHub Actions keep the package healthy and provide a downloadable binary:

* `Test` runs on pushes to `main` and all pull requests, setting up Swift 6.2 on macOS and executing `swift test --parallel`.
* `macOS Binary` is a manually triggered workflow that builds the `arstdhneio` release product on macOS, captures the release bin path with `swift build --configuration release --show-bin-path`, lists the contents of that directory for debugging, and uploads the resulting executable as an artifact.
