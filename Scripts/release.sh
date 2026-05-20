#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION="${VERSION:-0.1.0}"
TEAM_ID="${TEAM_ID:-}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-notarization-profile}"
DRAFT_GITHUB_RELEASE="${DRAFT_GITHUB_RELEASE:-0}"

BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/HanToggle.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/HanToggle"
ENTITLEMENTS="$BUILD_DIR/HanToggle.entitlements"
ZIP_PATH="$BUILD_DIR/HanToggle-$VERSION.zip"
DMG_ROOT="$BUILD_DIR/dmg-root"
DMG_PATH="$BUILD_DIR/HanToggle-$VERSION.dmg"

cd "$PROJECT_DIR"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

require_env() {
    if [[ -z "${!1:-}" ]]; then
        echo "Missing required environment variable: $1" >&2
        exit 1
    fi
}

require_command swift
require_command lipo
require_command codesign
require_command xcrun
require_command hdiutil
require_command spctl
require_command security

require_env TEAM_ID
require_env SIGN_IDENTITY

if [[ "$DRAFT_GITHUB_RELEASE" == "1" ]]; then
    require_command gh
fi

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    echo "Working directory is dirty. Commit or remove changes before release." >&2
    git status --short
    exit 1
fi

if ! security find-identity -v -p codesigning | grep -F "$SIGN_IDENTITY" >/dev/null; then
    echo "Signing identity not found: $SIGN_IDENTITY" >&2
    exit 1
fi

echo "Running tests..."
swift test

NOTARY_PROFILE="$NOTARY_PROFILE" "$SCRIPT_DIR/check-notarization.sh"
"$SCRIPT_DIR/build-app.sh"

ARCH_INFO="$(lipo -info "$APP_BINARY")"
if [[ "$ARCH_INFO" != *"arm64"* || "$ARCH_INFO" != *"x86_64"* ]]; then
    echo "Release binary is not universal: $ARCH_INFO" >&2
    exit 1
fi

echo "Signing app with Developer ID identity..."
codesign \
    --force \
    --options runtime \
    --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SIGN_IDENTITY" \
    "$APP_BUNDLE"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "Creating notarization zip..."
rm -f "$ZIP_PATH"
(
    cd "$BUILD_DIR"
    ditto -c -k --keepParent "HanToggle.app" "$ZIP_PATH"
)

echo "Submitting app zip for notarization..."
xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --team-id "$TEAM_ID" \
    --wait

echo "Stapling notarization ticket to app..."
xcrun stapler staple "$APP_BUNDLE"
xcrun stapler validate "$APP_BUNDLE"

echo "Creating DMG..."
rm -rf "$DMG_ROOT"
rm -f "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_BUNDLE" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create \
    -volname "HanToggle $VERSION" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "Signing DMG..."
codesign \
    --force \
    --timestamp \
    --sign "$SIGN_IDENTITY" \
    "$DMG_PATH"

echo "Submitting DMG for notarization..."
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --team-id "$TEAM_ID" \
    --wait

echo "Stapling notarization ticket to DMG..."
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo "Verifying DMG with Gatekeeper..."
spctl --assess --type open --context context:primary-signature -v "$DMG_PATH"

if [[ "$DRAFT_GITHUB_RELEASE" == "1" ]]; then
    echo "Drafting GitHub release v$VERSION..."
    gh release create "v$VERSION" "$DMG_PATH" \
        --draft \
        --title "HanToggle $VERSION" \
        --notes-file CHANGELOG.md
fi

echo "Final artifact: $DMG_PATH"
