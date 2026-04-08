import Foundation
import Testing
@testable import PostureCheck

struct ReminderEngineTests {
    @Test
    func disabledScheduleReturnsNothing() {
        var settings = ReminderSettings.default
        settings.isEnabled = false

        let dates = ReminderEngine.upcomingReminders(
            from: date(2026, 4, 6, 8, 0),
            settings: settings,
            calendar: denverCalendar,
            horizonDays: 3,
            maxCount: 10
        )

        #expect(dates.isEmpty)
    }

    @Test
    func workingHoursAnchorScheduleToWindowStart() {
        let settings = ReminderSettings.default

        let dates = ReminderEngine.upcomingReminders(
            from: date(2026, 4, 6, 9, 13),
            settings: settings,
            calendar: denverCalendar,
            horizonDays: 1,
            maxCount: 5
        )

        #expect(times(for: dates) == ["10:00", "11:00", "12:00", "13:00", "14:00"])
    }

    @Test
    func weekendsAreSkippedWhenWeekdaysOnlyIsEnabled() {
        let settings = ReminderSettings.default

        let dates = ReminderEngine.upcomingReminders(
            from: date(2026, 4, 10, 16, 15),
            settings: settings,
            calendar: denverCalendar,
            horizonDays: 4,
            maxCount: 4
        )

        #expect(dates.count == 4)
        #expect(weekdaySymbols(for: dates) == ["Mon", "Mon", "Mon", "Mon"])
    }

    @Test
    func allDaySchedulesCarryAcrossMidnight() {
        var settings = ReminderSettings.default
        settings.workingHoursEnabled = false
        settings.intervalMinutes = 180

        let dates = ReminderEngine.upcomingReminders(
            from: date(2026, 4, 6, 22, 30),
            settings: settings,
            calendar: denverCalendar,
            horizonDays: 2,
            maxCount: 3
        )

        #expect(times(for: dates) == ["00:00", "03:00", "06:00"])
    }

    @Test
    func daylightSavingTransitionKeepsWallClockTimesStable() {
        let settings = ReminderSettings.default

        let dates = ReminderEngine.upcomingReminders(
            from: date(2026, 3, 6, 16, 30),
            settings: settings,
            calendar: denverCalendar,
            horizonDays: 5,
            maxCount: 8
        )

        #expect(times(for: Array(dates.prefix(3))) == ["09:00", "10:00", "11:00"])
        #expect(weekdaySymbols(for: Array(dates.prefix(3))) == ["Mon", "Mon", "Mon"])
    }

    private var denverCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Denver") ?? .current
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        let components = DateComponents(
            calendar: denverCalendar,
            timeZone: denverCalendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return denverCalendar.date(from: components) ?? .distantPast
    }

    private func times(for dates: [Date]) -> [String] {
        let formatter = DateFormatter()
        formatter.calendar = denverCalendar
        formatter.timeZone = denverCalendar.timeZone
        formatter.dateFormat = "HH:mm"
        return dates.map { formatter.string(from: $0) }
    }

    private func weekdaySymbols(for dates: [Date]) -> [String] {
        let formatter = DateFormatter()
        formatter.calendar = denverCalendar
        formatter.timeZone = denverCalendar.timeZone
        formatter.dateFormat = "EEE"
        return dates.map { formatter.string(from: $0) }
    }
}
