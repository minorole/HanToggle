import Carbon
import Testing
@testable import HanToggleApp

@MainActor
@Suite("HotkeyManager")
struct HotkeyManagerTests {
    @Test("successful start registers exclusive hotkey")
    func successfulStartRegistersExclusiveHotkey() throws {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)

        try manager.start(hotkey: .default)

        #expect(registrar.registered.map(\.hotkey) == [.default])
        #expect(registrar.registered.first?.options == UInt32(kEventHotKeyExclusive))
        #expect(manager.activeHotkey == .default)
    }

    @Test("failed start leaves previous hotkey active")
    func failedStartKeepsPreviousHotkey() throws {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)
        try manager.start(hotkey: .default)

        registrar.nextRegistrationError = OSStatus(eventHotKeyExistsErr)
        let replacement = GlobalHotkey(keyCode: 17, modifiers: [.command, .shift])

        do {
            try manager.start(hotkey: replacement)
            Issue.record("Expected registration failure.")
        } catch HotkeyManagerError.hotkeyRegistrationFailed(let hotkey, let status) {
            #expect(hotkey == replacement.displayName)
            #expect(status == OSStatus(eventHotKeyExistsErr))
        }

        #expect(manager.activeHotkey == .default)
        #expect(registrar.unregistered.count == 0)
    }

    @Test("test registration unregisters probe and does not replace active hotkey")
    func testRegistrationDoesNotReplaceActiveHotkey() throws {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)
        try manager.start(hotkey: .default)
        let candidate = GlobalHotkey(keyCode: 11, modifiers: [.control, .option])

        try manager.testRegistration(hotkey: candidate)

        #expect(manager.activeHotkey == .default)
        #expect(registrar.registered.map(\.hotkey) == [.default, candidate])
        #expect(registrar.unregistered.count == 1)
    }
}

private struct FakeRegistration: Equatable {
    let hotkey: GlobalHotkey
    let options: UInt32
}

private final class FakeHotkeyRegistrar: HotkeyRegistering {
    private(set) var registered: [FakeRegistration] = []
    private(set) var unregistered: [HotkeyRegistrationToken] = []
    var nextRegistrationError: OSStatus = noErr

    func register(
        hotkey: GlobalHotkey,
        options: UInt32,
        hotkeyID: EventHotKeyID
    ) throws -> HotkeyRegistrationToken {
        let nextRegistrationError = nextRegistrationError
        self.nextRegistrationError = noErr

        if nextRegistrationError != noErr {
            throw HotkeyRegistrarError.registrationFailed(status: nextRegistrationError)
        }

        registered.append(FakeRegistration(hotkey: hotkey, options: options))
        return HotkeyRegistrationToken(rawPointer: OpaquePointer(bitPattern: registered.count)!)
    }

    func unregister(_ token: HotkeyRegistrationToken) throws {
        unregistered.append(token)
    }
}
