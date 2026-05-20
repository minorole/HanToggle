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
        Self.keyDisplayNames[keyCode] ?? "Key \(keyCode)"
    }

    // macOS virtual key-code display names for common key codes.
    private static let keyDisplayNames: [UInt32: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
        38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
        45: "N", 46: "M", 47: ".", 50: "`", 65: ".", 67: "*", 69: "+",
        71: "Clear", 75: "/", 76: "Enter", 78: "-", 81: "=", 82: "0",
        83: "1", 84: "2", 85: "3", 86: "4", 87: "5", 88: "6",
        89: "7", 91: "8", 92: "9", 96: "F5", 97: "F6", 98: "F7",
        99: "F3", 100: "F8", 101: "F9", 103: "F11", 109: "F10",
        111: "F12", 118: "F4", 120: "F2", 122: "F1",
    ]
}

private extension GlobalHotkey.Modifier {
    static let displayOrder: [(value: GlobalHotkey.Modifier, name: String)] = [
        (.command, "Command"),
        (.control, "Control"),
        (.option, "Option"),
        (.shift, "Shift"),
    ]
}
