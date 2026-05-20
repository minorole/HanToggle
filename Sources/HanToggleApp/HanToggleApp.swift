import AppKit
import SwiftUI

@main
struct HanToggleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegateAdaptor
    @StateObject private var state = appState

    var body: some Scene {
        MenuBarExtra(isInserted: Binding(
            get: { state.showMenuBarItem },
            set: { state.updateShowMenuBarItem($0) }
        )) {
            StatusMenuView()
                .environmentObject(state)
                .environment(\.hanToggleActions, appDelegateAdaptor.actionsForViews)
        } label: {
            Label("HanToggle", systemImage: state.menuBarSystemImageName)
        }
    }
}
