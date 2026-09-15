import Foundation
import Testing
@testable import FingrCore

@MainActor private final class MemoryPreferences: PreferencesPort {
    var value = Preferences()
    func load() -> Preferences { value }
    func save(_ preferences: Preferences) { value = preferences }
}

/// Records what would have gone to Game Center, so the tests can assert on progress
/// without a signed-in player.
@MainActor private final class RecordingAchievements: AchievementsPort {
    private(set) var latest: [Achievement: Double] = [:]
    private(set) var reports = 0
    func report(_ progress: [Achievement: Double]) {
        latest = progress
        reports += 1
    }
}

@MainActor private final class RecordingFeedback: FeedbackPort, SoundtrackPort {
    var announcements: [String] = []
    enum MusicEvent: Equatable { case countdown(Int), reveal, stop }
    var music: [MusicEvent] = []
    func play(_ event: FeedbackEvent, haptics: Bool) {}
    func startCountdown(seconds: Int) { music.append(.countdown(seconds)) }
    func playReveal() { music.append(.reveal) }
    func stop() { music.append(.stop) }
    func announce(_ message: String) { announcements.append(message) }
}

private actor ManualClock: CountdownClock {
    private var waiters: [(UUID, CheckedContinuation<Void, any Error>)] = []
    var pending: Int { waiters.count }

    func waitOneSecond() async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                if Task.isCancelled { continuation.resume(throwing: CancellationError()) }
                else { waiters.append((id, continuation)) }
            }
        } onCancel: {
            Task { await self.cancel(id) }
        }
    }

    func advance() {
        guard !waiters.isEmpty else { return }
        waiters.removeFirst().1.resume()
    }

    private func cancel(_ id: UUID) {
        guard let index = waiters.firstIndex(where: { $0.0 == id }) else { return }
        waiters.remove(at: index).1.resume(throwing: CancellationError())
    }
}

@MainActor
struct SessionTests {
    private func waitUntil(_ condition: () async -> Bool) async throws {
        for _ in 0..<3000 {
            if await condition() { return }
            try await Task.sleep(for: .milliseconds(2))
        }
        Issue.record("Timed out waiting for the expected state")
    }

    private func fixture(winnerCount: Int = 1, mode: GameMode = .picker, playerCount: Int? = nil) -> (GameSession, AppModel, MemoryPreferences, RecordingFeedback, ManualClock) {
        let storage = MemoryPreferences()
        let feedback = RecordingFeedback()
        let app = AppModel(storage: storage, feedback: feedback, soundtrack: feedback, achievements: RecordingAchievements())
        app.setWinnerCount(winnerCount)
        app.setGameMode(mode)
        app.setPlayerCount(playerCount)
        let clock = ManualClock()
        let session = GameSession(prompt: .goesFirst, app: app, random: FixedRandom(value: 0), clock: clock, feedback: feedback)
        return (session, app, storage, feedback, clock)
    }

    private var pair: [TouchInput] {
        [.began(1, TouchPoint(x: 0.2, y: 0.3)), .began(2, TouchPoint(x: 0.8, y: 0.7))]
    }

    private func tick(_ clock: ManualClock) async throws {
        try await waitUntil { await clock.pending == 1 }
        await clock.advance()
        await Task.yield()
    }

    @Test func automaticCountdownRecordsAndAnnouncesExactlyOneWinner() async throws {
        let (session, app, storage, feedback, clock) = fixture()
        session.receive(pair)
        #expect(session.round.phase == .counting(3))
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(app.preferences.completedRounds == 1)
        #expect(storage.value.completedRounds == 1)
        #expect(feedback.announcements == ["Finger 1. You're up first."])
        session.receive([.ended(1), .ended(2)])
        #expect(session.round.isFinished)
        #expect(app.preferences.completedRounds == 1)
    }

    @Test func liftingBelowMinimumCancelsPendingSelection() async throws {
        let (session, app, _, _, clock) = fixture()
        session.receive(pair)
        try await tick(clock)
        session.receive([.ended(2)])
        try await waitUntil { await clock.pending == 0 }
        #expect(session.round.phase == .gathering)
        await clock.advance()
        #expect(app.preferences.completedRounds == 0)
        session.reset()
    }

    @Test func joiningRestartsTheFullCountdown() async throws {
        let (session, _, _, _, clock) = fixture()
        session.receive(pair)
        try await tick(clock)
        try await waitUntil { session.round.phase == .counting(2) }
        session.receive([.began(3, TouchPoint(x: 0.5, y: 0.5))])
        #expect(session.round.phase == .counting(3))
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(session.round.fingers.count == 3)
    }

    @Test func backgroundAndReplayCannotLeakAnOldCountdown() async throws {
        let (session, app, _, _, clock) = fixture()
        session.receive(pair)
        try await tick(clock)
        session.suspend()
        try await waitUntil { await clock.pending == 0 }
        #expect(session.round.fingers.isEmpty)
        #expect(session.round.phase == .gathering)
        #expect(session.inputGeneration == 1)
        session.receive(pair)
        #expect(session.round.phase == .counting(3))
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(app.preferences.completedRounds == 1)
        session.reset()
        #expect(session.round.fingers.isEmpty)
        #expect(session.inputGeneration == 2)
    }

    @Test func demoUsesTheRealGameButDoesNotCountAsAPlayedRound() async throws {
        let (session, app, _, _, clock) = fixture()
        session.startDemo()
        try await waitUntil { session.round.fingers.count == 3 }
        session.receive([.began(999, TouchPoint(x: 0, y: 0))])
        #expect(session.round.fingers.count == 3)
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(app.preferences.completedRounds == 0)
        #expect(session.isDemo)
        session.reset()
        #expect(!session.isDemo)
    }

    @Test func cancelledDemoDoesNotAddGhostFingers() async throws {
        let (session, _, _, _, _) = fixture()
        session.startDemo()
        session.reset()
        try await Task.sleep(for: .milliseconds(500))
        #expect(session.round.fingers.isEmpty)
        #expect(session.round.phase == .gathering)
    }

    @Test func preferencesSurviveRecreatingTheApplication() {
        let (_, app, storage, feedback, _) = fixture()
        app.selectTheme(.roseClub)
        app.setCountdown(5)
        app.setSound(true)
        app.setHaptics(false)
        app.setWinnerCount(3)
        let restored = AppModel(storage: storage, feedback: feedback, soundtrack: feedback, achievements: RecordingAchievements())
        #expect(restored.preferences.theme == .roseClub)
        #expect(restored.preferences.countdownSeconds == 5)
        #expect(restored.preferences.soundEnabled)
        #expect(!restored.preferences.hapticsEnabled)
        #expect(restored.preferences.winnerCount == 3)
    }

    @Test func malformedPreferenceValuesAreNormalized() throws {
        let data = Data(#"{"theme":"afterHours","hapticsEnabled":true,"soundEnabled":false,"countdownSeconds":-4,"completedRounds":-9}"#.utf8)
        let decoded = try JSONDecoder().decode(Preferences.self, from: data).validated
        #expect(decoded.countdownSeconds == 3)
        #expect(decoded.completedRounds == 0)
    }

    @Test func twoWinnersWaitForThreeFingersAndCountAsOneRound() async throws {
        let (session, app, _, feedback, clock) = fixture(winnerCount: 2)
        session.receive(pair)
        #expect(session.round.phase == .gathering)
        #expect(await clock.pending == 0)
        session.receive([.began(3, TouchPoint(x: 0.5, y: 0.5))])
        #expect(session.round.phase == .counting(3))
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(session.round.winners.map(\.id) == [1, 2])
        #expect(app.preferences.completedRounds == 1)
        #expect(feedback.announcements == ["Fingers 1, 2. You're up first together."])
        session.reset()
        #expect(session.round.winnerCount == 2)
        #expect(session.round.fingers.isEmpty)
    }

    @Test func fallingBelowTheRequestedGroupSizeCancelsCountdown() async throws {
        let (session, app, _, _, clock) = fixture(winnerCount: 2)
        session.receive(pair + [.began(3, TouchPoint(x: 0.5, y: 0.5))])
        try await tick(clock)
        session.receive([.ended(3)])
        try await waitUntil { await clock.pending == 0 }
        #expect(session.round.phase == .gathering)
        #expect(session.round.winners.isEmpty)
        #expect(app.preferences.completedRounds == 0)
        session.receive([.began(4, TouchPoint(x: 0.5, y: 0.5))])
        #expect(session.round.phase == .counting(3))
        session.suspend()
        #expect(session.round.winnerCount == 2)
        #expect(session.round.fingers.isEmpty)
    }

    @Test func winnerCountIsFixedForTheCurrentRound() {
        let (session, app, _, _, _) = fixture(winnerCount: 2)
        app.setWinnerCount(3)
        #expect(session.round.winnerCount == 2)
        session.reset()
        #expect(session.round.winnerCount == 3)
    }

    @Test(arguments: [2, 4, 9]) func demoAddsEnoughFingersForTheSelectedCount(count: Int) async throws {
        let (session, app, _, _, clock) = fixture(winnerCount: count)
        session.startDemo()
        try await waitUntil { session.round.fingers.count == count + 1 }
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(session.round.winners.count == count)
        #expect(app.preferences.completedRounds == 0)
        session.reset()
        #expect(session.round.winnerCount == count)
    }

    @Test func oldPreferencesDefaultToOneWithoutLosingExistingChoices() throws {
        let legacy = Data(#"{"theme":"daydream","hapticsEnabled":false,"soundEnabled":true,"countdownSeconds":5,"completedRounds":12}"#.utf8)
        let decoded = try JSONDecoder().decode(Preferences.self, from: legacy)
        #expect(decoded.winnerCount == 1)
        #expect(decoded.theme == .daydream)
        #expect(decoded.countdownSeconds == 5)
        #expect(decoded.completedRounds == 12)
        #expect(decoded.soundEnabled)
        #expect(!decoded.hapticsEnabled)
    }

    @Test func selectedWinnerCountSurvivesEncodingAndInvalidCountsAreClamped() throws {
        let saved = Preferences(theme: .matcha, completedRounds: 7, winnerCount: 4)
        let restored = try JSONDecoder().decode(Preferences.self, from: JSONEncoder().encode(saved))
        #expect(restored == saved)
        let (_, app, _, _, _) = fixture()
        app.setWinnerCount(0)
        #expect(app.preferences.winnerCount == 1)
        app.setWinnerCount(100)
        #expect(app.preferences.winnerCount == 9)
    }

    @Test(arguments: [4, 6]) func teamRoundsIncludeEveryoneAndCountOnce(count: Int) async throws {
        let (session, app, _, feedback, clock) = fixture(winnerCount: 9, mode: .teams)
        let inputs: [TouchInput] = (1...count).map { .began($0, TouchPoint(x: Double($0) / Double(count + 1), y: 0.5)) }
        session.receive(inputs)
        #expect(session.round.phase == .counting(3))
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(session.round.teams.map { $0.members.count } == [count / 2, count / 2])
        #expect(session.round.teams.flatMap(\.members).count == count)
        #expect(app.preferences.completedRounds == 1)
        #expect(feedback.announcements.count == 1)
        #expect(feedback.announcements[0].contains("Team A: fingers"))
        #expect(feedback.announcements[0].contains("Team B: fingers"))
        session.receive((1...count).map { .ended($0) })
        #expect(session.round.teams.flatMap(\.members).count == count)
        session.reset()
        #expect(session.round.mode == .teams)
        #expect(session.round.teams.isEmpty)
        #expect(session.round.fingers.isEmpty)
    }

    @Test func teamCountdownTracksTheCurrentGroupAndCancelsInBackground() async throws {
        let (session, app, _, _, clock) = fixture(mode: .teams)
        session.receive(pair)
        try await tick(clock)
        session.receive([.began(3, TouchPoint(x: 0.5, y: 0.5))])
        #expect(session.round.phase == .counting(3))
        session.receive([.ended(1), .ended(2)])
        try await waitUntil { await clock.pending == 0 }
        #expect(session.round.phase == .gathering)
        session.receive([.began(4, TouchPoint(x: 0.8, y: 0.8))])
        #expect(session.round.phase == .counting(3))
        session.suspend()
        try await waitUntil { await clock.pending == 0 }
        #expect(session.round.mode == .teams)
        #expect(session.round.fingers.isEmpty)
        #expect(session.round.teams.isEmpty)
        #expect(app.preferences.completedRounds == 0)
    }

    @Test func teamDemoCreatesTwoTeamsOfTwoWithoutCountingARealRound() async throws {
        let (session, app, _, _, clock) = fixture(winnerCount: 9, mode: .teams)
        session.startDemo()
        try await waitUntil { session.round.fingers.count == 4 }
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(session.round.teams.map { $0.members.count } == [2, 2])
        #expect(app.preferences.completedRounds == 0)
        session.reset()
        #expect(!session.isDemo)
        #expect(session.round.mode == .teams)
    }

    @Test func modePersistsWithoutOverwritingPickerPreferencesOrAnActiveRound() throws {
        let (session, app, storage, feedback, _) = fixture(winnerCount: 3)
        app.setGameMode(.teams)
        #expect(session.round.mode == .picker)
        session.reset()
        #expect(session.round.mode == .teams)
        let encoded = try JSONEncoder().encode(app.preferences)
        let decoded = try JSONDecoder().decode(Preferences.self, from: encoded)
        #expect(decoded.gameMode == .teams)
        #expect(decoded.winnerCount == 3)
        let restored = AppModel(storage: storage, feedback: feedback, soundtrack: feedback, achievements: RecordingAchievements())
        #expect(restored.preferences.gameMode == .teams)
        restored.setGameMode(.picker)
        #expect(restored.preferences.winnerCount == 3)
    }

    @Test func preferencesFromBeforeTeamModeStillLoadAsPicker() throws {
        let legacy = Data(#"{"theme":"daydream","hapticsEnabled":false,"soundEnabled":true,"countdownSeconds":5,"completedRounds":12,"winnerCount":3}"#.utf8)
        let decoded = try JSONDecoder().decode(Preferences.self, from: legacy)
        #expect(decoded.gameMode == .picker)
        #expect(decoded.playerCount == nil)
        #expect(decoded.winnerCount == 3)
        #expect(decoded.theme == .daydream)
        #expect(decoded.completedRounds == 12)
    }
    @Test func optionsCancelPendingWorkAndResumeWithNewRules() async throws {
        let (session, app, _, feedback, clock) = fixture()
        session.receive(pair)
        try await tick(clock)
        session.pauseForConfiguration()
        try await waitUntil { await clock.pending == 0 }
        #expect(session.isPaused)
        #expect(session.round.fingers.isEmpty)
        let generation = session.inputGeneration
        session.receive(pair)
        session.startDemo()
        session.suspend() // Backgrounding while options are open must keep input blocked.
        session.receive(pair)
        #expect(session.round.fingers.isEmpty)
        #expect(!session.isDemo)
        #expect(session.isPaused)
        await clock.advance()
        #expect(app.preferences.completedRounds == 0)
        #expect(feedback.announcements.isEmpty)

        app.setGameMode(.teams)
        app.setPlayerCount(6)
        app.setCountdown(5)
        session.resumeAfterConfiguration(prompt: .makingCoffee)
        #expect(!session.isPaused)
        #expect(session.inputGeneration > generation)
        #expect(session.prompt == .makingCoffee)
        #expect(session.round.requiredPlayers == 6)
        let inputs: [TouchInput] = (1...5).map { .began($0, TouchPoint(x: 0.5, y: 0.5)) }
        session.receive(inputs)
        #expect(session.round.phase == .gathering)
        session.receive([.began(6, TouchPoint(x: 0.2, y: 0.2))])
        #expect(session.round.phase == .counting(5))
        for _ in 0..<5 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(session.round.teams.map { $0.members.count } == [3, 3])
        #expect(app.preferences.completedRounds == 1)
        #expect(feedback.announcements.count == 1)
    }

    @Test(arguments: [2, 6, 10]) func demoHonorsTheChosenTeamSize(count: Int) async throws {
        let (session, app, _, _, clock) = fixture(mode: .teams, playerCount: count)
        session.startDemo()
        try await waitUntil { session.round.fingers.count == count }
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(session.round.teams.map { $0.members.count } == [count / 2, count / 2])
        #expect(app.preferences.completedRounds == 0)
    }

    @Test func chosenPlayerCountPersistsAndStaysCompatibleWithWinners() throws {
        let (_, app, storage, feedback, _) = fixture(playerCount: 4)
        let restored = AppModel(storage: storage, feedback: feedback, soundtrack: feedback, achievements: RecordingAchievements())
        #expect(restored.preferences.playerCount == 4)
        let encoded = try JSONEncoder().encode(app.preferences)
        #expect(try JSONDecoder().decode(Preferences.self, from: encoded).playerCount == 4)
        app.setWinnerCount(5)
        #expect(app.preferences.playerCount == 6)
        app.setGameMode(.teams)
        app.setPlayerCount(2)
        #expect(app.preferences.playerCount == 2)
        app.setGameMode(.picker)
        #expect(app.preferences.playerCount == 6)
        app.setPlayerCount(nil)
        #expect(app.preferences.playerCount == nil)
        #expect(storage.value.playerCount == nil)
        app.setWinnerCount(9)
        #expect(app.preferences.playerCount == nil)
        let invalid = Preferences(winnerCount: 3, playerCount: -10)
        #expect(invalid.playerCount == 4)
    }

    @Test(arguments: [3, 5], GameMode.allCases)
    func musicFollowsTheCountdownAndLandsOnTheResult(seconds: Int, mode: GameMode) async throws {
        let (session, app, _, feedback, clock) = fixture(mode: mode)
        app.setCountdown(seconds)
        session.receive([pair[0]])
        #expect(!feedback.music.contains(.countdown(seconds)))
        session.receive([pair[1]])
        #expect(feedback.music.last == .countdown(seconds))
        let events = feedback.music
        session.receive([.moved(1, TouchPoint(x: 0.4, y: 0.3))])
        #expect(feedback.music == events)
        for _ in 0..<(seconds - 1) { try await tick(clock) }
        #expect(!feedback.music.contains(.reveal))
        try await tick(clock)
        try await waitUntil { session.round.isFinished }
        #expect(feedback.music.last == .reveal)
        #expect(feedback.music.filter { $0 == .reveal }.count == 1)
        session.receive([.ended(1), .ended(2)])
        #expect(feedback.music.filter { $0 == .reveal }.count == 1)
        session.reset()
        #expect(feedback.music.last == .stop)
    }

    @Test func musicRestartsForNewPlayersAndStopsWhenTheRoundIsCancelled() async throws {
        let (session, _, _, feedback, clock) = fixture()
        session.receive(pair)
        try await tick(clock)
        session.receive([.began(3, TouchPoint(x: 0.5, y: 0.5))])
        #expect(Array(feedback.music.suffix(2)) == [.stop, .countdown(3)])
        #expect(feedback.music.filter { $0 == .countdown(3) }.count == 2)
        session.receive([.ended(2), .ended(3)])
        #expect(feedback.music.last == .stop)
        try await waitUntil { await clock.pending == 0 }
        await clock.advance()
        #expect(!feedback.music.contains(.reveal))
        session.receive([pair[1]])
        #expect(feedback.music.last == .countdown(3))
        session.pauseForConfiguration()
        #expect(feedback.music.last == .stop)
        session.resumeAfterConfiguration(prompt: .justForFun)
        session.receive(pair)
        session.suspend()
        #expect(feedback.music.last == .stop)
        try await waitUntil { await clock.pending == 0 }
        #expect(!feedback.music.contains(.reveal))
    }

    @Test func mutedRoundsStaySilentAndRememberTheChoice() async throws {
        let (session, app, storage, feedback, clock) = fixture()
        session.receive(pair)
        #expect(feedback.music.last == .countdown(3))
        app.setSound(false)
        #expect(feedback.music.last == .stop)
        feedback.music.removeAll()
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(feedback.music.isEmpty)
        session.reset()
        session.receive(pair)
        #expect(!feedback.music.contains(.countdown(3)))
        for _ in 0..<3 { try await tick(clock) }
        try await waitUntil { session.round.isFinished }
        #expect(!feedback.music.contains(.reveal))
        let restored = AppModel(storage: storage, feedback: feedback, soundtrack: feedback, achievements: RecordingAchievements())
        #expect(!restored.preferences.soundEnabled)
        restored.setSound(true)
        #expect(feedback.music.last == .reveal) // Immediate, short preview when enabled.
    }

    @Test func musicIsOnForNewInstallsAndLegacyMuteIsPreserved() throws {
        #expect(Preferences().soundEnabled)
        let legacy = Data(#"{"theme":"afterHours","hapticsEnabled":true,"soundEnabled":false,"countdownSeconds":3,"completedRounds":5}"#.utf8)
        let preferences = try JSONDecoder().decode(Preferences.self, from: legacy)
        #expect(!preferences.soundEnabled)
        #expect(preferences.completedRounds == 5)
    }

}
