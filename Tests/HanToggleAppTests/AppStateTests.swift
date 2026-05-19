import Testing
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
            showMenuBarStatus: false,
            launchAtLogin: true
        )

        #expect(state.hotkeyDisplayName == "Control-Option-H")
        #expect(!state.showMenuBarStatus)
        #expect(state.launchAtLogin)
    }

    @Test("menu bar visibility can be updated independently")
    func updateMenuBarVisibility() {
        let state = AppState()

        state.updateShowMenuBarStatus(false)

        #expect(!state.showMenuBarStatus)
    }

    @Test("hidden menu bar status keeps the menu item quiet during errors")
    func hiddenMenuBarStatusKeepsMenuItemQuiet() {
        let state = AppState()

        state.updateShowMenuBarStatus(false)
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
