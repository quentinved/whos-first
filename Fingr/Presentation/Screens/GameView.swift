import SwiftUI
import FingrCore

struct GameView: View {
    let session: GameSession
    let theme: AppTheme
    let isMenuPresented: Bool
    let menu: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wasIdleTimerDisabled = false
    @State private var spotlightStep = 0
    @State private var dareOffset = 0

    private var round: Round { session.round }
    private var winners: [Finger] { round.winners }
    private var isTeamMode: Bool { round.mode == .teams }
    private var hasDare: Bool { !isTeamMode && session.prompt == .tinyDare }
    private var isCounting: Bool {
        if case .counting = round.phase { return true }
        return false
    }
    private var canAnimate: Bool {
        !reduceMotion && !isMenuPresented && scenePhase == .active && !LaunchArguments.isUITesting
    }
    private var animateSpotlight: Bool { isCounting && canAnimate }
    private var visibleFingers: [Finger] { round.isFinished && !isTeamMode ? winners : round.fingers }
    private var spotlightID: Int? {
        guard isCounting, !round.fingers.isEmpty else { return nil }
        let fingers = round.fingers.sorted { $0.slot < $1.slot }
        return fingers[spotlightStep % fingers.count].id
    }

    var body: some View {
        board
            .background(theme.background.ignoresSafeArea())
            .environment(\.colorScheme, theme.colorScheme)
            .preferredColorScheme(theme.colorScheme)
            .statusBarHidden()
            .persistentSystemOverlays(.hidden)
            .onAppear {
                wasIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
                updateIdleTimer()
            }
            .onDisappear {
                session.suspend()
                UIApplication.shared.isIdleTimerDisabled = wasIdleTimerDisabled
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { session.suspend() }
                updateIdleTimer()
            }
            .onChange(of: isMenuPresented) { updateIdleTimer() }
            .onChange(of: session.inputGeneration) { dareOffset = 0 }
            .task(id: animateSpotlight) { await runSpotlight() }
    }

    /// A single, stable coordinate space extends beneath all non-interactive chrome. Only
    /// the options and replay buttons sit above the touch surface.
    private var board: some View {
        ZStack {
            playArea.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                heading.allowsHitTesting(false)
                Spacer(minLength: 0)
                footer.frame(maxWidth: 540).padding(.bottom, 14)
            }
        }
    }

    /// The screen stays awake while a board is in front of the players. Anything else
    /// hands the system back whatever it had.
    private func updateIdleTimer() {
        let keepAwake = scenePhase == .active && !isMenuPresented
        UIApplication.shared.isIdleTimerDisabled = keepAwake || wasIdleTimerDisabled
    }

    /// Hops the highlight between fingers, faster as the countdown nears zero.
    private func runSpotlight() async {
        spotlightStep = 0
        guard animateSpotlight else { return }
        while !Task.isCancelled {
            guard case .counting(let remaining) = round.phase else { return }
            do { try await Task.sleep(for: .milliseconds(Self.spotlightInterval(remaining: remaining))) }
            catch { return }
            spotlightStep += 1
        }
    }

    private static func spotlightInterval(remaining: Int) -> Int {
        switch remaining {
        case 1: 85
        case 2: 135
        default: 210
        }
    }

    // MARK: Header and heading

    private var header: some View {
        HStack {
            Text("who's first").font(.system(size: 27, weight: .bold, design: .default)).tracking(-1.2)
                .lineLimit(1).minimumScaleFactor(0.7)
                .accessibilityLabel("Who's First")
                .allowsHitTesting(false)
            Spacer()
            CircleButton(icon: "slider.horizontal.3", label: "Game options", theme: theme, action: menu)
                .accessibilityIdentifier("game.menu")
        }
        .foregroundStyle(theme.ink).padding(.horizontal, 24).padding(.vertical, 8)
    }

    private var heading: some View {
        VStack(spacing: 5) {
            if case .counting(let remaining) = round.phase {
                countdownHeading(remaining)
            } else {
                titleHeading
            }
            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .default)).foregroundStyle(theme.muted)
                .lineLimit(1).minimumScaleFactor(0.8)
                .accessibilityIdentifier("game.selectionRule")
        }
        .padding(.horizontal, 22).frame(height: 77)
    }

    private func countdownHeading(_ remaining: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(remaining)").font(.system(size: 31, weight: .bold, design: .default))
                .foregroundStyle(theme.onAccent)
                .contentTransition(.numericText(countsDown: true))
                .frame(width: 46, height: 46).background(theme.accent, in: Circle())
                .overlay(Circle().strokeBorder(theme.ink, lineWidth: 1.5))
                .accessibilityIdentifier("game.countdown")
            Text("Hold steady.")
                .font(.system(size: 27, weight: .semibold, design: .default)).tracking(-0.8)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .foregroundStyle(theme.ink).frame(height: 43)
        .animation(reduceMotion ? nil : .spring(response: 0.3), value: remaining)
    }

    private var titleHeading: some View {
        Text(title)
            .font(.system(size: hasDare ? 27 : 30, weight: .semibold, design: .default)).tracking(-0.9)
            .foregroundStyle(theme.ink).multilineTextAlignment(.center)
            .lineLimit(2).minimumScaleFactor(0.8).frame(height: 43)
            .accessibilityIdentifier(titleIdentifier)
    }

    private var title: String {
        if round.isFinished {
            if isTeamMode { return "Teams are set." }
            if winners.count == 1, let winner = winners.first { return "Player \(winner.number)" }
            return "\(winners.count) selected"
        }
        if isTeamMode { return "Who teams up?" }
        return session.prompt == .justForFun ? "Who's the one?" : session.prompt.question
    }

    private var titleIdentifier: String {
        guard round.isFinished else { return "game.question" }
        return isTeamMode ? "game.teamsResult" : "game.winner"
    }

    private var subtitle: String {
        guard round.isFinished else { return selectionRule }
        if isTeamMode { return "Find your color." }
        return session.prompt == .justForFun ? "You're the one." : session.prompt.result(winnerCount: winners.count)
    }

    private var selectionRule: String {
        let players = round.playerCount.map { "Wait for \($0) players" } ?? "\(round.requiredPlayers)+ players"
        return isTeamMode ? "2 balanced teams · \(players)" : "Keep \(round.winnerCount) · \(players)"
    }

    // MARK: Play area

    private var playArea: some View {
        GeometryReader { geometry in
            ZStack {
                boardBackground(size: geometry.size)
                if round.fingers.isEmpty {
                    emptyState(compact: geometry.size.height < 700)
                        .frame(maxWidth: .infinity, maxHeight: .infinity).transition(.opacity)
                }
                ForEach(visibleFingers) { finger in
                    orb(for: finger, in: geometry.size)
                }
            }
            .allowsHitTesting(false)
            .overlay {
                MultiTouchSurface(generation: session.inputGeneration, requiredPlayers: round.requiredPlayers,
                                  onInput: session.receive)
                    .allowsHitTesting(!isMenuPresented)
            }
            .clipped()
            .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.7),
                       value: visibleFingers.map(\.id))
            .animation(reduceMotion ? nil : .spring(response: 0.35), value: round.isFinished)
        }
    }

    private func boardBackground(size: CGSize) -> some View {
        ZStack {
            theme.background
            RadialGradient(colors: [theme.secondary.opacity(theme.isDark ? 0.13 : 0.20), .clear],
                           center: UnitPoint(x: 0.8, y: 0.42), startRadius: 10, endRadius: size.height * 0.6)
            RadialGradient(colors: [theme.accent.opacity(theme.isDark ? 0.06 : 0.18), .clear],
                           center: UnitPoint(x: 0.05, y: 0.72), startRadius: 0, endRadius: size.width * 0.9)
            AmbientTexture(theme: theme)
        }
    }

    private func orb(for finger: Finger, in size: CGSize) -> some View {
        let color = color(for: finger)
        let lit = spotlightID == finger.id
        return TouchOrb(color: color, size: orbSize, number: finger.number,
                        teamLabel: round.team(for: finger.id)?.rawValue,
                        spotlight: lit, selected: round.isFinished && !isTeamMode)
            .shadow(color: color.opacity(theme.isDark ? 0.25 : 0), radius: lit ? 26 : 14)
            .position(x: finger.position.x * size.width, y: finger.position.y * size.height)
            .transition(.scale(scale: 0.1).combined(with: .opacity))
    }

    private var orbSize: CGFloat {
        if round.isFinished && winners.count == 1 { return 100 }
        return round.fingers.count > 6 ? 65 : 82
    }

    private func color(for finger: Finger) -> Color {
        round.team(for: finger.id).map(theme.teamColor) ?? theme.fingerColor(finger.slot)
    }

    private func emptyState(compact: Bool) -> some View {
        VStack(spacing: compact ? 22 : 30) {
            TouchInvitation(theme: theme, compact: compact)
            VStack(spacing: 10) {
                Text("Leave it to chance.")
                    .font(.system(size: 26, weight: .medium)).tracking(-0.6)
                Text("Touch anywhere. One finger each.")
                    .font(.system(size: 13)).foregroundStyle(theme.muted)
            }
            .foregroundStyle(theme.ink)
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 9) {
            if round.isFinished { resultFooter } else { gatheringFooter }
        }
        .padding(.horizontal, 21).padding(.bottom, 5)
    }

    @ViewBuilder private var resultFooter: some View {
        if isTeamMode {
            teamSummary.allowsHitTesting(false)
        } else if hasDare {
            dareCard
        } else {
            Text("Decision made.")
                .font(.system(size: 13, weight: .bold, design: .default)).foregroundStyle(theme.ink)
                .allowsHitTesting(false)
        }
        if !isTeamMode { winnerList }
        PrimaryButton(title: replayTitle, theme: theme, icon: "arrow.clockwise") { session.reset() }
            .accessibilityIdentifier("game.again")
    }

    private var replayTitle: String {
        if session.isDemo { return "Start playing" }
        return isTeamMode ? "Shuffle teams" : "Play again"
    }

    private var winnerList: some View {
        Text(winners.map { "Player \($0.number)" }.joined(separator: " · "))
            .font(.system(size: 10, weight: .semibold, design: .default)).foregroundStyle(theme.muted)
            .lineLimit(1).minimumScaleFactor(0.7)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(winners.count) \(winners.count == 1 ? "finger" : "fingers") selected")
            .accessibilityIdentifier("game.selectedCount")
            .allowsHitTesting(false)
    }

    @ViewBuilder private var gatheringFooter: some View {
        HStack(spacing: 8) {
            playerDots
            Text(playerStatus).font(.system(size: 12, weight: .bold, design: .default))
                .foregroundStyle(theme.ink).lineLimit(1).minimumScaleFactor(0.75)
                .accessibilityIdentifier("game.status")
        }
        .padding(.horizontal, 14).padding(.vertical, 10).background(theme.surface, in: Capsule())
        .allowsHitTesting(false)
        Text(partyCaption).font(.system(size: 11, weight: .medium, design: .default))
            .foregroundStyle(theme.muted).lineLimit(1).minimumScaleFactor(0.8)
            .allowsHitTesting(false)
        if session.isDemo {
            Button("Practice round · End") { session.reset() }
                .font(.system(size: 12, weight: .bold, design: .default)).foregroundStyle(theme.ink)
                .frame(minHeight: 44)
                .buttonStyle(PressStyle()).accessibilityIdentifier("game.endDemo")
        }
    }

    /// One dot per expected seat, in the colour of whoever is holding it.
    private var playerDots: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(round.requiredPlayers, round.fingers.count), id: \.self) { index in
                Circle().fill(dotColor(at: index))
                    .frame(width: 7, height: 7)
                    .overlay(Circle().stroke(theme.ink.opacity(0.2), lineWidth: 0.5))
            }
        }
    }

    private func dotColor(at index: Int) -> Color {
        guard index < round.fingers.count else { return theme.ink.opacity(0.12) }
        return theme.fingerColor(round.fingers[index].slot)
    }

    private var playerStatus: String {
        let count = round.fingers.count
        if count < round.requiredPlayers {
            if count == 0 && round.playerCount == nil { return "Waiting for players" }
            return "\(count) in · Waiting for \(round.requiredPlayers - count) more"
        }
        if isTeamMode { return "\(count) in · \((count + 1) / 2) vs \(count / 2) · Hold…" }
        return "\(count) fingers in · Hold…"
    }

    private var partyCaption: String {
        switch round.phase {
        case .counting(let seconds):
            if seconds == 1 { return "Here we go." }
            if seconds == 2 { return "Almost there." }
            return "Making the call…"
        default:
            if round.fingers.count == 1 { return "Keep holding. Waiting for another player." }
            return hasDare ? "One pick. One challenge." : "Touch. Hold. Find out."
        }
    }

    private var dareCard: some View {
        HStack(spacing: 9) {
            VStack(alignment: .leading, spacing: 5) {
                TinyLabel(text: "Your challenge", color: theme.ink)
                Text(GameCopy.dares[(session.inputGeneration + dareOffset) % GameCopy.dares.count])
                    .font(.system(size: 12, weight: .semibold, design: .default)).foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("game.dare")
            }
            .allowsHitTesting(false)
            Spacer(minLength: 0)
            Button { dareOffset += 1 } label: {
                Image(systemName: "shuffle").font(.system(size: 15, weight: .bold)).foregroundStyle(theme.ink)
                    .frame(width: 44, height: 44).background(theme.surface.opacity(0.7), in: Circle())
            }
            .buttonStyle(PressStyle()).accessibilityLabel("Another challenge")
            .accessibilityIdentifier("game.dare.shuffle")
        }
        .padding(.horizontal, 13).padding(.vertical, 10)
        .card(theme.isDark ? theme.surface : theme.tertiary.opacity(0.4), radius: 19)
    }

    private var teamSummary: some View {
        HStack(spacing: 10) {
            ForEach(round.teams) { team in
                teamCard(team)
            }
        }
    }

    private func teamCard(_ team: Team) -> some View {
        let count = team.members.count
        let numbers = team.members.map { String($0.number) }.joined(separator: ", ")
        return HStack(spacing: 9) {
            Text(team.id.rawValue).font(.system(size: 18, weight: .bold, design: .default))
                .frame(width: 32, height: 32).background(.white.opacity(0.65), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Team \(team.id.rawValue)")
                    .font(.system(size: 12, weight: .semibold, design: .default)).lineLimit(1).minimumScaleFactor(0.8)
                Text("\(count) \(count == 1 ? "player" : "players")")
                    .font(.system(size: 10, weight: .medium, design: .default))
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(theme.onAccent).padding(10).frame(maxWidth: .infinity)
        .card(theme.teamColor(team.id), radius: 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Team \(team.id.rawValue), \(count) players. Fingers \(numbers).")
        .accessibilityIdentifier("game.team.\(team.id.rawValue)")
    }
}
