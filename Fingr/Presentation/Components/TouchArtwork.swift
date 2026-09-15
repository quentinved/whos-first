import SwiftUI

/// A stable touch marker: light, color, and a player number.
struct TouchOrb: View {
    let color: Color
    var size: CGFloat = 84
    var number: Int? = nil
    var teamLabel: String? = nil
    var spotlight = false
    var selected = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var lit: Bool { spotlight || selected }
    private var foreground: Color {
        if selected { return AppTheme.inkOnAccent }
        return colorScheme == .dark ? .white : AppTheme.inkOnLight
    }

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(spotlight ? 0.18 : 0.06))
                .blur(radius: size * 0.18)
            Circle().stroke(color.opacity(lit ? 0.7 : 0.16), lineWidth: 1)
                .scaleEffect(lit ? 1.16 : 1.08)
            Circle().fill(selected ? color : color.opacity(spotlight ? 0.24 : 0.10))
                .overlay(Circle().strokeBorder(color.opacity(lit ? 1 : 0.7), lineWidth: spotlight ? 2.5 : 1.5))
            if let number {
                label(number: number)
            } else {
                Circle().fill(color).frame(width: size * 0.16, height: size * 0.16)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(spotlight && !reduceMotion ? 1.04 : 1)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.20), value: spotlight)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: selected)
        .accessibilityHidden(true)
    }

    private func label(number: Int) -> some View {
        VStack(spacing: 3) {
            if let teamLabel {
                Text(teamLabel).font(.system(size: size * 0.15, weight: .medium))
            }
            Text(String(number)).font(.system(size: size * 0.29, weight: .medium)).monospacedDigit()
        }
        .foregroundStyle(foreground)
    }
}

struct TouchInvitation: View {
    let theme: AppTheme
    var compact = false

    var body: some View {
        ZStack {
            Circle().fill(theme.accent.opacity(0.06)).blur(radius: 24)
            Circle().stroke(theme.accent.opacity(0.07), lineWidth: 1)
            Circle().stroke(theme.accent.opacity(0.15), lineWidth: 1).padding(25)
            Circle().stroke(theme.accent.opacity(0.40), lineWidth: 1).padding(50)
            Image(systemName: "touchid")
                .font(.system(size: compact ? 45 : 54, weight: .ultraLight))
                .foregroundStyle(theme.accent)
        }
        .frame(width: compact ? 210 : 250, height: compact ? 210 : 250)
        .accessibilityHidden(true)
    }
}

struct AmbientTexture: View {
    let theme: AppTheme

    var body: some View {
        Canvas { context, size in
            for x in stride(from: CGFloat(24), to: size.width, by: 48) {
                for y in stride(from: CGFloat(24), to: size.height, by: 48) {
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                                 with: .color(theme.ink.opacity(0.045)))
                }
            }
        }
        .accessibilityHidden(true).allowsHitTesting(false)
    }
}

enum GameCopy {
    static let dares = [
        "Pitch your ideal weekend in 15 seconds.",
        "Give your best celebrity impression.",
        "Name a song everyone here should hear.",
        "Tell a story in just two sentences.",
        "Defend your most controversial food opinion.",
        "Invent a slogan for this group.",
        "Describe the person to your left in three words.",
        "Name one thing on your bucket list."
    ]
}
