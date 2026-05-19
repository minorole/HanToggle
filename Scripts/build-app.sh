#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/HanToggle.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
APP_BINARY="$MACOS_DIR/HanToggle"
SOURCE_BINARY="$PROJECT_DIR/.build/release/HanToggleApp"
INFO_PLIST="$PROJECT_DIR/Sources/HanToggleApp/Resources/Info.plist"
SOURCE_ENTITLEMENTS="$PROJECT_DIR/Sources/HanToggleApp/Resources/HanToggle.entitlements"
BUILD_ENTITLEMENTS="$BUILD_DIR/HanToggle.entitlements"

cd "$PROJECT_DIR"

echo "Building HanToggleApp release product..."
swift build -c release --product HanToggleApp

echo "Creating app bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"

cp "$SOURCE_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cp "$INFO_PLIST" "$CONTENTS_DIR/Info.plist"
cp "$SOURCE_ENTITLEMENTS" "$BUILD_ENTITLEMENTS"

echo "Built $APP_BUNDLE"
