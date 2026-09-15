import Observation

@MainActor @Observable
public final class AppModel {
    public private(set) var preferences: Preferences
    @ObservationIgnored private let storage: any PreferencesPort
    @ObservationIgnored private let feedback: any FeedbackPort
    @ObservationIgnored private let soundtrack: any SoundtrackPort
    @ObservationIgnored private let achievements: any AchievementsPort

    public init(storage: any PreferencesPort, feedback: any FeedbackPort, soundtrack: any SoundtrackPort,
                achievements: any AchievementsPort) {
        self.storage = storage
        self.feedback = feedback
        self.soundtrack = soundtrack
        self.achievements = achievements
        preferences = storage.load().validated
    }

    /// Send the saved tally up again. Called once Game Center has a player, so progress
    /// earned while signed out is not lost.
    public func reportAchievements() {
        achievements.report(preferences.tally.progress)
    }

    public func selectTheme(_ theme: ThemeID) {
        update { $0.theme = theme }
        play(.selection)
    }

    public func setHaptics(_ enabled: Bool) {
        update { $0.hapticsEnabled = enabled }
        if enabled { play(.selection) }
    }

    public func setSound(_ enabled: Bool) {
        update { $0.soundEnabled = enabled }
        if enabled { soundtrack.playReveal() }
        else { soundtrack.stop() }
    }

    public func setCountdown(_ seconds: Int) {
        update { $0.countdownSeconds = Preferences.validCountdown(seconds) }
    }

    public func setWinnerCount(_ count: Int) {
        update { $0.winnerCount = Round.winnerCountRange.clamping(count) }
        play(.selection)
    }

    public func setGameMode(_ mode: GameMode) {
        update { $0.gameMode = mode }
        play(.selection)
    }

    public func setPlayerCount(_ count: Int?) {
        update { $0.playerCount = count }
        play(.selection)
    }

    /// One finished real round. Demos never reach here, so nothing can be earned by
    /// watching a practice round.
    public func recordRound(players: Int, mode: GameMode, prompt: DecisionPrompt) {
        let theme = preferences.theme
        update {
            $0.completedRounds += 1
            $0.tally.record(players: players, mode: mode, prompt: prompt, theme: theme)
        }
        achievements.report(preferences.tally.progress)
    }

    public func play(_ event: FeedbackEvent) {
        feedback.play(event, haptics: preferences.hapticsEnabled)
        if case .winner = event, preferences.soundEnabled { soundtrack.playReveal() }
    }

    public func startCountdownMusic() {
        if preferences.soundEnabled { soundtrack.startCountdown(seconds: preferences.countdownSeconds) }
    }

    public func stopMusic() {
        soundtrack.stop()
    }

    private func update(_ change: (inout Preferences) -> Void) {
        change(&preferences)
        preferences = preferences.validated
        storage.save(preferences)
    }
}
