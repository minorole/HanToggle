import Testing
@testable import HanToggleApp

@Suite("GlobalHotkey")
struct GlobalHotkeyTests {
    @Test("default hotkey is Control-Option-H")
    func defaultHotkey() {
        #expect(GlobalHotkey.default.keyCode == 4)
        #expect(GlobalHotkey.default.modifiers == [.control, .option])
        #expect(GlobalHotkey.default.displayName == "Control-Option-H")
    }

    @Test("raw value round trips key code and modifiers")
    func rawValueRoundTrip() throws {
        let hotkey = GlobalHotkey(keyCode: 11, modifiers: [.command, .shift])

        #expect(hotkey.rawValue == "11:9")

        let decoded = try #require(GlobalHotkey(rawValue: hotkey.rawValue))
        #expect(decoded == hotkey)
        #expect(decoded.displayName == "Command-Shift-B")
    }

    @Test("display name falls back to key code for unknown keys")
    func fallbackDisplayName() {
        let hotkey = GlobalHotkey(keyCode: 42, modifiers: [.control])

        #expect(hotkey.displayName == "Control-Key 42")
    }
}
