#!/bin/zsh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="$ROOT/build/DerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug/PostureCheck.app"

if [[ -d /Applications/Xcode.app ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

pkill -x PostureCheck >/dev/null 2>&1 || true

xcodebuild \
  -project "$ROOT/PostureCheck.xcodeproj" \
  -scheme PostureCheck \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build

open "$APP_PATH"
