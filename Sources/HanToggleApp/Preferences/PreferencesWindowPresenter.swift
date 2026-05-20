import AppKit
import SwiftUI

@MainActor
protocol PreferencesWindowPresenting {
    func showPreferencesWindow(actions: HanToggleActions)
    func closePreferencesWindow()
}

@MainActor
final class AppKitPreferencesWindowPresenter: PreferencesWindowPresenting {
    private let state: AppState
    private var window: NSWindow?

    init(state: AppState = .shared) {
        self.state = state
    }

    func showPreferencesWindow(actions: HanToggleActions) {
        let preferencesWindow = window ?? makePreferencesWindow(actions: actions)
        window = preferencesWindow

        if let controller = preferencesWindow.contentViewController as? NSHostingController<AnyView> {
            controller.rootView = AnyView(
                PreferencesView()
                .environmentObject(state)
                .environment(\.hanToggleActions, actions)
            )
        }

        preferencesWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func closePreferencesWindow() {
        window?.close()
    }

    private func makePreferencesWindow(actions: HanToggleActions) -> NSWindow {
        let view = AnyView(
            PreferencesView()
            .environmentObject(state)
            .environment(\.hanToggleActions, actions)
        )
        let controller = NSHostingController(rootView: view)
        let preferencesWindow = NSWindow(contentViewController: controller)

        preferencesWindow.title = "HanToggle Preferences"
        preferencesWindow.styleMask = [.titled, .closable, .miniaturizable]
        preferencesWindow.isReleasedWhenClosed = false
        preferencesWindow.setContentSize(NSSize(width: 600, height: 640))
        preferencesWindow.contentMinSize = NSSize(width: 540, height: 500)
        preferencesWindow.center()

        return preferencesWindow
    }
}
