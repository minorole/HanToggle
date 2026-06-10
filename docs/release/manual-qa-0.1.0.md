# HanToggle 0.1.0 Manual QA

Date: 2026-06-09 EDT
Tester: Project owner
Build: `/Applications/HanToggle.app` installed from notarized `build/HanToggle-0.1.0.dmg`
macOS version: 26.5.1 (25F80)
Machine architecture: Apple Silicon (`arm64`)
Xcode: 26.5 (17F42)
Swift: 6.3.2

## Automated Verification

- [x] `swift test`
- [x] `swift test --filter openingAccessibilitySettingsDoesNotRequestSystemPrompt`
- [x] `swift run hantoggle "这句话是简体中文。"`
- [x] `swift run hantoggle "這句話是簡體中文。"`
- [x] `Scripts/build-app.sh`
- [x] `Scripts/release.sh`
- [x] `lipo -info build/HanToggle.app/Contents/MacOS/HanToggle` shows `x86_64 arm64`
- [x] App zip notarization accepted by Apple notary service
- [x] DMG notarization accepted by Apple notary service
- [x] App and DMG stapler validation passed
- [x] Gatekeeper accepted `build/HanToggle-0.1.0.dmg` as `Notarized Developer ID`

## Install Package Verification

- [x] Existing `/Applications/HanToggle.app` removed before install
- [x] `com.minorole.HanToggle` preferences deleted before first-run QA
- [x] Accessibility permission reset with `tccutil reset Accessibility com.minorole.HanToggle`
- [x] Installed app from `build/HanToggle-0.1.0.dmg`
- [x] Installed app signature verifies
- [x] Installed app stapler validation passes
- [x] Gatekeeper accepts installed app as `Notarized Developer ID`
- [x] Installed app version is `0.1.0`, build `1`
- [x] Installed app binary is universal: `x86_64 arm64`
- [x] DMG opens cleanly
- [x] DMG contains `HanToggle.app`
- [x] DMG contains `Applications -> /Applications` shortcut

## First-Run Setup QA

- [x] Setup window appears on first launch after clearing preferences
- [x] Setup shows Accessibility, keyboard shortcut, and local conversion test rows
- [x] Default shortcut is `Control-Option-H`
- [x] **Open Accessibility Settings** opens the Accessibility settings flow once, without a duplicate macOS prompt
- [x] Enabling Accessibility permission updates HanToggle to `Allowed`
- [x] Local conversion test passes
- [x] **Done** becomes available only after setup requirements pass
- [x] Completing setup shows menu status `HanToggle is ready`
- [x] Menu shows `Preferences` and `Quit`

## Native App Verification

- [x] TextEdit: Simplified text converts to Traditional
- [x] TextEdit: pressing the hotkey again converts back
- [x] TextEdit: clipboard is preserved after successful conversion
- [x] TextEdit: no selected text shows clear failure and clipboard is preserved
- [x] TextEdit: non-Chinese selected text shows clear failure and clipboard is preserved

## Common Non-Native App Verification

- [x] Common non-native app: selected Simplified text converts to Traditional
- [x] Common non-native app: pressing the hotkey again converts back
- [x] Common non-native app: clipboard is preserved after success

## Permission Verification

- [x] With Accessibility permission removed while running, conversion is blocked
- [x] With Accessibility permission removed, HanToggle shows Accessibility Required guidance
- [x] With Accessibility permission missing, hotkey does not mutate clipboard
- [x] After granting permission again, HanToggle recovers without restart
- [x] After granting permission again, hotkey conversion works

## Hotkey Verification

- [x] Changing to a valid unused shortcut saves and activates it
- [x] Shortcut owned by another global hotkey app is not saved by HanToggle
- [x] Resetting back to `Control-Option-H` validates, registers, and saves
- [x] Conversion works again with the default shortcut

## Menu Bar, Dock, And Launch Verification

- [x] Menu-bar item is visible by default
- [x] Menu-bar item can be hidden only when a working hotkey exists
- [x] Reopening HanToggle from `/Applications` opens Preferences when the menu-bar item is hidden
- [x] Menu-bar item can be restored
- [x] Dock icon can be shown
- [x] Dock icon can be hidden again
- [x] Launch at login toggle does not crash
- [x] Launch at login state persists as expected
- [x] Quit and relaunch does not re-run first setup
- [x] Fresh launch after completed setup is ready without extra steps

## Privacy And Safety Verification

- [x] No selected text, converted text, or clipboard contents were recorded in this QA file
- [x] Source scan found no analytics, telemetry, crash reporting, update checks, or network conversion code
- [x] Clipboard was preserved in success, no-op, and missing-permission flows tested manually

## Release Blockers

No release blockers found.

- [x] No clipboard data loss found
- [x] No selected text, converted text, or clipboard contents logged, persisted, or transmitted
- [x] No silent hotkey failure found in tested flows
- [x] App recovered from hotkey changes and conflicts tested manually
- [x] App guided user to Accessibility permission
- [x] Universal build, signing, notarization, stapling, and Gatekeeper verification passed
- [x] Third-party notices are present in `THIRD_PARTY_NOTICES.md`

## Artifact

- DMG: `build/HanToggle-0.1.0.dmg`
- SHA-256 before final clean-tree rebuild: `ca0c8fff941c46842779cd8ccb9e867f938192dfbc13c45f8af90624c860be97`

Final release artifact must be rebuilt from a clean committed tree with `Scripts/release.sh`; record the final SHA-256 in the GitHub release notes.

## Release Decision

Ready for public 0.1.0 direct-download release after the final clean-tree release build passes and the GitHub release is published with privacy and support information.
