import SwiftUI

enum SetupChecklistRowState {
    case ready
    case needsAction
    case inProgress

    var iconName: String {
        switch self {
        case .ready:
            "checkmark.circle.fill"
        case .needsAction:
            "exclamationmark.circle"
        case .inProgress:
            "record.circle"
        }
    }

    var iconColor: Color {
        switch self {
        case .ready:
            .green
        case .needsAction:
            .orange
        case .inProgress:
            .accentColor
        }
    }
}

struct SetupChecklistRow<Content: View>: View {
    let title: String
    let message: String
    let state: SetupChecklistRowState
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: state.iconName)
                .foregroundStyle(state.iconColor)
                .imageScale(.large)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .foregroundStyle(.secondary)

                content
            }
        }
        .padding(.vertical, 4)
    }
}
