import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @State private var isRecordingHotkey = false

    var body: some View {
        Form {
            hotkeySection
            permissionSection
            menuBarSection
            launchSection
            privacySection
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 520)
    }

    private var hotkeySection: some View {
        Section("Hotkey") {
            HStack {
                Text("Shortcut")

                Spacer()

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

                    Text("Press new shortcut...")
                        .foregroundStyle(.secondary)

                    Button("Cancel") {
                        isRecordingHotkey = false
                        state.setHotkeyRecordingError(nil)
                    }

                    Button("Reset") {
                        if appDelegate?.resetHotkeyToDefault() == true {
                            isRecordingHotkey = false
                        }
                        state.setHotkeyRecordingError(nil)
                    }
                } else {
                    Text(state.hotkeyDisplayName)
                        .foregroundStyle(.secondary)

                    Button("Change...") {
                        isRecordingHotkey = true
                        state.setHotkeyRecordingError(nil)
                    }
                }
            }

            if let hotkeyRecordingError = state.hotkeyRecordingError {
                Text(hotkeyRecordingError)
                    .foregroundStyle(.red)
            }
        }
    }

    private var permissionSection: some View {
        Section("Accessibility") {
            LabeledContent("Status", value: state.accessibilityStatusLabel)

            Text(state.accessibilityGuidance)
                .foregroundStyle(.secondary)

            Button("Open Accessibility Settings") {
                appDelegate?.openAccessibilitySettings()
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
            set: { newValue in
                let settings = AppSettings()
                let allowedValue = newValue || !state.hasActiveHotkey
                settings.showMenuBarItem = allowedValue
                state.updateShowMenuBarItem(allowedValue)
                appDelegate?.applySettings()
            }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { state.launchAtLogin },
            set: { newValue in
                _ = appDelegate?.setLaunchAtLogin(newValue)
            }
        )
    }

    private var appDelegate: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }
}
