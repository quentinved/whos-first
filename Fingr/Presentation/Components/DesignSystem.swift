import SwiftUI

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

/// A rounded card. The opaque base under the tint keeps translucent theme colours readable
/// on either colour scheme, which matters in the theme picker where every card renders in
/// its own scheme.
struct CardSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let color: Color
    var radius: CGFloat = 18
    var outlined = false

    private var base: Color { colorScheme == .dark ? AppTheme.nightBackground : .white }
    private var border: Color {
        let ink = colorScheme == .dark ? Color.white : AppTheme.inkOnLight
        return ink.opacity(outlined ? 0.24 : 0.10)
    }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: radius).fill(base)
                    RoundedRectangle(cornerRadius: radius).fill(color)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(border, lineWidth: 1))
            .compositingGroup()
    }
}

extension View {
    func card(_ color: Color, radius: CGFloat = 18, outlined: Bool = false) -> some View {
        modifier(CardSurface(color: color, radius: radius, outlined: outlined))
    }
}

struct PrimaryButton: View {
    let title: String
    let theme: AppTheme
    var icon = "arrow.up.right"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Spacer(minLength: 0)
                Text(title).font(.system(size: 17, weight: .semibold, design: .default))
                Image(systemName: icon).font(.system(size: 15, weight: .bold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(theme.onAccent)
            .padding(.horizontal, 20).frame(minHeight: 52)
            .card(theme.accent, radius: 20, outlined: true)
        }
        .buttonStyle(PressStyle())
    }
}

struct CircleButton: View {
    let icon: String
    let label: String
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.ink).frame(width: 46, height: 46)
                .card(theme.surface, radius: 17, outlined: true)
        }
        .buttonStyle(PressStyle()).accessibilityLabel(label)
    }
}

struct TinyLabel: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased()).font(.system(size: 10, weight: .semibold, design: .default))
            .tracking(1.3).foregroundStyle(color)
    }
}

/// One tap applies the choice; no confirmation step and no stepping through values.
struct ChoiceChip: View {
    let title: String
    let selected: Bool
    let theme: AppTheme
    var label: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 14, weight: .semibold, design: .default)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(selected ? theme.onAccent : theme.ink)
                .padding(.horizontal, 6).frame(maxWidth: .infinity, minHeight: 44)
                .background(selected ? theme.accent : theme.background, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? theme.ink : theme.line, lineWidth: 1))
                // The adaptive grid sizes the cell, not the label, so without an
                // explicit shape the tappable area collapses on regular-width
                // layouts and the chip stops responding on iPad.
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle()).accessibilityLabel(label ?? title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

/// Grid of chips that wraps instead of scrolling, so every value stays one tap away.
struct ChipGrid<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 6)], spacing: 6) { content }
    }
}
