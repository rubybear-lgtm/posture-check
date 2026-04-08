#!/bin/zsh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICON_DIR="$ROOT/PostureCheck/Assets.xcassets/AppIcon.appiconset"

find "$ICON_DIR" -maxdepth 1 -name 'icon_*.png' -delete
find "$ICON_DIR" -maxdepth 1 -name 'appicon-*.png' -delete
swift "$ROOT/scripts/generate_app_icon.swift" "$ICON_DIR"
