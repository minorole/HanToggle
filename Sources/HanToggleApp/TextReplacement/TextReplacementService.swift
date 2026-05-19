import AppKit
import Foundation
import HanToggle

@MainActor
protocol AccessibilityPermissionChecking {
    func isTrusted(prompt: Bool) -> Bool
    func canCreateEventTap() -> Bool
}

extension AccessibilityPermissionManager: AccessibilityPermissionChecking {}

@MainActor
protocol KeyboardEventSending {
    func sendCommandC() -> Bool
    func sendCommandV() -> Bool
}

extension KeyboardEventSender: KeyboardEventSending {}

enum TextReplacementError: LocalizedError, Equatable {
    case missingAccessibilityPermission
    case incompleteClipboardSnapshot
    case copyEventFailed
    case noSelectedChineseTextFoundOrUnchangedSelection
    case pasteEventFailed
    case clipboardRestoreFailed
    case converterInitializationFailed
    case replacementAlreadyInProgress

    var errorDescription: String? {
        switch self {
        case .missingAccessibilityPermission:
            "Accessibility permission is required. Enable HanToggle in System Settings > Privacy & Security > Accessibility."
        case .incompleteClipboardSnapshot:
            "HanToggle could not safely preserve the current clipboard, so selected text was not changed."
        case .copyEventFailed:
            "HanToggle could not copy the selected text. Select Chinese text and try again."
        case .noSelectedChineseTextFoundOrUnchangedSelection:
            "No selected Chinese text was found, or the selected text did not need conversion."
        case .pasteEventFailed:
            "HanToggle converted the text but could not paste it back into the app."
        case .clipboardRestoreFailed:
            "HanToggle could not restore the previous clipboard contents."
        case .converterInitializationFailed:
            "HanToggle could not start the Chinese text converter."
        case .replacementAlreadyInProgress:
            "HanToggle is already converting selected text. Wait for the current conversion to finish and try again."
        }
    }
}

@MainActor
final class TextReplacementService {
    private let permissionManager: any AccessibilityPermissionChecking
    private let keyboardEventSender: any KeyboardEventSending
    private let scriptToggler: ScriptToggler
    private let pasteboard: NSPasteboard
    private let copyDelay: Duration
    private let pasteDelay: Duration
    private let snapshotCapture: (NSPasteboard) -> PasteboardSnapshot
    private let snapshotRestore: (PasteboardSnapshot, NSPasteboard) -> Bool
    private var isReplacementInProgress = false

    init(
        permissionManager: any AccessibilityPermissionChecking = AccessibilityPermissionManager(),
        keyboardEventSender: any KeyboardEventSending = KeyboardEventSender(),
        scriptToggler: ScriptToggler? = nil,
        pasteboard: NSPasteboard = .general,
        copyDelay: Duration = .milliseconds(120),
        pasteDelay: Duration = .milliseconds(120),
        snapshotCapture: @escaping (NSPasteboard) -> PasteboardSnapshot = { PasteboardSnapshot(from: $0) },
        snapshotRestore: @escaping (PasteboardSnapshot, NSPasteboard) -> Bool = { $0.restore(to: $1) }
    ) throws {
        self.permissionManager = permissionManager
        self.keyboardEventSender = keyboardEventSender
        self.pasteboard = pasteboard
        self.copyDelay = copyDelay
        self.pasteDelay = pasteDelay
        self.snapshotCapture = snapshotCapture
        self.snapshotRestore = snapshotRestore

        if let scriptToggler {
            self.scriptToggler = scriptToggler
        } else {
            do {
                self.scriptToggler = try ScriptToggler()
            } catch {
                throw TextReplacementError.converterInitializationFailed
            }
        }
    }

    func toggleSelection() async throws -> ToggleResult {
        guard !isReplacementInProgress else {
            throw TextReplacementError.replacementAlreadyInProgress
        }

        isReplacementInProgress = true
        defer { isReplacementInProgress = false }

        guard permissionManager.isTrusted(prompt: false), permissionManager.canCreateEventTap() else {
            throw TextReplacementError.missingAccessibilityPermission
        }

        let originalClipboard = snapshotCapture(pasteboard)
        guard originalClipboard.isComplete else {
            throw TextReplacementError.incompleteClipboardSnapshot
        }

        pasteboard.clearContents()

        let result: ToggleResult

        do {
            guard keyboardEventSender.sendCommandC() else {
                throw TextReplacementError.copyEventFailed
            }

            try await Task.sleep(for: copyDelay)

            guard let selectedText = pasteboard.string(forType: .string), !selectedText.isEmpty else {
                throw TextReplacementError.noSelectedChineseTextFoundOrUnchangedSelection
            }

            result = scriptToggler.toggle(selectedText)
            guard result.direction != .unchanged else {
                throw TextReplacementError.noSelectedChineseTextFoundOrUnchangedSelection
            }

            let convertedItem = NSPasteboardItem()
            let autoGeneratedType = NSPasteboard.PasteboardType("org.nspasteboard.AutoGeneratedType")

            guard convertedItem.setString(result.text, forType: .string),
                  convertedItem.setData(Data(), forType: autoGeneratedType)
            else {
                throw TextReplacementError.pasteEventFailed
            }

            pasteboard.clearContents()
            guard pasteboard.writeObjects([convertedItem]) else {
                throw TextReplacementError.pasteEventFailed
            }

            guard keyboardEventSender.sendCommandV() else {
                throw TextReplacementError.pasteEventFailed
            }

            try await Task.sleep(for: pasteDelay)
        } catch {
            try restore(originalClipboard)
            throw error
        }

        try restore(originalClipboard)

        return result
    }

    private func restore(_ snapshot: PasteboardSnapshot) throws {
        guard snapshotRestore(snapshot, pasteboard) else {
            throw TextReplacementError.clipboardRestoreFailed
        }
    }
}
