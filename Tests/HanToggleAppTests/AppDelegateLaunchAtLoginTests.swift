import AppKit
import Foundation
import Testing
@testable import HanToggleApp

@MainActor
@Suite("AppDelegate launch at login")
struct AppDelegateLaunchAtLoginTests {
    @Test("launch at login status updates after OS registration succeeds")
    func launchAtLoginPersistsAfterRegistrationSucceeds() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let manager = FakeLaunchAtLoginManager()
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: manager,
            state: state,
            hotkeyManager: FakeHotkeyManager()
        )

        let didUpdate = appDelegate.setLaunchAtLogin(true)

        #expect(didUpdate)
        #expect(state.launchAtLoginStatus == .enabled)
        #expect(manager.requests == [true])
    }

    @Test("launch at login failure keeps service status and shows error")
    func launchAtLoginFailureKeepsPreviousSettingAndShowsError() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let manager = FakeLaunchAtLoginManager(error: LaunchAtLoginTestError.failed)
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: manager,
            state: state
        )

        let didUpdate = appDelegate.setLaunchAtLogin(true)

        #expect(!didUpdate)
        #expect(state.launchAtLoginStatus == .disabled)
        #expect(state.lastError == "HanToggle could not update Launch at Login.")
        #expect(manager.requests == [true])
    }

    @Test("applying unrelated settings does not touch launch at login")
    func applySettingsDoesNotTouchLaunchAtLogin() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let manager = FakeLaunchAtLoginManager()
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: manager,
            state: state,
            hotkeyManager: FakeHotkeyManager()
        )

        appDelegate.applySettings()

        #expect(manager.requests.isEmpty)
    }

    @Test("application activation updates permission state from injected permission manager")
    func applicationActivationRefreshesPermissionState() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted)
        )

        appDelegate.applicationDidBecomeActive(Notification(name: NSApplication.didBecomeActiveNotification))

        #expect(state.accessibilityStatus == .trusted)
        #expect(state.statusMessage == "HanToggle is ready")
        #expect(state.lastError == nil)
    }

    @Test("settings menu opens injected settings window presenter")
    func settingsMenuOpensSettingsWindow() {
        let presenter = FakeSettingsWindowPresenter()
        let appDelegate = AppDelegate(
            settings: AppSettings(defaults: makeDefaults()),
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: AppState(),
            settingsWindowPresenter: presenter
        )

        appDelegate.showSettingsWindow()

        #expect(presenter.showSettingsWindowCalls == 1)
    }

    @Test("setup window is shown when setup is incomplete")
    func setupWindowShownWhenSetupIncomplete() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.hasCompletedSetup = false
        let setupPresenter = FakeSetupWindowPresenter()

        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: AppState(),
            hotkeyManager: FakeHotkeyManager(),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            setupWindowPresenter: setupPresenter
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(setupPresenter.showSetupWindowCalls == 1)
    }

    @Test("setup window is not shown when setup is complete and app is ready")
    func setupWindowNotShownWhenReady() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.hasCompletedSetup = true
        let setupPresenter = FakeSetupWindowPresenter()

        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: AppState(),
            hotkeyManager: FakeHotkeyManager(activeHotkey: GlobalHotkey.default),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            setupWindowPresenter: setupPresenter
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(setupPresenter.showSetupWindowCalls == 0)
    }

    @Test("launch shows settings when completed app has hidden menu bar")
    func launchShowsSettingsWhenMenuBarIsHidden() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.hasCompletedSetup = true
        settings.showMenuBarItem = false
        let settingsPresenter = FakeSettingsWindowPresenter()
        let setupPresenter = FakeSetupWindowPresenter()

        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: AppState(),
            hotkeyManager: FakeHotkeyManager(activeHotkey: GlobalHotkey.default),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            settingsWindowPresenter: settingsPresenter,
            setupWindowPresenter: setupPresenter
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(settingsPresenter.showSettingsWindowCalls == 1)
        #expect(setupPresenter.showSetupWindowCalls == 0)
    }

    @Test("reopening app shows primary window")
    func reopeningAppShowsPrimaryWindow() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.hasCompletedSetup = true
        let settingsPresenter = FakeSettingsWindowPresenter()

        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: AppState(),
            hotkeyManager: FakeHotkeyManager(activeHotkey: GlobalHotkey.default),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            settingsWindowPresenter: settingsPresenter
        )
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        let shouldHandle = appDelegate.applicationShouldHandleReopen(NSApplication.shared, hasVisibleWindows: false)

        #expect(!shouldHandle)
        #expect(settingsPresenter.showSettingsWindowCalls == 1)
    }

    @Test("setup completion persists only when app is ready")
    func setupCompletionPersistsOnlyWhenReady() {
        let settings = AppSettings(defaults: makeDefaults())
        let state = AppState()
        let setupPresenter = FakeSetupWindowPresenter()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            permissionManager: FakeAccessibilityPermissionManager(status: .notTrusted),
            setupWindowPresenter: setupPresenter
        )

        let didComplete = appDelegate.completeSetup()

        #expect(!didComplete)
        #expect(!settings.hasCompletedSetup)
        #expect(setupPresenter.closeSetupWindowCalls == 0)
        #expect(state.currentIssue?.kind == .accessibilityRequired)
        #expect(state.currentIssue?.recoveryActions == [.openAccessibilitySettings, .openSetup])
        #expect(state.lastError == "Enable HanToggle in System Settings > Privacy & Security > Accessibility.")
    }

    @Test("setup completion closes setup when app is ready")
    func setupCompletionClosesSetupWhenReady() {
        let settings = AppSettings(defaults: makeDefaults())
        let setupPresenter = FakeSetupWindowPresenter()
        let state = AppState()

        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            hotkeyManager: FakeHotkeyManager(),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            setupWindowPresenter: setupPresenter
        )
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        state.confirmHotkeyActive("Control-Option-H")
        state.updateConversionTestStatus(.passed)

        let didComplete = appDelegate.completeSetup()

        #expect(didComplete)
        #expect(settings.hasCompletedSetup)
        #expect(setupPresenter.closeSetupWindowCalls == 1)
    }

    @Test("setup completion restores hidden menu bar preference")
    func setupCompletionRestoresHiddenMenuBarPreference() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.showMenuBarItem = false
        let setupPresenter = FakeSetupWindowPresenter()
        let state = AppState()

        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            hotkeyManager: FakeHotkeyManager(),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            setupWindowPresenter: setupPresenter
        )
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        state.updateConversionTestStatus(.passed)
        #expect(state.showMenuBarItem)

        let didComplete = appDelegate.completeSetup()

        #expect(didComplete)
        #expect(!settings.showMenuBarItem)
        #expect(!state.showMenuBarItem)
        #expect(setupPresenter.closeSetupWindowCalls == 1)
    }

    @Test("setup cannot complete without converter initialization")
    func setupCannotCompleteWithoutConverter() {
        let settings = AppSettings(defaults: makeDefaults())
        let state = AppState()
        let setupPresenter = FakeSetupWindowPresenter()

        state.updateAccessibility(.trusted)
        state.confirmHotkeyActive("Control-Option-H")

        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            setupWindowPresenter: setupPresenter
        )

        let didComplete = appDelegate.completeSetup()

        #expect(!didComplete)
        #expect(!settings.hasCompletedSetup)
        #expect(setupPresenter.closeSetupWindowCalls == 0)
        #expect(state.lastError == TextReplacementError.converterInitializationFailed.localizedDescription)
        #expect(state.currentIssue?.kind == .converterUnavailable)
        #expect(state.currentIssue?.recoveryActions == [.openSettings])
    }

    @Test("initialized app delegate is available to menu views")
    func initializedAppDelegateIsAvailableToMenuViews() {
        let appDelegate = AppDelegate(
            settings: AppSettings(defaults: makeDefaults()),
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: AppState()
        )

        #expect(AppDelegate.shared === appDelegate)
    }

    @Test("accessibility settings failure shows actionable error")
    func accessibilitySettingsFailureShowsActionableError() {
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: AppSettings(defaults: makeDefaults()),
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            permissionManager: FakeAccessibilityPermissionManager(
                status: .notTrusted,
                openAccessibilitySettingsResult: false
            )
        )

        appDelegate.openAccessibilitySettings()

        #expect(state.lastError == "HanToggle could not open Accessibility settings. Open System Settings > Privacy & Security > Accessibility manually.")
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "HanToggleAppTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class FakeLaunchAtLoginManager: LaunchAtLoginManaging {
    private let error: (any Error)?
    private var statusValue: LaunchAtLoginStatus
    private(set) var requests: [Bool] = []

    init(error: (any Error)? = nil, status: LaunchAtLoginStatus = .disabled) {
        self.error = error
        self.statusValue = status
    }

    func status() -> LaunchAtLoginStatus {
        statusValue
    }

    func setEnabled(_ enabled: Bool) throws {
        requests.append(enabled)

        if let error {
            throw error
        }

        statusValue = enabled ? .enabled : .disabled
    }
}

private enum LaunchAtLoginTestError: Error {
    case failed
}

private final class FakeSettingsWindowPresenter: SettingsWindowPresenting {
    private(set) var showSettingsWindowCalls = 0

    func showSettingsWindow() {
        showSettingsWindowCalls += 1
    }
}

private final class FakeSetupWindowPresenter: SetupWindowPresenting {
    private(set) var showSetupWindowCalls = 0
    private(set) var closeSetupWindowCalls = 0

    func showSetupWindow() {
        showSetupWindowCalls += 1
    }

    func closeSetupWindow() {
        closeSetupWindowCalls += 1
    }
}

private final class FakeHotkeyManager: HotkeyManaging {
    var onHotkey: (() -> Void)?
    private let activeHotkeyOverride: GlobalHotkey?
    private(set) var startCalls: [GlobalHotkey] = []

    init(activeHotkey: GlobalHotkey? = nil) {
        self.activeHotkeyOverride = activeHotkey
    }

    var activeHotkey: GlobalHotkey? {
        activeHotkeyOverride
    }

    func start(hotkey: GlobalHotkey) throws {
        startCalls.append(hotkey)
    }

    func testRegistration(hotkey: GlobalHotkey) throws {}

    func stop() {}
}

private struct FakeAccessibilityPermissionManager: AccessibilityPermissionChecking {
    private let statusValue: AccessibilityPermissionStatus
    private let openAccessibilitySettingsResult: Bool

    init(
        status: AccessibilityPermissionStatus,
        openAccessibilitySettingsResult: Bool = true
    ) {
        statusValue = status
        self.openAccessibilitySettingsResult = openAccessibilitySettingsResult
    }

    func status(prompt: Bool) -> AccessibilityPermissionStatus {
        statusValue
    }

    func openAccessibilitySettings() -> Bool {
        openAccessibilitySettingsResult
    }
}
