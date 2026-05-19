import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @State private var isRecordingHotkey = false

    var body: some View {
        Form {
            Section("General") {
                VStack(alignment: .leading, spacing: 8) {
                    if isRecordingHotkey {
                        Text("Press new shortcut...")
                        HotkeyRecorderView { hotkey in
                            if appDelegate?.setHotkey(hotkey) == true {
                                isRecordingHotkey = false
                            }
                        }
                        .frame(height: 1)

                        HStack {
                            Button("Cancel") {
                                isRecordingHotkey = false
                                state.setHotkeyRecordingError(nil)
                            }

                            Button("Reset") {
                                if appDelegate?.resetHotkeyToDefault() == true {
                                    isRecordingHotkey = false
                                }
                            }
                        }
                    } else {
                        HStack {
                            LabeledContent("Hotkey", value: state.hotkeyDisplayName)
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

            Section("Visibility") {
                Toggle("Show menu-bar status", isOn: showMenuBarStatusBinding)
            }

            Section("Launch") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
            }

            Section("Permissions") {
                LabeledContent("Accessibility", value: accessibilityStatus)

                HStack {
                    Button("Request Permission") {
                        appDelegate?.requestAccessibilityPermission()
                    }

                    Button("Open System Settings") {
                        appDelegate?.openAccessibilitySettings()
                    }
                }
            }

            Section("About") {
                LabeledContent("App", value: "HanToggle")
                Text("Conversion happens locally. HanToggle does not send selected text, clipboard contents, or settings to a server.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 460)
    }

    private var showMenuBarStatusBinding: Binding<Bool> {
        Binding(
            get: { state.showMenuBarStatus },
            set: { newValue in
                let settings = AppSettings()
                settings.showMenuBarStatus = newValue
                state.updateShowMenuBarStatus(newValue)
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

    private var accessibilityStatus: String {
        switch (state.isAccessibilityTrusted, state.canUseAccessibilityEvents) {
        case (true, true):
            "Allowed"
        case (true, false):
            "Restart needed"
        case (false, _):
            "Not allowed"
        }
    }

    private var appDelegate: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }
}
