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
        let settings = await center.notificationSettings()
        return PermissionState(status: settings.authorizationStatus)
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
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
            try await center.add(request)
        }
    }

    func removeAllPendingRequests() async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.postureReminderPrefix) || $0 == Self.testNotificationIdentifier }
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
        try await center.add(request)
    }

    private func reminderIdentifier(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return Self.postureReminderPrefix + formatter.string(from: date).replacingOccurrences(of: ":", with: "-")
    }
}
