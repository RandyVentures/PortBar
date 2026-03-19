#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/PortBar.xcodeproj"
BUILD_ROOT="$ROOT_DIR/build"
DERIVED_DATA_PATH="$BUILD_ROOT/ReleaseDerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/PortBar.app"
DEVELOPMENT_TEAM="${PORTBAR_DEVELOPMENT_TEAM:-}"
SIGNING_IDENTITY="${PORTBAR_CODE_SIGN_IDENTITY:-Developer ID Application}"

rm -rf "$DERIVED_DATA_PATH"

xcodebuild_args=(
  -project "$PROJECT_PATH" \
  -scheme PortBar \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  ENABLE_HARDENED_RUNTIME=YES \
  ENABLE_DEBUG_DYLIB=NO \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  build
)

if [[ -n "$DEVELOPMENT_TEAM" ]]; then
  xcodebuild_args+=(DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM")
fi

xcodebuild "${xcodebuild_args[@]}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected release app bundle not found at $APP_PATH" >&2
  exit 1
fi

echo
echo "Built release app:"
echo "$APP_PATH"
