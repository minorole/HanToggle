import SwiftUI

struct ShortcutRecorderControl: View {
    let displayName: String
    let errorMessage: String?
    @Binding var isRecording: Bool
    let onHotkeyCaptured: (GlobalHotkey) -> Bool
    let onCancel: () -> Void
    let onReset: () -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("Shortcut")

                Spacer()

                shortcutField

                if isRecording {
                    Button("Cancel") {
                        cancelRecording()
                    }

                    Button("Reset") {
                        if onReset() {
                            isRecording = false
                        }
                    }
                } else {
                    Button("Change") {
                        isRecording = true
                    }

                    Button("Reset") {
                        _ = onReset()
                    }
                }
            }

            if isRecording {
                HotkeyRecorderView(
                    onHotkeyCaptured: { hotkey in
                        if onHotkeyCaptured(hotkey) {
                            isRecording = false
                        }
                    },
                    onCancel: cancelRecording
                )
                .frame(width: 1, height: 1)

                Text("Press a shortcut using Control, Option, or Command.")
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    private var shortcutField: some View {
        Text(isRecording ? "Recording..." : displayName)
            .font(.body.monospaced())
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }

    private func cancelRecording() {
        isRecording = false
        onCancel()
    }
}
