# HanToggle 0.1.0

HanToggle is a lightweight macOS menu-bar utility for toggling selected Chinese text between Simplified and Traditional with a global hotkey.

## Download

Download `HanToggle-0.1.0.dmg`, open it, and drag `HanToggle.app` to Applications.

## Compatibility

- macOS 13 or newer
- Universal build for Apple Silicon and Intel Macs

## First-Run Setup

1. Launch HanToggle from Applications.
2. In the setup window, click **Open Accessibility Settings**.
3. Enable HanToggle in System Settings > Privacy & Security > Accessibility.
4. Return to HanToggle and run the local conversion test.
5. Click **Done** when HanToggle reports it is ready.

The default hotkey is `Control-Option-H`. You can change it in Preferences.

## What's Included

- Native macOS menu-bar app
- Local Simplified/Traditional Chinese conversion
- Configurable global hotkey
- Accessibility permission guidance
- Clipboard-preserving selected-text replacement
- Launch-at-login option
- Notarized Developer ID DMG

## Privacy

HanToggle converts text locally. It does not include analytics, telemetry, crash reporting, update checks, or network conversion.

Selected text, converted text, and clipboard contents are not logged, persisted, or transmitted. The text replacement flow is designed to preserve the user's clipboard whenever possible.

Privacy details are also documented in the README: https://github.com/minorole/HanToggle#privacy

## Support

For feedback, feature requests, or support, email hi@minor-role.com.

Do not include private selected text or clipboard contents in support messages.

Support details are also documented in the README: https://github.com/minorole/HanToggle#support

## Verification

This release passed automated tests, manual first-run setup QA, TextEdit conversion QA, common non-native app conversion QA, hotkey configuration QA, permission recovery QA, and notarized DMG verification.

Final artifact SHA-256:

```text
b601febff4053b0d1902b919d85757f1599dd557369ec2ab8d6460cb0381023d
```
