import Observation

public enum TouchInput: Sendable {
    case began(Int, TouchPoint)
    case moved(Int, TouchPoint)
    case ended(Int)
}

@MainActor @Observable
public final class GameSession {
    public private(set) var round: Round
    public private(set) var isDemo = false
    public private(set) var inputGeneration = 0
    public private(set) var prompt: DecisionPrompt
    public private(set) var isPaused = false

    @ObservationIgnored private let app: AppModel
    @ObservationIgnored private let random: any RandomSource
    @ObservationIgnored private let clock: any CountdownClock
    @ObservationIgnored private let feedback: any FeedbackPort
    @ObservationIgnored private var countdownTask: Task<Void, Never>?
    @ObservationIgnored private var demoTask: Task<Void, Never>?
    @ObservationIgnored private var countdownGeneration = 0

    public init(prompt: DecisionPrompt, app: AppModel, random: any RandomSource,
                clock: any CountdownClock, feedback: any FeedbackPort) {
        self.prompt = prompt
        self.app = app
        self.random = random
        self.clock = clock
        self.feedback = feedback
        round = Round(preferences: app.preferences)
    }

    public func receive(_ inputs: [TouchInput]) {
        guard !isDemo, !isPaused else { return }
        apply(inputs)
    }

    public func reset() {
        cancelTasks()
        isDemo = false
        round = Round(preferences: app.preferences)
        inputGeneration += 1
    }

    /// Options never allow a hidden countdown or touches behind the sheet.
    public func pauseForConfiguration() {
        reset()
        isPaused = true
    }

    public func resumeAfterConfiguration(prompt: DecisionPrompt) {
        self.prompt = prompt
        reset()
        isPaused = false
    }

    /// Cancelling on background/exit prevents a delayed, unseen winner.
    public func suspend() {
        if round.isFinished {
            cancelTasks()
        } else {
            reset()
        }
    }

    public func startDemo() {
        guard !isPaused else { return }
        reset()
        isDemo = true
        let count = round.playerCount ?? max(round.mode == .teams ? 4 : 3, round.requiredPlayers)
        let points = Self.demoLayout(count: count)
        demoTask = Task { [weak self] in
            for (index, point) in points.enumerated() {
                guard !Task.isCancelled else { return }
                self?.apply([.began(100 + index, point)])
                do { try await Task.sleep(for: .milliseconds(450)) }
                catch { return }
            }
        }
    }

    /// Where the virtual fingers land. Three sit in a loose triangle; more fill a grid that
    /// leaves room for the floating controls on the full-screen canvas.
    private static func demoLayout(count: Int) -> [TouchPoint] {
        if count == 3 {
            return [TouchPoint(x: 0.27, y: 0.32), TouchPoint(x: 0.73, y: 0.44), TouchPoint(x: 0.40, y: 0.62)]
        }
        let columns = count <= 6 ? 2 : 3
        let rows = (count + columns - 1) / columns
        return (0..<count).map { index in
            TouchPoint(x: (Double(index % columns) + 0.5) / Double(columns),
                       y: 0.28 + Double(index / columns) / Double(max(1, rows - 1)) * 0.38)
        }
    }

    /// Batch membership changes so simultaneous fingers only restart the clock once.
    private func apply(_ inputs: [TouchInput]) {
        guard !round.isFinished else { return }
        var membershipChanged = false
        for input in inputs {
            switch input {
            case let .began(id, point):
                if round.join(id: id, at: point) {
                    membershipChanged = true
                    app.play(.joined)
                }
            case let .moved(id, point): round.move(id: id, to: point)
            case let .ended(id):
                if round.leave(id: id) { membershipChanged = true }
            }
        }
        if membershipChanged { restartCountdown() }
    }

    private func restartCountdown() {
        countdownTask?.cancel()
        countdownGeneration += 1
        app.stopMusic()
        guard round.canStartCountdown else { return }
        round.beginCountdown(seconds: app.preferences.countdownSeconds)
        app.startCountdownMusic()
        let generation = countdownGeneration
        countdownTask = Task { [weak self] in
            await self?.runCountdown(generation: generation)
        }
    }

    /// One tick per clock second until the round finishes or a newer countdown replaces this one.
    private func runCountdown(generation: Int) async {
        while !Task.isCancelled {
            do { try await clock.waitOneSecond() }
            catch { return }
            guard !Task.isCancelled, countdownGeneration == generation else { return }
            round.tick(random: random)
            if round.isFinished {
                finishRound()
                return
            }
            app.play(.tick)
        }
    }

    private func finishRound() {
        app.play(.winner)
        feedback.announce(resultAnnouncement)
        guard !isDemo else { return }
        app.recordRound(players: round.fingers.count, mode: round.mode, prompt: prompt)
    }

    private func cancelTasks() {
        app.stopMusic()
        countdownGeneration += 1
        countdownTask?.cancel()
        countdownTask = nil
        demoTask?.cancel()
        demoTask = nil
    }

    private var resultAnnouncement: String {
        switch round.phase {
        case .teams(let teams):
            return teams.map { team in
                let numbers = team.members.map { String($0.number) }.joined(separator: ", ")
                return "Team \(team.id.rawValue): fingers \(numbers)."
            }.joined(separator: " ")
        case .winners(let fingers):
            let numbers = fingers.map { String($0.number) }.joined(separator: ", ")
            let label = fingers.count == 1 ? "Finger" : "Fingers"
            return "\(label) \(numbers). \(prompt.result(winnerCount: fingers.count))"
        case .gathering, .counting: return ""
        }
    }
}
