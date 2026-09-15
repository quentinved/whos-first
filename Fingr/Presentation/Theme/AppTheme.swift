import SwiftUI
import FingrCore

struct AppTheme: Identifiable {
    /// Shared by every palette: the dark board, the lettering on light surfaces, and the
    /// lettering on accent-filled controls.
    static let nightBackground = Color(hex: 0x10121B)
    static let inkOnLight = Color(hex: 0x29332B)
    static let inkOnAccent = Color(hex: 0x20272B)

    let id: ThemeID
    let name: String
    let background: Color
    let surface: Color
    let accent: Color
    let secondary: Color
    let tertiary: Color

    var isDark: Bool { id == .afterHours }
    var colorScheme: ColorScheme { isDark ? .dark : .light }
    var ink: Color { isDark ? Color(hex: 0xF4F5EF) : Self.inkOnLight }
    var muted: Color { isDark ? Color(hex: 0xA7ABBE) : Color(hex: 0x687168) }
    /// Accent buttons and selected rings always use dark lettering.
    var onAccent: Color { Self.inkOnAccent }
    var line: Color { ink.opacity(0.13) }
    var colors: [Color] {
        [accent, secondary, tertiary, Color(hex: 0x81C7F5), Color(hex: 0xF3E58F),
         Color(hex: 0xED93BF), Color(hex: 0xC7B9FD), Color(hex: 0xA6CDC3),
         Color(hex: 0xF1AEAE), Color(hex: 0xC1D4EF)]
    }

    func fingerColor(_ slot: Int) -> Color { colors[slot % colors.count] }

    func teamColor(_ team: TeamID) -> Color { team == .a ? accent : secondary }

    static func resolve(_ id: ThemeID) -> AppTheme {
        all.first { $0.id == id } ?? all[0]
    }

    static let all: [AppTheme] = [
        .init(id: .afterHours, name: "After Hours",
              background: nightBackground, surface: Color(hex: 0x202331),
              accent: Color(hex: 0xC9F27A), secondary: Color(hex: 0xB9A5FF), tertiary: Color(hex: 0xFFB99B)),
        .init(id: .daydream, name: "Daydream",
              background: Color(hex: 0xF2EDFC), surface: Color(hex: 0xFFFBFF),
              accent: Color(hex: 0xCFBCFA), secondary: Color(hex: 0xF2BBCE), tertiary: Color(hex: 0xB1D8F0)),
        .init(id: .tangerine, name: "Tangerine",
              background: Color(hex: 0xFFF0E3), surface: Color(hex: 0xFFFAF3),
              accent: Color(hex: 0xFFB184), secondary: Color(hex: 0xF5DA90), tertiary: Color(hex: 0xCCD09B)),
        .init(id: .poolside, name: "Poolside",
              background: Color(hex: 0xEAF7FA), surface: Color(hex: 0xF7FEFF),
              accent: Color(hex: 0x8EDFEB), secondary: Color(hex: 0xB9C1FA), tertiary: Color(hex: 0xE2EBAD)),
        .init(id: .roseClub, name: "Rose",
              background: Color(hex: 0xFCEBF2), surface: Color(hex: 0xFFF8FC),
              accent: Color(hex: 0xF6AACB), secondary: Color(hex: 0xD2B6EE), tertiary: Color(hex: 0xFFCBA3)),
        .init(id: .matcha, name: "Matcha",
              background: Color(hex: 0xEFF2E5), surface: Color(hex: 0xFAFCF3),
              accent: Color(hex: 0xCEDBA0), secondary: Color(hex: 0xEACAA6), tertiary: Color(hex: 0xB7D6BB))
    ]
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255, opacity: 1)
    }
}

extension DecisionPrompt {
    var icon: String {
        switch self {
        case .justForFun: "sparkles"
        case .tinyDare: "theatermasks.fill"
        case .goesFirst: "flag.checkered"
        case .paying: "creditcard"
        case .pickingDinner: "fork.knife"
        case .onAux: "music.note"
        case .makingCoffee: "cup.and.saucer"
        }
    }

    var shortTitle: String {
        switch self {
        case .justForFun: "Just for fun"
        case .tinyDare: "Quick dare"
        case .goesFirst: "First to go"
        case .paying: "The bill"
        case .pickingDinner: "Dinner plans"
        case .onAux: "On the aux"
        case .makingCoffee: "Coffee run"
        }
    }
}
