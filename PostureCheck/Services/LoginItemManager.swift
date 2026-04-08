import Foundation
import ServiceManagement

enum LoginItemManagerError: LocalizedError {
    case unsupportedStatus

    var errorDescription: String? {
        switch self {
        case .unsupportedStatus:
            return "macOS returned an unsupported launch-at-login status."
        }
    }
}

struct LoginItemManager {
    func isEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
