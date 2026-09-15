import Testing
@testable import FingrCore

struct FixedRandom: RandomSource {
    let value: Int
    func index(upperBound: Int) -> Int { value }
}

struct RoundTests {
    private let point = TouchPoint(x: 0.3, y: 0.5)

    @Test func requiresAtLeastTwoFingers() {
        var round = Round()
        round.beginCountdown(seconds: 3)
        #expect(round.phase == .gathering)
        round.join(id: 1, at: point)
        round.beginCountdown(seconds: 3)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.phase == .gathering)
    }

    @Test func selectsExactlyOneOfTheCurrentParticipants() {
        var round = Round()
        for id in 1...4 { round.join(id: id, at: point) }
        round.leave(id: 2)
        round.beginCountdown(seconds: 3)
        round.tick(random: FixedRandom(value: 1))
        #expect(round.phase == .counting(2))
        round.tick(random: FixedRandom(value: 1))
        #expect(round.phase == .counting(1))
        round.tick(random: FixedRandom(value: 1))
        #expect(round.winners.count == 1)
        #expect(round.winners.first?.id == 3)
    }

    @Test(arguments: 0..<10) func everySlotCanWin(index: Int) {
        var round = Round()
        for id in 0..<10 { round.join(id: id, at: point) }
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: index))
        #expect(round.winners.count == 1)
        #expect(round.winners.first?.id == index)
    }

    @Test func membershipChangesInvalidateCountdown() {
        var round = Round()
        round.join(id: 1, at: point)
        round.join(id: 2, at: point)
        round.beginCountdown(seconds: 3)
        round.join(id: 3, at: point)
        #expect(round.phase == .gathering)
        round.beginCountdown(seconds: 3)
        round.leave(id: 1)
        #expect(round.phase == .gathering)
    }

    @Test func movingDoesNotRestartCountdownAndUpdatesWinnerPosition() {
        var round = Round()
        round.join(id: 1, at: point)
        round.join(id: 2, at: point)
        round.beginCountdown(seconds: 1)
        let moved = TouchPoint(x: 0.8, y: 0.2)
        round.move(id: 2, to: moved)
        #expect(round.phase == .counting(1))
        round.tick(random: FixedRandom(value: 1))
        #expect(round.winners.first?.position == moved)
    }

    @Test func completedRoundStaysFrozenUntilReset() {
        var round = Round()
        round.join(id: 1, at: point)
        round.join(id: 2, at: point)
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: 0))
        let finished = round
        round.leave(id: 1)
        round.move(id: 1, to: TouchPoint(x: 0, y: 0))
        round.join(id: 3, at: point)
        round.beginCountdown(seconds: 3)
        round.tick(random: FixedRandom(value: 1))
        #expect(round == finished)
    }

    @Test func stableDistinctNumbersWhenFingersComeAndGo() {
        var round = Round()
        for id in 0..<3 { round.join(id: id, at: point) }
        round.leave(id: 1)
        round.join(id: 8, at: point)
        #expect(round.fingers.map(\.number) == [1, 3, 2])
        let duplicateJoined = round.join(id: 8, at: point)
        let unknownLeft = round.leave(id: 99)
        #expect(!duplicateJoined)
        #expect(!unknownLeft)
    }

    @Test func enforcesCapacityAndClampsCoordinates() {
        var round = Round()
        for id in 0..<15 { round.join(id: id, at: point) }
        #expect(round.fingers.count == 10)
        #expect(TouchPoint(x: -3, y: 4) == TouchPoint(x: 0, y: 1))
    }

    @Test(arguments: 1...9) func keepsExactlyTheRequestedNumberWithoutDuplicates(count: Int) {
        var round = Round(winnerCount: count)
        for id in 0..<10 { round.join(id: id, at: point) }
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.isFinished)
        #expect(round.winners.count == count)
        #expect(Set(round.winners.map(\.id)).count == count)
        #expect(round.winners.map(\.id) == Array(0..<count))
    }

    @Test(arguments: 1...9) func waitsForMoreFingersThanTheNumberToKeep(count: Int) {
        var round = Round(winnerCount: count)
        for id in 0..<count { round.join(id: id, at: point) }
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.phase == .gathering)
        #expect(!round.canStartCountdown)
        round.join(id: count, at: point)
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.winners.count == count)
    }

    @Test func allTwoWinnerSubsetsAreEquallyLikely() {
        struct TwoDraws: RandomSource {
            let first: Int
            let second: Int
            func index(upperBound: Int) -> Int { upperBound == 4 ? first : second }
        }
        var frequencies: [Set<Int>: Int] = [:]
        for first in 0..<4 {
            for second in 0..<3 {
                var round = Round(winnerCount: 2)
                for id in 0..<4 { round.join(id: id, at: point) }
                round.beginCountdown(seconds: 1)
                round.tick(random: TwoDraws(first: first, second: second))
                frequencies[Set(round.winners.map(\.id)), default: 0] += 1
            }
        }
        #expect(frequencies.count == 6)
        #expect(frequencies.values.allSatisfy { $0 == 2 })
    }

    @Test func multipleWinnersExcludeDepartedFingersAndStayFrozen() {
        var round = Round(winnerCount: 2)
        for id in 0..<4 { round.join(id: id, at: point) }
        round.leave(id: 0)
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.winners.map(\.id) == [1, 2])
        let finished = round
        round.leave(id: 1)
        round.move(id: 2, to: TouchPoint(x: 0.8, y: 0.9))
        round.join(id: 9, at: point)
        #expect(round == finished)
    }

    @Test func winnerCountDefaultsToOneAndStaysWithinCapacity() {
        #expect(Round().winnerCount == 1)
        #expect(Round(winnerCount: -1).winnerCount == 1)
        #expect(Round(winnerCount: 100).winnerCount == 9)
    }
    @Test(arguments: 2...10) func chosenPlayerCountWaitsForEveryone(count: Int) {
        for mode in GameMode.allCases {
            var round = Round(mode: mode, playerCount: count)
            for id in 0..<(count - 1) { round.join(id: id, at: point) }
            round.beginCountdown(seconds: 1)
            round.tick(random: FixedRandom(value: 0))
            #expect(round.phase == .gathering)
            round.join(id: count - 1, at: point)
            round.beginCountdown(seconds: 1)
            round.tick(random: FixedRandom(value: 0))
            #expect(round.isFinished)
            if mode == .teams { #expect(round.teams.flatMap(\.members).count == count) }
            else { #expect(round.winners.count == 1) }
        }
    }

    @Test func extraPlayersJoinAndLeavingBelowTheTargetStopsTheRound() {
        var round = Round(mode: .teams, playerCount: 4)
        for id in 0..<5 { round.join(id: id, at: point) }
        round.beginCountdown(seconds: 1)
        round.leave(id: 4)
        round.leave(id: 3)
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.phase == .gathering)
        for id in 5..<8 { round.join(id: id, at: point) }
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.teams.map { $0.members.count } == [3, 3])
        #expect(Set(round.teams.flatMap(\.members).map(\.id)) == Set([0, 1, 2, 5, 6, 7]))
    }

    @Test func playerLimitsStayPlayableAndAutoNeedsNoConfiguration() {
        #expect(Round().playerCount == nil)
        #expect(Round().requiredPlayers == 2)
        #expect(Round(winnerCount: 5).requiredPlayers == 6)
        #expect(Round(winnerCount: 9, mode: .teams).requiredPlayers == 2)
        #expect(Round(playerCount: -1).requiredPlayers == 2)
        #expect(Round(playerCount: 99).requiredPlayers == 10)
        #expect(Round(winnerCount: 5, playerCount: 2).requiredPlayers == 6)
    }

}
