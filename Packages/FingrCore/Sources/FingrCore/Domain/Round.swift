/// Coordinates stay independent of UIKit and survive changes in screen size.
public struct TouchPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = (0...1).clamping(x)
        self.y = (0...1).clamping(y)
    }
}

public struct Finger: Identifiable, Equatable, Sendable {
    public let id: Int
    public let slot: Int
    public var position: TouchPoint
    public var number: Int { slot + 1 }
}

public enum RoundPhase: Equatable, Sendable {
    case gathering
    case counting(Int)
    case winners([Finger])
    case teams([Team])
}

public protocol RandomSource: Sendable {
    /// Returns a uniformly distributed integer in 0..<upperBound.
    func index(upperBound: Int) -> Int
}

/// The game rules have no UI, storage, timer, or device dependencies.
public struct Round: Equatable, Sendable {
    public static let minimumPlayers = 2
    public static let maximumPlayers = 10
    public static let winnerCountRange = 1...(maximumPlayers - 1)
    public let mode: GameMode
    public let winnerCount: Int
    /// Nil starts automatically; a number waits until that many people have joined.
    public let playerCount: Int?
    public private(set) var fingers: [Finger] = []
    public private(set) var phase: RoundPhase = .gathering

    public init(winnerCount: Int = 1, mode: GameMode = .picker, playerCount: Int? = nil) {
        self.mode = mode
        self.winnerCount = Self.winnerCountRange.clamping(winnerCount)
        let minimum = Self.minimumPlayers(for: mode, winnerCount: self.winnerCount)
        self.playerCount = playerCount.map { (minimum...Self.maximumPlayers).clamping($0) }
    }

    /// Picker leaves someone unselected; teams include everyone from two players up.
    public static func minimumPlayers(for mode: GameMode, winnerCount: Int) -> Int {
        mode == .teams ? minimumPlayers : winnerCount + 1
    }

    public var requiredPlayers: Int {
        playerCount ?? Self.minimumPlayers(for: mode, winnerCount: winnerCount)
    }

    public var canStartCountdown: Bool { !isFinished && fingers.count >= requiredPlayers }

    public var winners: [Finger] {
        if case .winners(let selected) = phase { return selected }
        return []
    }

    public var teams: [Team] {
        if case .teams(let groups) = phase { return groups }
        return []
    }

    public var isFinished: Bool {
        switch phase {
        case .winners, .teams: return true
        case .gathering, .counting: return false
        }
    }

    public func team(for fingerID: Int) -> TeamID? {
        teams.first { $0.members.contains { $0.id == fingerID } }?.id
    }

    @discardableResult
    public mutating func join(id: Int, at position: TouchPoint) -> Bool {
        guard !isFinished, fingers.count < Self.maximumPlayers,
              !fingers.contains(where: { $0.id == id }) else { return false }
        let usedSlots = Set(fingers.map(\.slot))
        let slot = (0..<Self.maximumPlayers).first { !usedSlots.contains($0) }!
        fingers.append(Finger(id: id, slot: slot, position: position))
        phase = .gathering
        return true
    }

    public mutating func move(id: Int, to position: TouchPoint) {
        guard !isFinished, let index = fingers.firstIndex(where: { $0.id == id }) else { return }
        fingers[index].position = position
    }

    @discardableResult
    public mutating func leave(id: Int) -> Bool {
        guard !isFinished, fingers.contains(where: { $0.id == id }) else { return false }
        fingers.removeAll { $0.id == id }
        phase = .gathering
        return true
    }

    public mutating func beginCountdown(seconds: Int) {
        guard canStartCountdown else { return }
        phase = .counting(max(1, seconds))
    }

    public mutating func tick(random: any RandomSource) {
        guard case .counting(let remaining) = phase, canStartCountdown else { return }
        if remaining > 1 {
            phase = .counting(remaining - 1)
        } else {
            draw(random: random)
        }
    }

    /// Draw without replacement, so each distinct subset has equal probability.
    private mutating func draw(random: any RandomSource) {
        var candidates = fingers
        var selected: [Finger] = []
        let selectionCount = mode == .teams ? (fingers.count + 1) / 2 : winnerCount
        for _ in 0..<selectionCount {
            let index = random.index(upperBound: candidates.count)
            guard candidates.indices.contains(index) else { return }
            selected.append(candidates.remove(at: index))
        }
        selected.sort { $0.slot < $1.slot }
        if mode == .teams {
            let rest = candidates.sorted { $0.slot < $1.slot }
            phase = .teams([Team(id: .a, members: selected), Team(id: .b, members: rest)])
        } else {
            phase = .winners(selected)
        }
    }
}

extension ClosedRange {
    func clamping(_ value: Bound) -> Bound {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
