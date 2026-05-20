import AppKit
import Foundation
import Testing
@testable import HanToggleApp

@MainActor
@Suite("AppDelegate Dock icon visibility")
struct AppDelegateDockIconTests {
    @Test("launch applies accessory policy by default")
    func launchAppliesAccessoryPolicyByDefault() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.hasCompletedSetup = true
        let activationPolicyManager = FakeActivationPolicyManager()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: AppState(),
            hotkeyManager: FakeHotkeyManager(activeHotkey: .default),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            activationPolicyManager: activationPolicyManager
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(activationPolicyManager.appliedPolicies == [.accessory])
    }

    @Test("launch applies regular policy when Dock icon setting is enabled")
    func launchAppliesRegularPolicyWhenSettingEnabled() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.hasCompletedSetup = true
        settings.showDockIcon = true
        let state = AppState()
        let activationPolicyManager = FakeActivationPolicyManager()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            hotkeyManager: FakeHotkeyManager(activeHotkey: .default),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            activationPolicyManager: activationPolicyManager
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(activationPolicyManager.appliedPolicies == [.regular])
        #expect(state.showDockIcon)
    }

    @Test("launch failure reverts persisted Dock icon setting and reports error")
    func launchFailureRevertsPersistedDockIconSettingAndReportsError() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.hasCompletedSetup = true
        settings.showDockIcon = true
        let state = AppState()
        let activationPolicyManager = FakeActivationPolicyManager(error: ActivationPolicyTestError.failed)
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            hotkeyManager: FakeHotkeyManager(activeHotkey: .default),
            permissionManager: FakeAccessibilityPermissionManager(status: .trusted),
            activationPolicyManager: activationPolicyManager
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(!settings.showDockIcon)
        #expect(!state.showDockIcon)
        #expect(state.lastError == "HanToggle could not update Dock icon visibility.")
        #expect(activationPolicyManager.appliedPolicies == [.regular])
    }

    @Test("preference change persists and applies immediately")
    func preferenceChangePersistsAndAppliesImmediately() {
        let settings = AppSettings(defaults: makeDefaults())
        let state = AppState()
        let activationPolicyManager = FakeActivationPolicyManager()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            activationPolicyManager: activationPolicyManager
        )

        appDelegate.setShowDockIcon(true)

        #expect(settings.showDockIcon)
        #expect(state.showDockIcon)
        #expect(activationPolicyManager.appliedPolicies == [.regular])
    }

    @Test("activation policy failure reports error and preserves previous state")
    func activationPolicyFailureReportsErrorAndPreservesPreviousState() {
        let settings = AppSettings(defaults: makeDefaults())
        let state = AppState()
        let activationPolicyManager = FakeActivationPolicyManager(error: ActivationPolicyTestError.failed)
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            activationPolicyManager: activationPolicyManager
        )

        appDelegate.setShowDockIcon(true)

        #expect(!settings.showDockIcon)
        #expect(!state.showDockIcon)
        #expect(state.lastError == "HanToggle could not update Dock icon visibility.")
        #expect(activationPolicyManager.appliedPolicies == [.regular])
    }

    @Test("activation policy failure while hiding Dock icon preserves previous visible state")
    func activationPolicyFailureWhileHidingDockIconPreservesPreviousVisibleState() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.showDockIcon = true
        let state = AppState()
        state.updateShowDockIcon(true)
        let activationPolicyManager = FakeActivationPolicyManager(error: ActivationPolicyTestError.failed)
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            activationPolicyManager: activationPolicyManager
        )

        appDelegate.setShowDockIcon(false)

        #expect(settings.showDockIcon)
        #expect(state.showDockIcon)
        #expect(state.lastError == "HanToggle could not update Dock icon visibility.")
        #expect(activationPolicyManager.appliedPolicies == [.accessory])
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "HanToggleAppTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class FakeActivationPolicyManager: ApplicationActivationPolicyManaging {
    private let error: (any Error)?
    private(set) var appliedPolicies: [HanToggleActivationPolicy] = []

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func apply(_ policy: HanToggleActivationPolicy) throws {
        appliedPolicies.append(policy)

        if let error {
            throw error
        }
    }
}

private enum ActivationPolicyTestError: Error {
    case failed
}

private final class FakeLaunchAtLoginManager: LaunchAtLoginManaging {
    func status() -> LaunchAtLoginStatus {
        .disabled
    }

    func setEnabled(_ enabled: Bool) throws {}
}

private final class FakeHotkeyManager: HotkeyManaging {
    var onHotkey: (() -> Void)?
    private let activeHotkeyOverride: GlobalHotkey?

    init(activeHotkey: GlobalHotkey? = nil) {
        self.activeHotkeyOverride = activeHotkey
    }

    var activeHotkey: GlobalHotkey? {
        activeHotkeyOverride
    }

    func start(hotkey: GlobalHotkey) throws {}
    func testRegistration(hotkey: GlobalHotkey) throws {}
    func stop() {}
}

private struct FakeAccessibilityPermissionManager: AccessibilityPermissionChecking {
    let status: AccessibilityPermissionStatus

    func status(prompt: Bool) -> AccessibilityPermissionStatus {
        status
    }

    func openAccessibilitySettings() -> Bool {
        true
    }
}
