import Foundation
import HanToggle

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var statusMessage = "Starting HanToggle..."
    @Published private(set) var lastError: String?
    @Published private(set) var isAccessibilityTrusted = false
    @Published private(set) var canUseAccessibilityEvents = false
    @Published private(set) var lastDirection: ToggleDirection = .unchanged
    @Published private(set) var hotkeyDisplayName = GlobalHotkey.default.displayName
    @Published private(set) var hotkeyRecordingError: String?
    @Published private(set) var hasActiveHotkey = false
    @Published private(set) var showMenuBarStatus = true
    @Published private(set) var launchAtLogin = false

    private var lastErrorSource: ErrorSource?

    var canToggleSelection: Bool {
        isAccessibilityTrusted && canUseAccessibilityEvents
    }

    var menuBarSystemImageName: String {
        guard showMenuBarStatus, lastError != nil else {
            return "character.textbox"
        }

        return "exclamationmark.triangle"
    }

    func setReady() {
        statusMessage = "HanToggle is ready"
        lastError = nil
        lastErrorSource = nil
    }

    func setError(_ message: String, source: ErrorSource = .general) {
        statusMessage = "HanToggle needs attention"
        lastError = message
        lastErrorSource = source
    }

    func updateAccessibility(trusted: Bool, canUseEvents: Bool) {
        isAccessibilityTrusted = trusted
        canUseAccessibilityEvents = canUseEvents

        switch (trusted, canUseEvents) {
        case (true, true):
            setReady()
        case (true, false):
            setError(
                "Accessibility permission is enabled, but HanToggle cannot receive keyboard events yet. Restart HanToggle and try again.",
                source: .accessibility
            )
        case (false, _):
            setError(
                "Accessibility permission is required. Enable HanToggle in System Settings > Privacy & Security > Accessibility.",
                source: .accessibility
            )
        }
    }

    func updateAfterToggle(_ result: ToggleResult) {
        lastDirection = result.direction
        lastError = nil
        lastErrorSource = nil

        switch result.direction {
        case .simplifiedToTraditional:
            statusMessage = "Converted to Traditional"
        case .traditionalToSimplified:
            statusMessage = "Converted to Simplified"
        case .unchanged:
            statusMessage = "Ready"
        }
    }

    func updateHotkeyDisplayName(_ displayName: String) {
        hotkeyDisplayName = displayName
        hasActiveHotkey = true
        hotkeyRecordingError = nil
    }

    func confirmHotkeyActive(_ displayName: String) {
        hotkeyDisplayName = displayName
        hasActiveHotkey = true
        hotkeyRecordingError = nil

        if lastError == nil || lastErrorSource == .hotkey {
            setReady()
        }
    }

    func setHotkeyRecordingError(_ error: String?) {
        hotkeyRecordingError = error
    }

    func markHotkeyInactive(_ message: String) {
        hasActiveHotkey = false
        setError(message, source: .hotkey)
        hotkeyRecordingError = message
    }

    func updateSettings(hotkeyDisplayName: String, showMenuBarStatus: Bool, launchAtLogin: Bool) {
        self.hotkeyDisplayName = hotkeyDisplayName
        self.showMenuBarStatus = showMenuBarStatus
        self.launchAtLogin = launchAtLogin
    }

    func updateShowMenuBarStatus(_ showMenuBarStatus: Bool) {
        self.showMenuBarStatus = showMenuBarStatus
    }

    func updateLaunchAtLogin(_ launchAtLogin: Bool) {
        self.launchAtLogin = launchAtLogin
    }

    enum ErrorSource {
        case accessibility
        case hotkey
        case general
    }
}

@MainActor
let appState = AppState.shared
