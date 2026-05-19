import Foundation

struct GlobalHotkey: Equatable, RawRepresentable {
    struct Modifier: OptionSet, Equatable {
        let rawValue: UInt32

        static let command = Modifier(rawValue: 1 << 0)
        static let option = Modifier(rawValue: 1 << 1)
        static let control = Modifier(rawValue: 1 << 2)
        static let shift = Modifier(rawValue: 1 << 3)
    }

    static let `default` = GlobalHotkey(keyCode: 4, modifiers: [.control, .option])

    let keyCode: UInt32
    let modifiers: Modifier

    init(keyCode: UInt32, modifiers: Modifier) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(rawValue: String) {
        let parts = rawValue.split(separator: ":", omittingEmptySubsequences: false)

        guard parts.count == 2,
              let keyCode = UInt32(parts[0]),
              let modifierRawValue = UInt32(parts[1])
        else {
            return nil
        }

        self.keyCode = keyCode
        modifiers = Modifier(rawValue: modifierRawValue)
    }

    var rawValue: String {
        "\(keyCode):\(modifiers.rawValue)"
    }

    var displayName: String {
        let modifierNames = Modifier.displayOrder.compactMap { modifier -> String? in
            guard modifiers.contains(modifier.value) else {
                return nil
            }

            return modifier.name
        }

        return (modifierNames + [keyDisplayName]).joined(separator: "-")
    }

    private var keyDisplayName: String {
        switch keyCode {
        case 4:
            "H"
        case 11:
            "B"
        case 17:
            "T"
        default:
            "Key \(keyCode)"
        }
    }
}

private extension GlobalHotkey.Modifier {
    static let displayOrder: [(value: GlobalHotkey.Modifier, name: String)] = [
        (.command, "Command"),
        (.control, "Control"),
        (.option, "Option"),
        (.shift, "Shift"),
    ]
}
