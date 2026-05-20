import AppKit

enum HanToggleActivationPolicy: Equatable {
    case accessory
    case regular

    var appKitPolicy: NSApplication.ActivationPolicy {
        switch self {
        case .accessory:
            return .accessory
        case .regular:
            return .regular
        }
    }
}

@MainActor
protocol ApplicationActivationPolicyManaging {
    func apply(_ policy: HanToggleActivationPolicy) throws
}

@MainActor
struct ApplicationActivationPolicyManager: ApplicationActivationPolicyManaging {
    func apply(_ policy: HanToggleActivationPolicy) throws {
        guard NSApplication.shared.setActivationPolicy(policy.appKitPolicy) else {
            throw ApplicationActivationPolicyError.updateFailed
        }
    }
}

enum ApplicationActivationPolicyError: Error {
    case updateFailed
}
