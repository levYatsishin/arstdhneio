#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT_NAME="${PRODUCT_NAME:-arstdhneio}"
CONFIGURATION="${CONFIGURATION:-release}"
SWIFT_BIN="${SWIFT:-swift}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/dist}"
BUNDLE_NAME="${BUNDLE_NAME:-arstdhneio}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-com.levyatsishin.arstdhneio}"
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BUILD="${APP_BUILD:-1}"
MINIMUM_SYSTEM_VERSION="${MINIMUM_SYSTEM_VERSION:-13.0}"
APP_BUNDLE="$OUTPUT_DIR/$BUNDLE_NAME.app"
APP_ICON_SOURCE="${APP_ICON_SOURCE:-$ROOT_DIR/icon/icon.png}"
APP_ICON_NAME="${APP_ICON_NAME:-AppIcon}"

cd "$ROOT_DIR"

"$SWIFT_BIN" build --configuration "$CONFIGURATION" --product "$PRODUCT_NAME"
BIN_PATH="$("$SWIFT_BIN" build --configuration "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH/$PRODUCT_NAME" "$APP_BUNDLE/Contents/MacOS/$PRODUCT_NAME"

if [[ -f "$APP_ICON_SOURCE" ]]; then
  ICON_WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/arstdhneio-icon.XXXXXX")"
  ICONSET_DIR="$ICON_WORK_DIR/$APP_ICON_NAME.iconset"
  mkdir -p "$ICONSET_DIR"

  for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$APP_ICON_SOURCE" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
    double_size=$((size * 2))
    sips -z "$double_size" "$double_size" "$APP_ICON_SOURCE" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
  done

  iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/$APP_ICON_NAME.icns"
  rm -rf "$ICON_WORK_DIR"
fi

sed \
  -e "s/__BUNDLE_NAME__/$BUNDLE_NAME/g" \
  -e "s/__BUNDLE_IDENTIFIER__/$BUNDLE_IDENTIFIER/g" \
  -e "s/__EXECUTABLE_NAME__/$PRODUCT_NAME/g" \
  -e "s/__VERSION__/$APP_VERSION/g" \
  -e "s/__BUILD__/$APP_BUILD/g" \
  -e "s/__MINIMUM_SYSTEM_VERSION__/$MINIMUM_SYSTEM_VERSION/g" \
  -e "s/__ICON_NAME__/$APP_ICON_NAME/g" \
  "$ROOT_DIR/Support/Info.plist.template" > "$APP_BUNDLE/Contents/Info.plist"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true
fi

echo "Built app bundle at $APP_BUNDLE"
echo "Note: this bundle is ad-hoc signed for local use. Rebuilding or reinstalling it may require re-granting macOS privacy permissions."
