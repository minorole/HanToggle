import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let permissionManager = AccessibilityPermissionManager()
    private var textReplacementService: TextReplacementService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        refreshAccessibilityState(prompt: false)

        do {
            textReplacementService = try TextReplacementService(permissionManager: permissionManager)
        } catch {
            appState.setError(error.localizedDescription)
        }
    }

    func refreshAccessibilityState(prompt: Bool) {
        let trusted = permissionManager.isTrusted(prompt: prompt)
        let canUseEvents = permissionManager.canCreateEventTap()

        appState.updateAccessibility(trusted: trusted, canUseEvents: canUseEvents)
    }

    func toggleSelection() {
        guard AppState.shared.canToggleSelection else {
            AppState.shared.setError("Accessibility permission is required before HanToggle can convert selected text.")
            return
        }

        guard let textReplacementService else {
            AppState.shared.setError(TextReplacementError.converterInitializationFailed.localizedDescription)
            return
        }

        Task { @MainActor in
            do {
                let result = try await textReplacementService.toggleSelection()
                AppState.shared.updateAfterToggle(result)
            } catch {
                AppState.shared.setError(error.localizedDescription)
            }
        }
    }
}
