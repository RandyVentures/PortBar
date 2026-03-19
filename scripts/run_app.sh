#!/bin/zsh
set -euo pipefail

ROOT="/Users/randall/Developer/Src/Repos/Portbar/PortBar"
APP_PATH="$ROOT/build/DerivedData/Build/Products/Debug/PortBar.app"

if [[ ! -d "$APP_PATH" ]]; then
  "$ROOT/scripts/build_app.sh" >/dev/null
fi

pkill -f 'PortBar.app/Contents/MacOS/PortBar' >/dev/null 2>&1 || true
open "$APP_PATH"
