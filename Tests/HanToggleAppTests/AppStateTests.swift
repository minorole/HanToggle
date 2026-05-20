import Testing
import Combine
import HanToggle
@testable import HanToggleApp

@MainActor
@Suite("AppState")
struct AppStateTests {
    @Test("default hotkey display name is shown")
    func defaultHotkeyDisplayName() {
        let state = AppState()

        #expect(state.hotkeyDisplayName == GlobalHotkey.default.displayName)
    }

    @Test("setup cannot complete before permission and hotkey are ready")
    func setupCannotCompleteBeforeReady() {
        let state = AppState()

        state.updateAccessibility(.notTrusted)

        #expect(!state.canCompleteSetup)
        #expect(state.setupStatusTitle == "Accessibility Required")
        #expect(state.setupPrimaryMessage == "Enable HanToggle in System Settings > Privacy & Security > Accessibility.")
    }

    @Test("setup can complete when permission and hotkey are ready")
    func setupCanCompleteWhenReady() {
        let state = AppState()

        state.updateAccessibility(.trusted)
        state.setTextReplacementServiceReady(true)
        state.confirmHotkeyActive("Control-Option-H")
        state.updateConversionTestStatus(.passed)

        #expect(state.canCompleteSetup)
        #expect(state.setupStatusTitle == "HanToggle is ready")
        #expect(state.setupPrimaryMessage == "Select Chinese text in most apps, then press Control-Option-H.")
    }

    @Test("setup cannot complete until local conversion test passes")
    func setupRequiresConversionTestPass() {
        let state = AppState()

        state.updateAccessibility(.trusted)
        state.setTextReplacementServiceReady(true)
        state.confirmHotkeyActive("Control-Option-H")

        #expect(!state.canCompleteSetup)
        #expect(state.setupStatusTitle == "Test Conversion")
        #expect(state.setupPrimaryMessage == "Run the local conversion test before completing setup.")

        state.updateConversionTestStatus(.passed)

        #expect(state.canCompleteSetup)
        #expect(state.setupStatusTitle == "HanToggle is ready")
    }

    @Test("conversion test failure blocks setup and exposes message")
    func conversionTestFailureBlocksSetup() {
        let state = AppState()

        state.updateAccessibility(.trusted)
        state.setTextReplacementServiceReady(true)
        state.confirmHotkeyActive("Control-Option-H")
        state.updateConversionTestStatus(.failed("HanToggle converted the sample incorrectly."))

        #expect(!state.canCompleteSetup)
        #expect(state.setupStatusTitle == "Test Conversion")
        #expect(state.setupPrimaryMessage == "HanToggle converted the sample incorrectly.")
    }

    @Test("known app issue updates status and last error")
    func appIssueUpdatesStatusAndLastError() {
        let state = AppState()
        let issue = AppIssue(textReplacementError: .pasteEventFailed)

        state.setIssue(issue)

        #expect(state.currentIssue == issue)
        #expect(state.lastError == TextReplacementError.pasteEventFailed.localizedDescription)
        #expect(state.statusMessage == "HanToggle needs attention")
        #expect(state.menuBarSystemImageName == "exclamationmark.triangle")
    }

    @Test("successful toggle clears warning issues")
    func successfulToggleClearsWarningIssue() {
        let state = AppState()
        let result = ToggleResult(text: "測試", direction: .simplifiedToTraditional, changedCharacterCount: 2)

        state.setIssue(AppIssue(textReplacementError: .pasteEventFailed))
        state.updateAfterToggle(result)

        #expect(state.currentIssue == nil)
        #expect(state.lastError == nil)
        #expect(state.statusMessage == "Converted to Traditional")
    }

    @Test("setup is blocked when text replacement service is unavailable")
    func setupBlockedWhenTextReplacementServiceUnavailable() {
        let state = AppState()

        state.updateAccessibility(.trusted)
        state.setTextReplacementServiceReady(false)
        state.confirmHotkeyActive("Control-Option-H")

        #expect(!state.canCompleteSetup)
        #expect(state.setupStatusTitle == "Text Converter")
        #expect(state.setupPrimaryMessage == TextReplacementError.converterInitializationFailed.localizedDescription)
    }

    @Test("inactive hotkey blocks setup completion")
    func inactiveHotkeyBlocksSetupCompletion() {
        let state = AppState()

        state.updateAccessibility(.trusted)
        state.setTextReplacementServiceReady(true)
        state.markHotkeyInactive("Could not register the shortcut.")

        #expect(!state.canCompleteSetup)
        #expect(state.setupStatusTitle == "Keyboard Shortcut")
        #expect(state.setupPrimaryMessage == "Choose a keyboard shortcut before completing setup.")
    }

    @Test("trusted accessibility refresh preserves non-accessibility errors")
    func trustedAccessibilityRefreshPreservesNonAccessibilityErrors() {
        let state = AppState()
        let hotkeyMessage = "Could not register the shortcut."

        state.setError(hotkeyMessage, source: .hotkey)
        state.updateAccessibility(.trusted)

        #expect(state.lastError == hotkeyMessage)
        #expect(state.statusMessage == "HanToggle needs attention")
    }

    @Test("trusted accessibility refresh clears accessibility guidance")
    func trustedAccessibilityRefreshClearsAccessibilityGuidance() {
        let state = AppState()
        let accessibilityMessage = "Enable HanToggle in System Settings > Privacy & Security > Accessibility."

        state.setError(accessibilityMessage, source: .accessibility)
        state.updateAccessibility(.trusted)

        #expect(state.lastError == nil)
        #expect(state.statusMessage == "HanToggle is ready")
    }

    @Test("hotkey update failure keeps display and stores recorder error")
    func hotkeyUpdateFailure() {
        let state = AppState()

        state.updateHotkeyDisplayName("Control-Option-H")
        state.setHotkeyRecordingError("This shortcut is already in use or reserved by macOS. Choose another shortcut.")

        #expect(state.hotkeyDisplayName == "Control-Option-H")
        #expect(state.hotkeyRecordingError == "This shortcut is already in use or reserved by macOS. Choose another shortcut.")
    }

    @Test("successful hotkey update clears recorder error and marks active")
    func hotkeyUpdateSuccess() {
        let state = AppState()
        let replacement = GlobalHotkey(keyCode: 8, modifiers: .command)

        state.setHotkeyRecordingError("This shortcut is already in use or reserved by macOS. Choose another shortcut.")
        state.updateHotkeyDisplayName(replacement.displayName)

        #expect(state.hotkeyDisplayName == replacement.displayName)
        #expect(state.hotkeyRecordingError == nil)
        #expect(state.hasActiveHotkey)
    }

    @Test("successful hotkey update does not clear existing global error state")
    func hotkeyUpdateSuccessKeepsExistingGlobalError() {
        let state = AppState()
        let message = "Could not register the shortcut."

        state.setError(message)
        state.setHotkeyRecordingError("This shortcut is already in use or reserved by macOS. Choose another shortcut.")
        state.updateHotkeyDisplayName("Command-Shift-T")

        #expect(state.hotkeyDisplayName == "Command-Shift-T")
        #expect(state.lastError == message)
        #expect(state.statusMessage == "HanToggle needs attention")
        #expect(state.hasActiveHotkey)
        #expect(state.hotkeyRecordingError == nil)
    }

    @Test("hotkey recovery clears global hotkey error state")
    func hotkeyRecoveryClearsGlobalErrorState() {
        let state = AppState()

        state.markHotkeyInactive("Could not register the shortcut.")
        state.confirmHotkeyActive("Command-Shift-T")

        #expect(state.hotkeyDisplayName == "Command-Shift-T")
        #expect(state.lastError == nil)
        #expect(state.statusMessage == "HanToggle is ready")
        #expect(state.hasActiveHotkey)
        #expect(state.hotkeyRecordingError == nil)
    }

    @Test("hotkey confirmation keeps unrelated global error state")
    func hotkeyConfirmationKeepsUnrelatedGlobalErrorState() {
        let state = AppState()
        let accessibilityMessage = "Accessibility permission is required."

        state.setError(accessibilityMessage)
        state.setHotkeyRecordingError("This shortcut is already in use or reserved by macOS. Choose another shortcut.")
        state.confirmHotkeyActive("Command-Shift-T")

        #expect(state.hotkeyDisplayName == "Command-Shift-T")
        #expect(state.lastError == accessibilityMessage)
        #expect(state.statusMessage == "HanToggle needs attention")
        #expect(state.hasActiveHotkey)
        #expect(state.hotkeyRecordingError == nil)
    }

    @Test("marking hotkey inactive sets global error state")
    func markHotkeyInactiveSetsErrorState() {
        let state = AppState()
        let message = "Could not register the shortcut."

        state.markHotkeyInactive(message)

        #expect(state.hotkeyRecordingError == message)
        #expect(state.lastError == message)
        #expect(state.statusMessage == "HanToggle needs attention")
        #expect(!state.hasActiveHotkey)
    }

    @Test("settings snapshot is loaded into app state")
    func updateSettings() {
        let state = AppState()

        state.updateSettings(
            hotkeyDisplayName: "Control-Option-H",
            showMenuBarItem: false,
            showDockIcon: true,
            hasCompletedSetup: true,
            launchAtLoginStatus: .enabled
        )

        #expect(state.hotkeyDisplayName == "Control-Option-H")
        #expect(state.showMenuBarItem)
        #expect(state.showDockIcon)
        #expect(state.hasCompletedSetup)
        #expect(state.launchAtLoginStatus == .enabled)
    }

    @Test("dock icon visibility can be updated")
    func updateDockIconVisibility() {
        let state = AppState()

        #expect(!state.showDockIcon)

        state.updateShowDockIcon(true)

        #expect(state.showDockIcon)
    }

    @Test("launch at login status is stored from service state")
    func launchAtLoginStatusStoredFromServiceState() {
        let state = AppState()

        state.updateLaunchAtLoginStatus(.requiresApproval)

        #expect(state.launchAtLoginStatus == .requiresApproval)
        #expect(!state.launchAtLoginStatus.isEnabled)
        #expect(state.launchAtLoginStatus.isProblem)
    }

    @Test("setup checklist visibility uses setup completion and blocking service state")
    func setupChecklistVisibility() {
        let state = AppState()

        #expect(state.shouldShowSetupChecklist)

        state.updateAccessibility(.trusted)
        state.setTextReplacementServiceReady(true)
        state.confirmHotkeyActive("Control-Option-H")
        state.updateConversionTestStatus(.passed)
        state.markSetupCompleted()

        #expect(!state.shouldShowSetupChecklist)
    }

    @Test("menu bar can be hidden with active hotkey")
    func menuBarCanHideWithActiveHotkey() {
        let state = AppState()
        state.updateHotkeyDisplayName("Control-Option-H")

        state.updateShowMenuBarItem(false)

        #expect(!state.showMenuBarItem)
    }

    @Test("menu bar visibility can be updated when no guard is needed")
    func updateMenuBarVisibility() {
        let state = AppState()

        state.updateHotkeyDisplayName("Control-Option-H")
        state.updateShowMenuBarItem(false)

        #expect(!state.showMenuBarItem)
    }

    @Test("unchanged menu bar visibility does not publish")
    func unchangedMenuBarVisibilityDoesNotPublish() {
        let state = AppState()
        var publishCount = 0
        let cancellable = state.objectWillChange.sink {
            publishCount += 1
        }

        state.updateShowMenuBarItem(true)

        #expect(state.showMenuBarItem)
        #expect(publishCount == 0)
        cancellable.cancel()
    }

    @Test("menu bar cannot be hidden without active hotkey")
    func menuBarCannotHideWithoutActiveHotkey() {
        let state = AppState()
        state.markHotkeyInactive("Hotkey unavailable")

        state.updateShowMenuBarItem(false)

        #expect(state.showMenuBarItem)
    }

    @Test("hidden menu bar status keeps the menu item quiet during errors")
    func hiddenMenuBarStatusKeepsMenuItemQuiet() {
        let state = AppState()

        state.updateHotkeyDisplayName("Control-Option-H")
        state.updateShowMenuBarItem(false)
        state.setError("Accessibility permission is required.")

        #expect(state.menuBarSystemImageName == "character.textbox")
    }

    @Test("update after toggle records direction and Traditional status")
    func updateAfterSimplifiedToTraditionalToggle() {
        let state = AppState()
        let result = ToggleResult(text: "測試", direction: .simplifiedToTraditional, changedCharacterCount: 2)

        state.updateAfterToggle(result)

        #expect(state.lastDirection == .simplifiedToTraditional)
        #expect(state.statusMessage == "Converted to Traditional")
        #expect(state.lastError == nil)
    }

    @Test("update after toggle records direction and Simplified status")
    func updateAfterTraditionalToSimplifiedToggle() {
        let state = AppState()
        let result = ToggleResult(text: "测试", direction: .traditionalToSimplified, changedCharacterCount: 2)

        state.updateAfterToggle(result)

        #expect(state.lastDirection == .traditionalToSimplified)
        #expect(state.statusMessage == "Converted to Simplified")
        #expect(state.lastError == nil)
    }

    @Test("unchanged toggle reports ready")
    func updateAfterUnchangedToggle() {
        let state = AppState()
        let result = ToggleResult(text: "abc", direction: .unchanged, changedCharacterCount: 0)

        state.updateAfterToggle(result)

        #expect(state.lastDirection == .unchanged)
        #expect(state.statusMessage == "Ready")
        #expect(state.lastError == nil)
    }
}
