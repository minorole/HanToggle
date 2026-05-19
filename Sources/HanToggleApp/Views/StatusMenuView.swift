import AppKit
import SwiftUI

struct StatusMenuView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        if state.showMenuBarItem {
            Label(state.statusMessage, systemImage: statusIconName)
        } else {
            Label("HanToggle", systemImage: "character.textbox")
        }

        Text("Hotkey: \(state.hotkeyDisplayName)")
            .foregroundStyle(.secondary)

        if let lastError = state.lastError {
            Divider()

            Text(lastError)

            if state.accessibilityStatus != .trusted {
                Button("Open Accessibility Settings") {
                    appDelegate?.openAccessibilitySettings()
                }
            }
        }

        Divider()

        Button("Settings") {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }

        Button("Quit") {
            NSApp.terminate(nil)
        }
    }

    private var statusIconName: String {
        state.lastError == nil ? "checkmark.circle" : "exclamationmark.triangle"
    }

    private var appDelegate: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }
}
