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
   Important: `make install-app` replaces the app bundle. Because the bundle is only ad-hoc signed,
   reinstalling it can invalidate existing Accessibility or Input Monitoring grants for that app path.
   For a real release check, do one clean install, grant permissions to that exact bundle, and test
   without reinstalling again in the middle of the check.
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
8. Update `CHANGELOG.md` with the release notes you want reflected on GitHub.

## GitHub release flow

The repo is configured so that pushing a tag like `v0.3.0` triggers the release workflow and
uploads `arstdhneio-macos-app.zip`.

Example:

```sh
git tag v0.3.0
git push origin v0.3.0
```

## Known limitation

The current local app bundle is ad-hoc signed for development and personal distribution. Rebuilding
or reinstalling it may cause macOS to ask for Accessibility or Input Monitoring permissions again.
For more stable TCC behavior in public distribution, the next step is proper Apple code signing.

## Publish readiness

What is already in place:

- renamed app/bundle/package identity for `arstdhneio`
- release workflow and local release archive flow
- `.app` bundle packaging
- README, architecture notes, and publishing notes
- menu bar app flow, configuration UI, and launch-at-login toggle

What is still incomplete for a polished first public release:

- the app is not signed with a stable Apple developer identity yet
- TCC permission grants can be invalidated after reinstall/update
- full `swift test` verification is still blocked in the current local environment because `XCTest` is not resolving here
- the current `Cmd+;` click path still needs real-world validation on your installed app flow
