import Foundation

enum ReminderSettingsError: LocalizedError {
    case invalidInterval
    case invalidWorkingHours

    var errorDescription: String? {
        switch self {
        case .invalidInterval:
            return "Choose an interval between 15 minutes and 4 hours."
        case .invalidWorkingHours:
            return "Start time must be earlier than end time."
        }
    }
}

struct ReminderSettings: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 2
    static let minimumIntervalMinutes = 15
    static let maximumIntervalMinutes = 240

    var isEnabled: Bool
    var intervalMinutes: Int
    var workingHoursEnabled: Bool
    var startMinutes: Int
    var endMinutes: Int
    var weekdaysOnly: Bool
    var launchAtLogin: Bool
    var showMenuBarIcon: Bool
    var schemaVersion: Int

    static let defaultValue = ReminderSettings(
        isEnabled: true,
        intervalMinutes: 60,
        workingHoursEnabled: true,
        startMinutes: 9 * 60,
        endMinutes: 17 * 60,
        weekdaysOnly: true,
        launchAtLogin: false,
        showMenuBarIcon: true,
        schemaVersion: currentSchemaVersion
    )

    static let `default` = defaultValue

    enum CodingKeys: String, CodingKey {
        case isEnabled
        case intervalMinutes
        case workingHoursEnabled
        case startMinutes
        case endMinutes
        case weekdaysOnly
        case launchAtLogin
        case showMenuBarIcon
        case schemaVersion
    }

    var clampedIntervalMinutes: Int {
        min(max(intervalMinutes, Self.minimumIntervalMinutes), Self.maximumIntervalMinutes)
    }

    var startHour: Int {
        get { startMinutes / 60 }
        set { startMinutes = (newValue * 60) + startMinute }
    }

    var startMinute: Int {
        get { startMinutes % 60 }
        set { startMinutes = (startHour * 60) + newValue }
    }

    var endHour: Int {
        get { endMinutes / 60 }
        set { endMinutes = (newValue * 60) + endMinute }
    }

    var endMinute: Int {
        get { endMinutes % 60 }
        set { endMinutes = (endHour * 60) + newValue }
    }

    var startComponents: DateComponents {
        DateComponents(hour: startHour, minute: startMinute)
    }

    var endComponents: DateComponents {
        DateComponents(hour: endHour, minute: endMinute)
    }

    var hasValidTimeWindow: Bool {
        guard workingHoursEnabled else { return true }
        return startMinutes < endMinutes
    }

    var normalized: ReminderSettings {
        var copy = self
        copy.intervalMinutes = clampedIntervalMinutes
        copy.startMinutes = min(max(startMinutes, 0), 1_439)
        copy.endMinutes = min(max(endMinutes, 1), 1_440)
        copy.showMenuBarIcon = showMenuBarIcon
        copy.schemaVersion = Self.currentSchemaVersion
        return copy
    }

    var validationError: String? {
        do {
            try validate()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    var scheduleSummary: String {
        let interval = "Every \(clampedIntervalMinutes) minutes"
        let days = weekdaysOnly ? "weekdays only" : "every day"

        guard workingHoursEnabled else {
            return "\(interval), \(days), all day."
        }

        return "\(interval), \(days), between \(Self.format(minutes: startMinutes)) and \(Self.format(minutes: endMinutes))."
    }

    func validate() throws {
        guard (Self.minimumIntervalMinutes...Self.maximumIntervalMinutes).contains(intervalMinutes) else {
            throw ReminderSettingsError.invalidInterval
        }
        guard (0..<1_440).contains(startMinutes), (1...1_440).contains(endMinutes) else {
            throw ReminderSettingsError.invalidWorkingHours
        }
        if workingHoursEnabled && startMinutes >= endMinutes {
            throw ReminderSettingsError.invalidWorkingHours
        }
    }

    static func format(minutes: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        let calendar = Calendar.autoupdatingCurrent
        let startOfDay = calendar.startOfDay(for: .now)
        let date = calendar.date(byAdding: .minute, value: minutes, to: startOfDay) ?? startOfDay
        return formatter.string(from: date)
    }

    init(
        isEnabled: Bool,
        intervalMinutes: Int,
        workingHoursEnabled: Bool,
        startMinutes: Int,
        endMinutes: Int,
        weekdaysOnly: Bool,
        launchAtLogin: Bool,
        showMenuBarIcon: Bool,
        schemaVersion: Int
    ) {
        self.isEnabled = isEnabled
        self.intervalMinutes = intervalMinutes
        self.workingHoursEnabled = workingHoursEnabled
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.weekdaysOnly = weekdaysOnly
        self.launchAtLogin = launchAtLogin
        self.showMenuBarIcon = showMenuBarIcon
        self.schemaVersion = schemaVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            isEnabled: try container.decode(Bool.self, forKey: .isEnabled),
            intervalMinutes: try container.decode(Int.self, forKey: .intervalMinutes),
            workingHoursEnabled: try container.decode(Bool.self, forKey: .workingHoursEnabled),
            startMinutes: try container.decode(Int.self, forKey: .startMinutes),
            endMinutes: try container.decode(Int.self, forKey: .endMinutes),
            weekdaysOnly: try container.decode(Bool.self, forKey: .weekdaysOnly),
            launchAtLogin: try container.decode(Bool.self, forKey: .launchAtLogin),
            showMenuBarIcon: try container.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? true,
            schemaVersion: try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        )
    }
}
