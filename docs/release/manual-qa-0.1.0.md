# HanToggle 0.1.0 Manual QA

Date:
Tester:
Build:
macOS version:
Machine architecture:

## Automated Verification

- [ ] `swift test`
- [ ] `swift build --product HanToggleApp`
- [ ] `swift run hantoggle "这句话是简体中文。"`
- [ ] `swift run hantoggle "這句話是簡體中文。"`
- [ ] `Scripts/build-app.sh`
- [ ] `lipo -info build/HanToggle.app/Contents/MacOS/HanToggle` shows `arm64` and `x86_64`

## Native App Verification

- [ ] TextEdit: Simplified text converts to Traditional.
- [ ] TextEdit: pressing the hotkey again converts back.
- [ ] TextEdit: Traditional text converts to Simplified.
- [ ] TextEdit: no selected text shows clear failure and clipboard is preserved.
- [ ] TextEdit: non-Chinese selected text shows clear failure and clipboard is preserved.

## Common Non-Native App Verification

App tested:

- [ ] Selected Simplified text converts to Traditional.
- [ ] Pressing the hotkey again converts back.
- [ ] Clipboard is preserved after success.

## Permission Verification

- [ ] With Accessibility permission removed, HanToggle shows Accessibility Required.
- [ ] Open Accessibility Settings opens System Settings to Privacy & Security > Accessibility as closely as macOS allows.
- [ ] With Accessibility permission missing, hotkey does not mutate clipboard.
- [ ] After granting permission and restarting if needed, hotkey works.

## Hotkey Verification

- [ ] Changing to a valid unused shortcut saves and activates it.
- [ ] Invalid shortcut is rejected inline.
- [ ] Conflict or registration failure keeps previous working shortcut active.
- [ ] Reset to default validates, registers, and saves.

## Menu Bar And Launch Verification

- [ ] Menu-bar item is visible by default.
- [ ] Menu-bar item can be hidden only when a working hotkey exists.
- [ ] If hotkey registration fails on launch, menu-bar item becomes visible and shows the error.
- [ ] Launch at login toggle does not crash.
- [ ] If macOS rejects launch-at-login from the local build, HanToggle shows a clear error.

## Release Blockers

Stop release for any checked item:

- [ ] Clipboard data loss.
- [ ] Selected text, converted text, or clipboard contents logged, persisted, or transmitted.
- [ ] Silent hotkey failure.
- [ ] App cannot recover from a bad hotkey.
- [ ] App cannot guide user to Accessibility permission.
- [ ] Universal build, signing, notarization, stapling, or Gatekeeper verification fails.
- [ ] Third-party notices incomplete.

## Notes

Record failures, affected app, exact text selected, and whether clipboard contents changed. Do not paste private clipboard contents into this file.
