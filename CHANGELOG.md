# Changelog

All notable changes to this fork are documented in this file.

The format is based on Keep a Changelog, adapted for this repository.

## [v0.3.0] - 2026-04-23

### Added

- A configurable activation shortcut model that supports arbitrary combinations of `Command`, `Option`, `Control`, and `Shift` plus a printable key.
- In-app shortcut controls in the menu bar `Configuration...` window, including saved modifier toggles and a live shortcut preview.
- Launch-time shortcut overrides with `--activation-key`, `--activation-modifiers`, and `ARSTDHNEIO_ACTIVATION_*` environment variables.
- App icon generation from `icon/icon.png` into bundled `.icns` assets for local and release builds.
- Release packaging and publishing documentation for the forked `arstdhneio.app` flow.

### Changed

- Activation is now centered around a configurable shortcut model instead of a fixed `Cmd+;` assumption, while keeping `Command+;` as the default.
- The settings model now persists activation mode, shortcut modifiers, and shortcut key in `UserDefaults`.
- Hotkey registration now resolves the configured key through the current layout under the selected modifier set, rather than assuming a Command-only binding.
- README and architecture docs now describe the shortcut system, release flow, and current packaged-app behavior more accurately.

### Fixed

- The Configuration window now exposes the active shortcut clearly instead of hiding it behind a hard-coded `Cmd+;` path.
- Shortcut settings now round-trip cleanly between stored defaults, launch-time overrides, and runtime hotkey re-registration.
