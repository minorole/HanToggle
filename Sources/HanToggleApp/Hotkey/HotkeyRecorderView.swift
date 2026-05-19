import AppKit
import SwiftUI

struct HotkeyRecorderView: NSViewRepresentable {
    let onHotkeyCaptured: (GlobalHotkey) -> Void
    let onCancel: () -> Void

    init(
        onHotkeyCaptured: @escaping (GlobalHotkey) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.onHotkeyCaptured = onHotkeyCaptured
        self.onCancel = onCancel
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.startMonitoring()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.updateCaptureHandler(onHotkeyCaptured)
        context.coordinator.updateCancelHandler(onCancel)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stopMonitoring()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onHotkeyCaptured: onHotkeyCaptured, onCancel: onCancel)
    }

    final class Coordinator: NSObject {
        private var hotkeyCaptured: (GlobalHotkey) -> Void
        private var cancelled: () -> Void
        private var monitor: Any?

        init(
            onHotkeyCaptured: @escaping (GlobalHotkey) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.hotkeyCaptured = onHotkeyCaptured
            self.cancelled = onCancel
        }

        func updateCaptureHandler(_ onHotkeyCaptured: @escaping (GlobalHotkey) -> Void) {
            hotkeyCaptured = onHotkeyCaptured
        }

        func updateCancelHandler(_ onCancel: @escaping () -> Void) {
            cancelled = onCancel
        }

        func startMonitoring() {
            guard monitor == nil else {
                return
            }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else {
                    return event
                }

                if event.keyCode == 53 {
                    self.cancelled()
                    return nil
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
