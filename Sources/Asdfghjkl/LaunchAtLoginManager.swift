#if os(macOS)
import Foundation
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case unavailable
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

enum LaunchAtLoginError: LocalizedError, Equatable {
    case requiresBundledApp

    var errorDescription: String? {
        switch self {
        case .requiresBundledApp:
            return "Launch at Login is only available when arstdhneio is running from arstdhneio.app."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .requiresBundledApp:
            return "Build or install arstdhneio.app, launch that app bundle, then enable Launch at Login from the menu bar."
        }
    }
}

protocol LaunchAtLoginServicing {
    var status: LaunchAtLoginStatus { get }
    func register() throws
    func unregister() throws
    func openSystemSettings()
}

struct MainAppLaunchAtLoginService: LaunchAtLoginServicing {
    private let service = SMAppService.mainApp

    var status: LaunchAtLoginStatus {
        switch service.status {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        case .notRegistered:
            return .notRegistered
        @unknown default:
            return .notRegistered
        }
    }

    func register() throws {
        try service.register()
    }

    func unregister() throws {
        try service.unregister()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

final class LaunchAtLoginManager {
    private let service: LaunchAtLoginServicing
    private let isBundledAppProvider: () -> Bool

    init(
        service: LaunchAtLoginServicing = MainAppLaunchAtLoginService(),
        isBundledAppProvider: @escaping () -> Bool = { AppBundleSupport.isBundledApp() }
    ) {
        self.service = service
        self.isBundledAppProvider = isBundledAppProvider
    }

    var status: LaunchAtLoginStatus {
        guard isBundledAppProvider() else { return .unavailable }
        return service.status
    }

    var isAvailable: Bool {
        status != .unavailable
    }

    var isEnabled: Bool {
        status == .enabled
    }

    @discardableResult
    func toggle() throws -> LaunchAtLoginStatus {
        guard isBundledAppProvider() else {
            throw LaunchAtLoginError.requiresBundledApp
        }

        switch service.status {
        case .enabled:
            try service.unregister()
        case .requiresApproval:
            service.openSystemSettings()
            return .requiresApproval
        case .notRegistered, .notFound:
            try service.register()
        case .unavailable:
            throw LaunchAtLoginError.requiresBundledApp
        }

        let updatedStatus = service.status
        if updatedStatus == .requiresApproval {
            service.openSystemSettings()
        }

        return updatedStatus
    }
}
#endif
