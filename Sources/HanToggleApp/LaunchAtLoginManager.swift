import ServiceManagement

protocol LaunchAtLoginManaging {
    func setEnabled(_ enabled: Bool) throws
}

struct LaunchAtLoginManager: LaunchAtLoginManaging {
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
