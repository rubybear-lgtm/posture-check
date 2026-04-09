#!/bin/zsh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT/PostureCheck.xcodeproj"
SCHEME="${SCHEME:-PostureCheck}"
APP_NAME="${APP_NAME:-PostureCheck}"
DISPLAY_NAME="${DISPLAY_NAME:-Posture Check}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-$ROOT/build/release}"
DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
DMG_STAGING_PATH="$BUILD_DIR/dmg-staging"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
CHECKSUM_PATH="$BUILD_DIR/$APP_NAME.dmg.sha256"

if [[ -d /Applications/Xcode.app ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

mkdir -p "$BUILD_DIR"
rm -rf "$DERIVED_DATA_PATH" "$DMG_STAGING_PATH" "$DMG_PATH" "$CHECKSUM_PATH"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected built app at $APP_PATH" >&2
  exit 1
fi

mkdir -p "$DMG_STAGING_PATH"
cp -R "$APP_PATH" "$DMG_STAGING_PATH/"
ln -s /Applications "$DMG_STAGING_PATH/Applications"

hdiutil create \
  -volname "$DISPLAY_NAME" \
  -srcfolder "$DMG_STAGING_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

shasum -a 256 "$DMG_PATH" > "$CHECKSUM_PATH"

echo "Built unsigned DMG:"
echo "  $DMG_PATH"
echo "Checksum:"
cat "$CHECKSUM_PATH"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "dmg_path=$DMG_PATH"
    echo "checksum_path=$CHECKSUM_PATH"
  } >> "$GITHUB_OUTPUT"
fi
