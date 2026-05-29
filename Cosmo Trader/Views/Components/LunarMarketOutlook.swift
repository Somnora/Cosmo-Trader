import SwiftUI

// MARK: - Lunar Market Outlook
// ============================
// A comprehensive lunar market view showing current phase, trading signals,
// and historical volatility data. Presents lunar trading wisdom with appropriate
// skepticism: "Some traders watch this. Here's what they look for."

struct LunarMarketOutlook: View {

    // MARK: - Properties

    let lunarData: LunarData

    // MARK: - State

    @State private var showHistoricalInfo: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Section header
            sectionHeader

            // Main moon phase card
            prominentMoonDisplay

            // Trading signal card
            tradingSignalCard

            // Moon sign influence
            moonSignInfluence

            // Historical volatility (collapsible)
            historicalVolatilitySection

            // Disclaimer
            disclaimer
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    CosmicTheme.gold.opacity(0.3),
                                    CosmicTheme.nebulaBlue.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .font(.title3)
                .foregroundStyle(CosmicTheme.goldGradient)

            Text("Lunar Market Outlook")
                .font(TerminalFont.headline(18))
                .foregroundColor(CosmicTheme.textPrimary)

            Spacer()

            // Quick phase badge
            MoonPhaseBadge(lunarData: lunarData)
        }
    }

    // MARK: - Prominent Moon Display

    private var prominentMoonDisplay: some View {
        HStack(spacing: 20) {
            // Large moon visual with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                lunarData.phase.color.opacity(0.4),
                                lunarData.phase.color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 25,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                MoonVisual(
                    illumination: lunarData.illumination,
                    isWaxing: lunarData.isWaxing,
                    size: 70
                )
            }

            // Phase info
            VStack(alignment: .leading, spacing: 8) {
                Text(lunarData.phase.rawValue)
                    .font(TerminalFont.headline(20))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(lunarData.formattedIllumination + " illuminated")
                    .font(TerminalFont.data(13))
                    .foregroundColor(CosmicTheme.textSecondary)

                // Waxing/Waning indicator
                HStack(spacing: 6) {
                    Image(systemName: lunarData.isWaxing ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)

                    Text(lunarData.isWaxing ? "Waxing (Growing)" : "Waning (Shrinking)")
                        .font(TerminalFont.data(11))
                }
                .foregroundColor(lunarData.isWaxing ? CosmicTheme.positive : CosmicTheme.textMuted)

                // Days until significant phases
                HStack(spacing: 16) {
                    phaseCountdown("Full", days: lunarData.daysUntilFullMoon, icon: "circle.fill")
                    phaseCountdown("New", days: lunarData.daysUntilNewMoon, icon: "circle")
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }

    private func phaseCountdown(_ label: String, days: Int, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))

            Text("\(days)d")
                .font(TerminalFont.price(13))
                .foregroundColor(days <= 2 ? CosmicTheme.gold : CosmicTheme.textPrimary)
        }
    }

    // MARK: - Trading Signal Card

    private var tradingSignalCard: some View {
        let signal = lunarData.phase.tradingSignal

        return VStack(alignment: .leading, spacing: 12) {
            // Signal header
            HStack {
                Image(systemName: signal.type.icon)
                    .font(.title3)
                    .foregroundColor(signal.type.color)

                Text(signal.headline)
                    .font(TerminalFont.headline(16))
                    .foregroundColor(signal.type.color)

                Spacer()

                // Sentiment badge
                HStack(spacing: 4) {
                    Image(systemName: signal.sentiment.icon)
                        .font(.caption2)
                    Text(signal.sentiment.rawValue)
                        .font(TerminalFont.data(10, weight: .semibold))
                }
                .foregroundColor(signal.sentiment.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(signal.sentiment.color.opacity(0.15))
                )
            }

            // Signal summary
            Text(signal.summary)
                .font(TerminalFont.data(13))
                .foregroundColor(CosmicTheme.textSecondary)

            // Detailed description
            Text(signal.description)
                .font(TerminalFont.body(12))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(signal.type.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(signal.type.color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Moon Sign Influence

    private var moonSignInfluence: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                ZodiacSymbolView(sign: lunarData.moonSign, size: 24, color: elementColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Moon in \(lunarData.moonSign.displayName)")
                        .font(TerminalFont.headline(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("\(lunarData.moonSign.element.displayName) Sign")
                        .font(TerminalFont.data(11))
                        .foregroundColor(elementColor)
                }

                Spacer()

                // Element badge
                HStack(spacing: 4) {
                    ElementSymbolView(element: lunarData.moonSign.element, size: 12, color: elementColor)
                    Text(lunarData.moonSign.element.displayName)
                        .font(TerminalFont.data(10, weight: .semibold))
                }
                .foregroundColor(elementColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(elementColor.opacity(0.15))
                )
            }

            // Moon sign insight
            Text(lunarData.moonSignInsight)
                .font(TerminalFont.body(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)

            // Aligned stock types
            HStack(spacing: 8) {
                Text("Aligned sectors:")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)

                Text(lunarData.alignedStockTypes)
                    .font(TerminalFont.data(10, weight: .medium))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    // MARK: - Historical Volatility Section

    private var historicalVolatilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle header
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showHistoricalInfo.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(CosmicTheme.nebulaBlue)

                    Text("Historical Patterns")
                        .font(TerminalFont.headline(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Spacer()

                    Image(systemName: showHistoricalInfo ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
            .buttonStyle(.plain)

            if showHistoricalInfo {
                VStack(alignment: .leading, spacing: 16) {
                    // Full moon stat
                    volatilityStat(
                        LunarMarketStats.fullMoonVolatility,
                        isHighlighted: lunarData.phase == .fullMoon
                    )

                    // New moon stat
                    volatilityStat(
                        LunarMarketStats.newMoonStats,
                        isHighlighted: lunarData.phase == .newMoon
                    )

                    // Historical insight
                    Text(LunarMarketStats.historicalInsight)
                        .font(TerminalFont.body(11))
                        .foregroundColor(CosmicTheme.textMuted)
                        .lineSpacing(4)
                        .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    private func volatilityStat(_ stat: LunarVolatilityStat, isHighlighted: Bool) -> some View {
        HStack(spacing: 12) {
            // Phase icon
            stat.phase.sfImage
                .font(.title2)
                .foregroundColor(stat.phase.color)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(stat.phase.rawValue)
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    if isHighlighted {
                        Text("NOW")
                            .font(TerminalFont.data(9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(CosmicTheme.gold)
                            )
                    }
                }

                Text(stat.description)
                    .font(TerminalFont.body(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(2)
            }

            Spacer()

            // Volatility change
            VStack(alignment: .trailing, spacing: 2) {
                Text(stat.formattedChange)
                    .font(TerminalFont.price(14))
                    .foregroundColor((stat.averageVolatilityChange ?? 0) > 0 ? .orange : CosmicTheme.textSecondary)

                Text("market history")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHighlighted ? CosmicTheme.gold.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHighlighted ? CosmicTheme.gold.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)

            Text(LunarMarketStats.disclaimer)
                .font(TerminalFont.body(10))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CosmicTheme.background.opacity(0.5))
        )
    }

    // MARK: - Helpers

    private var elementColor: Color {
        switch lunarData.moonSign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Compact Lunar Widget

/// A smaller lunar widget for dashboard/summary views
struct LunarWidget: View {

    let lunarData: LunarData
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                // Moon visual
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    lunarData.phase.color.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 15,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)

                    MoonVisual(
                        illumination: lunarData.illumination,
                        isWaxing: lunarData.isWaxing,
                        size: 44
                    )
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(lunarData.phase.rawValue)
                        .font(TerminalFont.headline(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    // Trading signal
                    HStack(spacing: 4) {
                        Image(systemName: lunarData.phase.tradingSignal.type.icon)
                            .font(.caption2)
                        Text(lunarData.phase.tradingSignal.headline)
                            .font(TerminalFont.data(11))
                    }
                    .foregroundColor(lunarData.phase.tradingSignal.type.color)

                    // Moon sign
                    HStack(spacing: 4) {
                        Text("Moon in")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(lunarData.moonSign.displayName)
                            .font(TerminalFont.data(10, weight: .semibold))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(CosmicTheme.border, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lunar Alert Banner

/// Alert banner for significant lunar events (full/new moon)
struct LunarAlertBanner: View {

    let lunarData: LunarData
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Moon icon
            lunarData.phase.sfImage
                .font(.title2)
                .foregroundColor(CosmicTheme.gold)

            VStack(alignment: .leading, spacing: 2) {
                Text(alertTitle)
                    .font(TerminalFont.headline(13))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(alertMessage)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()

            if let dismiss = onDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(alertColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(alertColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var alertTitle: String {
        if lunarData.phase == .fullMoon {
            return "Full Moon Today"
        } else if lunarData.phase == .newMoon {
            return "New Moon Today"
        } else if lunarData.daysUntilFullMoon == 1 {
            return "Full Moon Tomorrow"
        } else if lunarData.daysUntilNewMoon == 1 {
            return "New Moon Tomorrow"
        }
        return "Lunar Update"
    }

    private var alertMessage: String {
        if lunarData.phase == .fullMoon {
            return "Full Moon marker. The market's emotions can feel louder."
        } else if lunarData.phase == .newMoon {
            return "New Moon marker. A quiet point for research notes."
        } else if lunarData.daysUntilFullMoon == 1 {
            return "Full Moon tomorrow. A calendar note, not a market call."
        } else if lunarData.daysUntilNewMoon == 1 {
            return "Cycle ending. Prepare for fresh energy."
        }
        return lunarData.phase.tradingSignal.summary
    }

    private var alertColor: Color {
        if lunarData.phase == .fullMoon || lunarData.daysUntilFullMoon == 1 {
            return .orange
        }
        return CosmicTheme.nebulaBlue
    }
}

// MARK: - Preview

#Preview("Lunar Market Outlook") {
    let service = MoonPhaseService.shared
    let data = service.getCurrentLunarData()

    return ScrollView {
        VStack(spacing: 24) {
            LunarMarketOutlook(lunarData: data)

            LunarWidget(lunarData: data)

            LunarAlertBanner(lunarData: data)
        }
        .padding()
    }
    .background(CosmicTheme.background)
}
