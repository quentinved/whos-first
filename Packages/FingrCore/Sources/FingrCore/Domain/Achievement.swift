/// The Game Center achievements, and the running tally they are earned from.
///
/// Every achievement here is something the app can actually observe during a real round,
/// so none of them can be earned by a practice round or by changing a setting. The
/// identifiers are the ones registered in App Store Connect and must not change once a
/// version has shipped with them: Game Center keys a player's progress on the string.

public enum Achievement: String, CaseIterable, Sendable, Identifiable {
    case firstCall = "first.call"
    case regulars = "rounds.10"
    case houseRules = "rounds.50"
    case settledIt = "rounds.250"
    case pickSides = "teams.first"
    case fullHouse = "table.ten"
    case dareDevil = "dare.ten"
    case decorator = "themes.all"

    public var id: String { rawValue }

    /// Shown in Game Center, and seeded into App Store Connect from the same source.
    public var title: String {
        switch self {
        case .firstCall: "First Call"
        case .regulars: "Regulars"
        case .houseRules: "House Rules"
        case .settledIt: "Settled It"
        case .pickSides: "Pick Sides"
        case .fullHouse: "Full House"
        case .dareDevil: "Dare Devil"
        case .decorator: "Interior Decorator"
        }
    }

    public var unearnedDescription: String {
        switch self {
        case .firstCall: "Let the app settle something for the first time."
        case .regulars: "Finish 10 rounds."
        case .houseRules: "Finish 50 rounds."
        case .settledIt: "Finish 250 rounds."
        case .pickSides: "Split a group into two teams."
        case .fullHouse: "Get ten fingers on the screen at once."
        case .dareDevil: "Hand out 10 challenges."
        case .decorator: "Play a round in all six themes."
        }
    }

    public var earnedDescription: String {
        switch self {
        case .firstCall: "You let the app make the call."
        case .regulars: "Ten rounds settled."
        case .houseRules: "Fifty rounds settled. This is the house rule now."
        case .settledIt: "Two hundred and fifty rounds. Nobody argues any more."
        case .pickSides: "You split the room in two."
        case .fullHouse: "Ten fingers, one screen."
        case .dareDevil: "Ten challenges handed out."
        case .decorator: "You played a round in every single theme."
        }
    }

    /// How many of the thing the tally counts are needed. One means a single event does it.
    public var target: Int {
        switch self {
        case .firstCall: 1
        case .regulars: 10
        case .houseRules: 50
        case .settledIt: 250
        case .pickSides: 1
        case .fullHouse: 1
        case .dareDevil: 10
        case .decorator: ThemeID.allCases.count
        }
    }

    /// What Game Center awards. Apple caps an app at 1000 points across all achievements;
    /// these come to 290, which leaves room for more in a later version.
    public var points: Int {
        switch self {
        case .firstCall: 5
        case .regulars: 25
        case .houseRules: 50
        case .settledIt: 100
        case .pickSides: 10
        case .fullHouse: 50
        case .dareDevil: 25
        case .decorator: 25
        }
    }

    /// The name shown only inside App Store Connect, never to a player.
    public var referenceName: String { "\(title) (\(rawValue))" }

    /// Ordering for the Game Center list and for the seeding tool.
    public var displayOrder: Int {
        Achievement.allCases.firstIndex(of: self) ?? 0
    }
}

/// What a player has done across every real round, kept locally so progress survives a
/// launch where Game Center is unavailable and can be reported again later.
public struct AchievementTally: Codable, Equatable, Sendable {
    public var rounds: Int
    public var teamRounds: Int
    public var dareRounds: Int
    public var biggestTable: Int
    public var themesPlayed: Set<ThemeID>

    public init(rounds: Int = 0, teamRounds: Int = 0, dareRounds: Int = 0,
                biggestTable: Int = 0, themesPlayed: Set<ThemeID> = []) {
        self.rounds = max(0, rounds)
        self.teamRounds = max(0, teamRounds)
        self.dareRounds = max(0, dareRounds)
        self.biggestTable = max(0, biggestTable)
        self.themesPlayed = themesPlayed
    }

    /// Fold one finished round in. Only real rounds reach here; demos never do.
    public mutating func record(players: Int, mode: GameMode, prompt: DecisionPrompt, theme: ThemeID) {
        rounds += 1
        if mode == .teams { teamRounds += 1 }
        if mode == .picker, prompt == .tinyDare { dareRounds += 1 }
        biggestTable = max(biggestTable, players)
        themesPlayed.insert(theme)
    }

    /// How far along each achievement is, as the 0–100 Game Center works in.
    public var progress: [Achievement: Double] {
        var result: [Achievement: Double] = [:]
        for achievement in Achievement.allCases {
            result[achievement] = percent(for: achievement)
        }
        return result
    }

    private func count(for achievement: Achievement) -> Int {
        switch achievement {
        case .firstCall, .regulars, .houseRules, .settledIt: rounds
        case .pickSides: teamRounds
        case .fullHouse: biggestTable >= 10 ? 1 : 0
        case .dareDevil: dareRounds
        case .decorator: themesPlayed.count
        }
    }

    public func percent(for achievement: Achievement) -> Double {
        let done = Double(count(for: achievement))
        let target = Double(achievement.target)
        guard target > 0 else { return 0 }
        return min(100, done / target * 100)
    }
}
