import Foundation
import Testing
@testable import FingrCore

@Suite struct AchievementTests {
    @Test func aFreshTallyHasEarnedNothing() {
        let tally = AchievementTally()
        for achievement in Achievement.allCases {
            #expect(tally.percent(for: achievement) == 0)
        }
    }

    @Test func oneRoundEarnsTheFirstCallAndNothingElseOutright() {
        var tally = AchievementTally()
        tally.record(players: 3, mode: .picker, prompt: .justForFun, theme: .afterHours)
        #expect(tally.percent(for: .firstCall) == 100)
        #expect(tally.percent(for: .regulars) == 10)
        #expect(tally.percent(for: .pickSides) == 0)
        #expect(tally.percent(for: .fullHouse) == 0)
        #expect(tally.percent(for: .dareDevil) == 0)
    }

    @Test(arguments: [(10, Achievement.regulars), (50, .houseRules), (250, .settledIt)])
    func roundCountsCompleteTheirAchievement(target: Int, achievement: Achievement) {
        var tally = AchievementTally()
        for _ in 0 ..< target {
            tally.record(players: 2, mode: .picker, prompt: .justForFun, theme: .afterHours)
        }
        #expect(tally.percent(for: achievement) == 100)
    }

    @Test func progressNeverRunsPastOneHundred() {
        var tally = AchievementTally()
        for _ in 0 ..< 400 {
            tally.record(players: 2, mode: .picker, prompt: .justForFun, theme: .afterHours)
        }
        for achievement in Achievement.allCases {
            #expect(tally.percent(for: achievement) <= 100)
        }
        #expect(tally.percent(for: .settledIt) == 100)
    }

    @Test func onlyTeamRoundsCountTowardsPickSides() {
        var tally = AchievementTally()
        tally.record(players: 4, mode: .picker, prompt: .justForFun, theme: .afterHours)
        #expect(tally.percent(for: .pickSides) == 0)
        tally.record(players: 4, mode: .teams, prompt: .justForFun, theme: .afterHours)
        #expect(tally.percent(for: .pickSides) == 100)
        #expect(tally.teamRounds == 1)
    }

    @Test func onlyDareRoundsCountAndTeamsNeverDo() {
        var tally = AchievementTally()
        for _ in 0 ..< 10 {
            // Teams mode has no dare, so these must not count even with the dare prompt saved.
            tally.record(players: 4, mode: .teams, prompt: .tinyDare, theme: .afterHours)
        }
        #expect(tally.percent(for: .dareDevil) == 0)
        for _ in 0 ..< 10 {
            tally.record(players: 4, mode: .picker, prompt: .tinyDare, theme: .afterHours)
        }
        #expect(tally.percent(for: .dareDevil) == 100)
    }

    @Test func fullHouseNeedsTenFingersAndRemembersTheBiggestTable() {
        var tally = AchievementTally()
        tally.record(players: 9, mode: .picker, prompt: .justForFun, theme: .afterHours)
        #expect(tally.percent(for: .fullHouse) == 0)
        tally.record(players: 10, mode: .picker, prompt: .justForFun, theme: .afterHours)
        #expect(tally.percent(for: .fullHouse) == 100)
        // A smaller table afterwards cannot take it away.
        tally.record(players: 2, mode: .picker, prompt: .justForFun, theme: .afterHours)
        #expect(tally.biggestTable == 10)
        #expect(tally.percent(for: .fullHouse) == 100)
    }

    @Test func everyThemeIsNeededForTheDecorator() {
        var tally = AchievementTally()
        for theme in ThemeID.allCases.dropLast() {
            tally.record(players: 2, mode: .picker, prompt: .justForFun, theme: theme)
        }
        #expect(tally.percent(for: .decorator) < 100)
        tally.record(players: 2, mode: .picker, prompt: .justForFun, theme: ThemeID.allCases.last!)
        #expect(tally.percent(for: .decorator) == 100)
    }

    @Test func playingTheSameThemeTwiceDoesNotDoubleCount() {
        var tally = AchievementTally()
        tally.record(players: 2, mode: .picker, prompt: .justForFun, theme: .matcha)
        tally.record(players: 2, mode: .picker, prompt: .justForFun, theme: .matcha)
        #expect(tally.themesPlayed.count == 1)
    }

    @Test func identifiersAreUniqueAndStable() {
        let ids = Achievement.allCases.map(\.rawValue)
        #expect(Set(ids).count == ids.count)
        // Game Center keys progress on these strings; changing one silently resets players.
        #expect(ids.contains("first.call"))
        #expect(ids.contains("themes.all"))
    }

    @Test func aTallySurvivesBeingSavedAndLoaded() throws {
        var tally = AchievementTally()
        tally.record(players: 10, mode: .teams, prompt: .justForFun, theme: .poolside)
        let preferences = Preferences(tally: tally)
        let data = try JSONEncoder().encode(preferences)
        let restored = try JSONDecoder().decode(Preferences.self, from: data)
        #expect(restored.tally == tally)
        #expect(restored.tally.percent(for: .fullHouse) == 100)
    }

    @Test func settingsSavedBeforeAchievementsExistedStillLoad() throws {
        // A 1.0 install upgrading in place has no tally key at all.
        let json = """
        {"theme":"matcha","hapticsEnabled":true,"soundEnabled":true,"countdownSeconds":3,
         "completedRounds":12,"winnerCount":1,"gameMode":"picker"}
        """
        let restored = try JSONDecoder().decode(Preferences.self, from: Data(json.utf8))
        #expect(restored.completedRounds == 12)
        #expect(restored.tally == AchievementTally())
    }
}

@Suite struct AchievementCatalogueTests {
    @Test func pointsStayUnderApplesCap() {
        let total = Achievement.allCases.reduce(0) { $0 + $1.points }
        #expect(total <= 1000)
        #expect(total == 290)
    }

    @Test func everyAchievementIsDescribedBothWays() {
        for achievement in Achievement.allCases {
            #expect(!achievement.title.isEmpty)
            #expect(!achievement.unearnedDescription.isEmpty)
            #expect(!achievement.earnedDescription.isEmpty)
            #expect(achievement.target >= 1)
            #expect(achievement.points > 0)
        }
    }
}
