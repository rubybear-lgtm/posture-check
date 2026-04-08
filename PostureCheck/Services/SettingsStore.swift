import Foundation

struct SettingsStore {
    private let defaults: UserDefaults
    private let key = "posture-check.settings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ReminderSettings {
        guard let data = defaults.data(forKey: key) else {
            return .defaultValue
        }

        do {
            let decoded = try JSONDecoder().decode(ReminderSettings.self, from: data)
            return decoded.normalized
        } catch {
            return .defaultValue
        }
    }

    func save(_ settings: ReminderSettings) throws {
        let data = try JSONEncoder().encode(settings.normalized)
        defaults.set(data, forKey: key)
    }
}
