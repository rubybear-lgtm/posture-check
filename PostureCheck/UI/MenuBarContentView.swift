import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Posture Check")
                            .font(.headline)
                        Text(statusSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    Text(statusTitle)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(statusBadgeColor))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next reminder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(nextReminderText)
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    }

                    Spacer()
                }
            }

            Divider()

            Toggle(
                "Enable reminders",
                isOn: Binding(
                    get: { appState.settings.isEnabled },
                    set: { appState.toggleReminders($0) }
                )
            )

            LabeledContent("Notifications", value: appState.permissionState.summary)
            LabeledContent("Schedule", value: compactScheduleSummary)

            if let statusMessage = appState.statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 8) {
                Button("Settings...") {
                    appState.openSettingsWindow()
                }
                .buttonStyle(.borderedProminent)

                Button("Send Reminder") {
                    Task {
                        await appState.sendTestReminder()
                    }
                }
                .disabled(!appState.permissionState.isAuthorized)
            }

            if !appState.permissionState.isAuthorized {
                Button(notificationActionTitle) {
                    if appState.permissionState == .denied {
                        appState.openNotificationSettings()
                    } else {
                        Task {
                            _ = await appState.requestNotificationPermission()
                        }
                    }
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 320)
    }

    private var nextReminderText: String {
        guard let nextReminderDate = appState.nextReminderDate else {
            return "Not scheduled"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: nextReminderDate)
    }

    private var statusTitle: String {
        if !appState.settings.isEnabled {
            return "Paused"
        }
        if !appState.permissionState.isAuthorized {
            return appState.permissionState == .denied ? "Blocked" : "Pending"
        }
        return appState.nextReminderDate == nil ? "Idle" : "Active"
    }

    private var statusSummary: String {
        if !appState.settings.isEnabled {
            return "Reminders are turned off."
        }
        if !appState.permissionState.isAuthorized {
            return "Notification access is needed before reminders can run."
        }
        return "Local reminders are scheduled from the menu bar."
    }

    private var compactScheduleSummary: String {
        if appState.settings.workingHoursEnabled {
            return "\(appState.settings.clampedIntervalMinutes) min, \(appState.settings.weekdaysOnly ? "weekdays" : "daily")"
        }
        return "\(appState.settings.clampedIntervalMinutes) min, all day"
    }

    private var notificationActionTitle: String {
        appState.permissionState == .denied ? "Open Notification Settings" : "Enable Notifications"
    }

    private var statusBadgeColor: Color {
        switch statusTitle {
        case "Active":
            return Color.green.opacity(0.14)
        case "Blocked", "Pending":
            return Color.orange.opacity(0.16)
        default:
            return Color.secondary.opacity(0.14)
        }
    }
}
