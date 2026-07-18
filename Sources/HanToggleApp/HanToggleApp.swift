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
            if let menuBarIcon = NSImage.hanToggleMenuBarIcon {
                Image(nsImage: menuBarIcon)
                    .accessibilityLabel("HanToggle")
            } else {
                Label("HanToggle", systemImage: state.menuBarSystemImageName)
            }
        }
    }
}

private extension NSImage {
    static var hanToggleMenuBarIcon: NSImage? {
        let resourceURL = menuBarIconURL(in: .main)
            ?? Bundle(
                url: Bundle.main.bundleURL
                    .appendingPathComponent("HanToggle_HanToggleApp.bundle")
            ).flatMap(menuBarIconURL)

        guard let url = resourceURL,
            let image = NSImage(contentsOf: url)
        else {
            return nil
        }

        image.isTemplate = true
        image.size = NSSize(width: 24, height: 24)
        return image
    }

    private static func menuBarIconURL(in bundle: Bundle) -> URL? {
        bundle.url(
            forResource: "MenuBarIconTemplate",
            withExtension: "png"
        )
    }
}
