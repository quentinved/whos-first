import SwiftUI
import FingrCore

/// One options sheet; every setting still saves with a single tap.
struct SettingsView: View {
    let app: AppModel
    @Binding var prompt: DecisionPrompt
    let done: () -> Void
    let demo: () -> Void
    private var theme: AppTheme { .resolve(app.preferences.theme) }
    /// Chip order on the sheet: the two most used first, then the rest by how often they come up.
    private let occasions: [DecisionPrompt] = [
        .justForFun, .tinyDare, .goesFirst, .pickingDinner, .onAux, .paying, .makingCoffee
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    gameSetup
                    if app.preferences.gameMode == .picker { occasionPicker }
                    themePicker
                    soundAndTiming
                    demoButton
                    Text("Touch. Hold. Find out.")
                        .font(.system(size: 11, weight: .medium, design: .default)).foregroundStyle(theme.muted)
                        .frame(maxWidth: .infinity).padding(.top, 2)
                }
                .padding(.horizontal, 20).padding(.top, 5).padding(.bottom, 26)
            }
        }
        .foregroundStyle(theme.ink).background(theme.background)
        .environment(\.colorScheme, theme.colorScheme)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                TinyLabel(text: "Who's First", color: theme.muted)
                Text("Your game.").font(.system(size: 28, weight: .semibold, design: .default)).tracking(-0.9)
                    .accessibilityIdentifier("settings.title")
            }
            Spacer(minLength: 0)
            Button(action: done) {
                Text("Done").font(.system(size: 12, weight: .semibold, design: .default))
                    .padding(.horizontal, 15).frame(minHeight: 44)
                    .foregroundStyle(theme.onAccent).card(theme.accent, radius: 16, outlined: true)
            }
            .buttonStyle(PressStyle()).accessibilityIdentifier("settings.done")
        }
        .padding(.horizontal, 22).padding(.top, 30).padding(.bottom, 22)
    }

    // MARK: Game rules

    private var gameSetup: some View {
        VStack(spacing: 13) {
            GameModeControl(mode: Binding(get: { app.preferences.gameMode }, set: { app.setGameMode($0) }),
                            theme: theme, identifierPrefix: "settings.mode")
            if app.preferences.gameMode == .teams {
                TeamModeInfo(theme: theme)
            } else {
                WinnerCountControl(count: Binding(get: { app.preferences.winnerCount }, set: { app.setWinnerCount($0) }),
                                   theme: theme, identifierPrefix: "settings.winnerCount")
            }
            playerCount
        }
    }

    private var playerCount: some View {
        let minimum = app.preferences.minimumPlayers
        let chosen = app.preferences.playerCount
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Players").font(.system(size: 14, weight: .bold, design: .default))
                Text(chosen == nil ? "Starts with \(minimum) or more." : "Wait for everyone to join.")
                    .font(.system(size: 10, weight: .medium, design: .default)).foregroundStyle(theme.muted)
                    .accessibilityIdentifier("settings.players.value")
            }
            ChipGrid {
                ChoiceChip(title: "Auto", selected: chosen == nil, theme: theme,
                           label: "Automatic player count") { app.setPlayerCount(nil) }
                    .accessibilityIdentifier("settings.players.auto")
                ForEach(minimum...Round.maximumPlayers, id: \.self) { count in
                    ChoiceChip(title: "\(count)", selected: chosen == count, theme: theme,
                               label: "\(count) players") { app.setPlayerCount(count) }
                        .accessibilityIdentifier("settings.players.\(count)")
                }
            }
        }
        .padding(14).card(theme.surface, radius: 22)
        .accessibilityElement(children: .contain)
    }

    // MARK: Occasion

    private var occasionPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Play for…", note: prompt == .tinyDare ? "Quick dare" : "Your call")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(occasions) { option in occasionChip(option) }
                }
                .padding(.bottom, 3)
            }
            if prompt == .tinyDare {
                Text("The selected player gets a quick challenge.")
                    .font(.system(size: 11, weight: .medium, design: .default)).foregroundStyle(theme.muted)
            }
        }
    }

    private func occasionChip(_ option: DecisionPrompt) -> some View {
        let selected = prompt == option
        return Button { prompt = option; app.play(.selection) } label: {
            Label(option.shortTitle, systemImage: option.icon)
                .font(.system(size: 12, weight: .bold, design: .default))
                .foregroundStyle(selected ? theme.onAccent : theme.ink)
                .padding(.horizontal, 14).frame(minHeight: 44)
                .background(selected ? theme.tertiary : theme.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? theme.ink : theme.line, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(PressStyle()).accessibilityIdentifier("settings.prompt.\(option.rawValue)")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    // MARK: Appearance

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("Appearance", note: "6 free themes")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 11), count: 3), spacing: 13) {
                ForEach(AppTheme.all) { palette in themeOption(palette) }
            }
        }
    }

    private func themeOption(_ palette: AppTheme) -> some View {
        let selected = app.preferences.theme == palette.id
        return Button { app.selectTheme(palette.id) } label: {
            VStack(spacing: 11) {
                HStack(spacing: -8) {
                    Circle().fill(palette.secondary).frame(width: 26, height: 26)
                    Circle().fill(palette.accent).frame(width: 36, height: 36)
                    Circle().fill(palette.tertiary).frame(width: 22, height: 22)
                }
                .padding(.top, 5).accessibilityHidden(true)
                Text(palette.name).font(.system(size: 11, weight: .bold, design: .default))
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(palette.ink).frame(maxWidth: .infinity).padding(.vertical, 13)
            .card(palette.background, radius: 22, outlined: selected)
            .environment(\.colorScheme, palette.colorScheme)
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 15, weight: .bold))
                        .foregroundStyle(palette.ink).background(palette.background, in: Circle()).padding(8)
                }
            }
        }
        .buttonStyle(PressStyle()).accessibilityLabel(palette.name)
        .accessibilityAddTraits(selected ? [.isSelected] : []).accessibilityIdentifier("theme.\(palette.id.rawValue)")
    }

    // MARK: Sound and timing

    private var soundAndTiming: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("Sound & timing", note: "3 or 5 seconds")
            VStack(spacing: 20) {
                HStack {
                    Label("Countdown", systemImage: "timer")
                    Spacer()
                    HStack(spacing: 7) {
                        ForEach(Preferences.countdownChoices, id: \.self) { seconds in countdownOption(seconds) }
                    }
                }
                Rectangle().fill(theme.line).frame(height: 1)
                Toggle(isOn: Binding(get: { app.preferences.hapticsEnabled }, set: { app.setHaptics($0) })) {
                    Label("Haptics", systemImage: "waveform.path")
                }
                .accessibilityLabel("Haptics").accessibilityIdentifier("settings.haptics")
                Toggle(isOn: Binding(get: { app.preferences.soundEnabled }, set: { app.setSound($0) })) {
                    Label("Music & sound", systemImage: "music.note")
                }
                .accessibilityIdentifier("settings.sound")
            }
            .font(.system(size: 13, weight: .semibold, design: .default))
            .tint(theme.isDark ? Color(hex: 0x6F9045) : Color(hex: 0x588545))
            .padding(17).card(theme.surface, radius: 22)
        }
    }

    private func countdownOption(_ seconds: Int) -> some View {
        let selected = app.preferences.countdownSeconds == seconds
        return Button { app.setCountdown(seconds) } label: {
            Text("\(seconds)s").font(.system(size: 13, weight: .semibold, design: .default))
                .frame(width: 44, height: 44).foregroundStyle(selected ? theme.onAccent : theme.ink)
                .background(selected ? theme.accent : theme.background, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? theme.ink : theme.line, lineWidth: 1))
        }
        .buttonStyle(PressStyle()).accessibilityLabel("\(seconds) seconds")
        .accessibilityAddTraits(selected ? [.isSelected] : []).accessibilityIdentifier("settings.countdown.\(seconds)")
    }

    // MARK: Demo

    private var demoButton: some View {
        Button(action: demo) {
            HStack(spacing: 15) {
                Image(systemName: "play.circle").font(.system(size: 30, weight: .light)).foregroundStyle(theme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Try a round").font(.system(size: 15, weight: .semibold, design: .default))
                    Text("Preview with virtual players")
                        .font(.system(size: 11, weight: .medium, design: .default)).foregroundStyle(theme.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "play.fill").font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(theme.ink).padding(17).card(theme.tertiary.opacity(theme.isDark ? 0.10 : 0.3), radius: 24)
        }
        .buttonStyle(PressStyle()).accessibilityIdentifier("settings.demo")
    }

    private func sectionTitle(_ title: String, note: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(size: 17, weight: .semibold, design: .default)).tracking(-0.4)
            Spacer(minLength: 5)
            Text(note).font(.system(size: 10, weight: .semibold, design: .default)).foregroundStyle(theme.muted)
        }
    }
}
