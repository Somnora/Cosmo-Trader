import SwiftUI

// MARK: - MoonWidgetView
// ======================
// A prominent moon phase widget for swing traders.
// Features:
// - Custom drawn moon phase circle with shadow mask
// - Monospace trading signal warning label
// - Terminal-style aesthetic matching the app theme
//
// DESIGN PHILOSOPHY:
// - "Serious trading tool" appearance
// - High visibility trading signal in monospace
// - Tappable for detailed lunar view

struct MoonWidgetView: View {

    // MARK: - Properties

    let lunarData: LunarData
    var onTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: 16) {
                // Top row: Moon visual + Phase info
                HStack(spacing: 20) {
                    // Custom drawn moon with glow
                    moonDisplay

                    // Phase details
                    phaseInfo

                    Spacer()

                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }

                // Trading signal bar - monospace warning label
                tradingSignalBar
            }
            .padding(16)
            .background(widgetBackground)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view lunar details")
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let signal = lunarData.phase.tradingSignal
        return "\(lunarData.phase.rawValue), \(lunarData.formattedIllumination) illuminated. Trading signal: \(signal.headline)"
    }

    // MARK: - Moon Display

    private var moonDisplay: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            lunarData.phase.color.opacity(0.4),
                            lunarData.phase.color.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 45
                    )
                )
                .frame(width: 90, height: 90)

            // Custom drawn moon
            MoonVisual(
                illumination: lunarData.illumination,
                isWaxing: lunarData.isWaxing,
                size: 56
            )
        }
    }

    // MARK: - Phase Info

    private var phaseInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Phase name
            Text(lunarData.phase.rawValue.uppercased())
                .font(TerminalFont.ticker(16))
                .foregroundColor(CosmicTheme.textPrimary)

            // Illumination percentage - monospace
            Text(lunarData.formattedIllumination + " illuminated")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)

            // Waxing/Waning indicator
            HStack(spacing: 4) {
                Image(systemName: lunarData.isWaxing ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 10))

                Text(lunarData.isWaxing ? "WAXING" : "WANING")
                    .font(TerminalFont.data(10, weight: .semibold))
            }
            .foregroundColor(lunarData.isWaxing ? CosmicTheme.positive : CosmicTheme.textMuted)

            // Days until significant phases
            HStack(spacing: 12) {
                phaseCountdown("FULL", days: lunarData.daysUntilFullMoon, emoji: "🌕")
                phaseCountdown("NEW", days: lunarData.daysUntilNewMoon, emoji: "🌑")
            }
        }
    }

    private func phaseCountdown(_ label: String, days: Int, emoji: String) -> some View {
        HStack(spacing: 3) {
            Text(emoji)
                .font(.system(size: 10))

            Text("\(days)d")
                .font(TerminalFont.price(11))
                .foregroundColor(days <= 2 ? CosmicTheme.gold : CosmicTheme.textSecondary)
        }
    }

    // MARK: - Trading Signal Bar (Monospace Warning Label)

    private var tradingSignalBar: some View {
        let signal = lunarData.phase.tradingSignal

        return HStack(spacing: 10) {
            // Signal type icon
            Image(systemName: signal.type.icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(signal.type.color)

            // Monospace trading signal text
            Text(signal.headline.uppercased())
                .font(TerminalFont.ticker(13))
                .foregroundColor(signal.type.color)

            Spacer()

            // Sentiment badge
            HStack(spacing: 4) {
                Image(systemName: signal.sentiment.icon)
                    .font(.system(size: 10))

                Text(signal.sentiment.rawValue.uppercased())
                    .font(TerminalFont.data(9, weight: .bold))
            }
            .foregroundColor(signal.sentiment.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(signal.sentiment.color.opacity(0.15))
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(signal.type.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(signal.type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Widget Background

    private var widgetBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(CosmicTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                lunarData.phase.color.opacity(0.4),
                                CosmicTheme.border.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Compact Moon Widget

/// Even more compact version for tight spaces
struct CompactMoonWidget: View {

    let lunarData: LunarData
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Moon visual
                MoonVisual(
                    illumination: lunarData.illumination,
                    isWaxing: lunarData.isWaxing,
                    size: 36
                )

                // Phase name and signal
                VStack(alignment: .leading, spacing: 2) {
                    Text(lunarData.phase.rawValue)
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    // Monospace signal
                    Text(lunarData.phase.tradingSignal.headline)
                        .font(TerminalFont.data(10))
                        .foregroundColor(lunarData.phase.tradingSignal.type.color)
                }

                Spacer()

                // Signal type icon
                Image(systemName: lunarData.phase.tradingSignal.type.icon)
                    .font(.caption)
                    .foregroundColor(lunarData.phase.tradingSignal.type.color)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.border, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Moon Trading Signal Strip

/// Horizontal strip showing just the trading signal in monospace
struct MoonSignalStrip: View {

    let lunarData: LunarData

    var body: some View {
        let signal = lunarData.phase.tradingSignal

        HStack(spacing: 8) {
            // Moon emoji
            Text(lunarData.phase.emoji)
                .font(.system(size: 14))

            // Phase
            Text(lunarData.phase.rawValue.uppercased())
                .font(TerminalFont.data(11, weight: .semibold))
                .foregroundColor(CosmicTheme.textSecondary)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(width: 1, height: 14)

            // Signal icon
            Image(systemName: signal.type.icon)
                .font(.system(size: 12))
                .foregroundColor(signal.type.color)

            // Monospace signal text
            Text(signal.headline.uppercased())
                .font(TerminalFont.ticker(11))
                .foregroundColor(signal.type.color)

            Spacer()

            // Sentiment
            Text(signal.sentiment.rawValue.uppercased())
                .font(TerminalFont.data(9, weight: .bold))
                .foregroundColor(signal.sentiment.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CosmicTheme.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(signal.type.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview("Moon Widget View") {
    let service = MoonPhaseService.shared
    let data = service.getCurrentLunarData()

    return ScrollView {
        VStack(spacing: 24) {
            Text("MOON WIDGET")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            MoonWidgetView(lunarData: data)

            Divider()
                .background(CosmicTheme.border)

            Text("COMPACT WIDGET")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            CompactMoonWidget(lunarData: data)

            Divider()
                .background(CosmicTheme.border)

            Text("SIGNAL STRIP")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            MoonSignalStrip(lunarData: data)
        }
        .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("All Moon Phases") {
    let service = MoonPhaseService.shared

    // Generate sample data for different phases
    let phases: [(MoonPhase, Double, Bool)] = [
        (.newMoon, 0.02, true),
        (.waxingCrescent, 0.25, true),
        (.firstQuarter, 0.50, true),
        (.waxingGibbous, 0.75, true),
        (.fullMoon, 0.98, false),
        (.waningGibbous, 0.75, false),
        (.lastQuarter, 0.50, false),
        (.waningCrescent, 0.25, false)
    ]

    return ScrollView {
        VStack(spacing: 16) {
            ForEach(phases, id: \.0) { phase, illumination, isWaxing in
                let mockData = LunarData(
                    phase: phase,
                    illumination: illumination,
                    isWaxing: isWaxing,
                    moonSign: .cancer,
                    daysUntilFullMoon: 7,
                    daysUntilNewMoon: 14
                )

                MoonSignalStrip(lunarData: mockData)
            }
        }
        .padding()
    }
    .background(CosmicTheme.background)
}
