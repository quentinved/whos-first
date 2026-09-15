import Foundation
import Combine
import FingrCore

@MainActor
final class AppContainer: ObservableObject {
    let app: AppModel
    let session: GameSession
    private let achievements = GameCenterAdapter()
    private static let testSuite = "com.quentinvedrenne.whosfirst.uitests"
    private static var didResetTestPreferences = false

    init() {
        let feedback = DeviceFeedbackAdapter()
        let app = AppModel(storage: LocalPreferencesAdapter(defaults: Self.makeDefaults()), feedback: feedback,
                           soundtrack: CountdownMusicAdapter(), achievements: achievements)
        self.app = app
        session = GameSession(prompt: .justForFun, app: app, random: SystemRandomSource(),
                              clock: SystemCountdownClock(), feedback: feedback)
    }

    /// Signs in to Game Center, then sends up whatever was earned while signed out. Never
    /// blocks play: a refusal or a missing network just leaves achievements unreported.
    func start() {
        // UI tests drive a throwaway preferences suite and must not meet Apple's sign-in sheet.
        guard !LaunchArguments.isUITesting else { return }
        achievements.authenticate { [weak self] in
            self?.app.reportAchievements()
        }
    }

    /// UI tests get their own suite, wiped once per process when asked, so they never
    /// touch the player's real settings.
    private static func makeDefaults() -> UserDefaults {
        guard LaunchArguments.isUITesting, let defaults = UserDefaults(suiteName: testSuite) else {
            return .standard
        }
        if LaunchArguments.resetsUIState, !didResetTestPreferences {
            defaults.removePersistentDomain(forName: testSuite)
            didResetTestPreferences = true
        }
        return defaults
    }
}
