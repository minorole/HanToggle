import AppKit
import SwiftUI

struct StatusMenuView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.hanToggleActions) private var actions

    var body: some View {
        if state.showMenuBarItem {
            Label(state.statusMessage, systemImage: statusIconName)
        } else {
            Label("HanToggle", systemImage: "character.textbox")
        }

        Text("Hotkey: \(state.hotkeyDisplayName)")
            .foregroundStyle(.secondary)

        if let issue = state.currentIssue {
            Divider()

            Text(issue.message)

            if let hint = issue.hint {
                Text(hint)
                    .foregroundStyle(.secondary)
            }

            ForEach(issue.recoveryActions, id: \.self) { action in
                recoveryButton(for: action)
            }
        } else if let lastError = state.lastError {
            Divider()

            Text(lastError)
        }

        Divider()

        Button(state.shouldShowSetupChecklist ? "Set Up HanToggle" : "Preferences") {
            actions.showPreferencesWindow()
        }

        Button("Quit") {
            actions.quit()
        }
    }

    @ViewBuilder
    private func recoveryButton(for action: RecoveryAction) -> some View {
        switch action {
        case .openAccessibilitySettings:
            Button("Open Accessibility Settings") {
                actions.openAccessibilitySettings()
            }
        case .openSettings:
            Button("Open Settings") {
                actions.showPreferencesWindow()
            }
        case .openSetup:
            Button("Setup HanToggle") {
                actions.showPreferencesWindow()
            }
        case .changeShortcut:
            Button("Change Shortcut") {
                actions.showPreferencesWindow()
            }
        }
    }

    private var statusIconName: String {
        state.lastError == nil ? "checkmark.circle" : "exclamationmark.triangle"
    }

}
