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
            menuBarSection
            launchSection
            privacySection
        }
        .formStyle(.grouped)
        .padding(20)
    }

    private var setupSection: some View {
        Section("Setup") {
            LabeledContent("Status", value: state.setupStatusTitle)

            Text(state.setupPrimaryMessage)
                .foregroundStyle(.secondary)

            Button("Done") {
                _ = actions.completeSetup()
            }
            .disabled(!state.canCompleteSetup)
            .keyboardShortcut(.defaultAction)
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

            Button("Open Accessibility Settings") {
                actions.openAccessibilitySettings()
            }
        }
    }

    private var menuBarSection: some View {
        Section("Menu Bar") {
            Toggle("Show HanToggle in menu bar", isOn: showMenuBarItemBinding)

            if !state.hasActiveHotkey {
                Text("A working hotkey is required before hiding the menu-bar item.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var launchSection: some View {
        Section("Launch") {
            Toggle("Launch at login", isOn: launchAtLoginBinding)
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Text("Conversion happens locally. HanToggle does not log, store, or transmit selected text or clipboard contents.")
                .foregroundStyle(.secondary)
        }
    }

    private var showMenuBarItemBinding: Binding<Bool> {
        Binding(
            get: { state.showMenuBarItem },
            set: { actions.setShowMenuBarItem($0) }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { state.launchAtLogin },
            set: { _ = actions.setLaunchAtLogin($0) }
        )
    }
}
