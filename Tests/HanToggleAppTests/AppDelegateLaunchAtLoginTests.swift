import Foundation
import Testing
@testable import HanToggleApp

@MainActor
@Suite("AppDelegate launch at login")
struct AppDelegateLaunchAtLoginTests {
    @Test("launch at login is persisted only after OS registration succeeds")
    func launchAtLoginPersistsAfterRegistrationSucceeds() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let manager = FakeLaunchAtLoginManager()
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: manager,
            state: state
        )

        let didUpdate = appDelegate.setLaunchAtLogin(true)

        #expect(didUpdate)
        #expect(settings.launchAtLogin)
        #expect(state.launchAtLogin)
        #expect(manager.requests == [true])
    }

    @Test("launch at login failure keeps previous setting and shows error")
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
        #expect(!settings.launchAtLogin)
        #expect(!state.launchAtLogin)
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
            state: state
        )

        appDelegate.applySettings()

        #expect(manager.requests.isEmpty)
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
    private(set) var requests: [Bool] = []

    init(error: (any Error)? = nil) {
        self.error = error
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
