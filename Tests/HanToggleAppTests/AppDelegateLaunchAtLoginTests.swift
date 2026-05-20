import AppKit
import Foundation
import Testing
@testable import HanToggleApp

@MainActor
@Suite("AppDelegate launch at login")
struct AppDelegateLaunchAtLoginTests {
    @Test("launch at login refreshes from service status after registration succeeds but requires approval")
    func launchAtLoginRefreshesAfterRegistrationSucceedsButRequiresApproval() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let manager = FakeLaunchAtLoginManager(statuses: [.disabled, .requiresApproval])
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: manager,
            state: state,
            hotkeyManager: FakeHotkeyManager()
        )

        appDelegate.applicationDidBecomeActive(Notification(name: NSApplication.didBecomeActiveNotification))
        #expect(state.launchAtLoginStatus == .disabled)

        let didUpdate = appDelegate.setLaunchAtLogin(true)

        #expect(didUpdate)
        #expect(state.launchAtLoginStatus == .requiresApproval)
        #expect(manager.requests == [true])
    }

    @Test("launch at login failure refreshes real service status and shows error")
    func launchAtLoginFailureRefreshesStatusAndShowsError() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let manager = FakeLaunchAtLoginManager(
            statuses: [.enabled, .disabled],
            error: LaunchAtLoginTestError.failed
        )
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: manager,
            state: state
        )

        appDelegate.applicationDidBecomeActive(Notification(name: NSApplication.didBecomeActiveNotification))
        #expect(state.launchAtLoginStatus == .enabled)

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
    private var statuses: [LaunchAtLoginStatus]
    private let error: (any Error)?
    private(set) var requests: [Bool] = []

    init(error: (any Error)? = nil, status: LaunchAtLoginStatus = .disabled) {
        self.statuses = [status]
        self.error = error
    }

    init(statuses: [LaunchAtLoginStatus], error: (any Error)? = nil) {
        self.statuses = statuses
        self.error = error
    }

    func status() -> LaunchAtLoginStatus {
        if statuses.count > 1 {
            return statuses.removeFirst()
        }

        return statuses.first ?? .disabled
    }

    func setEnabled(_ enabled: Bool) throws {
        requests.append(enabled)

        if let error {
            throw error
        }
    }
}

private enum LaunchAtLoginTestError: Error {
    case failed
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
