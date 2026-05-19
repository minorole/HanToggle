#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TEAM_ID="${TEAM_ID:-YOURTEAMID}"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Your Name (YOURTEAMID)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-notarization-profile}"

BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/HanToggle.app"
ENTITLEMENTS="$BUILD_DIR/HanToggle.entitlements"
ZIP_PATH="$BUILD_DIR/HanToggle.zip"
DMG_ROOT="$BUILD_DIR/dmg-root"
DMG_PATH="$BUILD_DIR/HanToggle.dmg"

cd "$PROJECT_DIR"

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    echo "Working directory is dirty. Commit or remove changes before release." >&2
    git status --short
    exit 1
fi

echo "Running tests..."
swift test

NOTARY_PROFILE="$NOTARY_PROFILE" "$SCRIPT_DIR/check-notarization.sh"
"$SCRIPT_DIR/build-app.sh"

echo "Signing app with Developer ID identity..."
codesign \
    --force \
    --options runtime \
    --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SIGN_IDENTITY" \
    "$APP_BUNDLE"

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

echo "Creating DMG..."
rm -rf "$DMG_ROOT"
rm -f "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_BUNDLE" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create \
    -volname "HanToggle" \
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

echo "Verifying DMG with Gatekeeper..."
spctl --assess --type open --context context:primary-signature -v "$DMG_PATH"

echo "Final artifact: $DMG_PATH"
