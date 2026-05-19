import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var statusMessage = "Starting HanToggle..."
    @Published private(set) var lastError: String?

    func setReady() {
        statusMessage = "HanToggle is ready"
        lastError = nil
    }

    func setError(_ message: String) {
        statusMessage = "HanToggle needs attention"
        lastError = message
    }
}

@MainActor
let appState = AppState()
