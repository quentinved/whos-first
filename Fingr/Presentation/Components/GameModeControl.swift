import SwiftUI
import FingrCore

struct GameModeControl: View {
    @Binding var mode: GameMode
    let theme: AppTheme
    let identifierPrefix: String

    var body: some View {
        HStack(spacing: 12) {
            option(.picker, title: "Pick", detail: "One or more winners")
            option(.teams, title: "Teams", detail: "Two balanced groups")
        }
    }

    private func option(_ value: GameMode, title: String, detail: String) -> some View {
        let selected = mode == value
        return Button { mode = value } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Image(systemName: value == .picker ? "scope" : "circle.grid.2x2")
                        .font(.system(size: 29, weight: .light))
                        .foregroundStyle(tint(for: value))
                        .frame(height: 38)
                    Spacer(minLength: 0)
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(theme.ink.opacity(selected ? 1 : 0.22))
                }
                Text(title).font(.system(size: 17, weight: .semibold, design: .default))
                Text(detail).font(.system(size: 10, weight: .medium, design: .default)).foregroundStyle(theme.muted)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(theme.ink).padding(14).frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
            .card(cardColor(for: value, selected: selected), radius: 25, outlined: selected)
            .overlay(RoundedRectangle(cornerRadius: 25)
                .strokeBorder(selected ? theme.accent : .clear, lineWidth: theme.isDark ? 1.5 : 0))
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(value == .picker ? "Pick fingers" : "Team mode")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier("\(identifierPrefix).\(value.rawValue)")
    }

    private func tint(for value: GameMode) -> Color {
        value == .picker ? theme.accent : theme.secondary
    }

    private func cardColor(for value: GameMode, selected: Bool) -> Color {
        guard selected else { return theme.surface }
        return tint(for: value).opacity(theme.isDark ? 0.13 : 0.45)
    }
}

struct TeamModeInfo: View {
    let theme: AppTheme
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "equal").font(.system(size: 21)).foregroundStyle(theme.onAccent)
                .frame(width: 42, height: 42).background(theme.secondary, in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 4) {
                Text("Everyone gets a team.").font(.system(size: 14, weight: .bold, design: .default))
                Text("4 → 2 + 2 · 6 → 3 + 3 · Odd groups stay balanced")
                    .font(.system(size: 10, weight: .medium, design: .default)).foregroundStyle(theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(theme.ink).padding(14).card(theme.surface, radius: 22)
    }
}
