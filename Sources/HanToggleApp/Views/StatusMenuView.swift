import AppKit
import SwiftUI

struct StatusMenuView: View {
    @EnvironmentObject private var state: AppState

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

        Button("Settings") {
            appDelegate?.showSettingsWindow()
        }

        if !state.canCompleteSetup {
            Button("Setup HanToggle") {
                appDelegate?.showSetupWindow()
            }
        }

        Button("Quit") {
            NSApp.terminate(nil)
        }
    }

    @ViewBuilder
    private func recoveryButton(for action: RecoveryAction) -> some View {
        switch action {
        case .openAccessibilitySettings:
            Button("Open Accessibility Settings") {
                appDelegate?.openAccessibilitySettings()
            }
        case .openSettings:
            Button("Open Settings") {
                appDelegate?.showSettingsWindow()
            }
        case .openSetup:
            Button("Setup HanToggle") {
                appDelegate?.showSetupWindow()
            }
        case .changeShortcut:
            Button("Change Shortcut") {
                appDelegate?.showSettingsWindow()
            }
        }
    }

    private var statusIconName: String {
        state.lastError == nil ? "checkmark.circle" : "exclamationmark.triangle"
    }

    private var appDelegate: AppDelegate? {
        AppDelegate.shared ?? (NSApp.delegate as? AppDelegate)
    }
}
