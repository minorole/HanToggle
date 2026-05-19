import AppKit
import SwiftUI

@main
struct HanToggleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegateAdaptor
    @StateObject private var state = appState

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView()
                .environmentObject(state)
        } label: {
            Label("HanToggle", systemImage: state.menuBarSystemImageName)
        }

        Settings {
            SettingsView()
                .environmentObject(state)
        }
    }
}
