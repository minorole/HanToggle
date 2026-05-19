import AppKit
import Testing
@testable import HanToggleApp

@MainActor
@Suite("PasteboardSnapshot")
struct PasteboardSnapshotTests {
    @Test("restore brings back string pasteboard contents")
    func restoreStringPasteboard() throws {
        let pasteboard = makePasteboard()
        pasteboard.clearContents()
        #expect(pasteboard.setString("測試文字", forType: .string))

        let snapshot = PasteboardSnapshot(from: pasteboard)

        pasteboard.clearContents()
        #expect(pasteboard.setString("replacement", forType: .string))

        #expect(snapshot.isComplete)
        #expect(snapshot.restore(to: pasteboard))

        #expect(pasteboard.string(forType: .string) == "測試文字")
        #expect(pasteboard.pasteboardItems?.count == 1)
    }

    @Test("restore of empty snapshot clears pasteboard")
    func restoreEmptyPasteboard() {
        let source = makePasteboard()
        source.clearContents()
        let snapshot = PasteboardSnapshot(from: source)

        let target = makePasteboard()
        target.clearContents()
        #expect(target.setString("temporary", forType: .string))

        #expect(snapshot.isComplete)
        #expect(snapshot.restore(to: target))

        #expect(target.pasteboardItems?.isEmpty ?? true)
        #expect(target.string(forType: .string) == nil)
    }

    @Test("incomplete snapshot is detectable")
    func incompleteSnapshotIsDetectable() {
        let snapshot = PasteboardSnapshot(
            items: [
                .init(
                    contents: [
                        .init(type: .string, data: nil),
                    ]
                ),
            ]
        )

        #expect(!snapshot.isComplete)
    }

    @Test("failed restore leaves target pasteboard unchanged")
    func failedRestoreLeavesTargetPasteboardUnchanged() {
        let snapshot = PasteboardSnapshot(
            items: [
                .init(
                    contents: [
                        .init(type: .string, data: Data()),
                        .init(type: .string, data: Data()),
                    ]
                ),
            ]
        )
        let target = makePasteboard()
        target.clearContents()
        #expect(target.setString("existing", forType: .string))

        #expect(!snapshot.restore(to: target))

        #expect(target.string(forType: .string) == "existing")
    }

    private func makePasteboard() -> NSPasteboard {
        let name = NSPasteboard.Name("HanToggleAppTests.\(UUID().uuidString)")
        return NSPasteboard(name: name)
    }
}
