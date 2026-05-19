import Testing
import HanToggle
@testable import HanToggleApp

@MainActor
@Suite("AppState")
struct AppStateTests {
    @Test("update after toggle records direction and Traditional status")
    func updateAfterSimplifiedToTraditionalToggle() {
        let state = AppState()
        let result = ToggleResult(text: "測試", direction: .simplifiedToTraditional, changedCharacterCount: 2)

        state.updateAfterToggle(result)

        #expect(state.lastDirection == .simplifiedToTraditional)
        #expect(state.statusMessage == "Converted to Traditional")
        #expect(state.lastError == nil)
    }

    @Test("update after toggle records direction and Simplified status")
    func updateAfterTraditionalToSimplifiedToggle() {
        let state = AppState()
        let result = ToggleResult(text: "测试", direction: .traditionalToSimplified, changedCharacterCount: 2)

        state.updateAfterToggle(result)

        #expect(state.lastDirection == .traditionalToSimplified)
        #expect(state.statusMessage == "Converted to Simplified")
        #expect(state.lastError == nil)
    }

    @Test("unchanged toggle reports ready")
    func updateAfterUnchangedToggle() {
        let state = AppState()
        let result = ToggleResult(text: "abc", direction: .unchanged, changedCharacterCount: 0)

        state.updateAfterToggle(result)

        #expect(state.lastDirection == .unchanged)
        #expect(state.statusMessage == "Ready")
        #expect(state.lastError == nil)
    }
}
