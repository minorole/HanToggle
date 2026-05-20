import SwiftUI

struct ConversionTestView: View {
    let status: ConversionTestStatus
    let runTest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Sample", value: ConversionTestService.sampleSource)

            switch status {
            case .notRun:
                Text("Run a local test conversion.")
                    .foregroundStyle(.secondary)
            case .running:
                ProgressView("Testing local conversion...")
                    .controlSize(.small)
            case .passed:
                LabeledContent("Result", value: ConversionTestService.sampleExpected)
                Text("Local conversion is working.")
                    .foregroundStyle(.secondary)
            case .failed(let message):
                Text(message)
                    .foregroundStyle(.red)
            }

            Button(buttonTitle) {
                runTest()
            }
            .disabled(status == .running)
        }
    }

    private var buttonTitle: String {
        switch status {
        case .notRun:
            "Test"
        case .running:
            "Testing..."
        case .passed:
            "Test Again"
        case .failed:
            "Try Again"
        }
    }
}
