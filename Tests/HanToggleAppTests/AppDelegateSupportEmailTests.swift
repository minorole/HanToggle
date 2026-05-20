import Foundation
import Testing
@testable import HanToggleApp

@MainActor
@Suite("AppDelegate support email")
struct AppDelegateSupportEmailTests {
    @Test("view action opens support email")
    func viewActionOpensSupportEmail() {
        let supportEmailOpener = FakeSupportEmailOpener(result: true)
        let appDelegate = AppDelegate(
            settings: AppSettings(defaults: makeDefaults()),
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: AppState(),
            supportEmailOpener: supportEmailOpener
        )

        appDelegate.actionsForViews.openSupportEmail()

        #expect(supportEmailOpener.openCalls == 1)
    }

    @Test("support email open failure reports a general app error")
    func supportEmailOpenFailureReportsError() {
        let state = AppState()
        let supportEmailOpener = FakeSupportEmailOpener(result: false)
        let appDelegate = AppDelegate(
            settings: AppSettings(defaults: makeDefaults()),
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            supportEmailOpener: supportEmailOpener
        )

        appDelegate.openSupportEmail()

        #expect(supportEmailOpener.openCalls == 1)
        #expect(state.lastError == "HanToggle could not open your email app. Email hi@minor-role.com manually.")
        #expect(state.statusMessage == "HanToggle needs attention")
    }
}

@MainActor
private final class FakeSupportEmailOpener: SupportEmailOpening {
    private let result: Bool
    private(set) var openCalls = 0

    init(result: Bool) {
        self.result = result
    }

    func openSupportEmail() -> Bool {
        openCalls += 1
        return result
    }
}

private final class FakeLaunchAtLoginManager: LaunchAtLoginManaging {
    func status() -> LaunchAtLoginStatus { .disabled }
    func setEnabled(_ enabled: Bool) throws {}
}

private func makeDefaults() -> UserDefaults {
    let suiteName = "HanToggleAppTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}
