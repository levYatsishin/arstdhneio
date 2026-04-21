#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${APP_PATH:-$ROOT_DIR/dist/arstdhneio.app}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications}"
TARGET_PATH="$INSTALL_DIR/arstdhneio.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found at $APP_PATH. Run ./scripts/build-app.sh first." >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
rm -rf "$TARGET_PATH"
ditto "$APP_PATH" "$TARGET_PATH"
xattr -cr "$TARGET_PATH" >/dev/null 2>&1 || true

echo "Installed app bundle to $TARGET_PATH"
