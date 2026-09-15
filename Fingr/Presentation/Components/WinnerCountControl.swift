import SwiftUI
import FingrCore

/// Tapping a number sets it straight away; there is nothing else to confirm.
struct WinnerCountControl: View {
    @Binding var count: Int
    let theme: AppTheme
    let identifierPrefix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Winners").font(.system(size: 14, weight: .bold, design: .default))
                Text("Keep \(count) · Needs \(count + 1)+ players")
                    .font(.system(size: 11, weight: .medium, design: .default)).foregroundStyle(theme.muted)
                    .accessibilityIdentifier("\(identifierPrefix).value")
            }
            ChipGrid {
                ForEach(Round.winnerCountRange, id: \.self) { value in
                    ChoiceChip(title: "\(value)", selected: count == value, theme: theme,
                               label: value == 1 ? "Keep 1 finger" : "Keep \(value) fingers") { count = value }
                        .accessibilityIdentifier("\(identifierPrefix).\(value)")
                }
            }
        }
        .foregroundStyle(theme.ink).padding(14).card(theme.surface, radius: 22)
        .accessibilityElement(children: .contain)
    }
}
