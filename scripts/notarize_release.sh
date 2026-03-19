#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$ROOT_DIR/build/ReleaseDerivedData/Build/Products/Release/PortBar.app"
KEYCHAIN_PROFILE="${PORTBAR_NOTARY_PROFILE:-portbar-notary}"
VERSION="${1:-$(git -C "$ROOT_DIR" rev-parse --short HEAD)}"
NOTARY_ZIP="$DIST_DIR/PortBar-${VERSION}-for-notary.zip"
FINAL_ZIP="$DIST_DIR/PortBar-${VERSION}-macOS.zip"
CHECKSUM_PATH="$FINAL_ZIP.sha256"

"$ROOT_DIR/scripts/build_release.sh" >/dev/null

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected release app bundle not found at $APP_PATH" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -f "$NOTARY_ZIP" "$FINAL_ZIP" "$CHECKSUM_PATH"

ditto -c -k --keepParent "$APP_PATH" "$NOTARY_ZIP"

xcrun notarytool submit "$NOTARY_ZIP" \
  --keychain-profile "$KEYCHAIN_PROFILE" \
  --wait

xcrun stapler staple "$APP_PATH"

ditto -c -k --keepParent "$APP_PATH" "$FINAL_ZIP"
shasum -a 256 "$FINAL_ZIP" > "$CHECKSUM_PATH"

echo "Notarized release archive:"
echo "$FINAL_ZIP"
echo
echo "SHA-256:"
cat "$CHECKSUM_PATH"
