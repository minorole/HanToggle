import Foundation
import OpenCC

public enum ToggleDirection: Equatable, Sendable {
    case simplifiedToTraditional
    case traditionalToSimplified
    case unchanged
}

public struct ToggleResult: Equatable, Sendable {
    public let text: String
    public let direction: ToggleDirection
    public let changedCharacterCount: Int

    public init(text: String, direction: ToggleDirection, changedCharacterCount: Int) {
        self.text = text
        self.direction = direction
        self.changedCharacterCount = changedCharacterCount
    }
}

public final class ScriptToggler {
    private static let converterInitializationLock = NSLock()

    private let traditionalConverter: ChineseConverter
    private let simplifiedConverter: ChineseConverter

    public init() throws {
        Self.converterInitializationLock.lock()
        defer { Self.converterInitializationLock.unlock() }

        traditionalConverter = try ChineseConverter(options: [.traditionalize, .twStandard, .twIdiom])
        simplifiedConverter = try ChineseConverter(options: [.simplify, .twStandard, .twIdiom])
    }

    public func toggle(_ input: String) -> ToggleResult {
        let traditional = traditionalConverter.convert(input)
        let simplified = simplifiedConverter.convert(input)

        let traditionalDistance = Self.editDistance(from: input, to: traditional)
        let simplifiedDistance = Self.editDistance(from: input, to: simplified)

        if traditionalDistance == 0 && simplifiedDistance == 0 {
            return ToggleResult(text: input, direction: .unchanged, changedCharacterCount: 0)
        }

        if traditionalDistance >= simplifiedDistance {
            return ToggleResult(
                text: traditional,
                direction: .simplifiedToTraditional,
                changedCharacterCount: traditionalDistance
            )
        }

        return ToggleResult(
            text: simplified,
            direction: .traditionalToSimplified,
            changedCharacterCount: simplifiedDistance
        )
    }

    private static func editDistance(from source: String, to target: String) -> Int {
        let sourceCharacters = Array(source)
        let targetCharacters = Array(target)

        if sourceCharacters.isEmpty { return targetCharacters.count }
        if targetCharacters.isEmpty { return sourceCharacters.count }

        var previousRow = Array(0...targetCharacters.count)
        var currentRow = Array(repeating: 0, count: targetCharacters.count + 1)

        for sourceIndex in 1...sourceCharacters.count {
            currentRow[0] = sourceIndex

            for targetIndex in 1...targetCharacters.count {
                let substitutionCost = sourceCharacters[sourceIndex - 1] == targetCharacters[targetIndex - 1] ? 0 : 1
                currentRow[targetIndex] = min(
                    previousRow[targetIndex] + 1,
                    currentRow[targetIndex - 1] + 1,
                    previousRow[targetIndex - 1] + substitutionCost
                )
            }

            swap(&previousRow, &currentRow)
        }

        return previousRow[targetCharacters.count]
    }
}
