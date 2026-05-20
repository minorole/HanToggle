import AppKit
import Foundation
import Testing
@testable import HanToggleApp

@MainActor
@Suite("AppDelegate preferences window routing")
struct AppDelegatePreferencesWindowTests {
    @Test("launch shows one preferences window when setup is incomplete")
    func launchShowsPreferencesWhenSetupIncomplete() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.hasCompletedSetup = false
        let presenter = FakePreferencesWindowPresenter()

        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(status: .disabled),
            state: AppState(),
            hotkeyManager: FakeHotkeyManager(activeHotkey: .default),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            preferencesWindowPresenter: presenter
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(presenter.showCalls == 1)
        #expect(presenter.closeCalls == 0)
    }

    @Test("show preferences always uses the same presenter")
    func showPreferencesUsesSinglePresenter() {
        let presenter = FakePreferencesWindowPresenter()
        let appDelegate = AppDelegate(
            settings: AppSettings(defaults: makeDefaults()),
            launchAtLoginManager: FakeLaunchAtLoginManager(status: .disabled),
            state: AppState(),
            preferencesWindowPresenter: presenter
        )

        appDelegate.showPreferencesWindow()
        appDelegate.showPrimaryWindow()

        #expect(presenter.showCalls == 2)
        #expect(presenter.closeCalls == 0)
    }

    @Test("setup completion keeps the preferences window open and marks setup complete")
    func setupCompletionKeepsPreferencesWindowOpen() {
        let settings = AppSettings(defaults: makeDefaults())
        let state = AppState()
        let presenter = FakePreferencesWindowPresenter()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(status: .disabled),
            state: state,
            hotkeyManager: FakeHotkeyManager(activeHotkey: .default),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            preferencesWindowPresenter: presenter
        )

        state.updateAccessibility(.trusted)
        state.setTextReplacementServiceReady(true)
        state.confirmHotkeyActive(GlobalHotkey.default.displayName)
        state.updateConversionTestStatus(.passed)

        let didComplete = appDelegate.completeSetup()

        #expect(didComplete)
        #expect(settings.hasCompletedSetup)
        #expect(state.hasCompletedSetup)
        #expect(presenter.closeCalls == 0)
    }

    @Test("reopening app opens preferences regardless of setup state")
    func reopeningAppOpensPreferences() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.hasCompletedSetup = true
        let presenter = FakePreferencesWindowPresenter()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(status: .disabled),
            state: AppState(),
            hotkeyManager: FakeHotkeyManager(activeHotkey: .default),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            preferencesWindowPresenter: presenter
        )

        let shouldHandle = appDelegate.applicationShouldHandleReopen(NSApplication.shared, hasVisibleWindows: false)

        #expect(!shouldHandle)
        #expect(presenter.showCalls == 1)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "HanToggleAppTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

@MainActor
private final class FakePreferencesWindowPresenter: PreferencesWindowPresenting {
    private(set) var showCalls = 0
    private(set) var closeCalls = 0

    func showPreferencesWindow(actions: HanToggleActions) {
        showCalls += 1
    }

    func closePreferencesWindow() {
        closeCalls += 1
    }
}

private final class FakeLaunchAtLoginManager: LaunchAtLoginManaging {
    private let statusValue: LaunchAtLoginStatus

    init(status: LaunchAtLoginStatus) {
        self.statusValue = status
    }

    func status() -> LaunchAtLoginStatus {
        statusValue
    }

    func setEnabled(_ enabled: Bool) throws {}
}

private final class FakeHotkeyManager: HotkeyManaging {
    var onHotkey: (() -> Void)?
    private let activeHotkeyValue: GlobalHotkey?

    init(activeHotkey: GlobalHotkey? = nil) {
        self.activeHotkeyValue = activeHotkey
    }

    var activeHotkey: GlobalHotkey? {
        activeHotkeyValue
    }

    func start(hotkey: GlobalHotkey) throws {}
    func testRegistration(hotkey: GlobalHotkey) throws {}
    func stop() {}
}

private struct FakeAccessibilityPermissionManager: AccessibilityPermissionChecking {
    let statusValue: AccessibilityPermissionStatus

    init(status: AccessibilityPermissionStatus) {
        self.statusValue = status
    }

    func status(prompt: Bool) -> AccessibilityPermissionStatus {
        statusValue
    }

    func openAccessibilitySettings() -> Bool {
        true
    }
}
