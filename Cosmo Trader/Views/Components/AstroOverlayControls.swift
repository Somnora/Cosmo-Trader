import SwiftUI

struct AstroOverlayControls: View {
    let filterState: AstroOverlayFilterState
    let onToggle: (AstroOverlayFilterOption) -> Void

    private let options: [AstroOverlayFilterOption] = [
        .init(label: "Moon Phases", kinds: [.newMoon, .fullMoon], icon: "moon.stars"),
        .init(label: "Mercury Rx", kinds: [.mercuryRetrograde], icon: "arrow.uturn.backward.circle"),
        .init(label: "Birth Month", kinds: [.companyBirthMonth], icon: "calendar"),
        .init(label: "Founding Day", kinds: [.companyFoundingAnniversary], icon: "building.2"),
        .init(label: "Moon In Sign", kinds: [.moonInSign], icon: "moon.haze")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options) { option in
                    let isEnabled = option.kinds.allSatisfy { filterState.enabledKinds.contains($0) }
                    let tint = chipTint(for: option)

                    Button {
                        onToggle(option)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: option.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(option.label.uppercased())
                                .font(TerminalFont.data(9, weight: .bold))
                                .tracking(0.5)
                        }
                        .foregroundColor(isEnabled ? tint : CosmicTheme.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isEnabled ? tint.opacity(0.14) : CosmicTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isEnabled ? tint.opacity(0.7) : CosmicTheme.border, lineWidth: 0.75)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(option.label) overlay")
                    .accessibilityValue(isEnabled ? "Enabled" : "Disabled")
                    .accessibilityAddTraits(isEnabled ? .isSelected : [])
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func chipTint(for option: AstroOverlayFilterOption) -> Color {
        option.kinds.first?.overlayColor ?? CosmicTheme.gold
    }
}

struct AstroOverlayFilterOption: Identifiable {
    let label: String
    let kinds: Set<AstroOverlayEventKind>
    let icon: String

    var id: String { label }
}
