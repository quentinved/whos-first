public enum FeedbackEvent: Sendable {
    case joined, tick, winner, selection
}

@MainActor
public protocol FeedbackPort {
    func play(_ event: FeedbackEvent, haptics: Bool)
    func announce(_ message: String)
}

@MainActor
public protocol SoundtrackPort {
    func startCountdown(seconds: Int)
    func playReveal()
    func stop()
}

/// Where achievement progress goes. Reporting is best effort: a player who never signs in
/// to Game Center keeps playing, and their tally is still kept locally.
@MainActor
public protocol AchievementsPort {
    func report(_ progress: [Achievement: Double])
}

@MainActor
public protocol PreferencesPort {
    func load() -> Preferences
    func save(_ preferences: Preferences)
}

public protocol CountdownClock: Sendable {
    func waitOneSecond() async throws
}

public struct SystemCountdownClock: CountdownClock {
    public init() {}
    public func waitOneSecond() async throws {
        try await Task.sleep(for: .seconds(1))
    }
}

public struct SystemRandomSource: RandomSource {
    public init() {}
    public func index(upperBound: Int) -> Int {
        Int.random(in: 0..<upperBound)
    }
}
