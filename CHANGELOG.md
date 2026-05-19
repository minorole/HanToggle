# Changelog

All notable changes to HanToggle will be documented in this file.

## 0.1.0 - 2026-05-19

### Added

- Native macOS menu-bar app for toggling selected Chinese text between Simplified and Traditional.
- Configurable global hotkey with validation and conflict warnings.
- Accessibility permission guidance with direct System Settings action.
- Clipboard-preserving selected-text replacement flow.
- Launch-at-login setting.
- Universal Apple Silicon and Intel release packaging scripts.

### Privacy

- Conversion remains local.
- HanToggle does not include analytics, telemetry, update checks, or network conversion.
- Selected text, converted text, and clipboard contents are not logged, persisted, or transmitted.

## Unreleased

- Added a local Chinese script conversion core using SwiftyOpenCC and OpenCC dictionaries.
- Added a command-line harness for testing Simplified and Traditional conversion.
- Added a SwiftPM macOS menu-bar app target.
- Added global hotkey registration, app settings, launch-at-login support, and status menu UI.
- Added selected-text replacement infrastructure with pasteboard preservation behavior.
- Added accessibility permission guidance and focused app/core tests.
- Added local app bundle and notarized release scripts.
