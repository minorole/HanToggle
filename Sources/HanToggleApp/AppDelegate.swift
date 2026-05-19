import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let permissionManager = AccessibilityPermissionManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        refreshAccessibilityState(prompt: false)
    }

    func refreshAccessibilityState(prompt: Bool) {
        let trusted = permissionManager.isTrusted(prompt: prompt)
        let canUseEvents = permissionManager.canCreateEventTap()

        appState.updateAccessibility(trusted: trusted, canUseEvents: canUseEvents)
    }
}
