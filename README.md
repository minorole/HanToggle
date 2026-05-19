# HanToggle

HanToggle is a lightweight macOS menu-bar utility for toggling selected Chinese text between Simplified and Traditional with a global hotkey.

The intended workflow is:

1. Select Chinese text in any app.
2. Press the configured hotkey.
3. HanToggle replaces the selection with the opposite script.
4. Press the hotkey again to convert it back.

## Current Status

HanToggle is under active development. The repository currently includes:

- A tested local conversion library.
- A small CLI harness for development and verification.
- A SwiftPM macOS menu-bar app target.
- Global hotkey, status menu, settings, launch-at-login, accessibility permission, pasteboard preservation, and text replacement infrastructure.
- Local build and release scripts.

Notarized public downloads are not published yet.

## Build And Test

Run commands from the repository root.

```sh
swift build
swift test
```

Try the CLI:

```sh
swift run hantoggle "这句话是简体中文。"
swift run hantoggle "這句話是簡體中文。"
```

Run the app from SwiftPM:

```sh
swift run HanToggleApp
```

Build a local `.app` bundle:

```sh
Scripts/build-app.sh
```

## Privacy

HanToggle converts text locally. It does not use analytics, telemetry, update checks, or network conversion.

Selected text and clipboard contents are private user data. The app should not log, persist, or transmit selected text, clipboard contents, or converted text. The text replacement flow is designed to preserve the user's clipboard whenever possible.

## Permissions

The menu-bar app needs macOS Accessibility permission to automate selected-text replacement in other apps. If permission is missing, HanToggle should fail clearly and guide the user to the correct macOS setting.

## Release Scripts

The scripts in `Scripts/` build and package local release artifacts:

- `Scripts/build-app.sh` builds `build/HanToggle.app`.
- `Scripts/check-notarization.sh` checks that the configured Apple notarytool keychain profile is available.
- `Scripts/release.sh` runs tests, builds, signs, notarizes, staples, and creates a DMG.

The notarized release flow requires local Apple signing credentials and a notarytool keychain profile such as `notarization-profile`. Those credentials are not stored in this repository.

## Architecture

- `Sources/HanToggle`: core conversion library.
- `Sources/HanToggleCLI`: command-line development harness.
- `Sources/HanToggleApp`: macOS menu-bar app, hotkey registration, settings, permissions, pasteboard, and text replacement services.
- `Tests/HanToggleTests`: conversion behavior tests.
- `Tests/HanToggleAppTests`: app service and settings tests.

The core conversion layer uses `SwiftyOpenCC`, pinned in `Package.swift` for reproducible dependency resolution.

## License

MIT. See `LICENSE`.
