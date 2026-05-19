import Testing
@testable import HanToggleApp

@Suite("HotkeyValidation")
struct HotkeyValidationTests {
    @Test("default hotkey is valid")
    func defaultHotkeyIsValid() {
        #expect(HotkeyValidator.validate(.default).isValid)
    }

    @Test("bare letter is rejected")
    func bareLetterRejected() {
        let result = HotkeyValidator.validate(GlobalHotkey(keyCode: 4, modifiers: []))

        #expect(result == .invalid("Use at least one modifier with the shortcut."))
    }

    @Test("shift-only letter is rejected")
    func shiftOnlyRejected() {
        let result = HotkeyValidator.validate(GlobalHotkey(keyCode: 4, modifiers: [.shift]))

        #expect(result == .invalid("Use Control, Option, or Command with the shortcut."))
    }

    @Test("escape return tab space and arrow keys are rejected")
    func reservedKeysRejected() {
        let reservedKeyCodes: [UInt32] = [53, 36, 48, 49, 123, 124, 125, 126]

        for keyCode in reservedKeyCodes {
            let result = HotkeyValidator.validate(GlobalHotkey(keyCode: keyCode, modifiers: [.control, .option]))
            #expect(result == .invalid("This key is reserved for system navigation or text input. Choose another shortcut."))
        }
    }

    @Test("function keys require a strong modifier")
    func functionKeysRequireStrongModifier() {
        let invalid = HotkeyValidator.validate(GlobalHotkey(keyCode: 122, modifiers: []))
        let valid = HotkeyValidator.validate(GlobalHotkey(keyCode: 122, modifiers: [.control]))

        #expect(invalid == .invalid("Use at least one modifier with the shortcut."))
        #expect(valid.isValid)
    }

    @Test("common modified letters are valid")
    func commonModifiedLettersAreValid() {
        #expect(HotkeyValidator.validate(GlobalHotkey(keyCode: 17, modifiers: [.command, .shift])).isValid)
        #expect(HotkeyValidator.validate(GlobalHotkey(keyCode: 11, modifiers: [.control, .option])).isValid)
    }
}
