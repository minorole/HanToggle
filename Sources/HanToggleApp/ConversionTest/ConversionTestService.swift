import Foundation
import HanToggle

enum ConversionTestStatus: Equatable {
    case notRun
    case running
    case passed
    case failed(String)
}

struct ConversionTestResult: Equatable {
    let source: String
    let expected: String
    let actual: String?
    let status: ConversionTestStatus

    var message: String {
        switch status {
        case .notRun:
            "Run a local test conversion."
        case .running:
            "Testing local conversion..."
        case .passed:
            "Local conversion is working."
        case .failed(let message):
            message
        }
    }
}

enum ConversionTestServiceError: LocalizedError, Equatable {
    case converterUnavailable

    var errorDescription: String? {
        switch self {
        case .converterUnavailable:
            "HanToggle could not start the Chinese text converter."
        }
    }
}

struct ConversionTestService {
    static let sampleSource = "这句话是简体中文。"
    static let sampleExpected = "這句話是簡體中文。"

    private let convert: (String) throws -> String

    init(convert: @escaping (String) throws -> String) {
        self.convert = convert
    }

    init() throws {
        do {
            let toggler = try ScriptToggler()
            self.convert = { toggler.toggle($0).text }
        } catch {
            throw ConversionTestServiceError.converterUnavailable
        }
    }

    func runSampleTest() -> ConversionTestResult {
        do {
            let actual = try convert(Self.sampleSource)
            guard actual == Self.sampleExpected else {
                return ConversionTestResult(
                    source: Self.sampleSource,
                    expected: Self.sampleExpected,
                    actual: actual,
                    status: .failed("HanToggle converted the sample incorrectly.")
                )
            }

            return ConversionTestResult(
                source: Self.sampleSource,
                expected: Self.sampleExpected,
                actual: actual,
                status: .passed
            )
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
                ?? "HanToggle could not start the Chinese text converter."
            return ConversionTestResult(
                source: Self.sampleSource,
                expected: Self.sampleExpected,
                actual: nil,
                status: .failed(message)
            )
        }
    }
}
