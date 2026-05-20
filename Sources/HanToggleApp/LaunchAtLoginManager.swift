import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
}

protocol LaunchAtLoginManaging {
    func status() -> LaunchAtLoginStatus
    func setEnabled(_ enabled: Bool) throws
}

extension LaunchAtLoginManaging {
    func status() -> LaunchAtLoginStatus {
        .disabled
    }
}

struct LaunchAtLoginManager: LaunchAtLoginManaging {
    func status() -> LaunchAtLoginStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        default:
            .disabled
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
