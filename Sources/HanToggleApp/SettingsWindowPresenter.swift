import AppKit
import SwiftUI

@MainActor
protocol SettingsWindowPresenting {
    func showSettingsWindow()
}

@MainActor
final class AppKitSettingsWindowPresenter: SettingsWindowPresenting {
    private let state: AppState
    private var window: NSWindow?

    init(state: AppState = .shared) {
        self.state = state
    }

    func showSettingsWindow() {
        let settingsWindow = window ?? makeSettingsWindow()
        window = settingsWindow

        settingsWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func makeSettingsWindow() -> NSWindow {
        let view = SettingsView()
            .environmentObject(state)
        let controller = NSHostingController(rootView: view)
        let settingsWindow = NSWindow(contentViewController: controller)

        settingsWindow.title = "HanToggle Settings"
        settingsWindow.styleMask = [.titled, .closable, .miniaturizable]
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.setContentSize(NSSize(width: 540, height: 560))
        settingsWindow.contentMinSize = NSSize(width: 520, height: 440)
        settingsWindow.center()

        return settingsWindow
    }
}
