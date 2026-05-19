#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/HanToggle.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
APP_BINARY="$MACOS_DIR/HanToggle"
ARM_BINARY="$PROJECT_DIR/.build/arm64-apple-macosx/release/HanToggleApp"
X86_BINARY="$PROJECT_DIR/.build/x86_64-apple-macosx/release/HanToggleApp"
INFO_PLIST="$PROJECT_DIR/Sources/HanToggleApp/Resources/Info.plist"
SOURCE_ENTITLEMENTS="$PROJECT_DIR/Sources/HanToggleApp/Resources/HanToggle.entitlements"
BUILD_ENTITLEMENTS="$BUILD_DIR/HanToggle.entitlements"
DEFAULT_SIGN_IDENTITY="Developer ID Application: Your Name (YOURTEAMID)"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

cd "$PROJECT_DIR"

echo "Building HanToggleApp for arm64..."
swift build -c release --product HanToggleApp --arch arm64

echo "Building HanToggleApp for x86_64..."
swift build -c release --product HanToggleApp --arch x86_64

echo "Creating app bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"

echo "Creating universal binary..."
lipo -create "$ARM_BINARY" "$X86_BINARY" -output "$APP_BINARY"
chmod +x "$APP_BINARY"

cp "$INFO_PLIST" "$CONTENTS_DIR/Info.plist"
cp "$SOURCE_ENTITLEMENTS" "$BUILD_ENTITLEMENTS"

if [[ -z "$SIGN_IDENTITY" ]]; then
    if security find-identity -v -p codesigning 2>/dev/null | grep -F "$DEFAULT_SIGN_IDENTITY" >/dev/null; then
        SIGN_IDENTITY="$DEFAULT_SIGN_IDENTITY"
    else
        SIGN_IDENTITY="-"
    fi
fi

if [[ "$SIGN_IDENTITY" == "-" ]]; then
    echo "Signing app ad-hoc..."
    codesign \
        --force \
        --entitlements "$BUILD_ENTITLEMENTS" \
        --sign "$SIGN_IDENTITY" \
        "$APP_BUNDLE"
    echo "Warning: ad-hoc signatures may require resetting Accessibility permission after each rebuild." >&2
else
    echo "Signing app with identity: $SIGN_IDENTITY"
    codesign \
        --force \
        --options runtime \
        --timestamp \
        --entitlements "$BUILD_ENTITLEMENTS" \
        --sign "$SIGN_IDENTITY" \
        "$APP_BUNDLE"
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

ARCH_INFO="$(lipo -info "$APP_BINARY")"
echo "$ARCH_INFO"

if [[ "$ARCH_INFO" != *"arm64"* || "$ARCH_INFO" != *"x86_64"* ]]; then
    echo "Universal binary verification failed. Expected arm64 and x86_64." >&2
    exit 1
fi

echo "Built $APP_BUNDLE"
