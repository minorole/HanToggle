import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings: AppSettings
    private let state: AppState
    private var hotkeyManager: any HotkeyManaging
    private let permissionManager = AccessibilityPermissionManager()
    private let launchAtLoginManager: any LaunchAtLoginManaging
    private var textReplacementService: TextReplacementService?

    override init() {
        self.settings = AppSettings()
        self.launchAtLoginManager = LaunchAtLoginManager()
        self.hotkeyManager = HotkeyManager()
        self.state = .shared
        super.init()
    }

    init(
        settings: AppSettings,
        launchAtLoginManager: any LaunchAtLoginManaging,
        state: AppState,
        hotkeyManager: any HotkeyManaging = HotkeyManager()
    ) {
        self.settings = settings
        self.launchAtLoginManager = launchAtLoginManager
        self.hotkeyManager = hotkeyManager
        self.state = state
        super.init()
    }

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
            state.setError(error.localizedDescription)
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

    func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        do {
            try launchAtLoginManager.setEnabled(enabled)
            settings.launchAtLogin = enabled
            state.updateLaunchAtLogin(enabled)
            return true
        } catch {
            state.updateLaunchAtLogin(settings.launchAtLogin)
            state.setError("HanToggle could not update Launch at Login.")
            return false
        }
    }

    func toggleSelection() {
        guard state.canToggleSelection else {
            state.setError("Accessibility permission is required before HanToggle can convert selected text.")
            return
        }

        guard let textReplacementService else {
            state.setError(TextReplacementError.converterInitializationFailed.localizedDescription)
            return
        }

        Task { @MainActor in
            do {
                let result = try await textReplacementService.toggleSelection()
                self.state.updateAfterToggle(result)
            } catch {
                self.state.setError(error.localizedDescription)
            }
        }
    }

    private func startHotkey() {
        let hotkey = settings.hotkey
        state.updateHotkeyDisplayName(hotkey.displayName)

        let validation = HotkeyValidator.validate(hotkey)

        switch validation {
        case .valid:
            break
        case .invalid:
            state.setError(validation.errorMessage ?? "Choose another shortcut.")
            return
        }

        do {
            try hotkeyManager.start(hotkey: hotkey)
        } catch {
            state.setError(error.localizedDescription)
        }
    }

    private func refreshSettingsState() {
        state.updateSettings(
            hotkeyDisplayName: settings.hotkey.displayName,
            showMenuBarStatus: settings.showMenuBarStatus,
            launchAtLogin: settings.launchAtLogin
        )
    }
}
