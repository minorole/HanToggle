import Foundation
import HanToggle

let input: String

if CommandLine.arguments.count > 1 {
    input = CommandLine.arguments.dropFirst().joined(separator: " ")
} else {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    input = String(data: data, encoding: .utf8) ?? ""
}

do {
    let toggler = try ScriptToggler()
    let result = toggler.toggle(input.trimmingCharacters(in: .newlines))
    print(result.text)
} catch {
    fputs("hantoggle: failed to initialize converter: \(error)\n", stderr)
    exit(1)
}
