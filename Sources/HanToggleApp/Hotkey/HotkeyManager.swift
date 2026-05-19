import Carbon
import Foundation

@MainActor
final class HotkeyManager {
    var onHotkey: (() -> Void)?

    private var eventHandler: EventHandlerRef?
    private var eventHotkey: EventHotKeyRef?
    private var registeredHotkeyID: EventHotKeyID?

    deinit {
        MainActor.assumeIsolated {
            stop()
        }
    }

    func start(hotkey: GlobalHotkey) throws {
        stop()

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

        let hotkeyID = EventHotKeyID(signature: HotkeyManager.hotkeySignature, id: 1)
        var hotkeyRef: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.carbonModifierFlags,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        guard registerStatus == noErr, let hotkeyRef else {
            stop()
            throw HotkeyManagerError.hotkeyRegistrationFailed(hotkey: hotkey.displayName, status: registerStatus)
        }

        eventHotkey = hotkeyRef
        registeredHotkeyID = hotkeyID
    }

    func stop() {
        if let eventHotkey {
            UnregisterEventHotKey(eventHotkey)
            self.eventHotkey = nil
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        registeredHotkeyID = nil
    }

    private func handlePressedHotkey(_ hotkeyID: EventHotKeyID) {
        guard hotkeyID.signature == registeredHotkeyID?.signature,
              hotkeyID.id == registeredHotkeyID?.id
        else {
            return
        }

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

    var errorDescription: String? {
        switch self {
        case .eventHandlerInstallationFailed(let status):
            "HanToggle could not install the global hotkey event handler. macOS returned status \(status)."
        case .hotkeyRegistrationFailed(let hotkey, let status):
            "HanToggle could not register the \(hotkey) global hotkey. It may already be used by another app. macOS returned status \(status)."
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
