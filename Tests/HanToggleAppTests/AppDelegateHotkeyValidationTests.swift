import Foundation
import Testing
@testable import HanToggleApp

@MainActor
@Suite("AppDelegate hotkey validation")
struct AppDelegateHotkeyValidationTests {
    private let conflictMessage = "This shortcut is already in use or reserved by macOS. Choose another shortcut."

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
        #expect(state.currentIssue?.kind == .hotkeyInvalid)
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
        #expect(state.currentIssue?.kind == .hotkeyInvalid)
        #expect(state.lastError == "This key is reserved for system navigation or text input. Choose another shortcut.")
    }

    @Test("invalid candidate is rejected before registration")
    func invalidCandidateDoesNotPersistOrRegister() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let launchAtLoginManager = FakeLaunchAtLoginManager()
        let hotkeyManager = FakeHotkeyManager()
        let state = AppState()

        let candidate = GlobalHotkey(keyCode: 53, modifiers: [.control])
        let persistedCandidate = settings.hotkey
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: hotkeyManager
        )

        let didSet = appDelegate.setHotkey(candidate)

        #expect(!didSet)
        #expect(settings.hotkey == persistedCandidate)
        #expect(state.hotkeyRecordingError == "This key is reserved for system navigation or text input. Choose another shortcut.")
        #expect(hotkeyManager.testRegistrationCalls == [])
        #expect(hotkeyManager.startCalls == [])
        #expect(hotkeyManager.callHistory == [])
    }

    @Test("candidate failing testRegistration is not persisted and does not start")
    func testRegistrationFailureIsBlocking() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let launchAtLoginManager = FakeLaunchAtLoginManager()
        let hotkeyManager = FakeHotkeyManager(testRegistrationError: SettableTestError.registrationFailed)
        let state = AppState()

        let candidate = GlobalHotkey(keyCode: 8, modifiers: [.control])
        let persistedCandidate = settings.hotkey
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: hotkeyManager
        )

        let didSet = appDelegate.setHotkey(candidate)

        #expect(!didSet)
        #expect(settings.hotkey == persistedCandidate)
        #expect(state.hotkeyRecordingError == conflictMessage)
        #expect(state.lastError == conflictMessage)
        #expect(state.currentIssue?.kind == .hotkeyConflict)
        #expect(!state.hasActiveHotkey)
        #expect(hotkeyManager.testRegistrationCalls == [candidate])
        #expect(hotkeyManager.startCalls == [])
        #expect(hotkeyManager.callHistory == ["test(\(candidate.displayName))"])
    }

    @Test("candidate passing testRegistration but failing start is not persisted and marks inactive when no active hotkey")
    func startFailureMarksInactiveAndKeepsStateConsistent() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let launchAtLoginManager = FakeLaunchAtLoginManager()
        let hotkeyManager = FakeHotkeyManager(startError: SettableTestError.startFailed)
        let state = AppState()

        let candidate = GlobalHotkey(keyCode: 9, modifiers: [.control])
        let persistedCandidate = settings.hotkey
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: hotkeyManager
        )

        let didSet = appDelegate.setHotkey(candidate)

        #expect(!didSet)
        #expect(settings.hotkey == persistedCandidate)
        #expect(state.hotkeyRecordingError == conflictMessage)
        #expect(state.lastError == conflictMessage)
        #expect(state.currentIssue?.kind == .hotkeyConflict)
        #expect(!state.hasActiveHotkey)
        #expect(hotkeyManager.testRegistrationCalls == [candidate])
        #expect(hotkeyManager.startCalls == [candidate])
        #expect(hotkeyManager.callHistory == [
            "test(\(candidate.displayName))",
            "start(\(candidate.displayName))"
        ])
    }

    @Test("successful candidate is tested, started, and persisted")
    func successfulCandidateIsPersistedAfterActivation() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let launchAtLoginManager = FakeLaunchAtLoginManager()
        let hotkeyManager = FakeHotkeyManager(activeHotkey: GlobalHotkey(keyCode: 11, modifiers: [.control, .option]))
        let state = AppState()

        let candidate = GlobalHotkey(keyCode: 2, modifiers: [.command])
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: hotkeyManager
        )

        let didSet = appDelegate.setHotkey(candidate)

        #expect(didSet)
        #expect(settings.hotkey == candidate)
        #expect(state.hotkeyRecordingError == nil)
        #expect(state.hotkeyDisplayName == candidate.displayName)
        #expect(state.hasActiveHotkey)
        #expect(hotkeyManager.testRegistrationCalls == [candidate])
        #expect(hotkeyManager.startCalls == [candidate])
        #expect(hotkeyManager.callHistory == [
            "test(\(candidate.displayName))",
            "start(\(candidate.displayName))"
        ])
    }

    @Test("successful candidate keeps unrelated global error state")
    func successfulCandidateKeepsUnrelatedGlobalErrorState() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let launchAtLoginManager = FakeLaunchAtLoginManager()
        let hotkeyManager = FakeHotkeyManager()
        let state = AppState()
        let accessibilityMessage = "Accessibility permission is required."

        state.setError(accessibilityMessage)

        let candidate = GlobalHotkey(keyCode: 2, modifiers: [.command])
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: hotkeyManager
        )

        let didSet = appDelegate.setHotkey(candidate)

        #expect(didSet)
        #expect(settings.hotkey == candidate)
        #expect(state.lastError == accessibilityMessage)
        #expect(state.statusMessage == "HanToggle needs attention")
        #expect(state.hotkeyRecordingError == nil)
        #expect(state.hotkeyDisplayName == candidate.displayName)
        #expect(hotkeyManager.callHistory == [
            "test(\(candidate.displayName))",
            "start(\(candidate.displayName))"
        ])
    }

    @Test("already active candidate is idempotent and does not probe")
    func alreadyActiveCandidateIsIdempotent() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let launchAtLoginManager = FakeLaunchAtLoginManager()
        let activeHotkey = settings.hotkey
        let hotkeyManager = FakeHotkeyManager(
            testRegistrationError: SettableTestError.registrationFailed,
            startError: SettableTestError.startFailed,
            activeHotkey: activeHotkey
        )
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: hotkeyManager
        )

        let didSet = appDelegate.setHotkey(activeHotkey)

        #expect(didSet)
        #expect(settings.hotkey == activeHotkey)
        #expect(state.hotkeyDisplayName == activeHotkey.displayName)
        #expect(state.hotkeyRecordingError == nil)
        #expect(state.hasActiveHotkey)
        #expect(hotkeyManager.testRegistrationCalls == [])
        #expect(hotkeyManager.startCalls == [])
        #expect(hotkeyManager.callHistory == [])
    }

    @Test("successful candidate clears prior global hotkey error")
    func successfulCandidateClearsPriorErrorState() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let launchAtLoginManager = FakeLaunchAtLoginManager()
        let hotkeyManager = FakeHotkeyManager()
        let state = AppState()

        state.markHotkeyInactive("Could not register the shortcut.")

        let candidate = GlobalHotkey(keyCode: 2, modifiers: [.command])
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: hotkeyManager
        )

        let didSet = appDelegate.setHotkey(candidate)

        #expect(didSet)
        #expect(state.lastError == nil)
        #expect(state.statusMessage == "HanToggle is ready")
        #expect(state.hotkeyDisplayName == candidate.displayName)
        #expect(settings.hotkey == candidate)
        #expect(hotkeyManager.startCalls == [candidate])
        #expect(hotkeyManager.callHistory == [
            "test(\(candidate.displayName))",
            "start(\(candidate.displayName))"
        ])
    }

    @Test("successful candidate clears stale global hotkey error after a different recorder error")
    func successfulCandidateClearsStaleHotkeyErrorAfterDifferentRecorderError() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        let launchAtLoginManager = FakeLaunchAtLoginManager()
        let failingHotkeyManager = FakeHotkeyManager(testRegistrationError: SettableTestError.registrationFailed)
        let state = AppState()
        let invalidCandidate = GlobalHotkey(keyCode: 53, modifiers: [.control])
        let validCandidate = GlobalHotkey(keyCode: 2, modifiers: [.command])

        let failingDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: failingHotkeyManager
        )

        #expect(!failingDelegate.setHotkey(validCandidate))
        #expect(!failingDelegate.setHotkey(invalidCandidate))
        #expect(state.lastError == conflictMessage)
        #expect(state.hotkeyRecordingError == "This key is reserved for system navigation or text input. Choose another shortcut.")

        let succeedingDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: launchAtLoginManager,
            state: state,
            hotkeyManager: FakeHotkeyManager()
        )

        let didSet = succeedingDelegate.setHotkey(validCandidate)

        #expect(didSet)
        #expect(state.lastError == nil)
        #expect(state.statusMessage == "HanToggle is ready")
        #expect(state.hotkeyRecordingError == nil)
        #expect(settings.hotkey == validCandidate)
    }

    @Test("saved hidden menu bar preference is restored after startup hotkey succeeds")
    func hiddenMenuBarPreferenceIsRestoredAfterStartupHotkeySucceeds() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.showMenuBarItem = false
        let state = AppState()
        let hotkeyManager = FakeHotkeyManager()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            hotkeyManager: hotkeyManager,
            permissionManager: FakeAccessibilityPermissionManager()
        )

        appDelegate.applySettings()

        #expect(settings.showMenuBarItem == false)
        #expect(state.showMenuBarItem == false)
        #expect(state.hasActiveHotkey)
        #expect(hotkeyManager.startCalls == [settings.hotkey])
    }

    @Test("startup hotkey failure shows menu bar without overwriting hidden preference")
    func startupHotkeyFailureDoesNotOverwriteHiddenMenuBarPreference() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.showMenuBarItem = false
        let state = AppState()
        let appDelegate = AppDelegate(
            settings: settings,
            launchAtLoginManager: FakeLaunchAtLoginManager(),
            state: state,
            hotkeyManager: FakeHotkeyManager(startError: SettableTestError.startFailed),
            permissionManager: FakeAccessibilityPermissionManager()
        )

        appDelegate.applySettings()

        #expect(settings.showMenuBarItem == false)
        #expect(state.showMenuBarItem == true)
        #expect(!state.hasActiveHotkey)
        #expect(state.lastError != nil)
        #expect(state.currentIssue?.kind == .hotkeyConflict)
        #expect(state.currentIssue?.recoveryActions == [.changeShortcut])
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
    var activeHotkey: GlobalHotkey?
    private(set) var startCalls: [GlobalHotkey] = []
    private(set) var stopCalls = 0
    private(set) var testRegistrationCalls: [GlobalHotkey] = []
    private(set) var callHistory: [String] = []
    private let testRegistrationError: (any Error)?
    private let startError: (any Error)?

    init(
        testRegistrationError: (any Error)? = nil,
        startError: (any Error)? = nil,
        activeHotkey: GlobalHotkey? = nil
    ) {
        self.testRegistrationError = testRegistrationError
        self.startError = startError
        self.activeHotkey = activeHotkey
    }

    func start(hotkey: GlobalHotkey) throws {
        startCalls.append(hotkey)
        callHistory.append("start(\(hotkey.displayName))")

        if let startError {
            throw startError
        }

        activeHotkey = hotkey
    }

    func stop() {
        stopCalls += 1
        activeHotkey = nil
    }

    func testRegistration(hotkey: GlobalHotkey) throws {
        testRegistrationCalls.append(hotkey)
        callHistory.append("test(\(hotkey.displayName))")

        if let testRegistrationError {
            throw testRegistrationError
        }
    }
}

private final class FakeLaunchAtLoginManager: LaunchAtLoginManaging {
    func status() -> LaunchAtLoginStatus {
        .disabled
    }

    func setEnabled(_ enabled: Bool) throws {}
}

private struct FakeAccessibilityPermissionManager: AccessibilityPermissionChecking {
    func status(prompt: Bool) -> AccessibilityPermissionStatus {
        .trusted
    }

    func openAccessibilitySettings() -> Bool {
        true
    }
}

private enum SettableTestError: Error {
    case registrationFailed
    case startFailed
}
