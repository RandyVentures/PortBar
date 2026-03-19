#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/PortBar.xcodeproj"
BUILD_ROOT="$ROOT_DIR/build"
DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug/PortBar.app"

rm -rf "$DERIVED_DATA_PATH"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme PortBar \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_ALLOWED=YES \
  ENABLE_DEBUG_DYLIB=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app bundle not found at $APP_PATH" >&2
  exit 1
fi

echo
echo "Built app:"
echo "$APP_PATH"
