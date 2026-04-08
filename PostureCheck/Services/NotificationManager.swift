import Foundation
import UserNotifications

@MainActor
struct NotificationManager {
    static let postureReminderPrefix = "posture-check-reminder-"
    static let testNotificationIdentifier = "posture-check-test-notification"

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> PermissionState {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: PermissionState(status: settings.authorizationStatus))
            }
        }
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func replaceScheduledReminders(with dates: [Date], calendar: Calendar = .autoupdatingCurrent) async throws {
        await removeAllPendingRequests()

        for date in dates {
            let content = UNMutableNotificationContent()
            content.title = "Posture check"
            content.body = "Sit tall. Drop your shoulders. Unclench your jaw."
            content.sound = nil

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminderIdentifier(for: date),
                content: content,
                trigger: trigger
            )
            try await add(request)
        }
    }

    func removeAllPendingRequests() async {
        let reminderPrefix = Self.postureReminderPrefix
        let testIdentifier = Self.testNotificationIdentifier
        let identifiers: [String] = await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let matches = requests
                    .map(\.identifier)
                    .filter { $0.hasPrefix(reminderPrefix) || $0 == testIdentifier }
                continuation.resume(returning: matches)
            }
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func scheduleImmediateReminder(after delay: TimeInterval = 3) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Posture check"
        content.body = "Sit tall. Drop your shoulders. Unclench your jaw."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.testNotificationIdentifier,
            content: content,
            trigger: trigger
        )
        try await add(request)
    }

    private func reminderIdentifier(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return Self.postureReminderPrefix + formatter.string(from: date).replacingOccurrences(of: ":", with: "-")
    }

    private func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
