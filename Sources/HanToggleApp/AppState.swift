import Foundation
import HanToggle

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var accessibilityStatus: AccessibilityPermissionStatus = .notTrusted
    @Published private(set) var statusMessage = "Starting HanToggle..."
    @Published private(set) var lastError: String?
    @Published private(set) var conversionTestStatus: ConversionTestStatus = .notRun
    @Published private(set) var isAccessibilityTrusted = false
    @Published private(set) var lastDirection: ToggleDirection = .unchanged
    @Published private(set) var hotkeyDisplayName = GlobalHotkey.default.displayName
    @Published private(set) var hotkeyRecordingError: String?
    @Published private(set) var hasActiveHotkey = false
    @Published private(set) var isTextReplacementServiceReady = false
    @Published private(set) var showMenuBarItem = true
    @Published private(set) var hasCompletedSetup = false
    @Published private(set) var launchAtLoginStatus: LaunchAtLoginStatus = .disabled
    @Published private(set) var currentIssue: AppIssue?

    private var lastErrorSource: ErrorSource?

    var canToggleSelection: Bool {
        accessibilityStatus == .trusted
    }

    var canCompleteSetup: Bool {
        accessibilityStatus == .trusted &&
        hasActiveHotkey &&
        isTextReplacementServiceReady &&
        conversionTestStatus == .passed
    }

    var shouldShowSetupChecklist: Bool {
        !hasCompletedSetup ||
        accessibilityStatus != .trusted ||
        !hasActiveHotkey ||
        !isTextReplacementServiceReady
    }

    var setupStatusTitle: String {
        switch accessibilityStatus {
        case .notTrusted:
            "Accessibility Required"
        case .trusted:
            if !isTextReplacementServiceReady {
                "Text Converter"
            } else if !hasActiveHotkey {
                "Keyboard Shortcut"
            } else if conversionTestStatus != .passed {
                "Test Conversion"
            } else {
                "HanToggle is ready"
            }
        }
    }

    var setupPrimaryMessage: String {
        switch accessibilityStatus {
        case .notTrusted:
            "Enable HanToggle in System Settings > Privacy & Security > Accessibility."
        case .trusted:
            if !isTextReplacementServiceReady {
                TextReplacementError.converterInitializationFailed.localizedDescription
            } else if !hasActiveHotkey {
                "Choose a keyboard shortcut before completing setup."
            } else {
                switch conversionTestStatus {
                case .notRun:
                    "Run the local conversion test before completing setup."
                case .running:
                    "Testing local conversion..."
                case .failed(let message):
                    message
                case .passed:
                    "Select Chinese text in most apps, then press \(hotkeyDisplayName)."
                }
            }
        }
    }

    var accessibilityStatusLabel: String {
        switch accessibilityStatus {
        case .trusted:
            "Allowed"
        case .notTrusted:
            "Not allowed"
        }
    }

    var accessibilityGuidance: String {
        switch accessibilityStatus {
        case .trusted:
            "HanToggle can replace selected text with the configured hotkey."
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
        currentIssue = nil
    }

    func setError(_ message: String, source: ErrorSource = .general) {
        switch source {
        case .accessibility:
            setIssue(.accessibilityRequired())
        case .hotkey:
            setIssue(.hotkeyInvalid(message))
        case .general:
            setIssue(.general(message))
        }
    }

    func updateConversionTestStatus(_ status: ConversionTestStatus) {
        conversionTestStatus = status
    }

    func updateConversionTestResult(_ result: ConversionTestResult) {
        conversionTestStatus = result.status
    }

    func setIssue(_ issue: AppIssue) {
        currentIssue = issue
        statusMessage = "HanToggle needs attention"
        lastError = issue.message

        switch issue.kind {
        case .accessibilityRequired:
            lastErrorSource = .accessibility
        case .hotkeyInvalid, .hotkeyConflict:
            lastErrorSource = .hotkey
        default:
            lastErrorSource = .general
        }
    }

    func updateAccessibility(_ status: AccessibilityPermissionStatus) {
        accessibilityStatus = status

        switch status {
        case .trusted:
            isAccessibilityTrusted = true

            guard lastErrorSource == .accessibility else {
                if lastError == nil {
                    statusMessage = "HanToggle is ready"
                }

                return
            }

            setReady()
        case .notTrusted:
            isAccessibilityTrusted = false
            setIssue(
                AppIssue(
                    message: "Enable HanToggle in System Settings > Privacy & Security > Accessibility.",
                    kind: .accessibilityRequired,
                    severity: .blocking,
                    recoveryActions: [.openAccessibilitySettings, .openSetup]
                )
            )
            statusMessage = "Accessibility Required"
        }
    }

    func updateAfterToggle(_ result: ToggleResult) {
        lastDirection = result.direction
        lastError = nil
        lastErrorSource = nil
        currentIssue = nil

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

    func setTextReplacementServiceReady(_ isReady: Bool) {
        isTextReplacementServiceReady = isReady
    }

    func updateSettings(
        hotkeyDisplayName: String,
        showMenuBarItem: Bool,
        hasCompletedSetup: Bool,
        launchAtLoginStatus: LaunchAtLoginStatus
    ) {
        self.hotkeyDisplayName = hotkeyDisplayName
        self.hasCompletedSetup = hasCompletedSetup
        updateShowMenuBarItem(showMenuBarItem)
        self.launchAtLoginStatus = launchAtLoginStatus
    }

    func updateShowMenuBarItem(_ showMenuBarItem: Bool) {
        guard showMenuBarItem || hasActiveHotkey else {
            guard !self.showMenuBarItem else {
                return
            }

            self.showMenuBarItem = true
            return
        }

        guard self.showMenuBarItem != showMenuBarItem else {
            return
        }

        self.showMenuBarItem = showMenuBarItem
    }

    func updateLaunchAtLoginStatus(_ status: LaunchAtLoginStatus) {
        launchAtLoginStatus = status
    }

    func markSetupCompleted() {
        hasCompletedSetup = true
    }

    enum ErrorSource {
        case accessibility
        case hotkey
        case general
    }
}

@MainActor
let appState = AppState.shared
