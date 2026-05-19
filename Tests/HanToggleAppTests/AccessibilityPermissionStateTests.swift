import Testing
@testable import HanToggleApp

@MainActor
@Suite("Accessibility permission state")
struct AccessibilityPermissionStateTests {
    @Test("not trusted state gives direct guidance")
    func notTrustedGuidance() {
        let state = AppState()

        state.updateAccessibility(.notTrusted)

        #expect(!state.canToggleSelection)
        #expect(state.statusMessage == "Accessibility Required")
        #expect(state.lastError == "Enable HanToggle in System Settings > Privacy & Security > Accessibility.")
    }

    @Test("trusted but events unavailable asks for restart")
    func trustedButEventsUnavailableGuidance() {
        let state = AppState()

        state.updateAccessibility(.trustedButEventsUnavailable)

        #expect(!state.canToggleSelection)
        #expect(state.statusMessage == "Restart Required")
        #expect(state.lastError == "Restart HanToggle after enabling Accessibility.")
    }

    @Test("trusted state is ready")
    func trustedStateReady() {
        let state = AppState()

        state.updateAccessibility(.trusted)

        #expect(state.canToggleSelection)
        #expect(state.statusMessage == "HanToggle is ready")
        #expect(state.lastError == nil)
    }
}
