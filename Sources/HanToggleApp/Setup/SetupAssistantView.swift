import AppKit
import SwiftUI

struct SetupAssistantView: View {
    @EnvironmentObject private var state: AppState
    @State private var isRecordingHotkey = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            Divider()
            accessibilityRow
            Divider()
            shortcutRow
            Divider()
            conversionTestRow
            Divider()
            footer
        }
        .padding(24)
        .frame(width: 580)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Set up HanToggle")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enable access, confirm the shortcut, and test local conversion.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var accessibilityRow: some View {
        SetupChecklistRow(
            title: "Accessibility",
            message: accessibilityGuidanceText,
            state: state.accessibilityStatus == .trusted ? .ready : .needsAction
        ) {
            if state.accessibilityStatus != .trusted {
                Button("Open Accessibility Settings") {
                    appDelegate?.openAccessibilitySettings()
                }
            }
        }
    }

    private var shortcutRow: some View {
        SetupChecklistRow(
            title: "Keyboard Shortcut",
            message: shortcutRowMessage,
            state: shortcutRowState
        ) {
            ShortcutRecorderControl(
                displayName: state.hotkeyDisplayName,
                errorMessage: state.hotkeyRecordingError,
                isRecording: $isRecordingHotkey,
                onHotkeyCaptured: { hotkey in
                    appDelegate?.setHotkey(hotkey) == true
                },
                onCancel: {
                    state.setHotkeyRecordingError(nil)
                },
                onReset: {
                    appDelegate?.resetHotkeyToDefault() == true
                }
            )
        }
    }

    private var conversionTestRow: some View {
        SetupChecklistRow(
            title: "Test Conversion",
            message: conversionTestMessage,
            state: conversionTestRowState
        ) {
            ConversionTestView(status: state.conversionTestStatus) {
                appDelegate?.runConversionTest()
            }
        }
    }

    private var shortcutRowMessage: String {
        if isRecordingHotkey {
            return "Press the shortcut you want to use."
        }

        if state.hasActiveHotkey {
            return "Current shortcut: \(state.hotkeyDisplayName)"
        }

        return state.hotkeyRecordingError ?? "Choose a keyboard shortcut before completing setup."
    }

    private var shortcutRowState: SetupChecklistRowState {
        if isRecordingHotkey {
            return .inProgress
        }

        return state.hasActiveHotkey ? .ready : .needsAction
    }

    private var conversionTestMessage: String {
        switch state.conversionTestStatus {
        case .notRun:
            "Confirm the local converter works before finishing setup."
        case .running:
            "Testing local conversion..."
        case .passed:
            "Local conversion is working."
        case .failed(let message):
            message
        }
    }

    private var conversionTestRowState: SetupChecklistRowState {
        switch state.conversionTestStatus {
        case .passed:
            .ready
        case .running:
            .inProgress
        case .notRun, .failed:
            .needsAction
        }
    }

    private var footer: some View {
        HStack {
            Button("Quit HanToggle") {
                NSApplication.shared.terminate(nil)
            }

            Spacer()

            Button("Done") {
                _ = appDelegate?.completeSetup()
            }
            .disabled(!state.canCompleteSetup)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var appDelegate: AppDelegate? {
        AppDelegate.shared ?? (NSApp.delegate as? AppDelegate)
    }

    private var accessibilityGuidanceText: String {
        switch state.accessibilityStatus {
        case .trusted:
            "Accessibility access is allowed. HanToggle can replace selected text in apps that support standard copy/paste events."
        case .notTrusted:
            "Enable Accessibility so HanToggle can use standard local copy/paste events to replace selected text."
        }
    }
}
