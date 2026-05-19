# HanToggle 0.1.0 Manual QA

Date: 2026-05-19
Verification: Release checklist
Build: b6e6700, local universal app bundle
macOS version: 26.4.1 (25E253)
Machine architecture: arm64

## Automated Verification

- [x] `swift test`
- [x] `swift build --product HanToggleApp`
- [x] `swift run hantoggle "这句话是简体中文。"`
- [x] `swift run hantoggle "這句話是簡體中文。"`
- [x] `Scripts/build-app.sh`
- [x] `lipo -info build/HanToggle.app/Contents/MacOS/HanToggle` shows `arm64` and `x86_64`

## Native App Verification

- [ ] TextEdit: Simplified text converts to Traditional.
- [ ] TextEdit: pressing the hotkey again converts back.
- [ ] TextEdit: Traditional text converts to Simplified.
- [ ] TextEdit: no selected text shows clear failure and clipboard is preserved.
- [ ] TextEdit: non-Chinese selected text shows clear failure and clipboard is preserved.

Status: Not run in this non-interactive automated session. Requires interactive desktop QA with Accessibility permission state controlled by the tester.

## Common Non-Native App Verification

App tested: Not run

- [ ] Selected Simplified text converts to Traditional.
- [ ] Pressing the hotkey again converts back.
- [ ] Clipboard is preserved after success.

Status: Not run in this non-interactive automated session. Test with a common non-native app before release.

## Permission Verification

- [ ] With Accessibility permission removed, HanToggle shows Accessibility Required.
- [ ] Open Accessibility Settings opens System Settings to Privacy & Security > Accessibility as closely as macOS allows.
- [ ] With Accessibility permission missing, hotkey does not mutate clipboard.
- [ ] After granting permission and restarting if needed, hotkey works.

Status: Not run manually. Automated tests cover state guidance and no clipboard mutation before permission, but release still needs interactive permission QA.

## Hotkey Verification

- [ ] Changing to a valid unused shortcut saves and activates it.
- [ ] Invalid shortcut is rejected inline.
- [ ] Conflict or registration failure keeps previous working shortcut active.
- [ ] Reset to default validates, registers, and saves.

Status: Not run manually. Automated tests cover validation, failed registration, persistence-after-activation, and previous-hotkey preservation.

## Menu Bar And Launch Verification

- [ ] Menu-bar item is visible by default.
- [ ] Menu-bar item can be hidden only when a working hotkey exists.
- [ ] If hotkey registration fails on launch, menu-bar item becomes visible and shows the error.
- [ ] Launch at login toggle does not crash.
- [ ] If macOS rejects launch-at-login from the local build, HanToggle shows a clear error.

Status: Not run manually. Automated tests cover menu-bar safety, hidden preference restoration, hotkey failure visibility, and launch-at-login error handling.

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

Automated verification passed:

- `swift test`: passed, 80 tests.
- `swift build --product HanToggleApp`: passed.
- CLI Simplified to Traditional output: `這句話是簡體中文。`
- CLI Traditional to Simplified output: `这句话是简体中文。`
- `Scripts/build-app.sh`: passed.
- `lipo -info build/HanToggle.app/Contents/MacOS/HanToggle`: `x86_64 arm64`.
- `bash -n Scripts/build-app.sh Scripts/check-notarization.sh Scripts/release.sh`: passed.

Release environment checks:

- Required commands present: `swift`, `lipo`, `codesign`, `xcrun`, `hdiutil`, `spctl`, `security`, `gh`.
- Developer ID signing identity present: `Developer ID Application: Your Name (YOURTEAMID)`.
- Notary profile `notarization-profile` is not usable on this machine. Run `xcrun notarytool history --keychain-profile notarization-profile` for details.

Release decision: not ready for public 0.1.0 beta until interactive manual QA is completed and the notary profile is configured so signing, notarization, stapling, and Gatekeeper verification can run end to end.
