#!/bin/zsh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT/PostureCheck.xcodeproj"
SCHEME="${SCHEME:-PostureCheck}"
APP_NAME="${APP_NAME:-PostureCheck}"
DISPLAY_NAME="${DISPLAY_NAME:-Posture Check}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-$ROOT/build/release}"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_OPTIONS_PLIST="$BUILD_DIR/ExportOptions.plist"
APP_ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"
DMG_STAGING_PATH="$BUILD_DIR/dmg-staging"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
CHECKSUM_PATH="$BUILD_DIR/$APP_NAME.dmg.sha256"
RUNNER_TEMP_DIR="${RUNNER_TEMP:-$BUILD_DIR/tmp}"
KEYCHAIN_PATH="$RUNNER_TEMP_DIR/app-signing.keychain-db"
CERTIFICATE_PATH="$RUNNER_TEMP_DIR/build_certificate.p12"
API_KEY_PATH="$RUNNER_TEMP_DIR/AuthKey_${APPLE_API_KEY_ID:-missing}.p8"

require_env() {
  local name="$1"
  if [[ -z "${(P)name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

cleanup() {
  rm -f "$CERTIFICATE_PATH" "$API_KEY_PATH"
  if security list-keychains -d user | grep -q "$KEYCHAIN_PATH"; then
    security delete-keychain "$KEYCHAIN_PATH" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

require_env BUILD_CERTIFICATE_BASE64
require_env P12_PASSWORD
require_env KEYCHAIN_PASSWORD
require_env APPLE_API_KEY_ID
require_env APPLE_API_ISSUER_ID
require_env APPLE_API_PRIVATE_KEY_BASE64

if [[ -d /Applications/Xcode.app ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

mkdir -p "$BUILD_DIR" "$RUNNER_TEMP_DIR"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$DMG_STAGING_PATH" "$DMG_PATH" "$APP_ZIP_PATH" "$CHECKSUM_PATH"

printf '%s' "$BUILD_CERTIFICATE_BASE64" | base64 -D > "$CERTIFICATE_PATH"
printf '%s' "$APPLE_API_PRIVATE_KEY_BASE64" | base64 -D > "$API_KEY_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$CERTIFICATE_PATH" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH"
security default-keychain -d user -s "$KEYCHAIN_PATH"

TEAM_ID="${TEAM_ID:-$(
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -showBuildSettings | awk -F' = ' '/DEVELOPMENT_TEAM = / { print $2; exit }'
)}"

if [[ -z "$TEAM_ID" ]]; then
  echo "Unable to determine DEVELOPMENT_TEAM from project settings." >&2
  exit 1
fi

DEVELOPER_ID_APPLICATION_IDENTITY="${DEVELOPER_ID_APPLICATION_IDENTITY:-$(
  security find-identity -v -p codesigning "$KEYCHAIN_PATH" |
    sed -n 's/.*\"\\(Developer ID Application:.*\\)\"/\\1/p' |
    head -n 1
)}"

if [[ -z "$DEVELOPER_ID_APPLICATION_IDENTITY" ]]; then
  echo "No Developer ID Application identity found in the temporary keychain." >&2
  exit 1
fi

cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>$TEAM_ID</string>
</dict>
</plist>
EOF

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  OTHER_CODE_SIGN_FLAGS="--keychain $KEYCHAIN_PATH" \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

EXPORTED_APP_PATH="$EXPORT_PATH/$APP_NAME.app"
if [[ ! -d "$EXPORTED_APP_PATH" ]]; then
  echo "Expected exported app at $EXPORTED_APP_PATH" >&2
  exit 1
fi

/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$EXPORTED_APP_PATH" "$APP_ZIP_PATH"
xcrun notarytool submit "$APP_ZIP_PATH" \
  --key "$API_KEY_PATH" \
  --key-id "$APPLE_API_KEY_ID" \
  --issuer "$APPLE_API_ISSUER_ID" \
  --wait
xcrun stapler staple "$EXPORTED_APP_PATH"

mkdir -p "$DMG_STAGING_PATH"
cp -R "$EXPORTED_APP_PATH" "$DMG_STAGING_PATH/"
ln -s /Applications "$DMG_STAGING_PATH/Applications"

hdiutil create \
  -volname "$DISPLAY_NAME" \
  -srcfolder "$DMG_STAGING_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

codesign \
  --force \
  --sign "$DEVELOPER_ID_APPLICATION_IDENTITY" \
  --timestamp \
  "$DMG_PATH"

xcrun notarytool submit "$DMG_PATH" \
  --key "$API_KEY_PATH" \
  --key-id "$APPLE_API_KEY_ID" \
  --issuer "$APPLE_API_ISSUER_ID" \
  --wait
xcrun stapler staple "$DMG_PATH"

spctl -a -vv "$EXPORTED_APP_PATH"
spctl -a -t open --context context:primary-signature -vv "$DMG_PATH"

shasum -a 256 "$DMG_PATH" > "$CHECKSUM_PATH"

echo "Built notarized DMG:"
echo "  $DMG_PATH"
echo "Checksum:"
cat "$CHECKSUM_PATH"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "dmg_path=$DMG_PATH"
    echo "checksum_path=$CHECKSUM_PATH"
  } >> "$GITHUB_OUTPUT"
fi
