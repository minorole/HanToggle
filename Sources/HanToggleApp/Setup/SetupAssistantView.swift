import AppKit
import SwiftUI

struct SetupAssistantView: View {
    @EnvironmentObject private var state: AppState
    @State private var isRecordingHotkey = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            Divider()
            permissionSection
            hotkeySection
            Divider()
            footer
        }
        .padding(24)
        .frame(width: 560)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Set up HanToggle")
                .font(.title2)
                .fontWeight(.semibold)

            Text("HanToggle runs from the menu bar after setup.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Use the menu-bar icon for Settings and Quit.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(state.setupStatusTitle)
                .font(.headline)

            Text(state.setupPrimaryMessage)
                .foregroundStyle(.secondary)
        }
    }

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accessibility")
                .font(.headline)

            LabeledContent("Status", value: state.accessibilityStatusLabel)

            if let lastError = state.lastError {
                Text(lastError)
                    .foregroundStyle(.red)
            }

            Text(accessibilityGuidanceText)
                .foregroundStyle(.secondary)

            Button("Open Accessibility Settings") {
                appDelegate?.openAccessibilitySettings()
            }
        }
    }

    private var hotkeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Keyboard Shortcut")
                .font(.headline)

            LabeledContent("Current shortcut", value: state.hotkeyDisplayName)

            if state.hasActiveHotkey {
                Text("Shortcut is ready.")
                    .foregroundStyle(.secondary)
            } else if let hotkeyRecordingError = state.hotkeyRecordingError {
                Text(hotkeyRecordingError)
                    .foregroundStyle(.red)
            }

            if isRecordingHotkey {
                HotkeyRecorderView(
                    onHotkeyCaptured: { hotkey in
                        if appDelegate?.setHotkey(hotkey) == true {
                            isRecordingHotkey = false
                        }
                    },
                    onCancel: {
                        isRecordingHotkey = false
                        state.setHotkeyRecordingError(nil)
                    }
                )
                .frame(width: 1, height: 1)

                HStack {
                    Text("Press new shortcut...")
                        .foregroundStyle(.secondary)

                    Button("Cancel") {
                        isRecordingHotkey = false
                        state.setHotkeyRecordingError(nil)
                    }

                    Button("Reset") {
                        if appDelegate?.resetHotkeyToDefault() == true {
                            isRecordingHotkey = false
                            state.setHotkeyRecordingError(nil)
                        }
                    }
                }
            } else {
                Button("Change Shortcut") {
                    isRecordingHotkey = true
                    state.setHotkeyRecordingError(nil)
                }
            }
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
