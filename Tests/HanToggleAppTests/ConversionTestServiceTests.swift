import Testing
@testable import HanToggleApp

@Suite("ConversionTestService")
struct ConversionTestServiceTests {
    @Test("sample conversion passes with expected Traditional output")
    func sampleConversionPasses() {
        let service = ConversionTestService { text in
            #expect(text == ConversionTestService.sampleSource)
            return ConversionTestService.sampleExpected
        }

        let result = service.runSampleTest()

        #expect(result.source == "这句话是简体中文。")
        #expect(result.expected == "這句話是簡體中文。")
        #expect(result.actual == "這句話是簡體中文。")
        #expect(result.status == .passed)
        #expect(result.message == "Local conversion is working.")
    }

    @Test("sample conversion fails when output does not match expected text")
    func sampleConversionMismatchFails() {
        let service = ConversionTestService { _ in "这句话是简体中文。" }

        let result = service.runSampleTest()

        #expect(result.status == .failed("HanToggle converted the sample incorrectly."))
        #expect(result.actual == "这句话是简体中文。")
        #expect(result.message == "HanToggle converted the sample incorrectly.")
    }

    @Test("sample conversion fails when converter throws")
    func sampleConversionThrowingConverterFails() {
        let service = ConversionTestService { _ in
            throw ConversionTestServiceError.converterUnavailable
        }

        let result = service.runSampleTest()

        #expect(result.status == .failed("HanToggle could not start the Chinese text converter."))
        #expect(result.actual == nil)
        #expect(result.message == "HanToggle could not start the Chinese text converter.")
    }
}
