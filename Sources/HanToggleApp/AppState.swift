import Foundation
import HanToggle

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var accessibilityStatus: AccessibilityPermissionStatus = .notTrusted
    @Published private(set) var statusMessage = "Starting HanToggle..."
    @Published private(set) var lastError: String?
    @Published private(set) var isAccessibilityTrusted = false
    @Published private(set) var canUseAccessibilityEvents = false
    @Published private(set) var lastDirection: ToggleDirection = .unchanged
    @Published private(set) var hotkeyDisplayName = GlobalHotkey.default.displayName
    @Published private(set) var hotkeyRecordingError: String?
    @Published private(set) var hasActiveHotkey = false
    @Published private(set) var showMenuBarItem = true
    @Published private(set) var launchAtLogin = false

    private var lastErrorSource: ErrorSource?

    var canToggleSelection: Bool {
        accessibilityStatus == .trusted
    }

    var accessibilityStatusLabel: String {
        switch accessibilityStatus {
        case .trusted:
            "Allowed"
        case .trustedButEventsUnavailable:
            "Restart needed"
        case .notTrusted:
            "Not allowed"
        }
    }

    var accessibilityGuidance: String {
        switch accessibilityStatus {
        case .trusted:
            "HanToggle can replace selected text with the configured hotkey."
        case .trustedButEventsUnavailable:
            "Restart HanToggle after enabling Accessibility."
        case .notTrusted:
            "Enable HanToggle in System Settings > Privacy & Security > Accessibility."
        }
    }

    var menuBarSystemImageName: String {
        guard showMenuBarItem, lastError != nil else {
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

    func updateAccessibility(_ status: AccessibilityPermissionStatus) {
        accessibilityStatus = status

        switch status {
        case .trusted:
            isAccessibilityTrusted = true
            canUseAccessibilityEvents = true
            setReady()
        case .trustedButEventsUnavailable:
            isAccessibilityTrusted = true
            canUseAccessibilityEvents = false
            statusMessage = "Restart Required"
            lastError = "Restart HanToggle after enabling Accessibility."
            lastErrorSource = .accessibility
        case .notTrusted:
            isAccessibilityTrusted = false
            canUseAccessibilityEvents = false
            statusMessage = "Accessibility Required"
            lastError = "Enable HanToggle in System Settings > Privacy & Security > Accessibility."
            lastErrorSource = .accessibility
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

    func updateSettings(hotkeyDisplayName: String, showMenuBarItem: Bool, launchAtLogin: Bool) {
        self.hotkeyDisplayName = hotkeyDisplayName
        updateShowMenuBarItem(showMenuBarItem)
        self.launchAtLogin = launchAtLogin
    }

    func updateShowMenuBarItem(_ showMenuBarItem: Bool) {
        guard showMenuBarItem || hasActiveHotkey else {
            self.showMenuBarItem = true
            return
        }

        self.showMenuBarItem = showMenuBarItem
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
