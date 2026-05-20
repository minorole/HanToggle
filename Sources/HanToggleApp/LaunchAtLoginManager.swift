import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable(String)

    var isEnabled: Bool {
        self == .enabled
    }

    var isProblem: Bool {
        switch self {
        case .requiresApproval, .unavailable:
            true
        case .enabled, .disabled:
            false
        }
    }

    var message: String? {
        switch self {
        case .enabled, .disabled:
            nil
        case .requiresApproval:
            "macOS requires approval in System Settings before HanToggle can launch at login."
        case .unavailable(let message):
            message
        }
    }
}

protocol LaunchAtLoginManaging {
    func status() -> LaunchAtLoginStatus
    func setEnabled(_ enabled: Bool) throws
}

struct LaunchAtLoginManager: LaunchAtLoginManaging {
    func status() -> LaunchAtLoginStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            .enabled
        case .notRegistered:
            .disabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .unavailable("macOS could not find HanToggle's launch-at-login registration.")
        @unknown default:
            .unavailable("macOS returned an unknown Launch at Login status.")
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
