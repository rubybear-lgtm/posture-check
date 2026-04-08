#!/bin/zsh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="$ROOT/build/DerivedDataSigned"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug/PostureCheck.app"
PROJECT_PATH="$ROOT/PostureCheck.xcodeproj"

if [[ -d /Applications/Xcode.app ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

if ! /usr/bin/xcodebuild -project "$PROJECT_PATH" -scheme PostureCheck -showBuildSettings 2>/dev/null | /usr/bin/grep -Eq '^[[:space:]]*DEVELOPMENT_TEAM = .+'; then
  echo "No DEVELOPMENT_TEAM is configured for PostureCheck."
  echo "Open $PROJECT_PATH in Xcode, select the PostureCheck target, then set Signing & Capabilities > Team."
  exit 1
fi

pkill -x PostureCheck >/dev/null 2>&1 || true

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme PostureCheck \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

open "$APP_PATH"
