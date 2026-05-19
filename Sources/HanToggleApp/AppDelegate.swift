import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate?

    private let settings: AppSettings
    private let state: AppState
    private var hotkeyManager: any HotkeyManaging
    private let permissionManager: any AccessibilityPermissionChecking
    private let launchAtLoginManager: any LaunchAtLoginManaging
    private let settingsWindowPresenter: any SettingsWindowPresenting
    private let setupWindowPresenter: any SetupWindowPresenting
    private var textReplacementService: TextReplacementService?

    override init() {
        self.settings = AppSettings()
        self.launchAtLoginManager = LaunchAtLoginManager()
        self.hotkeyManager = HotkeyManager()
        self.permissionManager = AccessibilityPermissionManager()
        self.state = .shared
        self.settingsWindowPresenter = AppKitSettingsWindowPresenter(state: self.state)
        self.setupWindowPresenter = AppKitSetupWindowPresenter(state: self.state)
        super.init()
        Self.shared = self
    }

    init(
        settings: AppSettings,
        launchAtLoginManager: any LaunchAtLoginManaging,
        state: AppState,
        hotkeyManager: any HotkeyManaging = HotkeyManager(),
        permissionManager: any AccessibilityPermissionChecking = AccessibilityPermissionManager(),
        settingsWindowPresenter: (any SettingsWindowPresenting)? = nil,
        setupWindowPresenter: (any SetupWindowPresenting)? = nil
    ) {
        self.settings = settings
        self.launchAtLoginManager = launchAtLoginManager
        self.hotkeyManager = hotkeyManager
        self.permissionManager = permissionManager
        self.state = state
        self.settingsWindowPresenter = settingsWindowPresenter ?? AppKitSettingsWindowPresenter(state: state)
        self.setupWindowPresenter = setupWindowPresenter ?? AppKitSetupWindowPresenter(state: state)
        super.init()
        Self.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if NSApp != nil {
            NSApp.setActivationPolicy(.accessory)
        }
        hotkeyManager.onHotkey = { [weak self] in
            self?.toggleSelection()
        }

        do {
            textReplacementService = try TextReplacementService(permissionManager: permissionManager)
            state.setTextReplacementServiceReady(true)
            applySettings()
            reconcileSetupPresentation()
        } catch {
            state.setTextReplacementServiceReady(false)
            reconcileSetupPresentation()
            state.setError(error.localizedDescription)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.stop()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        refreshAccessibilityState(prompt: false)
        reconcileSetupPresentation(refreshState: false)
    }

    func refreshAccessibilityState(prompt: Bool) {
        state.updateAccessibility(permissionManager.status(prompt: prompt))
    }

    func requestAccessibilityPermission() {
        refreshAccessibilityState(prompt: true)
    }

    func openAccessibilitySettings() {
        refreshAccessibilityState(prompt: true)
        let didOpenSettings = permissionManager.openAccessibilitySettings()
        refreshAccessibilityState(prompt: false)

        guard didOpenSettings else {
            state.setError("HanToggle could not open Accessibility settings. Open System Settings > Privacy & Security > Accessibility manually.")
            return
        }
    }

    func applySettings() {
        refreshSettingsState()
        refreshAccessibilityState(prompt: false)
        startHotkey()
    }

    func showSettingsWindow() {
        settingsWindowPresenter.showSettingsWindow()
    }

    func showSetupWindow() {
        setupWindowPresenter.showSetupWindow()
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

    func setHotkey(_ candidate: GlobalHotkey) -> Bool {
        let validation = HotkeyValidator.validate(candidate)
        let conflictMessage = "This shortcut is already in use or reserved by macOS. Choose another shortcut."

        switch validation {
        case .valid:
            break
        case .invalid:
            state.setHotkeyRecordingError(validation.errorMessage ?? "Choose another shortcut.")
            return false
        }

        if candidate == settings.hotkey, candidate == hotkeyManager.activeHotkey {
            state.confirmHotkeyActive(candidate.displayName)
            return true
        }

        do {
            try hotkeyManager.testRegistration(hotkey: candidate)
        } catch {
            state.setHotkeyRecordingError(conflictMessage)

            if hotkeyManager.activeHotkey == nil {
                state.markHotkeyInactive(conflictMessage)
            }
            return false
        }

        do {
            try hotkeyManager.start(hotkey: candidate)
        } catch {
            state.setHotkeyRecordingError(conflictMessage)

            if hotkeyManager.activeHotkey == nil {
                state.markHotkeyInactive(conflictMessage)
            }
            return false
        }

        settings.hotkey = candidate
        state.confirmHotkeyActive(candidate.displayName)
        return true
    }

    func resetHotkeyToDefault() -> Bool {
        setHotkey(.default)
    }

    func completeSetup() -> Bool {
        refreshAccessibilityState(prompt: false)

        guard state.canCompleteSetup else {
            if state.accessibilityStatus == .trusted {
                state.setError(state.setupPrimaryMessage)
            }
            setupWindowPresenter.showSetupWindow()
            return false
        }

        settings.hasCompletedSetup = true
        state.updateShowMenuBarItem(settings.showMenuBarItem)
        setupWindowPresenter.closeSetupWindow()
        state.setReady()
        return true
    }

    func reconcileSetupPresentation() {
        reconcileSetupPresentation(refreshState: true)
    }

    private func reconcileSetupPresentation(refreshState: Bool) {
        if refreshState {
            refreshSettingsState()
            refreshAccessibilityState(prompt: false)
        }

        guard shouldShowSetup else {
            return
        }

        state.updateShowMenuBarItem(true)
        setupWindowPresenter.showSetupWindow()
    }

    private func startHotkey() {
        let hotkey = settings.hotkey
        state.updateHotkeyDisplayName(hotkey.displayName)

        let validation = HotkeyValidator.validate(hotkey)

        switch validation {
        case .valid:
            break
        case .invalid:
            hotkeyManager.stop()
            let message = validation.errorMessage ?? "Choose another shortcut."
            state.markHotkeyInactive(message)
            return
        }

        do {
            try hotkeyManager.start(hotkey: hotkey)
            state.updateShowMenuBarItem(settings.showMenuBarItem)
        } catch {
            state.markHotkeyInactive(error.localizedDescription)
            state.updateShowMenuBarItem(true)
        }
    }

    private func refreshSettingsState() {
        state.updateSettings(
            hotkeyDisplayName: settings.hotkey.displayName,
            showMenuBarItem: settings.showMenuBarItem,
            launchAtLogin: settings.launchAtLogin
        )
    }

    private var shouldShowSetup: Bool {
        !settings.hasCompletedSetup ||
        state.accessibilityStatus != .trusted ||
        !state.hasActiveHotkey
    }
}
