import Testing
@testable import HanToggleApp

@MainActor
@Suite("Accessibility permission state")
struct AccessibilityPermissionStateTests {
    @Test("trusted accessibility status does not require a separate event tap probe")
    func trustedStatusDoesNotRequireEventTapProbe() {
        let manager = AccessibilityPermissionManager(trustCheck: { _ in true })

        #expect(manager.status(prompt: false) == .trusted)
    }

    @Test("not trusted state gives direct guidance")
    func notTrustedGuidance() {
        let state = AppState()

        state.updateAccessibility(.notTrusted)

        #expect(!state.canToggleSelection)
        #expect(state.statusMessage == "Accessibility Required")
        #expect(state.lastError == "Enable HanToggle in System Settings > Privacy & Security > Accessibility.")
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
