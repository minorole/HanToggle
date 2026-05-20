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
OPENCC_RESOURCE_BUNDLE_NAME="SwiftyOpenCC_OpenCC.bundle"
OPENCC_RESOURCE_BUNDLE="$RESOURCES_DIR/$OPENCC_RESOURCE_BUNDLE_NAME"
ARM_TRIPLE="arm64-apple-macosx"
X86_TRIPLE="x86_64-apple-macosx"
ARM_BINARY="$SWIFTPM_BUILD_DIR/$ARM_TRIPLE/release/HanToggleApp"
X86_BINARY="$SWIFTPM_BUILD_DIR/$X86_TRIPLE/release/HanToggleApp"
INFO_PLIST="$PROJECT_DIR/Sources/HanToggleApp/Resources/Info.plist"
SOURCE_ENTITLEMENTS="$PROJECT_DIR/Sources/HanToggleApp/Resources/HanToggle.entitlements"
BUILD_ENTITLEMENTS="$BUILD_DIR/HanToggle.entitlements"
APP_ICON="$PROJECT_DIR/Sources/HanToggleApp/Resources/HanToggle.icns"
MENU_BAR_ICON="$PROJECT_DIR/Sources/HanToggleApp/Resources/MenuBarIconTemplate.png"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

cd "$PROJECT_DIR"

patch_swifty_opencc_checkout() {
    local converter_file="$SWIFTPM_BUILD_DIR/checkouts/SwiftyOpenCC/Sources/OpenCC/ChineseConverter.swift"

    if [[ ! -f "$converter_file" ]]; then
        echo "Missing SwiftyOpenCC checkout file: $converter_file" >&2
        exit 1
    fi

    if grep -q "openCCResourceBundle" "$converter_file"; then
        return
    fi

    chmod u+w "$converter_file"
    perl -0pi -e 's/let loader = DictionaryLoader\(bundle: \.module\)/let loader = DictionaryLoader(bundle: Bundle.openCCResourceBundle)/' "$converter_file"

    cat >> "$converter_file" <<'SWIFT'

private final class OpenCCBundleFinder {}

private extension Bundle {
    static var openCCResourceBundle: Bundle {
        let bundleName = "SwiftyOpenCC_OpenCC.bundle"
        let candidates = [
            Bundle.main.resourceURL,
            Bundle(for: OpenCCBundleFinder.self).resourceURL,
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            guard let bundleURL = candidate?.appendingPathComponent(bundleName),
                  let bundle = Bundle(url: bundleURL) else {
                continue
            }

            return bundle
        }

        Swift.fatalError("could not load resource bundle: \(bundleName)")
    }
}
SWIFT

    if ! grep -q "DictionaryLoader(bundle: Bundle.openCCResourceBundle)" "$converter_file"; then
        echo "Failed to patch SwiftyOpenCC resource bundle loader." >&2
        exit 1
    fi
}

echo "Creating app bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "Resolving dependencies..."
swift package --scratch-path "$SWIFTPM_BUILD_DIR" resolve
patch_swifty_opencc_checkout

echo "Building HanToggleApp for arm64..."
swift build -c release --product HanToggleApp --arch arm64 --scratch-path "$SWIFTPM_BUILD_DIR"

echo "Building HanToggleApp for x86_64..."
swift build -c release --product HanToggleApp --arch x86_64 --scratch-path "$SWIFTPM_BUILD_DIR"

echo "Creating universal binary..."
lipo -create "$ARM_BINARY" "$X86_BINARY" -output "$APP_BINARY"
chmod +x "$APP_BINARY"

cp "$INFO_PLIST" "$CONTENTS_DIR/Info.plist"
cp "$SOURCE_ENTITLEMENTS" "$BUILD_ENTITLEMENTS"
cp "$APP_ICON" "$RESOURCES_DIR/HanToggle.icns"
cp "$MENU_BAR_ICON" "$RESOURCES_DIR/MenuBarIconTemplate.png"

echo "Copying SwiftPM resource bundle..."
for ARCH_TRIPLE in "$ARM_TRIPLE" "$X86_TRIPLE"; do
    RESOURCE_BUNDLE="$SWIFTPM_BUILD_DIR/$ARCH_TRIPLE/release/SwiftyOpenCC_OpenCC.bundle"
    if [[ ! -d "$RESOURCE_BUNDLE" ]]; then
        echo "Missing SwiftPM resource bundle: $RESOURCE_BUNDLE" >&2
        exit 1
    fi
done

rm -rf "$OPENCC_RESOURCE_BUNDLE"
cp -R "$SWIFTPM_BUILD_DIR/$ARM_TRIPLE/release/$OPENCC_RESOURCE_BUNDLE_NAME" "$OPENCC_RESOURCE_BUNDLE"
rm -rf "$SWIFTPM_BUILD_DIR"

if [[ -z "$SIGN_IDENTITY" ]]; then
    SIGN_IDENTITY="-"
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
