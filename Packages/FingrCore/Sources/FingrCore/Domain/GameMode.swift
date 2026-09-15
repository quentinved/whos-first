public enum GameMode: String, CaseIterable, Codable, Sendable, Identifiable {
    case picker, teams
    public var id: String { rawValue }
}

public enum TeamID: String, Sendable {
    case a = "A", b = "B"
}

public struct Team: Identifiable, Equatable, Sendable {
    public let id: TeamID
    public let members: [Finger]
}
