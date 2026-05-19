import Carbon
import Foundation

@MainActor
protocol HotkeyManaging: AnyObject {
    var onHotkey: (() -> Void)? { get set }
    var activeHotkey: GlobalHotkey? { get }
    func start(hotkey: GlobalHotkey) throws
    func testRegistration(hotkey: GlobalHotkey) throws
    func stop()
}

extension HotkeyManaging {
    var activeHotkey: GlobalHotkey? { nil }

    func testRegistration(hotkey: GlobalHotkey) throws {}
}

struct HotkeyRegistrationToken {
    fileprivate let hotkeyRef: OpaquePointer

    init(hotkeyRef: EventHotKeyRef) {
        self.hotkeyRef = hotkeyRef
    }

    init(rawPointer: OpaquePointer) {
        self.hotkeyRef = rawPointer
    }
}

protocol HotkeyRegistering {
    func register(hotkey: GlobalHotkey, options: UInt32, hotkeyID: EventHotKeyID) throws -> HotkeyRegistrationToken
    func unregister(_ token: HotkeyRegistrationToken) throws
}

enum HotkeyRegistrarError: LocalizedError {
    case registrationFailed(status: OSStatus)
    case unregistrationFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let status):
            "Could not register hotkey with Carbon. macOS returned status \(status)."
        case .unregistrationFailed(let status):
            "Could not unregister hotkey with Carbon. macOS returned status \(status)."
        }
    }
}

final class CarbonHotkeyRegistrar: HotkeyRegistering {
    func register(hotkey: GlobalHotkey, options: UInt32, hotkeyID: EventHotKeyID) throws -> HotkeyRegistrationToken {
        var hotkeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.carbonModifierFlags,
            hotkeyID,
            GetApplicationEventTarget(),
            options,
            &hotkeyRef
        )

        guard status == noErr, let hotkeyRef else {
            throw HotkeyRegistrarError.registrationFailed(status: status)
        }

        return HotkeyRegistrationToken(hotkeyRef: hotkeyRef)
    }

    func unregister(_ token: HotkeyRegistrationToken) throws {
        let status = UnregisterEventHotKey(token.hotkeyRef)
        guard status == noErr else {
            throw HotkeyRegistrarError.unregistrationFailed(status: status)
        }
    }
}

@MainActor
final class HotkeyManager: HotkeyManaging {
    var activeHotkey: GlobalHotkey?

    private var activeRegistration: HotkeyRegistration?
    var onHotkey: (() -> Void)?

    private var eventHandler: EventHandlerRef?
    private let registrar: HotkeyRegistering
    var isEventHandlerInstalledForTesting: Bool { eventHandler != nil }

    init(registrar: HotkeyRegistering = CarbonHotkeyRegistrar()) {
        self.registrar = registrar
    }

    deinit {
        MainActor.assumeIsolated {
            stop()
        }
    }

    func start(hotkey: GlobalHotkey) throws {
        if hotkey == activeHotkey {
            return
        }

        try installHandlerIfNeeded()
        let hadActiveRegistration = activeRegistration != nil

        let hotkeyID = EventHotKeyID(signature: HotkeyManager.hotkeySignature, id: 1)
        let candidate: HotkeyRegistration
        do {
            candidate = try register(hotkey: hotkey, hotkeyID: hotkeyID)
        } catch {
            if !hadActiveRegistration {
                removeEventHandlerIfNeeded()
            }
            throw error
        }

        let previousRegistration = activeRegistration

        do {
            if let previousRegistration {
                try registrar.unregister(previousRegistration.token)
            }
        } catch {
            guard let previousStatus = unregistrationStatus(from: error) else {
                throw error
            }
            do {
                try registrar.unregister(candidate.token)
            } catch {
                guard let cleanupStatus = unregistrationStatus(from: error) else {
                    throw error
                }
                throw HotkeyManagerError.hotkeyReplacementCleanupFailed(
                    hotkey: hotkey.displayName,
                    originalStatus: previousStatus,
                    cleanupStatus: cleanupStatus
                )
            }

            throw HotkeyManagerError.hotkeyReplacementFailed(
                hotkey: hotkey.displayName,
                status: previousStatus
            )
        }

        activeHotkey = hotkey
        self.activeRegistration = candidate
    }

    func testRegistration(hotkey: GlobalHotkey) throws {
        try installHandlerIfNeeded()
        let hadActiveRegistration = activeRegistration != nil
        let hotkeyID = EventHotKeyID(signature: HotkeyManager.hotkeySignature, id: 1)
        let candidate: HotkeyRegistration
        do {
            candidate = try register(hotkey: hotkey, hotkeyID: hotkeyID)
        } catch {
            if !hadActiveRegistration {
                removeEventHandlerIfNeeded()
            }
            throw error
        }
        try registrar.unregister(candidate.token)
    }

    func stop() {
        if let activeRegistration {
            // Cleanup is best effort during stop; if teardown fails, we still clear state
            // so the app does not continue to believe a hotkey is active.
            try? registrar.unregister(activeRegistration.token)
            self.activeRegistration = nil
            activeHotkey = nil
        }

        removeEventHandlerIfNeeded()
    }

    private func installHandlerIfNeeded() throws {
        guard eventHandler == nil else {
            return
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        var handlerRef: EventHandlerRef?
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            HotkeyManager.eventHandlerUPP,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )

        guard installStatus == noErr, let handlerRef else {
            throw HotkeyManagerError.eventHandlerInstallationFailed(status: installStatus)
        }

        eventHandler = handlerRef
    }

    private func removeEventHandlerIfNeeded() {
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private struct HotkeyRegistration {
        let token: HotkeyRegistrationToken
        let hotkey: GlobalHotkey
        let id: EventHotKeyID
    }

    private func register(
        hotkey: GlobalHotkey,
        hotkeyID: EventHotKeyID
    ) throws -> HotkeyRegistration {
        do {
            let token = try registrar.register(hotkey: hotkey, options: UInt32(kEventHotKeyExclusive), hotkeyID: hotkeyID)
            return HotkeyRegistration(token: token, hotkey: hotkey, id: hotkeyID)
        } catch {
            throw mapRegistrarError(error, hotkey: hotkey)
        }
    }

    private func mapRegistrarError(_ error: Error, hotkey: GlobalHotkey) -> Error {
        guard let registrarError = error as? HotkeyRegistrarError else {
            return error
        }

        switch registrarError {
        case .registrationFailed(let status), .unregistrationFailed(let status):
            return HotkeyManagerError.hotkeyRegistrationFailed(hotkey: hotkey.displayName, status: status)
        }
    }

    private func unregistrationStatus(from error: Error) -> OSStatus? {
        guard case let .unregistrationFailed(status) = error as? HotkeyRegistrarError else {
            return nil
        }

        return status
    }

    private func handlePressedHotkey(_ hotkeyID: EventHotKeyID) {
        guard let activeRegistration,
              hotkeyID.signature == activeRegistration.id.signature,
              hotkeyID.id == activeRegistration.id.id
        else { return }

        onHotkey?()
    }

    private static let hotkeySignature: OSType = 0x484E5447 // HNTG

    private static let eventHandlerUPP: EventHandlerUPP = { _, event, userData in
        guard let event,
              let userData
        else {
            return OSStatus(eventNotHandledErr)
        }

        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )

        guard status == noErr else {
            return status
        }

        let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        Task { @MainActor in
            manager.handlePressedHotkey(hotkeyID)
        }

        return noErr
    }
}

enum HotkeyManagerError: LocalizedError {
    case eventHandlerInstallationFailed(status: OSStatus)
    case hotkeyRegistrationFailed(hotkey: String, status: OSStatus)
    case hotkeyReplacementFailed(hotkey: String, status: OSStatus)
    case hotkeyReplacementCleanupFailed(hotkey: String, originalStatus: OSStatus, cleanupStatus: OSStatus)

    var errorDescription: String? {
        switch self {
        case .eventHandlerInstallationFailed(let status):
            "HanToggle could not install the global hotkey event handler. macOS returned status \(status)."
        case .hotkeyRegistrationFailed(let hotkey, let status):
            "HanToggle could not register the \(hotkey) global hotkey. It may already be used by another app. macOS returned status \(status)."
        case .hotkeyReplacementFailed(let hotkey, let status):
            "HanToggle could not replace the \(hotkey) global hotkey. It could not remove the previous registration (status \(status))."
        case .hotkeyReplacementCleanupFailed(let hotkey, let originalStatus, let cleanupStatus):
            "HanToggle could not replace the \(hotkey) global hotkey. Old hotkey unregistration status \(originalStatus), rollback cleanup status \(cleanupStatus)."
        }
    }
}

private extension GlobalHotkey {
    var carbonModifierFlags: UInt32 {
        var flags: UInt32 = 0

        if modifiers.contains(.command) {
            flags |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            flags |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            flags |= UInt32(controlKey)
        }
        if modifiers.contains(.shift) {
            flags |= UInt32(shiftKey)
        }

        return flags
    }
}
