#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${APP_PATH:-$ROOT_DIR/dist/arstdhneio.app}"
OUTPUT_PATH="${OUTPUT_PATH:-$ROOT_DIR/dist/arstdhneio-macos-app.zip}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found at $APP_PATH. Run ./scripts/build-app.sh first." >&2
  exit 1
fi

rm -f "$OUTPUT_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$OUTPUT_PATH"

echo "Packaged release archive at $OUTPUT_PATH"
