import Testing
@testable import HanToggleApp

@Suite("AppIssue")
struct AppIssueTests {
    @Test("accessibility issue maps to accessibility and setup recovery")
    func accessibilityIssueActions() {
        let issue = AppIssue.accessibilityRequired()

        #expect(issue.kind == .accessibilityRequired)
        #expect(issue.severity == .blocking)
        #expect(issue.recoveryActions == [.openAccessibilitySettings, .openSetup])
        #expect(issue.message == "Accessibility permission is required before HanToggle can convert selected text.")
    }

    @Test("known text replacement errors map to recoverable issue kinds")
    func textReplacementErrorMapping() {
        #expect(AppIssue(textReplacementError: .copyEventFailed).kind == .copyFailed)
        #expect(AppIssue(textReplacementError: .pasteEventFailed).kind == .pasteFailed)
        #expect(AppIssue(textReplacementError: .noSelectedChineseTextFoundOrUnchangedSelection).kind == .noConvertibleSelection)
        #expect(AppIssue(textReplacementError: .clipboardRestoreFailed).kind == .clipboardRestoreFailed)
        #expect(AppIssue(textReplacementError: .converterInitializationFailed).kind == .converterUnavailable)
        #expect(AppIssue(textReplacementError: .replacementAlreadyInProgress).kind == .replacementAlreadyInProgress)
    }

    @Test("clipboard restore failure is blocking and tells user to open settings")
    func clipboardRestoreFailureIsBlocking() {
        let issue = AppIssue(textReplacementError: .clipboardRestoreFailed)

        #expect(issue.severity == .blocking)
        #expect(issue.recoveryActions == [.openSettings])
        #expect(issue.hint == "Clipboard restore failed. Avoid copying new private data until you confirm the clipboard contents.")
    }

    @Test("paste failure gives TextEdit recovery hint")
    func pasteFailureHint() {
        let issue = AppIssue(textReplacementError: .pasteEventFailed)

        #expect(issue.recoveryActions == [.openSettings])
        #expect(issue.hint == "The current app may block simulated paste. Try TextEdit to confirm HanToggle is working.")
    }

    @Test("hotkey conflict maps to shortcut recovery")
    func hotkeyConflictIssue() {
        let issue = AppIssue.hotkeyConflict("This shortcut is already in use or reserved by macOS. Choose another shortcut.")

        #expect(issue.kind == .hotkeyConflict)
        #expect(issue.recoveryActions == [.changeShortcut])
        #expect(issue.message == "This shortcut is already in use or reserved by macOS. Choose another shortcut.")
    }
}
