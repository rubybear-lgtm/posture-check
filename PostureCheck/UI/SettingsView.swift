import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                summaryCard
                reminderCard
                availabilityCard
                systemCard

                if let statusMessage = appState.statusMessage {
                    card {
                        Text(statusMessage)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(24)
            .frame(width: 560, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Posture Check")
                .font(.system(size: 28, weight: .semibold))

            Text("A quiet menu bar reminder to sit tall on your schedule.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var summaryCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        statusBadge(title: appStatusTitle, tone: appStatusTone)

                        Text(appStatusDetail)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 16)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Next reminder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(nextReminderText)
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Current schedule")
                        .font(.subheadline.weight(.semibold))
                    Text(appState.settings.scheduleSummary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var reminderCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeading(
                    title: "Reminder",
                    subtitle: "Choose how often posture checks appear."
                )

                Toggle(
                    "Enable reminders",
                    isOn: Binding(
                        get: { appState.settings.isEnabled },
                        set: { appState.toggleReminders($0) }
                    )
                )
                .toggleStyle(.switch)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Picker(
                        "Interval",
                        selection: Binding(
                            get: { selectedIntervalTag },
                            set: { newValue in
                                if newValue == -1 {
                                    appState.setInterval(Int(appState.customIntervalMinutes.rounded()))
                                } else {
                                    appState.setInterval(newValue)
                                }
                            }
                        )
                    ) {
                        Text("30 minutes").tag(30)
                        Text("45 minutes").tag(45)
                        Text("60 minutes").tag(60)
                        Text("90 minutes").tag(90)
                        Text("Custom").tag(-1)
                    }
                    .pickerStyle(.menu)

                    if selectedIntervalTag == -1 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Custom interval")
                                Spacer()
                                Text("\(Int(appState.customIntervalMinutes.rounded())) min")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }

                            Slider(
                                value: Binding(
                                    get: { appState.customIntervalMinutes },
                                    set: { appState.updateCustomInterval(from: $0) }
                                ),
                                in: Double(ReminderSettings.minimumIntervalMinutes)...Double(ReminderSettings.maximumIntervalMinutes),
                                step: 15
                            )
                        }
                    }
                }
                .disabled(!appState.settings.isEnabled)
            }
        }
    }

    private var availabilityCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeading(
                    title: "Availability",
                    subtitle: "Limit reminders to working hours or weekdays."
                )

                Toggle(
                    "Only during these hours",
                    isOn: Binding(
                        get: { appState.settings.workingHoursEnabled },
                        set: { appState.setWorkingHoursEnabled($0) }
                    )
                )
                .toggleStyle(.switch)
                .disabled(!appState.settings.isEnabled)

                if appState.settings.workingHoursEnabled {
                    HStack(spacing: 12) {
                        DatePicker("Start", selection: startDateBinding, displayedComponents: .hourAndMinute)
                        DatePicker("End", selection: endDateBinding, displayedComponents: .hourAndMinute)
                    }
                    .disabled(!appState.settings.isEnabled)
                }

                Toggle(
                    "Weekdays only",
                    isOn: Binding(
                        get: { appState.settings.weekdaysOnly },
                        set: { appState.setWeekdaysOnly($0) }
                    )
                )
                .toggleStyle(.switch)
                .disabled(!appState.settings.isEnabled)

                if let validationError = appState.settings.validationError {
                    Text(validationError)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var systemCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeading(
                    title: "System",
                    subtitle: "Verify notification access and background behavior."
                )

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications")
                            .font(.subheadline.weight(.semibold))
                        Text(appState.permissionState.summary)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 16)

                    if appState.permissionState == .notDetermined {
                        Button("Enable Notifications") {
                            Task {
                                _ = await appState.requestNotificationPermission()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else if appState.permissionState == .denied {
                        Button("Open Notification Settings") {
                            appState.openNotificationSettings()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        statusBadge(title: "Ready", tone: .good)
                    }
                }

                HStack(spacing: 10) {
                    Button("Refresh Notification Status") {
                        Task {
                            await appState.refreshNotificationPermission()
                        }
                    }

                    Button("Send Reminder Now") {
                        Task {
                            await appState.sendTestReminder()
                        }
                    }
                    .disabled(!appState.permissionState.isAuthorized)
                }

                Divider()

                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { appState.loginItemEnabled },
                        set: { newValue in
                            Task {
                                await appState.setLaunchAtLogin(newValue)
                            }
                        }
                    )
                )
                .toggleStyle(.switch)

                Toggle(
                    "Show menu bar icon",
                    isOn: Binding(
                        get: { appState.settings.showMenuBarIcon },
                        set: { appState.setMenuBarIconVisibility($0) }
                    )
                )
                .toggleStyle(.switch)
            }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }

    private func sectionHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func statusBadge(title: String, tone: BadgeTone) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(tone.fillColor)
            )
            .foregroundStyle(tone.textColor)
    }

    private var startDateBinding: Binding<Date> {
        Binding(
            get: {
                makeDate(minutes: appState.settings.startMinutes)
            },
            set: { newDate in
                let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: newDate)
                appState.updateTimeWindow(
                    startHour: components.hour ?? appState.settings.startHour,
                    startMinute: components.minute ?? appState.settings.startMinute,
                    endHour: appState.settings.endHour,
                    endMinute: appState.settings.endMinute
                )
            }
        )
    }

    private var endDateBinding: Binding<Date> {
        Binding(
            get: {
                makeDate(minutes: appState.settings.endMinutes)
            },
            set: { newDate in
                let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: newDate)
                appState.updateTimeWindow(
                    startHour: appState.settings.startHour,
                    startMinute: appState.settings.startMinute,
                    endHour: components.hour ?? appState.settings.endHour,
                    endMinute: components.minute ?? appState.settings.endMinute
                )
            }
        )
    }

    private var selectedIntervalTag: Int {
        [30, 45, 60, 90].contains(appState.settings.intervalMinutes) ? appState.settings.intervalMinutes : -1
    }

    private var nextReminderText: String {
        guard let date = appState.nextReminderDate else { return "Not scheduled" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var appStatusTitle: String {
        if !appState.settings.isEnabled {
            return "Paused"
        }
        if !appState.permissionState.isAuthorized {
            return appState.permissionState == .denied ? "Blocked" : "Needs Access"
        }
        if appState.nextReminderDate == nil {
            return "Idle"
        }
        return "Active"
    }

    private var appStatusDetail: String {
        if !appState.settings.isEnabled {
            return "Reminders are turned off."
        }
        if !appState.permissionState.isAuthorized {
            return appState.permissionState == .denied
                ? "Notifications are blocked in System Settings."
                : "Enable notifications to start reminders."
        }
        if appState.nextReminderDate == nil {
            return "No reminder falls inside the current schedule."
        }
        return "The app is scheduling local reminders normally."
    }

    private var appStatusTone: BadgeTone {
        if !appState.settings.isEnabled {
            return .neutral
        }
        if !appState.permissionState.isAuthorized {
            return .warning
        }
        return appState.nextReminderDate == nil ? .neutral : .good
    }

    private func makeDate(minutes: Int) -> Date {
        let calendar = Calendar.autoupdatingCurrent
        let startOfDay = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .minute, value: minutes, to: startOfDay) ?? startOfDay
    }
}

private enum BadgeTone {
    case good
    case warning
    case neutral

    var fillColor: Color {
        switch self {
        case .good:
            return Color.green.opacity(0.14)
        case .warning:
            return Color.orange.opacity(0.16)
        case .neutral:
            return Color.secondary.opacity(0.14)
        }
    }

    var textColor: Color {
        switch self {
        case .good:
            return Color.green
        case .warning:
            return Color.orange
        case .neutral:
            return Color.primary
        }
    }
}
