import AppKit
@preconcurrency import ApplicationServices

enum AccessibilityPermissionStatus: Equatable {
    case trusted
    case notTrusted
}

struct AccessibilityPermissionManager {
    private static let accessibilitySettingsURLStrings = [
        "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
    ]

    private let trustCheck: (Bool) -> Bool

    init(trustCheck: @escaping (Bool) -> Bool = Self.axIsProcessTrusted(prompt:)) {
        self.trustCheck = trustCheck
    }

    func isTrusted(prompt: Bool = false) -> Bool {
        trustCheck(prompt)
    }

    func status(prompt: Bool = false) -> AccessibilityPermissionStatus {
        isTrusted(prompt: prompt) ? .trusted : .notTrusted
    }

    private static func axIsProcessTrusted(prompt: Bool) -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt,
        ] as CFDictionary

        return AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() -> Bool {
        let didOpenDeepLink = Self.accessibilitySettingsURLStrings
            .compactMap(URL.init(string:))
            .contains { NSWorkspace.shared.open($0) }

        let didOpenSettingsApp = didOpenDeepLink || NSWorkspace.shared.open(
            URL(fileURLWithPath: "/System/Applications/System Settings.app")
        )

        for bundleIdentifier in ["com.apple.systempreferences", "com.apple.SystemSettings"] {
            for application in NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier) {
                application.activate()
            }
        }

        return didOpenSettingsApp
    }
}
