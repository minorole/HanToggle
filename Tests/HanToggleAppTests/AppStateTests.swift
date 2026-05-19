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
