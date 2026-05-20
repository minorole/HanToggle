import Foundation
import Testing
@testable import HanToggleApp

@MainActor
@Suite("AppDelegate conversion test")
struct AppDelegateConversionTestTests {
    @Test("run conversion test updates app state with pass result")
    func runConversionTestPasses() {
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: AppSettings(defaults: makeDefaults()),
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            conversionTestServiceFactory: {
                ConversionTestService { _ in ConversionTestService.sampleExpected }
            }
        )

        appDelegate.runConversionTest()

        #expect(state.conversionTestStatus == .passed)
    }

    @Test("run conversion test updates app state with failure result")
    func runConversionTestFails() {
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: AppSettings(defaults: makeDefaults()),
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            conversionTestServiceFactory: {
                ConversionTestService { _ in "bad output" }
            }
        )

        appDelegate.runConversionTest()

        #expect(state.conversionTestStatus == .failed("HanToggle converted the sample incorrectly."))
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "HanToggleAppTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class FakeLaunchAtLoginManager: LaunchAtLoginManaging {
    func status() -> LaunchAtLoginStatus {
        .disabled
    }

    func setEnabled(_ enabled: Bool) throws {}
}
