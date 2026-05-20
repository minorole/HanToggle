import SwiftUI

struct HanToggleActions: Sendable {
    var showPreferencesWindow: @MainActor @Sendable () -> Void = {}
    var openAccessibilitySettings: @MainActor @Sendable () -> Void = {}
    var openSupportEmail: @MainActor @Sendable () -> Void = {}
    var runConversionTest: @MainActor @Sendable () -> Void = {}
    var setHotkey: @MainActor @Sendable (GlobalHotkey) -> Bool = { _ in false }
    var resetHotkeyToDefault: @MainActor @Sendable () -> Bool = { false }
    var completeSetup: @MainActor @Sendable () -> Bool = { false }
    var setShowMenuBarItem: @MainActor @Sendable (Bool) -> Void = { _ in }
    var setShowDockIcon: @MainActor @Sendable (Bool) -> Void = { _ in }
    var setLaunchAtLogin: @MainActor @Sendable (Bool) -> Bool = { _ in false }
    var quit: @MainActor @Sendable () -> Void = {}

    static let noop = HanToggleActions()
}

private struct HanToggleActionsKey: EnvironmentKey {
    static let defaultValue = HanToggleActions.noop
}

extension EnvironmentValues {
    var hanToggleActions: HanToggleActions {
        get { self[HanToggleActionsKey.self] }
        set { self[HanToggleActionsKey.self] = newValue }
    }
}
