import Testing
@testable import HanToggle

@Test func leavesEmptyStringUnchanged() throws {
    let toggler = try ScriptToggler()

    let result = toggler.toggle("")

    #expect(result.direction == .unchanged)
    #expect(result.text == "")
    #expect(result.changedCharacterCount == 0)
}

@Test func leavesWhitespaceAndPunctuationUnchanged() throws {
    let toggler = try ScriptToggler()

    let result = toggler.toggle("  ...!?  ")

    #expect(result.direction == .unchanged)
    #expect(result.text == "  ...!?  ")
    #expect(result.changedCharacterCount == 0)
}

@Test func leavesEmojiUnchanged() throws {
    let toggler = try ScriptToggler()

    let result = toggler.toggle("🙂🚀")

    #expect(result.direction == .unchanged)
    #expect(result.text == "🙂🚀")
    #expect(result.changedCharacterCount == 0)
}

@Test func preservesEnglishPunctuationAndNumbersAroundChinese() throws {
    let toggler = try ScriptToggler()

    let result = toggler.toggle("v2: 鼠标, silicon, 100%.")

    #expect(result.direction == .simplifiedToTraditional)
    #expect(result.text == "v2: 滑鼠, silicon, 100%.")
}

@Test func togglesTraditionalInsideMixedApplicationText() throws {
    let toggler = try ScriptToggler()

    let result = toggler.toggle("Chrome says: 滑鼠裡面的矽二極體壞了。")

    #expect(result.direction == .traditionalToSimplified)
    #expect(result.text == "Chrome says: 鼠标里面的硅二极管坏了。")
}

@Test func repeatTogglePreservesMixedTextWrapper() throws {
    let toggler = try ScriptToggler()
    let original = "Issue #42: 这句话 is selected."

    let first = toggler.toggle(original)
    let second = toggler.toggle(first.text)

    #expect(first.direction == .simplifiedToTraditional)
    #expect(second.direction == .traditionalToSimplified)
    #expect(second.text == original)
}
