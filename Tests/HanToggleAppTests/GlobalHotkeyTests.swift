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
        let hotkey = GlobalHotkey(keyCode: 999, modifiers: [.control])

        #expect(hotkey.displayName == "Control-Key 999")
    }

    @Test("known key names include common letters and function keys")
    func knownKeyNames() {
        #expect(GlobalHotkey(keyCode: 0, modifiers: [.command]).displayName == "Command-A")
        #expect(GlobalHotkey(keyCode: 8, modifiers: [.command]).displayName == "Command-C")
        #expect(GlobalHotkey(keyCode: 9, modifiers: [.command]).displayName == "Command-V")
        #expect(GlobalHotkey(keyCode: 122, modifiers: [.control]).displayName == "Control-F1")
    }
}
