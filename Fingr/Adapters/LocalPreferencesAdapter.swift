import Foundation
import FingrCore

final class LocalPreferencesAdapter: PreferencesPort {
    private let defaults: UserDefaults
    // Preserve saved settings from before the Fingr rename.
    private let key = "whois.preferences.v1"
    private let darkDefaultKey = "fingr.afterHoursDefault.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Preferences {
        var preferences = defaults.data(forKey: key)
            .flatMap { try? JSONDecoder().decode(Preferences.self, from: $0) }?.validated ?? Preferences()
        // Adopt the new default once, including installations with a saved light palette.
        // Any theme the player chooses afterwards continues to persist normally.
        if !defaults.bool(forKey: darkDefaultKey) {
            preferences.theme = .afterHours
            save(preferences)
            defaults.set(true, forKey: darkDefaultKey)
        }
        return preferences
    }

    func save(_ preferences: Preferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: key)
    }
}
