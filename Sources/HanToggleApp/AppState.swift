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

    var canToggleSelection: Bool {
        isAccessibilityTrusted && canUseAccessibilityEvents
    }

    func setReady() {
        statusMessage = "HanToggle is ready"
        lastError = nil
    }

    func setError(_ message: String) {
        statusMessage = "HanToggle needs attention"
        lastError = message
    }

    func updateAccessibility(trusted: Bool, canUseEvents: Bool) {
        isAccessibilityTrusted = trusted
        canUseAccessibilityEvents = canUseEvents

        switch (trusted, canUseEvents) {
        case (true, true):
            setReady()
        case (true, false):
            setError("Accessibility permission is enabled, but HanToggle cannot receive keyboard events yet. Restart HanToggle and try again.")
        case (false, _):
            setError("Accessibility permission is required. Enable HanToggle in System Settings > Privacy & Security > Accessibility.")
        }
    }

    func updateAfterToggle(_ result: ToggleResult) {
        lastDirection = result.direction
        lastError = nil

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
    }
}

@MainActor
let appState = AppState.shared
