import Foundation

enum AppIssueKind: Equatable {
    case accessibilityRequired
    case hotkeyInvalid
    case hotkeyConflict
    case noConvertibleSelection
    case copyFailed
    case pasteFailed
    case clipboardRestoreFailed
    case converterUnavailable
    case replacementAlreadyInProgress
    case dockIconVisibilityFailed
    case general
}

enum AppIssueSeverity: Equatable {
    case warning
    case blocking
}

enum RecoveryAction: Equatable {
    case openAccessibilitySettings
    case openPreferences
    case changeShortcut
}

struct AppIssue: Equatable {
    let message: String
    let kind: AppIssueKind
    let severity: AppIssueSeverity
    let recoveryActions: [RecoveryAction]
    let hint: String?

    init(
        message: String,
        kind: AppIssueKind,
        severity: AppIssueSeverity,
        recoveryActions: [RecoveryAction],
        hint: String? = nil
    ) {
        self.message = message
        self.kind = kind
        self.severity = severity
        self.recoveryActions = recoveryActions
        self.hint = hint
    }

    static func accessibilityRequired() -> AppIssue {
        AppIssue(
            message: "Accessibility permission is required before HanToggle can convert selected text.",
            kind: .accessibilityRequired,
            severity: .blocking,
            recoveryActions: [.openAccessibilitySettings, .openPreferences]
        )
    }

    static func hotkeyInvalid(_ message: String) -> AppIssue {
        AppIssue(
            message: message,
            kind: .hotkeyInvalid,
            severity: .blocking,
            recoveryActions: [.changeShortcut]
        )
    }

    static func hotkeyConflict(_ message: String) -> AppIssue {
        AppIssue(
            message: message,
            kind: .hotkeyConflict,
            severity: .blocking,
            recoveryActions: [.changeShortcut]
        )
    }

    static func general(_ message: String) -> AppIssue {
        AppIssue(
            message: message,
            kind: .general,
            severity: .warning,
            recoveryActions: [.openPreferences]
        )
    }

    static func dockIconVisibilityFailed(_ message: String) -> AppIssue {
        AppIssue(
            message: message,
            kind: .dockIconVisibilityFailed,
            severity: .warning,
            recoveryActions: [.openPreferences],
            hint: "HanToggle is still running from the menu bar."
        )
    }

    var statusMessage: String {
        switch kind {
        case .dockIconVisibilityFailed:
            "Dock icon update failed"
        default:
            "HanToggle needs attention"
        }
    }

    init(textReplacementError error: TextReplacementError) {
        switch error {
        case .missingAccessibilityPermission:
            self = .accessibilityRequired()
        case .incompleteClipboardSnapshot:
            self = AppIssue(
                message: error.localizedDescription,
                kind: .copyFailed,
                severity: .blocking,
                recoveryActions: [.openPreferences],
                hint: "HanToggle did not change selected text because it could not safely preserve the current clipboard."
            )
        case .copyEventFailed:
            self = AppIssue(
                message: error.localizedDescription,
                kind: .copyFailed,
                severity: .warning,
                recoveryActions: [.openPreferences],
                hint: "Select editable text and try again."
            )
        case .noSelectedChineseTextFoundOrUnchangedSelection:
            self = AppIssue(
                message: error.localizedDescription,
                kind: .noConvertibleSelection,
                severity: .warning,
                recoveryActions: [.openPreferences],
                hint: "Select Chinese text, then press the configured hotkey."
            )
        case .pasteEventFailed:
            self = AppIssue(
                message: error.localizedDescription,
                kind: .pasteFailed,
                severity: .warning,
                recoveryActions: [.openPreferences],
                hint: "The current app may block simulated paste. Try TextEdit to confirm HanToggle is working."
            )
        case .clipboardRestoreFailed:
            self = AppIssue(
                message: error.localizedDescription,
                kind: .clipboardRestoreFailed,
                severity: .blocking,
                recoveryActions: [.openPreferences],
                hint: "Clipboard restore failed. Avoid copying new private data until you confirm the clipboard contents."
            )
        case .converterInitializationFailed:
            self = AppIssue(
                message: error.localizedDescription,
                kind: .converterUnavailable,
                severity: .blocking,
                recoveryActions: [.openPreferences],
                hint: "The local converter could not start."
            )
        case .replacementAlreadyInProgress:
            self = AppIssue(
                message: error.localizedDescription,
                kind: .replacementAlreadyInProgress,
                severity: .warning,
                recoveryActions: [],
                hint: "Wait for the current conversion to finish and try again."
            )
        }
    }
}
