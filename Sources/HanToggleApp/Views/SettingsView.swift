import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        Form {
            Section("General") {
                LabeledContent("Hotkey", value: state.hotkeyDisplayName)

                Button("Reset to Control-Option-H") {
                    let settings = AppSettings()
                    settings.hotkey = .default
                    appDelegate?.applySettings()
                }
            }

            Section("Visibility") {
                Toggle("Show menu-bar status", isOn: showMenuBarStatusBinding)
            }

            Section("Launch") {
                LabeledContent("Launch at login", value: "Available after packaging")
                    .foregroundStyle(.secondary)
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
