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

    @Test("starting with active hotkey is idempotent")
    func idempotentStartSkipsReregistration() throws {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)
        try manager.start(hotkey: .default)
        let previousRegisteredCount = registrar.registered.count
        let previousUnregisterCount = registrar.unregistered.count

        try manager.start(hotkey: .default)

        #expect(manager.activeHotkey == .default)
        #expect(registrar.registered.count == previousRegisteredCount)
        #expect(registrar.unregistered.count == previousUnregisterCount)
    }

    @Test("old hotkey unregister failure triggers replacement failure and cleanup attempt")
    func oldUnregisterFailureRollsBackCandidate() throws {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)
        try manager.start(hotkey: .default)

        let replacement = GlobalHotkey(keyCode: 17, modifiers: [.command, .shift])
        registrar.nextUnregistrationErrors = [OSStatus(1)]

        do {
            try manager.start(hotkey: replacement)
            Issue.record("Expected old-hotkey-unregister failure.")
        } catch HotkeyManagerError.hotkeyReplacementFailed(let hotkey, let status) {
            #expect(hotkey == replacement.displayName)
            #expect(status == OSStatus(1))
        }

        #expect(manager.activeHotkey == .default)
        #expect(registrar.unregistered.count == 2)
        #expect(registrar.registered.map(\.hotkey) == [.default, replacement])
    }

    @Test("old hotkey unregister failure with candidate cleanup failure surfaces cleanup error")
    func oldUnregisterFailureWithCleanupFailureReturnsExplicitError() throws {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)
        try manager.start(hotkey: .default)

        let replacement = GlobalHotkey(keyCode: 17, modifiers: [.command, .shift])
        registrar.nextUnregistrationErrors = [OSStatus(1), OSStatus(2)]

        do {
            try manager.start(hotkey: replacement)
            Issue.record("Expected cleanup failure during hotkey replacement.")
        } catch HotkeyManagerError.hotkeyReplacementCleanupFailed(let hotkey, let originalStatus, let cleanupStatus) {
            #expect(hotkey == replacement.displayName)
            #expect(originalStatus == OSStatus(1))
            #expect(cleanupStatus == OSStatus(2))
        }

        #expect(manager.activeHotkey == .default)
        #expect(registrar.unregistered.count == 2)
    }

    @Test("failed start removes newly installed event handler when no active hotkey exists")
    func failedStartRemovesHandlerWhenNoActiveHotkeyExists() throws {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)
        registrar.nextRegistrationError = OSStatus(eventHotKeyExistsErr)

        do {
            try manager.start(hotkey: .default)
            Issue.record("Expected registration failure.")
        } catch HotkeyManagerError.hotkeyRegistrationFailed(let hotkey, let status) {
            #expect(hotkey == GlobalHotkey.default.displayName)
            #expect(status == OSStatus(eventHotKeyExistsErr))
        }

        #expect(manager.activeHotkey == nil)
        #expect(manager.isEventHandlerInstalledForTesting == false)
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

    @Test("failed test registration removes handler when no active hotkey exists")
    func failedTestRegistrationRemovesHandlerWhenNoActiveHotkeyExists() throws {
        let registrar = FakeHotkeyRegistrar()
        let manager = HotkeyManager(registrar: registrar)
        registrar.nextRegistrationError = OSStatus(eventHotKeyExistsErr)

        do {
            try manager.testRegistration(hotkey: .default)
            Issue.record("Expected registration failure.")
        } catch HotkeyManagerError.hotkeyRegistrationFailed(let hotkey, let status) {
            #expect(hotkey == GlobalHotkey.default.displayName)
            #expect(status == OSStatus(eventHotKeyExistsErr))
        }

        #expect(manager.activeHotkey == nil)
        #expect(manager.isEventHandlerInstalledForTesting == false)
    }
}

private struct FakeRegistration {
    let hotkey: GlobalHotkey
    let options: UInt32
    let token: HotkeyRegistrationToken
}

private final class FakeHotkeyRegistrar: HotkeyRegistering {
    private(set) var registered: [FakeRegistration] = []
    private(set) var unregistered: [HotkeyRegistrationToken] = []
    var nextRegistrationError: OSStatus = noErr
    var nextUnregistrationErrors: [OSStatus] = []

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

        let token = HotkeyRegistrationToken(rawPointer: OpaquePointer(bitPattern: registered.count + 1)!)
        registered.append(FakeRegistration(hotkey: hotkey, options: options, token: token))
        return token
    }

    func unregister(_ token: HotkeyRegistrationToken) throws {
        unregistered.append(token)
        let nextStatus = nextUnregistrationErrors.isEmpty ? noErr : nextUnregistrationErrors.removeFirst()

        if nextStatus != noErr {
            throw HotkeyRegistrarError.unregistrationFailed(status: nextStatus)
        }
    }
}
