import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private let hotkeyManager = HotkeyManager()
    private let permissionManager = AccessibilityPermissionManager()
    private var textReplacementService: TextReplacementService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        refreshSettingsState()
        refreshAccessibilityState(prompt: false)

        hotkeyManager.onHotkey = { [weak self] in
            self?.toggleSelection()
        }

        do {
            textReplacementService = try TextReplacementService(permissionManager: permissionManager)
            applySettings()
        } catch {
            appState.setError(error.localizedDescription)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.stop()
    }

    func refreshAccessibilityState(prompt: Bool) {
        let trusted = permissionManager.isTrusted(prompt: prompt)
        let canUseEvents = permissionManager.canCreateEventTap()

        appState.updateAccessibility(trusted: trusted, canUseEvents: canUseEvents)
    }

    func requestAccessibilityPermission() {
        refreshAccessibilityState(prompt: true)
    }

    func openAccessibilitySettings() {
        permissionManager.openAccessibilitySettings()
        refreshAccessibilityState(prompt: false)
    }

    func applySettings() {
        refreshSettingsState()
        refreshAccessibilityState(prompt: false)
        startHotkey()
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

    private func startHotkey() {
        let hotkey = settings.hotkey
        AppState.shared.updateHotkeyDisplayName(hotkey.displayName)

        do {
            try hotkeyManager.start(hotkey: hotkey)
        } catch {
            AppState.shared.setError(error.localizedDescription)
        }
    }

    private func refreshSettingsState() {
        AppState.shared.updateSettings(
            hotkeyDisplayName: settings.hotkey.displayName,
            showMenuBarStatus: settings.showMenuBarStatus,
            launchAtLogin: settings.launchAtLogin
        )
    }
}
