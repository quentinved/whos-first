import SwiftUI
import FingrCore

struct ContentView: View {
    // StateObject creates the adapters and session once, even when SwiftUI recreates this view.
    @StateObject private var container = AppContainer()
    @State private var prompt = DecisionPrompt.justForFun
    @State private var showOptions = false
    @State private var demoAfterOptions = false
    @Environment(\.scenePhase) private var scenePhase

    private var session: GameSession { container.session }
    private var theme: AppTheme { .resolve(container.app.preferences.theme) }

    var body: some View {
        GameView(session: session, theme: theme, isMenuPresented: showOptions) {
            session.pauseForConfiguration()
            container.app.play(.selection)
            showOptions = true
        }
        .tint(theme.ink)
        .task { container.start() }
        .sheet(isPresented: $showOptions, onDismiss: {
            session.resumeAfterConfiguration(prompt: prompt)
            if demoAfterOptions && scenePhase == .active { session.startDemo() }
            demoAfterOptions = false
        }) {
            SettingsView(app: container.app, prompt: $prompt) {
                showOptions = false
            } demo: {
                demoAfterOptions = true
                showOptions = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
            .presentationBackground(theme.background)
            .preferredColorScheme(theme.colorScheme)
        }
    }
}

#Preview {
    ContentView()
}
