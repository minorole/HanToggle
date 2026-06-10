# Changelog

All notable changes to HanToggle will be documented in this file.

## 0.1.0 - 2026-06-09

### Added

- Native macOS menu-bar app for toggling selected Chinese text between Simplified and Traditional.
- Configurable global hotkey with validation and conflict warnings.
- Accessibility permission guidance with direct System Settings action.
- Clipboard-preserving selected-text replacement flow.
- Launch-at-login setting.
- Universal Apple Silicon and Intel release packaging scripts.

### Fixed

- Opening Accessibility Settings no longer also triggers macOS's separate accessibility prompt, avoiding a double-open first-run flow.

### Privacy

- Conversion remains local.
- HanToggle does not include analytics, telemetry, update checks, or network conversion.
- Selected text, converted text, and clipboard contents are not logged, persisted, or transmitted.

## Unreleased

- No unreleased changes yet.
