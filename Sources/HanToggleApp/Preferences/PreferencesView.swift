import AppKit
import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.hanToggleActions) private var actions
    @State private var isRecordingHotkey = false

    var body: some View {
        Form {
            setupSection
            hotkeySection
            conversionTestSection
            accessibilitySection
            visibilitySection
            launchSection
            privacySection
            supportSection
        }
        .formStyle(.grouped)
        .padding(20)
    }

    @ViewBuilder
    private var setupSection: some View {
        if state.shouldShowSetupChecklist {
            Section("Setup") {
                SetupChecklistRow(
                    title: "Accessibility",
                    message: accessibilitySetupMessage,
                    state: accessibilitySetupState
                ) {
                    if state.accessibilityStatus != .trusted {
                        Button("Open Accessibility Settings") {
                            actions.openAccessibilitySettings()
                        }
                    }
                }

                SetupChecklistRow(
                    title: "Keyboard Shortcut",
                    message: keyboardShortcutSetupMessage,
                    state: keyboardShortcutSetupState
                ) {
                    EmptyView()
                }

                SetupChecklistRow(
                    title: "Test Conversion",
                    message: conversionTestSetupMessage,
                    state: conversionTestSetupState
                ) {
                    EmptyView()
                }

                Button("Done") {
                    _ = actions.completeSetup()
                }
                .disabled(!state.canCompleteSetup)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var hotkeySection: some View {
        Section("Hotkey") {
            ShortcutRecorderControl(
                displayName: state.hotkeyDisplayName,
                errorMessage: state.hotkeyRecordingError,
                isRecording: $isRecordingHotkey,
                onHotkeyCaptured: actions.setHotkey,
                onCancel: {
                    state.setHotkeyRecordingError(nil)
                },
                onReset: actions.resetHotkeyToDefault
            )
        }
    }

    private var conversionTestSection: some View {
        Section("Test Conversion") {
            ConversionTestView(status: state.conversionTestStatus) {
                actions.runConversionTest()
            }
        }
    }

    private var accessibilitySection: some View {
        Section("Accessibility") {
            LabeledContent("Status", value: state.accessibilityStatusLabel)

            Text(state.accessibilityGuidance)
                .foregroundStyle(.secondary)

            if !state.shouldShowSetupChecklist {
                Button("Open Accessibility Settings") {
                    actions.openAccessibilitySettings()
                }
            }
        }
    }

    private var visibilitySection: some View {
        Section("Visibility") {
            Toggle("Show HanToggle in menu bar", isOn: showMenuBarItemBinding)
            Toggle("Show HanToggle in Dock", isOn: showDockIconBinding)

            if !state.hasActiveHotkey {
                Text("A working hotkey is required before hiding the menu-bar item.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var launchSection: some View {
        Section("Launch") {
            Toggle("Launch at login", isOn: launchAtLoginBinding)

            if let message = state.launchAtLoginStatus.message {
                Text(message)
                    .foregroundStyle(state.launchAtLoginStatus.isProblem ? .red : .secondary)
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Text("Conversion happens locally. HanToggle does not log, store, or transmit selected text or clipboard contents.")
                .foregroundStyle(.secondary)
        }
    }

    private var supportSection: some View {
        Section("Support") {
            Text("For feedback, feature requests, or support, email \(SupportContact.emailAddress).")
                .foregroundStyle(.secondary)

            Button("Email Support") {
                actions.openSupportEmail()
            }
        }
    }

    private var showMenuBarItemBinding: Binding<Bool> {
        Binding(
            get: { state.showMenuBarItem },
            set: { actions.setShowMenuBarItem($0) }
        )
    }

    private var showDockIconBinding: Binding<Bool> {
        Binding(
            get: { state.showDockIcon },
            set: { actions.setShowDockIcon($0) }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { state.launchAtLoginStatus.isEnabled },
            set: { _ = actions.setLaunchAtLogin($0) }
        )
    }

    private var accessibilitySetupState: SetupChecklistRowState {
        state.accessibilityStatus == .trusted ? .ready : .needsAction
    }

    private var accessibilitySetupMessage: String {
        switch state.accessibilityStatus {
        case .trusted:
            "Allowed"
        case .notTrusted:
            "Enable HanToggle in Accessibility settings."
        }
    }

    private var keyboardShortcutSetupState: SetupChecklistRowState {
        state.hasActiveHotkey ? .ready : .needsAction
    }

    private var keyboardShortcutSetupMessage: String {
        state.hasActiveHotkey ? state.hotkeyDisplayName : "Choose a keyboard shortcut."
    }

    private var conversionTestSetupState: SetupChecklistRowState {
        guard state.isTextReplacementServiceReady else {
            return .needsAction
        }

        switch state.conversionTestStatus {
        case .passed:
            return .ready
        case .running:
            return .inProgress
        case .notRun, .failed:
            return .needsAction
        }
    }

    private var conversionTestSetupMessage: String {
        guard state.isTextReplacementServiceReady else {
            return TextReplacementError.converterInitializationFailed.localizedDescription
        }

        switch state.conversionTestStatus {
        case .notRun:
            return "Run the local conversion test."
        case .running:
            return "Testing local conversion..."
        case .passed:
            return "Local conversion is working."
        case .failed(let message):
            return message
        }
    }
}
