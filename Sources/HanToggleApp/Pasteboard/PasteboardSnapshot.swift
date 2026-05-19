import AppKit
import Foundation

struct PasteboardSnapshot {
    struct Item {
        let contents: [Content]
    }

    struct Content {
        let type: NSPasteboard.PasteboardType
        let data: Data?
    }

    private let items: [Item]
    let isComplete: Bool

    init(from pasteboard: NSPasteboard = .general) {
        self = Self.capture(from: pasteboard)
    }

    static func capture(from pasteboard: NSPasteboard = .general) -> PasteboardSnapshot {
        let items = pasteboard.pasteboardItems?.map { pasteboardItem in
            Item(
                contents: pasteboardItem.types.map { type in
                    Content(type: type, data: pasteboardItem.data(forType: type))
                }
            )
        } ?? []

        return PasteboardSnapshot(items: items)
    }

    init(items: [Item]) {
        self.items = items
        isComplete = items.allSatisfy { item in
            item.contents.allSatisfy { $0.data != nil }
        }
    }

    @discardableResult
    func restore(to pasteboard: NSPasteboard = .general) -> Bool {
        guard !items.isEmpty else {
            pasteboard.clearContents()
            return true
        }

        guard isComplete else {
            return false
        }

        var restoredItems: [NSPasteboardItem] = []

        for item in items {
            let pasteboardItem = NSPasteboardItem()
            var restoredTypes = Set<NSPasteboard.PasteboardType>()

            for content in item.contents {
                guard let data = content.data,
                      !restoredTypes.contains(content.type),
                      pasteboardItem.setData(data, forType: content.type)
                else {
                    return false
                }

                restoredTypes.insert(content.type)
            }

            restoredItems.append(pasteboardItem)
        }

        pasteboard.clearContents()
        return pasteboard.writeObjects(restoredItems)
    }
}
