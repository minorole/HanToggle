import AppKit
import Testing
@testable import HanToggleApp

@MainActor
@Suite("TextReplacementService")
struct TextReplacementServiceTests {
    @Test("missing accessibility permission blocks mutation")
    func missingAccessibilityPermissionPreventsMutation() async throws {
        let pasteboard = makePasteboard()
        Self.setString("original", on: pasteboard)
        let keyboard = FakeKeyboardEventSender()
        let service = try makeService(
            pasteboard: pasteboard,
            keyboardEventSender: keyboard,
            permissionStatus: .notTrusted
        )

        await expectTextReplacementError(.missingAccessibilityPermission) {
            _ = try await service.toggleSelection()
        }

        #expect(pasteboard.string(forType: .string) == "original")
        #expect(keyboard.copyCallCount == 0)
        #expect(keyboard.pasteCallCount == 0)
    }

    @Test("incomplete snapshot prevents pasteboard mutation")
    func incompleteSnapshotPreventsMutation() async throws {
        let pasteboard = makePasteboard()
        Self.setString("original", on: pasteboard)
        let keyboard = FakeKeyboardEventSender()
        let service = try makeService(
            pasteboard: pasteboard,
            keyboardEventSender: keyboard,
            snapshotCapture: { _ in Self.incompleteSnapshot() }
        )

        await expectTextReplacementError(.incompleteClipboardSnapshot) {
            _ = try await service.toggleSelection()
        }

        #expect(pasteboard.string(forType: .string) == "original")
        #expect(keyboard.copyCallCount == 0)
        #expect(keyboard.pasteCallCount == 0)
    }

    @Test("copy event failure restores original clipboard")
    func copyEventFailureRestoresOriginalClipboard() async throws {
        let pasteboard = makePasteboard()
        Self.setString("original", on: pasteboard)
        let keyboard = FakeKeyboardEventSender(copyResult: false)
        let service = try makeService(pasteboard: pasteboard, keyboardEventSender: keyboard)

        await expectTextReplacementError(.copyEventFailed) {
            _ = try await service.toggleSelection()
        }

        #expect(pasteboard.string(forType: .string) == "original")
        #expect(keyboard.copyCallCount == 1)
        #expect(keyboard.pasteCallCount == 0)
    }

    @Test("paste event failure restores original clipboard")
    func pasteEventFailureRestoresOriginalClipboard() async throws {
        let pasteboard = makePasteboard()
        Self.setString("original", on: pasteboard)
        let keyboard = FakeKeyboardEventSender(pasteResult: false)
        keyboard.onCopy = {
            Self.setString("这句话是简体中文。", on: pasteboard)
        }
        let service = try makeService(pasteboard: pasteboard, keyboardEventSender: keyboard)

        await expectTextReplacementError(.pasteEventFailed) {
            _ = try await service.toggleSelection()
        }

        #expect(pasteboard.string(forType: .string) == "original")
        #expect(keyboard.copyCallCount == 1)
        #expect(keyboard.pasteCallCount == 1)
    }

    @Test("restore failure is surfaced")
    func restoreFailureIsSurfaced() async throws {
        let pasteboard = makePasteboard()
        Self.setString("original", on: pasteboard)
        let keyboard = FakeKeyboardEventSender()
        let service = try makeService(
            pasteboard: pasteboard,
            keyboardEventSender: keyboard,
            snapshotRestore: { _, _ in false }
        )

        await expectTextReplacementError(.clipboardRestoreFailed) {
            _ = try await service.toggleSelection()
        }
    }

    @Test("concurrent second toggle fails without sending keyboard events")
    func concurrentSecondToggleFailsWithoutSendingKeyboardEvents() async throws {
        let pasteboard = makePasteboard()
        Self.setString("original", on: pasteboard)
        let keyboard = FakeKeyboardEventSender()
        keyboard.onCopy = {
            Self.setString("这句话是简体中文。", on: pasteboard)
        }
        let service = try makeService(
            pasteboard: pasteboard,
            keyboardEventSender: keyboard,
            copyDelay: .milliseconds(80),
            pasteDelay: .milliseconds(1)
        )

        let firstToggle = Task { @MainActor in
            try await service.toggleSelection()
        }
        for _ in 0..<10 where keyboard.copyCallCount == 0 {
            await Task.yield()
        }
        #expect(keyboard.copyCallCount == 1)

        await expectTextReplacementError(.replacementAlreadyInProgress) {
            _ = try await service.toggleSelection()
        }

        _ = try await firstToggle.value
        #expect(keyboard.copyCallCount == 1)
        #expect(keyboard.pasteCallCount == 1)
        #expect(pasteboard.string(forType: .string) == "original")
    }

    private func makeService(
        pasteboard: NSPasteboard,
        keyboardEventSender: FakeKeyboardEventSender,
        permissionStatus: AccessibilityPermissionStatus = .trusted,
        copyDelay: Duration = .zero,
        pasteDelay: Duration = .zero,
        snapshotCapture: @escaping (NSPasteboard) -> PasteboardSnapshot = { PasteboardSnapshot(from: $0) },
        snapshotRestore: @escaping (PasteboardSnapshot, NSPasteboard) -> Bool = { $0.restore(to: $1) }
    ) throws -> TextReplacementService {
        try TextReplacementService(
            permissionManager: FakePermissionManager(permissionStatus: permissionStatus),
            keyboardEventSender: keyboardEventSender,
            pasteboard: pasteboard,
            copyDelay: copyDelay,
            pasteDelay: pasteDelay,
            snapshotCapture: snapshotCapture,
            snapshotRestore: snapshotRestore
        )
    }

    private func makePasteboard() -> NSPasteboard {
        NSPasteboard(name: NSPasteboard.Name("TextReplacementServiceTests.\(UUID().uuidString)"))
    }

    private static func setString(_ value: String, on pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }

    private static func incompleteSnapshot() -> PasteboardSnapshot {
        PasteboardSnapshot(
            items: [
                .init(contents: [.init(type: .string, data: nil)]),
            ]
        )
    }

    private func expectTextReplacementError(
        _ expectedError: TextReplacementError,
        performing operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            Issue.record("Expected \(expectedError), but operation succeeded.")
        } catch let error as TextReplacementError {
            #expect(error == expectedError)
        } catch {
            Issue.record("Expected \(expectedError), but caught \(error).")
        }
    }
}

private struct FakePermissionManager: AccessibilityPermissionChecking {
    let permissionStatus: AccessibilityPermissionStatus

    func status(prompt: Bool) -> AccessibilityPermissionStatus {
        permissionStatus
    }

    func openAccessibilitySettings() {}
}

@MainActor
private final class FakeKeyboardEventSender: KeyboardEventSending {
    private let copyResult: Bool
    private let pasteResult: Bool
    var copyCallCount = 0
    var pasteCallCount = 0
    var onCopy: (() -> Void)?

    init(copyResult: Bool = true, pasteResult: Bool = true) {
        self.copyResult = copyResult
        self.pasteResult = pasteResult
    }

    func sendCommandC() -> Bool {
        copyCallCount += 1
        onCopy?()
        return copyResult
    }

    func sendCommandV() -> Bool {
        pasteCallCount += 1
        return pasteResult
    }
}
