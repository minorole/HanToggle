import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate?

    private let settings: AppSettings
    private let state: AppState
    private var hotkeyManager: any HotkeyManaging
    private let permissionManager: any AccessibilityPermissionChecking
    private let launchAtLoginManager: any LaunchAtLoginManaging
    private let activationPolicyManager: any ApplicationActivationPolicyManaging
    private let preferencesWindowPresenter: any PreferencesWindowPresenting
    private let conversionTestServiceFactory: () throws -> ConversionTestService
    private var textReplacementService: TextReplacementService?

    override init() {
        self.settings = AppSettings()
        self.launchAtLoginManager = LaunchAtLoginManager()
        self.hotkeyManager = HotkeyManager()
        self.permissionManager = AccessibilityPermissionManager()
        self.activationPolicyManager = ApplicationActivationPolicyManager()
        self.state = .shared
        self.preferencesWindowPresenter = AppKitPreferencesWindowPresenter(state: self.state)
        self.conversionTestServiceFactory = { try ConversionTestService() }
        super.init()
        Self.shared = self
    }

    init(
        settings: AppSettings,
        launchAtLoginManager: any LaunchAtLoginManaging,
        state: AppState,
        hotkeyManager: any HotkeyManaging = HotkeyManager(),
        permissionManager: any AccessibilityPermissionChecking = AccessibilityPermissionManager(),
        activationPolicyManager: any ApplicationActivationPolicyManaging = ApplicationActivationPolicyManager(),
        conversionTestServiceFactory: @escaping () throws -> ConversionTestService = { try ConversionTestService() },
        preferencesWindowPresenter: (any PreferencesWindowPresenting)? = nil
    ) {
        self.settings = settings
        self.launchAtLoginManager = launchAtLoginManager
        self.hotkeyManager = hotkeyManager
        self.permissionManager = permissionManager
        self.activationPolicyManager = activationPolicyManager
        self.conversionTestServiceFactory = conversionTestServiceFactory
        self.state = state
        self.preferencesWindowPresenter = preferencesWindowPresenter ?? AppKitPreferencesWindowPresenter(state: state)
        super.init()
        Self.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !applyDockIconVisibility(settings.showDockIcon) {
            settings.showDockIcon = false
            state.updateShowDockIcon(false)
        }

        hotkeyManager.onHotkey = { [weak self] in
            self?.toggleSelection()
        }

        do {
            textReplacementService = try TextReplacementService(permissionManager: permissionManager)
            state.setTextReplacementServiceReady(true)
            applySettings()
            showPreferencesWhenAttentionIsRequired()
        } catch let error as TextReplacementError {
            state.setTextReplacementServiceReady(false)
            applySettings()
            showPreferencesWhenAttentionIsRequired()
            state.setIssue(AppIssue(textReplacementError: error))
        } catch {
            state.setTextReplacementServiceReady(false)
            applySettings()
            showPreferencesWhenAttentionIsRequired()
            state.setIssue(AppIssue(textReplacementError: .converterInitializationFailed))
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.stop()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        refreshAccessibilityState(prompt: false)
        refreshLaunchAtLoginState()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPrimaryWindow()
        return false
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

    func showPreferencesWindow() {
        refreshSettingsState()
        refreshAccessibilityState(prompt: false)
        preferencesWindowPresenter.showPreferencesWindow(actions: actions)
    }

    func showPrimaryWindow() {
        showPreferencesWindow()
    }

    func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        do {
            try launchAtLoginManager.setEnabled(enabled)
            refreshLaunchAtLoginState()
            return true
        } catch {
            refreshLaunchAtLoginState()
            state.setError("HanToggle could not update Launch at Login.")
            return false
        }
    }

    func setShowMenuBarItem(_ showMenuBarItem: Bool) {
        let allowedValue = showMenuBarItem || !state.hasActiveHotkey
        settings.showMenuBarItem = allowedValue
        state.updateShowMenuBarItem(allowedValue)
        applySettings()
    }

    func setShowDockIcon(_ showDockIcon: Bool) {
        let previousValue = settings.showDockIcon

        guard applyDockIconVisibility(showDockIcon) else {
            settings.showDockIcon = previousValue
            state.updateShowDockIcon(previousValue)
            return
        }

        settings.showDockIcon = showDockIcon
        state.updateShowDockIcon(showDockIcon)
    }

    @discardableResult
    private func applyDockIconVisibility(_ showDockIcon: Bool) -> Bool {
        let policy: HanToggleActivationPolicy = showDockIcon ? .regular : .accessory

        do {
            try activationPolicyManager.apply(policy)
            state.updateShowDockIcon(showDockIcon)
            return true
        } catch {
            state.setError("HanToggle could not update Dock icon visibility.")
            return false
        }
    }

    func toggleSelection() {
        guard state.canToggleSelection else {
            state.setIssue(.accessibilityRequired())
            return
        }

        guard let textReplacementService else {
            state.setIssue(AppIssue(textReplacementError: .converterInitializationFailed))
            return
        }

        Task { @MainActor in
            do {
                let result = try await textReplacementService.toggleSelection()
                self.state.updateAfterToggle(result)
            } catch let error as TextReplacementError {
                self.state.setIssue(AppIssue(textReplacementError: error))
            } catch {
                self.state.setIssue(.general(error.localizedDescription))
            }
        }
    }

    func runConversionTest() {
        state.updateConversionTestStatus(.running)

        do {
            let service = try conversionTestServiceFactory()
            let result = service.runSampleTest()
            state.updateConversionTestResult(result)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
                ?? "HanToggle could not start the Chinese text converter."
            state.updateConversionTestStatus(.failed(message))
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
                state.setIssue(.hotkeyConflict(conflictMessage))
            }
            return false
        }

        do {
            try hotkeyManager.start(hotkey: candidate)
        } catch {
            state.setHotkeyRecordingError(conflictMessage)

            if hotkeyManager.activeHotkey == nil {
                state.markHotkeyInactive(conflictMessage)
                state.setIssue(.hotkeyConflict(conflictMessage))
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
                if !state.isTextReplacementServiceReady {
                    state.setIssue(AppIssue(textReplacementError: .converterInitializationFailed))
                } else {
                    state.setError(state.setupPrimaryMessage)
                }
            }
            showPreferencesWindow()
            return false
        }

        settings.hasCompletedSetup = true
        state.markSetupCompleted()
        state.updateShowMenuBarItem(settings.showMenuBarItem)
        state.setReady()
        return true
    }

    private func showPreferencesWhenAttentionIsRequired() {
        guard state.shouldShowSetupChecklist else {
            return
        }

        state.updateShowMenuBarItem(true)
        preferencesWindowPresenter.showPreferencesWindow(actions: actions)
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
            state.setIssue(.hotkeyInvalid(message))
            return
        }

        do {
            try hotkeyManager.start(hotkey: hotkey)
            state.updateShowMenuBarItem(settings.showMenuBarItem)
        } catch {
            state.markHotkeyInactive(error.localizedDescription)
            state.setIssue(.hotkeyConflict(error.localizedDescription))
            state.updateShowMenuBarItem(true)
        }
    }

    private func refreshSettingsState() {
        state.updateSettings(
            hotkeyDisplayName: settings.hotkey.displayName,
            showMenuBarItem: settings.showMenuBarItem,
            showDockIcon: settings.showDockIcon,
            hasCompletedSetup: settings.hasCompletedSetup,
            launchAtLoginStatus: launchAtLoginManager.status()
        )
    }

    private func refreshLaunchAtLoginState() {
        state.updateLaunchAtLoginStatus(launchAtLoginManager.status())
    }

    var actionsForViews: HanToggleActions {
        actions
    }

    private var actions: HanToggleActions {
        HanToggleActions(
            showPreferencesWindow: { [weak self] in
                self?.showPreferencesWindow()
            },
            openAccessibilitySettings: { [weak self] in
                self?.openAccessibilitySettings()
            },
            runConversionTest: { [weak self] in
                self?.runConversionTest()
            },
            setHotkey: { [weak self] hotkey in
                self?.setHotkey(hotkey) == true
            },
            resetHotkeyToDefault: { [weak self] in
                self?.resetHotkeyToDefault() == true
            },
            completeSetup: { [weak self] in
                self?.completeSetup() == true
            },
            setShowMenuBarItem: { [weak self] showMenuBarItem in
                self?.setShowMenuBarItem(showMenuBarItem)
            },
            setShowDockIcon: { [weak self] showDockIcon in
                self?.setShowDockIcon(showDockIcon)
            },
            setLaunchAtLogin: { [weak self] enabled in
                self?.setLaunchAtLogin(enabled) == true
            },
            quit: {
                NSApplication.shared.terminate(nil)
            }
        )
    }
}
