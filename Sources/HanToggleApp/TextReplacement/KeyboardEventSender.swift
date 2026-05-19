import CoreGraphics

struct KeyboardEventSender {
    func sendCommandC() -> Bool {
        sendCommandKey(keyCode: 8)
    }

    func sendCommandV() -> Bool {
        sendCommandKey(keyCode: 9)
    }

    private func sendCommandKey(keyCode: CGKeyCode) -> Bool {
        guard let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: keyCode,
            keyDown: true
        ),
            let keyUp = CGEvent(
                keyboardEventSource: nil,
                virtualKey: keyCode,
                keyDown: false
            )
        else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        return true
    }
}
