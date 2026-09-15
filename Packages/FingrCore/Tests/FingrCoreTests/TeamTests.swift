import Testing
@testable import FingrCore

struct TeamTests {
    @Test(arguments: 2...10) func everyoneBelongsToExactlyOneBalancedTeam(count: Int) {
        // A previously saved picker count must have no effect on team sizes.
        var round = Round(winnerCount: 9, mode: .teams)
        for id in 0..<count {
            round.join(id: id, at: TouchPoint(x: Double(id) / Double(count), y: 0.5))
        }
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.isFinished)
        #expect(round.teams.map(\.id) == [.a, .b])
        #expect(round.teams.map { $0.members.count } == [(count + 1) / 2, count / 2])
        let members = round.teams.flatMap(\.members)
        #expect(members.count == count)
        #expect(Set(members.map(\.id)) == Set(0..<count))
        #expect(round.winners.isEmpty)
        for team in round.teams {
            for member in team.members {
                #expect(round.team(for: member.id) == team.id)
                #expect(round.fingers.first { $0.id == member.id } == member)
            }
        }
    }

    @Test func needsTwoPeopleAndDoesNotAssignTeamsEarly() {
        var round = Round(mode: .teams)
        #expect(round.requiredPlayers == 2)
        round.join(id: 1, at: TouchPoint(x: 0.2, y: 0.5))
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.phase == .gathering)
        #expect(round.team(for: 1) == nil)
        round.join(id: 2, at: TouchPoint(x: 0.8, y: 0.5))
        round.beginCountdown(seconds: 2)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.teams.isEmpty)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.teams.map { $0.members.count } == [1, 1])
    }

    @Test func departedFingersAreExcludedAndFinalTeamsStayInPlace() {
        var round = Round(mode: .teams)
        for id in 0..<5 { round.join(id: id, at: TouchPoint(x: 0.5, y: 0.5)) }
        round.beginCountdown(seconds: 3)
        round.leave(id: 0)
        #expect(round.phase == .gathering)
        let moved = TouchPoint(x: 0.8, y: 0.2)
        round.move(id: 4, to: moved)
        round.beginCountdown(seconds: 1)
        round.tick(random: FixedRandom(value: 0))
        #expect(round.teams.map { $0.members.count } == [2, 2])
        #expect(round.team(for: 0) == nil)
        #expect(round.teams.flatMap(\.members).first { $0.id == 4 }?.position == moved)
        let finished = round
        round.leave(id: 1)
        round.move(id: 4, to: TouchPoint(x: 0, y: 0))
        round.join(id: 8, at: moved)
        round.tick(random: FixedRandom(value: 0))
        #expect(round == finished)
    }

    @Test func teamAssignmentsAreUniformAcrossAllFourPlayerDraws() {
        struct Draws: RandomSource {
            let first: Int
            let second: Int
            func index(upperBound: Int) -> Int { upperBound == 4 ? first : second }
        }
        var assignments: [Set<Int>: Int] = [:]
        for first in 0..<4 {
            for second in 0..<3 {
                var round = Round(mode: .teams)
                for id in 0..<4 { round.join(id: id, at: TouchPoint(x: 0.5, y: 0.5)) }
                round.beginCountdown(seconds: 1)
                round.tick(random: Draws(first: first, second: second))
                let firstTeam = Set(round.teams[0].members.map(\.id))
                let secondTeam = Set(round.teams[1].members.map(\.id))
                #expect(firstTeam.isDisjoint(with: secondTeam))
                assignments[firstTeam, default: 0] += 1
            }
        }
        #expect(assignments.count == 6)
        #expect(assignments.values.allSatisfy { $0 == 2 })
    }
}
