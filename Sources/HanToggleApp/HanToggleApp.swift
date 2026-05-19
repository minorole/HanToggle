import AppKit
import SwiftUI

@main
struct HanToggleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = appState

    var body: some Scene {
        MenuBarExtra("HanToggle", systemImage: "character.textbox") {
            Text(state.statusMessage)

            if let lastError = state.lastError {
                Divider()
                Text(lastError)
            }

            Divider()

            Button("Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(state)
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        Form {
            Text("HanToggle settings will appear here.")
            Text(state.statusMessage)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 360)
    }
}
