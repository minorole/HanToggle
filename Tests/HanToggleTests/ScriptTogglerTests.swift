import Testing
@testable import HanToggle

@Test func convertsSimplifiedChineseToTraditionalChinese() throws {
    let toggler = try ScriptToggler()

    let result = toggler.toggle("鼠标里面的硅二极管坏了。")

    #expect(result.direction == .simplifiedToTraditional)
    #expect(result.text == "滑鼠裡面的矽二極體壞了。")
}

@Test func convertsTraditionalChineseBackToSimplifiedChinese() throws {
    let toggler = try ScriptToggler()

    let result = toggler.toggle("滑鼠裡面的矽二極體壞了。")

    #expect(result.direction == .traditionalToSimplified)
    #expect(result.text == "鼠标里面的硅二极管坏了。")
}

@Test func pressingAgainReturnsToOriginalScript() throws {
    let toggler = try ScriptToggler()
    let original = "这句话是简体中文。"

    let first = toggler.toggle(original)
    let second = toggler.toggle(first.text)

    #expect(first.direction == .simplifiedToTraditional)
    #expect(second.direction == .traditionalToSimplified)
    #expect(second.text == original)
}

@Test func leavesNonChineseTextUnchanged() throws {
    let toggler = try ScriptToggler()

    let result = toggler.toggle("Open the settings menu.")

    #expect(result.direction == .unchanged)
    #expect(result.text == "Open the settings menu.")
}

@Test func preservesMixedTextAroundChinese() throws {
    let toggler = try ScriptToggler()

    let result = toggler.toggle("Convert: 这句话 is selected.")

    #expect(result.direction == .simplifiedToTraditional)
    #expect(result.text == "Convert: 這句話 is selected.")
}
