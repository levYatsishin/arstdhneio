# Publishing

This fork currently publishes a zipped `arstdhneio.app` bundle, not a loose binary.

## Local release prep

Use the same steps locally that CI uses:

```sh
SWIFT="$HOME/.swiftly/bin/swift" make publish-check
SWIFT="$HOME/.swiftly/bin/swift" make release-archive
```

That produces:

- `dist/arstdhneio.app`
- `dist/arstdhneio-macos-app.zip`

## Before tagging a release

1. Build the debug target:
   ```sh
   SWIFT="$HOME/.swiftly/bin/swift" make build
   ```
2. Build the app bundle:
   ```sh
   SWIFT="$HOME/.swiftly/bin/swift" make app
   ```
3. Install and launch the app from a stable path:
   ```sh
   SWIFT="$HOME/.swiftly/bin/swift" make install-app
   open ~/Applications/arstdhneio.app
   ```
4. Verify both activation modes:
   - default `Cmd+;` mode
   - optional `Double-Command Tap` mode
5. Verify both layout types:
   - a built-in preset such as `colemak5`
   - a custom four-row layout
6. Verify the menu bar items:
   - `Configuration...`
   - `Launch at Login`
   - `About arstdhneio`
7. Confirm the app bundle zip exists:
   ```sh
   SWIFT="$HOME/.swiftly/bin/swift" make release-archive
   ```

## GitHub release flow

The repo is configured so that pushing a tag like `v0.1.0` triggers the release workflow and
uploads `arstdhneio-macos-app.zip`.

Example:

```sh
git tag v0.1.0
git push origin v0.1.0
```

## Known limitation

The current local app bundle is ad-hoc signed for development and personal distribution. Rebuilding
or reinstalling it may cause macOS to ask for Accessibility or Input Monitoring permissions again.
For more stable TCC behavior in public distribution, the next step is proper Apple code signing.
