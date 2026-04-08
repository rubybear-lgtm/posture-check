import Foundation
import Testing
@testable import PostureCheck

struct ReminderSettingsTests {
    @Test
    func settingsRoundTripThroughStore() throws {
        let suiteName = "PostureCheckTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = SettingsStore(defaults: defaults)
        let settings = ReminderSettings(
            isEnabled: true,
            intervalMinutes: 45,
            workingHoursEnabled: true,
            startMinutes: 510,
            endMinutes: 1_020,
            weekdaysOnly: false,
            launchAtLogin: true,
            showMenuBarIcon: false,
            schemaVersion: ReminderSettings.currentSchemaVersion
        )

        try store.save(settings)
        let loaded = store.load()

        #expect(loaded == settings)
    }

    @Test
    func invalidWorkingHoursFailValidation() {
        var settings = ReminderSettings.default
        settings.startMinutes = 18 * 60
        settings.endMinutes = 17 * 60

        #expect(throws: ReminderSettingsError.self) {
            try settings.validate()
        }
    }

    @Test
    func missingMenuBarVisibilityDefaultsToShown() throws {
        let legacyJSON = """
        {
          "isEnabled": true,
          "intervalMinutes": 60,
          "workingHoursEnabled": true,
          "startMinutes": 540,
          "endMinutes": 1020,
          "weekdaysOnly": true,
          "launchAtLogin": false,
          "schemaVersion": 1
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(ReminderSettings.self, from: legacyJSON)

        #expect(decoded.showMenuBarIcon == true)
    }
}
