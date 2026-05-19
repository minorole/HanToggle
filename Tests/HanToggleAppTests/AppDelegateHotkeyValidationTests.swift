import Testing
import Foundation
@testable import HanToggleApp

@MainActor
@Suite("AppDelegate hotkey validation")
struct AppDelegateHotkeyValidationTests {
    @Test("invalid persisted hotkey is blocked before registration")
    func invalidPersistedHotkeyDoesNotRegister() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let launchAtLoginManager = FakeLaunchAtLoginManager()
        let hotkeyManager = FakeHotkeyManager()
        let state = AppState()

        settings.hotkey = GlobalHotkey(keyCode: 53, modifiers: [.control])

        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: hotkeyManager
        )

        appDelegate.applySettings()

        #expect(hotkeyManager.startCalls == [])
        #expect(state.lastError == "This key is reserved for system navigation or text input. Choose another shortcut.")
    }

    @Test("invalid persisted hotkey stops existing registration")
    func invalidPersistedHotkeyStopsPreviousRegistration() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let launchAtLoginManager = FakeLaunchAtLoginManager()
        let hotkeyManager = FakeHotkeyManager()
        let state = AppState()

        settings.hotkey = GlobalHotkey(keyCode: 11, modifiers: [.control, .option])

        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: hotkeyManager
        )

        appDelegate.applySettings()
        settings.hotkey = GlobalHotkey(keyCode: 53, modifiers: [.control])
        appDelegate.applySettings()

        #expect(hotkeyManager.startCalls == [GlobalHotkey(keyCode: 11, modifiers: [.control, .option])])
        #expect(hotkeyManager.stopCalls == 1)
        #expect(state.lastError == "This key is reserved for system navigation or text input. Choose another shortcut.")
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "HanToggleAppTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class FakeHotkeyManager: HotkeyManaging {
    var onHotkey: (() -> Void)?
    private(set) var startCalls: [GlobalHotkey] = []
    private(set) var stopCalls = 0

    func start(hotkey: GlobalHotkey) throws {
        startCalls.append(hotkey)
    }

    func stop() {
        stopCalls += 1
    }
}

private final class FakeLaunchAtLoginManager: LaunchAtLoginManaging {
    func setEnabled(_ enabled: Bool) throws {}
}
