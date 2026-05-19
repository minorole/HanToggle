import Foundation

enum HotkeyValidationResult: Equatable {
    case valid
    case invalid(String)

    var isValid: Bool {
        self == .valid
    }

    var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }

        return nil
    }
}

enum HotkeyValidator {
    private static let reservedKeyCodes: Set<UInt32> = [
        36,  // Return
        48,  // Tab
        49,  // Space
        53,  // Escape
        123, // Left arrow
        124, // Right arrow
        125, // Down arrow
        126, // Up arrow
    ]

    static func validate(_ hotkey: GlobalHotkey) -> HotkeyValidationResult {
        guard !hotkey.modifiers.isEmpty else {
            return .invalid("Use at least one modifier with the shortcut.")
        }

        guard hotkey.modifiers.contains(.control)
            || hotkey.modifiers.contains(.option)
            || hotkey.modifiers.contains(.command)
        else {
            return .invalid("Use Control, Option, or Command with the shortcut.")
        }

        guard !reservedKeyCodes.contains(hotkey.keyCode) else {
            return .invalid("This key is reserved for system navigation or text input. Choose another shortcut.")
        }

        return .valid
    }
}
