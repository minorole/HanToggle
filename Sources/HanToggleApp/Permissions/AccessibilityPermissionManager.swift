import AppKit
@preconcurrency import ApplicationServices

enum AccessibilityPermissionStatus: Equatable {
    case trusted
    case notTrusted
    case trustedButEventsUnavailable
}

struct AccessibilityPermissionManager {
    private static let accessibilitySettingsURLString =
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

    func isTrusted(prompt: Bool = false) -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt,
        ] as CFDictionary

        return AXIsProcessTrustedWithOptions(options)
    }

    func status(prompt: Bool = false) -> AccessibilityPermissionStatus {
        guard isTrusted(prompt: prompt) else {
            return .notTrusted
        }

        guard canCreateEventTap() else {
            return .trustedButEventsUnavailable
        }

        return .trusted
    }

    func canCreateEventTap() -> Bool {
        let eventMask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { _, _, event, _ in
                Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) else {
            return false
        }

        CGEvent.tapEnable(tap: eventTap, enable: false)
        CFMachPortInvalidate(eventTap)
        return true
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: Self.accessibilitySettingsURLString) else {
            return
        }

        NSWorkspace.shared.open(url)

        for application in NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences") {
            application.activate()
        }
    }
}
