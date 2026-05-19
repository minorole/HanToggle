import AppKit
import SwiftUI

struct HotkeyRecorderView: NSViewRepresentable {
    let onHotkeyCaptured: (GlobalHotkey) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.startMonitoring()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.updateCaptureHandler(onHotkeyCaptured)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stopMonitoring()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onHotkeyCaptured: onHotkeyCaptured)
    }

    final class Coordinator: NSObject {
        private var hotkeyCaptured: (GlobalHotkey) -> Void
        private var monitor: Any?

        init(onHotkeyCaptured: @escaping (GlobalHotkey) -> Void) {
            self.hotkeyCaptured = onHotkeyCaptured
        }

        func updateCaptureHandler(_ onHotkeyCaptured: @escaping (GlobalHotkey) -> Void) {
            hotkeyCaptured = onHotkeyCaptured
        }

        func startMonitoring() {
            guard monitor == nil else {
                return
            }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else {
                    return event
                }

                let hotkey = self.hotkey(from: event)
                self.hotkeyCaptured(hotkey)
                return nil
            }
        }

        func stopMonitoring() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }

            monitor = nil
        }

        private func hotkey(from event: NSEvent) -> GlobalHotkey {
            let filteredFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            var modifiers = GlobalHotkey.Modifier()

            if filteredFlags.contains(.command) {
                modifiers.insert(.command)
            }
            if filteredFlags.contains(.option) {
                modifiers.insert(.option)
            }
            if filteredFlags.contains(.control) {
                modifiers.insert(.control)
            }
            if filteredFlags.contains(.shift) {
                modifiers.insert(.shift)
            }

            return GlobalHotkey(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        }
    }
}
