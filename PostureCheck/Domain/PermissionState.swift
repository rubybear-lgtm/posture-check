import UserNotifications

enum PermissionState: String, Equatable, Sendable {
    case unknown
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral

    init(status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        case .provisional:
            self = .provisional
        case .ephemeral:
            self = .ephemeral
        @unknown default:
            self = .unknown
        }
    }

    var isAuthorized: Bool {
        self == .authorized || self == .provisional || self == .ephemeral
    }

    var summary: String {
        switch self {
        case .unknown:
            return "Checking…"
        case .notDetermined:
            return "Not enabled"
        case .denied:
            return "Blocked in System Settings"
        case .authorized:
            return "Enabled"
        case .provisional:
            return "Provisionally enabled"
        case .ephemeral:
            return "Enabled for this session"
        }
    }

    var statusLabel: String {
        summary
    }
}
