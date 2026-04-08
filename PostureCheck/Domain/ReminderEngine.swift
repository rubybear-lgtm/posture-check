import Foundation

enum ReminderEngine {
    static func upcomingReminders(
        from referenceDate: Date,
        settings: ReminderSettings,
        calendar: Calendar,
        horizonDays: Int,
        maxCount: Int
    ) -> [Date] {
        guard settings.isEnabled, horizonDays > 0, maxCount > 0 else {
            return []
        }

        guard settings.validationError == nil else {
            return []
        }

        let reference = referenceDate.addingTimeInterval(1)
        let startOfReferenceDay = calendar.startOfDay(for: reference)
        var results: [Date] = []

        for dayOffset in 0..<horizonDays where results.count < maxCount {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfReferenceDay) else {
                continue
            }

            if settings.weekdaysOnly, calendar.isDateInWeekend(day) {
                continue
            }

            let dayStart = calendar.startOfDay(for: day)
            let windowStartMinutes = settings.workingHoursEnabled ? settings.startMinutes : 0
            let windowEndMinutes = settings.workingHoursEnabled ? settings.endMinutes : 24 * 60

            guard let windowStart = calendar.date(byAdding: .minute, value: windowStartMinutes, to: dayStart),
                  let windowEnd = calendar.date(byAdding: .minute, value: windowEndMinutes, to: dayStart) else {
                continue
            }

            let effectiveStart = max(reference, windowStart)
            var candidate = align(effectiveStart, anchor: windowStart, intervalMinutes: settings.intervalMinutes)

            while candidate < windowEnd, results.count < maxCount {
                if candidate > referenceDate {
                    results.append(candidate)
                }

                candidate = candidate.addingTimeInterval(TimeInterval(settings.intervalMinutes * 60))
            }
        }

        return results
    }

    private static func align(_ date: Date, anchor: Date, intervalMinutes: Int) -> Date {
        let interval = TimeInterval(intervalMinutes * 60)
        let delta = max(0, date.timeIntervalSince(anchor))
        let steps = Int(ceil(delta / interval))
        return anchor.addingTimeInterval(Double(steps) * interval)
    }
}
