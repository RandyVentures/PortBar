#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$ROOT_DIR/build/ReleaseDerivedData/Build/Products/Release/PortBar.app"

VERSION="${1:-$(git -C "$ROOT_DIR" rev-parse --short HEAD)}"
ARCHIVE_NAME="PortBar-${VERSION}-macOS.zip"
ARCHIVE_PATH="$DIST_DIR/$ARCHIVE_NAME"
CHECKSUM_PATH="$ARCHIVE_PATH.sha256"

"$ROOT_DIR/scripts/build_release.sh" >/dev/null

mkdir -p "$DIST_DIR"
rm -f "$ARCHIVE_PATH" "$CHECKSUM_PATH"

ditto -c -k --keepParent "$APP_PATH" "$ARCHIVE_PATH"
shasum -a 256 "$ARCHIVE_PATH" > "$CHECKSUM_PATH"

echo "Packaged release archive:"
echo "$ARCHIVE_PATH"
echo
echo "SHA-256:"
cat "$CHECKSUM_PATH"
