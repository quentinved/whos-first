import Foundation

public enum ThemeID: String, CaseIterable, Codable, Sendable, Identifiable {
    case afterHours, daydream, tangerine, poolside, roseClub, matcha
    public var id: String { rawValue }
}

public enum DecisionPrompt: String, CaseIterable, Sendable, Identifiable {
    case justForFun, goesFirst, paying, pickingDinner, onAux, makingCoffee, tinyDare
    public var id: String { rawValue }

    public var question: String {
        switch self {
        case .justForFun: "Who's the chosen one?"
        case .tinyDare: "Who's taking the challenge?"
        case .goesFirst: "Who goes first?"
        case .paying: "Who's getting the bill?"
        case .pickingDinner: "Who's picking dinner?"
        case .onAux: "Who's on the aux?"
        case .makingCoffee: "Who's making coffee?"
        }
    }

    public var result: String {
        switch self {
        case .justForFun: "You're the chosen one."
        case .tinyDare: "Your challenge."
        case .goesFirst: "You're up first."
        case .paying: "This one's on you."
        case .pickingDinner: "Dinner is your call."
        case .onAux: "The playlist is yours."
        case .makingCoffee: "Coffee duty is yours."
        }
    }

    public func result(winnerCount: Int) -> String {
        guard winnerCount > 1 else { return result }
        switch self {
        case .justForFun: return "You're the chosen ones."
        case .tinyDare: return "Your shared challenge."
        case .goesFirst: return "You're up first together."
        case .paying: return "You're sharing this one."
        case .pickingDinner: return "Dinner is your call, together."
        case .onAux: return "You're on playlist duty together."
        case .makingCoffee: return "You're the coffee crew."
        }
    }
}

public struct Preferences: Codable, Equatable, Sendable {
    public static let countdownChoices = [3, 5]

    public var theme: ThemeID
    public var hapticsEnabled: Bool
    public var soundEnabled: Bool
    public var countdownSeconds: Int
    public var completedRounds: Int
    public var winnerCount: Int
    public var gameMode: GameMode
    public var playerCount: Int?
    /// What has been achieved across real rounds. Kept here so it is saved by the same
    /// adapter as everything else, and so a round played without Game Center still counts.
    public var tally: AchievementTally

    public init(
        theme: ThemeID = .afterHours,
        hapticsEnabled: Bool = true,
        soundEnabled: Bool = true,
        countdownSeconds: Int = 3,
        completedRounds: Int = 0,
        winnerCount: Int = 1,
        gameMode: GameMode = .picker,
        playerCount: Int? = nil,
        tally: AchievementTally = AchievementTally()
    ) {
        self.theme = theme
        self.hapticsEnabled = hapticsEnabled
        self.soundEnabled = soundEnabled
        self.countdownSeconds = Self.validCountdown(countdownSeconds)
        self.completedRounds = max(0, completedRounds)
        self.winnerCount = Round.winnerCountRange.clamping(winnerCount)
        self.gameMode = gameMode
        self.playerCount = Round(winnerCount: self.winnerCount, mode: gameMode, playerCount: playerCount).playerCount
        self.tally = tally
    }

    public static func validCountdown(_ seconds: Int) -> Int {
        countdownChoices.contains(seconds) ? seconds : countdownChoices[0]
    }

    public var validated: Preferences {
        Preferences(theme: theme, hapticsEnabled: hapticsEnabled, soundEnabled: soundEnabled,
                    countdownSeconds: countdownSeconds, completedRounds: completedRounds,
                    winnerCount: winnerCount, gameMode: gameMode, playerCount: playerCount, tally: tally)
    }

    /// The minimum number of fingers a round built from these preferences waits for.
    public var minimumPlayers: Int {
        Round.minimumPlayers(for: gameMode, winnerCount: winnerCount)
    }

    private enum CodingKeys: String, CodingKey {
        case theme, hapticsEnabled, soundEnabled, countdownSeconds, completedRounds
        case winnerCount, gameMode, playerCount, tally
    }

    /// Existing installations keep their saved settings and default to one winner.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            theme: try values.decode(ThemeID.self, forKey: .theme),
            hapticsEnabled: try values.decode(Bool.self, forKey: .hapticsEnabled),
            soundEnabled: try values.decode(Bool.self, forKey: .soundEnabled),
            countdownSeconds: try values.decode(Int.self, forKey: .countdownSeconds),
            completedRounds: try values.decode(Int.self, forKey: .completedRounds),
            winnerCount: try values.decodeIfPresent(Int.self, forKey: .winnerCount) ?? 1,
            gameMode: try values.decodeIfPresent(GameMode.self, forKey: .gameMode) ?? .picker,
            playerCount: try values.decodeIfPresent(Int.self, forKey: .playerCount),
            tally: try values.decodeIfPresent(AchievementTally.self, forKey: .tally) ?? AchievementTally()
        )
    }
}

extension Round {
    /// A fresh board configured from the saved settings.
    public init(preferences: Preferences) {
        self.init(winnerCount: preferences.winnerCount, mode: preferences.gameMode,
                  playerCount: preferences.playerCount)
    }
}
