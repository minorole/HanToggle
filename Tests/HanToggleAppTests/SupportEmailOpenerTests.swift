import Foundation
import Testing
@testable import HanToggleApp

@Suite("SupportEmailOpener")
struct SupportEmailOpenerTests {
    @Test("support email URL is a plain mailto link with no query")
    func supportEmailURLIsPlainMailtoLink() {
        #expect(SupportContact.emailAddress == "hi@minor-role.com")
        #expect(SupportContact.emailURL.absoluteString == "mailto:hi@minor-role.com")
        #expect(SupportContact.emailURL.query == nil)
    }

    @MainActor
    @Test("successful opener returns true and opens support email URL")
    func successfulOpenerReturnsTrueAndRecordsSupportEmailURL() {
        let urlOpener = RecordingURLOpener(result: true)
        let opener = SupportEmailOpener(urlOpener: urlOpener)

        let result = opener.openSupportEmail()

        #expect(result)
        #expect(urlOpener.openedURLs.map(\.absoluteString) == ["mailto:hi@minor-role.com"])
    }

    @MainActor
    @Test("failed opener returns false and opens support email URL")
    func failedOpenerReturnsFalseAndRecordsSupportEmailURL() {
        let urlOpener = RecordingURLOpener(result: false)
        let opener = SupportEmailOpener(urlOpener: urlOpener)

        let result = opener.openSupportEmail()

        #expect(!result)
        #expect(urlOpener.openedURLs.map(\.absoluteString) == ["mailto:hi@minor-role.com"])
    }
}

@MainActor
private final class RecordingURLOpener: URLOpening {
    private let result: Bool
    private(set) var openedURLs: [URL] = []

    init(result: Bool) {
        self.result = result
    }

    func open(_ url: URL) -> Bool {
        openedURLs.append(url)
        return result
    }
}
