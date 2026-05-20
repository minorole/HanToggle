import AppKit
import Foundation

@MainActor
protocol URLOpening: AnyObject {
    func open(_ url: URL) -> Bool
}

@MainActor
final class WorkspaceURLOpener: URLOpening {
    func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}

@MainActor
protocol SupportEmailOpening: AnyObject {
    func openSupportEmail() -> Bool
}

@MainActor
final class SupportEmailOpener: SupportEmailOpening {
    private let urlOpener: any URLOpening

    init(urlOpener: any URLOpening = WorkspaceURLOpener()) {
        self.urlOpener = urlOpener
    }

    func openSupportEmail() -> Bool {
        urlOpener.open(SupportContact.emailURL)
    }
}
