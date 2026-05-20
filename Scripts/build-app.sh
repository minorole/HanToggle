#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROJECT_DIR/build}"
APP_BUNDLE="$BUILD_DIR/HanToggle.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
APP_BINARY="$MACOS_DIR/HanToggle"
SWIFTPM_BUILD_DIR="$RESOURCES_DIR/SwiftPMBuild"
ARM_TRIPLE="arm64-apple-macosx"
X86_TRIPLE="x86_64-apple-macosx"
ARM_BINARY="$SWIFTPM_BUILD_DIR/$ARM_TRIPLE/release/HanToggleApp"
X86_BINARY="$SWIFTPM_BUILD_DIR/$X86_TRIPLE/release/HanToggleApp"
INFO_PLIST="$PROJECT_DIR/Sources/HanToggleApp/Resources/Info.plist"
SOURCE_ENTITLEMENTS="$PROJECT_DIR/Sources/HanToggleApp/Resources/HanToggle.entitlements"
BUILD_ENTITLEMENTS="$BUILD_DIR/HanToggle.entitlements"
DEFAULT_SIGN_IDENTITY="Developer ID Application: Your Name (YOURTEAMID)"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

cd "$PROJECT_DIR"

echo "Creating app bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "Building HanToggleApp for arm64..."
swift build -c release --product HanToggleApp --arch arm64 --scratch-path "$SWIFTPM_BUILD_DIR"

echo "Building HanToggleApp for x86_64..."
swift build -c release --product HanToggleApp --arch x86_64 --scratch-path "$SWIFTPM_BUILD_DIR"

echo "Creating universal binary..."
lipo -create "$ARM_BINARY" "$X86_BINARY" -output "$APP_BINARY"
chmod +x "$APP_BINARY"

cp "$INFO_PLIST" "$CONTENTS_DIR/Info.plist"
cp "$SOURCE_ENTITLEMENTS" "$BUILD_ENTITLEMENTS"

echo "Pruning SwiftPM build output to required resource bundles..."
PRUNED_RESOURCE_DIR="$BUILD_DIR/swiftpm-resource-bundles"
rm -rf "$PRUNED_RESOURCE_DIR"
for ARCH_TRIPLE in "$ARM_TRIPLE" "$X86_TRIPLE"; do
    RESOURCE_BUNDLE="$SWIFTPM_BUILD_DIR/$ARCH_TRIPLE/release/SwiftyOpenCC_OpenCC.bundle"
    if [[ ! -d "$RESOURCE_BUNDLE" ]]; then
        echo "Missing SwiftPM resource bundle: $RESOURCE_BUNDLE" >&2
        exit 1
    fi

    mkdir -p "$PRUNED_RESOURCE_DIR/$ARCH_TRIPLE/release"
    cp -R "$RESOURCE_BUNDLE" "$PRUNED_RESOURCE_DIR/$ARCH_TRIPLE/release/"
done
rm -rf "$SWIFTPM_BUILD_DIR"
mkdir -p "$SWIFTPM_BUILD_DIR"
cp -R "$PRUNED_RESOURCE_DIR"/. "$SWIFTPM_BUILD_DIR/"
rm -rf "$PRUNED_RESOURCE_DIR"

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
