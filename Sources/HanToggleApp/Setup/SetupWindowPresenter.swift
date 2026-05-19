import AppKit
import SwiftUI

@MainActor
protocol SetupWindowPresenting {
    func showSetupWindow()
    func closeSetupWindow()
}

@MainActor
final class AppKitSetupWindowPresenter: SetupWindowPresenting {
    private let state: AppState
    private var window: NSWindow?

    init(state: AppState = .shared) {
        self.state = state
    }

    func showSetupWindow() {
        let setupWindow = window ?? makeSetupWindow()
        window = setupWindow

        setupWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func closeSetupWindow() {
        window?.close()
    }

    private func makeSetupWindow() -> NSWindow {
        let view = SetupAssistantView()
            .environmentObject(state)
        let controller = NSHostingController(rootView: view)
        let setupWindow = NSWindow(contentViewController: controller)

        setupWindow.title = "Set up HanToggle"
        setupWindow.styleMask = [.titled, .closable, .miniaturizable]
        setupWindow.isReleasedWhenClosed = false
        setupWindow.setContentSize(NSSize(width: 580, height: 560))
        setupWindow.contentMinSize = NSSize(width: 540, height: 500)
        setupWindow.center()

        return setupWindow
    }
}
