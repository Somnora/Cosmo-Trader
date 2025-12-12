import SwiftUI

// MARK: - LunarCycleView
// ======================
// Terminal-style lunar market cycle display.
// Presents moon phases as legitimate market cycle indicators
// with data-driven precision and professional formatting.
//
// Real swing traders use lunar cycles. This presents the data
// factually — the user decides if they believe it.

struct LunarCycleView: View {

    // MARK: - Properties

    let lunarData: LunarData
    var showDetailedStats: Bool = true
    var onTap: (() -> Void)?

    // MARK: - Computed

    private var marketPhase: MarketCyclePhase {
        MarketCyclePhase.from(lunarData: lunarData)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            sectionHeader

            // Main content
            VStack(spacing: 0) {
                // Primary data rows
                dataSection

                // Divider
                terminalDivider

                // Signal section
                signalSection

                // Divider
                terminalDivider

                // Countdown section
                countdownSection

                if showDetailedStats {
                    terminalDivider
                    historicalDataSection
                }
            }
            .background(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(CosmicTheme.gold)
                .frame(width: 4, height: 16)

            Text("LUNAR MARKET CYCLE")
                .font(TerminalFont.data(11, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)
                .tracking(1.5)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 0.5)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Data Section

    private var dataSection: some View {
        VStack(spacing: 0) {
            // Phase row
            dataRow(
                label: "PHASE",
                value: marketPhase.displayName,
                detail: "(\(lunarData.phase.rawValue))",
                valueColor: marketPhase.color
            )

            // Illumination row
            dataRow(
                label: "ILLUMINATION",
                value: String(format: "%.1f%%", lunarData.illumination * 100),
                detail: lunarData.isWaxing ? "WAXING" : "WANING",
                valueColor: CosmicTheme.textPrimary
            )

            // Moon sign row with element
            dataRow(
                label: "MOON SIGN",
                value: lunarData.moonSign.displayName,
                detail: "(\(lunarData.moonSign.element.displayName) Sector)",
                valueColor: elementColor(for: lunarData.moonSign.element)
            )
        }
    }

    private func dataRow(label: String, value: String, detail: String?, valueColor: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textMuted)
                .frame(width: 110, alignment: .leading)

            Text(value)
                .font(TerminalFont.price(13))
                .foregroundColor(valueColor)

            if let detail = detail {
                Text(" \(detail)")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .fill(CosmicTheme.border.opacity(0.3))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Signal Section

    private var signalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Signal header with icon
            HStack(spacing: 8) {
                Text("SIGNAL")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)

                Spacer()

                // Signal badge
                HStack(spacing: 4) {
                    Image(systemName: marketPhase.signalIcon)
                        .font(.system(size: 10, weight: .bold))

                    Text(marketPhase.signalText)
                        .font(TerminalFont.data(10, weight: .semibold))
                }
                .foregroundColor(marketPhase.signalColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Rectangle()
                        .fill(marketPhase.signalColor.opacity(0.15))
                )
            }

            // Strategy text
            Text(marketPhase.strategy)
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(2)

            // Element volatility note
            HStack(spacing: 6) {
                ElementSymbolView(element: lunarData.moonSign.element, size: 14)

                Text(elementVolatilityNote)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
            }
        }
        .padding(12)
    }

    private var elementVolatilityNote: String {
        switch lunarData.moonSign.element {
        case .fire:
            return "Fire Sector volatility elevated"
        case .earth:
            return "Stability favored, Earth Sector calm"
        case .air:
            return "Air Sector active, communication stocks in focus"
        case .water:
            return "Water Sector sensitive, emotional trading heightened"
        }
    }

    // MARK: - Countdown Section

    private var countdownSection: some View {
        HStack(spacing: 0) {
            // Next New Moon
            countdownItem(
                label: "NEXT NEW MOON",
                days: lunarData.daysUntilNewMoon,
                date: nextPhaseDate(.newMoon),
                icon: "circle",
                isHighlighted: lunarData.daysUntilNewMoon <= 2
            )

            // Divider
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(width: 0.5)

            // Next Full Moon
            countdownItem(
                label: "NEXT FULL MOON",
                days: lunarData.daysUntilFullMoon,
                date: nextPhaseDate(.fullMoon),
                icon: "circle.fill",
                isHighlighted: lunarData.daysUntilFullMoon <= 2
            )
        }
    }

    private func countdownItem(label: String, days: Int, date: String, icon: String, isHighlighted: Bool) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(isHighlighted ? CosmicTheme.gold : CosmicTheme.textMuted)

                Text(label)
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Text("\(days) days")
                .font(TerminalFont.price(16))
                .foregroundColor(isHighlighted ? CosmicTheme.gold : CosmicTheme.textPrimary)

            Text(date)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func nextPhaseDate(_ phase: MoonPhase) -> String {
        let service = MoonPhaseService.shared
        let date = service.getNextPhase(phase)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Historical Data Section

    private var historicalDataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HISTORICAL PATTERN")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)

                Spacer()

                Text("S&P 500 (1950-2024)")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            // Volatility stat
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12))
                    .foregroundColor(CosmicTheme.gold.opacity(0.7))

                Text("0.8% higher volatility within ±2 days of full moons")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Disclaimer
            Text("Pattern observation, not guarantee. Make informed decisions.")
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .italic()
        }
        .padding(12)
        .background(CosmicTheme.secondaryBackground.opacity(0.5))
    }

    // MARK: - Helpers

    private var terminalDivider: some View {
        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 0.5)
    }

    private func elementColor(for element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Market Cycle Phase

/// Maps lunar phases to market cycle terminology
enum MarketCyclePhase: String, CaseIterable {
    case accumulation = "ACCUMULATION"
    case expansion = "EXPANSION"
    case distribution = "DISTRIBUTION"
    case correction = "CORRECTION"
    case consolidation = "CONSOLIDATION"

    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .accumulation:  return CosmicTheme.positive
        case .expansion:     return CosmicTheme.positive.opacity(0.8)
        case .distribution:  return .orange
        case .correction:    return CosmicTheme.negative.opacity(0.8)
        case .consolidation: return CosmicTheme.textSecondary
        }
    }

    var signalText: String {
        switch self {
        case .accumulation:  return "BULLISH SETUP"
        case .expansion:     return "BUILDING MOMENTUM"
        case .distribution:  return "HIGH VOLATILITY WARNING"
        case .correction:    return "COOLING PERIOD"
        case .consolidation: return "QUIET BEFORE RESET"
        }
    }

    var signalIcon: String {
        switch self {
        case .accumulation:  return "plus.circle.fill"
        case .expansion:     return "arrow.up.right.circle.fill"
        case .distribution:  return "exclamationmark.triangle.fill"
        case .correction:    return "arrow.down.right.circle.fill"
        case .consolidation: return "clock.fill"
        }
    }

    var signalColor: Color {
        switch self {
        case .accumulation:  return CosmicTheme.positive
        case .expansion:     return CosmicTheme.positive
        case .distribution:  return .orange
        case .correction:    return CosmicTheme.negative
        case .consolidation: return CosmicTheme.textSecondary
        }
    }

    var strategy: String {
        switch self {
        case .accumulation:
            return "Initiate new positions. Low visibility = opportunity. Research and build foundation for the cycle ahead."
        case .expansion:
            return "Add to winning positions. Energy building. Momentum favors the prepared."
        case .distribution:
            return "Take profits on winners. Emotional trading peaks. Expect price swings and heightened volatility."
        case .correction:
            return "Reduce exposure. Reassess positions. The market takes a breath after the peak."
        case .consolidation:
            return "Research and wait. Next cycle loading. Use this quiet period to plan ahead."
        }
    }

    /// Map lunar data to market cycle phase
    static func from(lunarData: LunarData) -> MarketCyclePhase {
        let illumination = lunarData.illumination

        // New Moon zone (0-3% illumination)
        if illumination < 0.03 {
            return .accumulation
        }

        // Waxing phases (building toward full)
        if lunarData.isWaxing {
            if illumination < 0.50 {
                return .expansion  // Waxing Crescent → First Quarter
            } else {
                return .distribution  // Waxing Gibbous → Full Moon
            }
        }

        // Waning phases (receding from full)
        if illumination > 0.50 {
            return .correction  // Waning Gibbous → Last Quarter
        }

        return .consolidation  // Waning Crescent
    }
}

// MARK: - Compact Lunar Cycle Strip

/// Horizontal strip version for tight spaces
struct LunarCycleStrip: View {

    let lunarData: LunarData

    private var marketPhase: MarketCyclePhase {
        MarketCyclePhase.from(lunarData: lunarData)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Moon visual
            MoonVisual(
                illumination: lunarData.illumination,
                isWaxing: lunarData.isWaxing,
                size: 28
            )

            // Phase info
            VStack(alignment: .leading, spacing: 2) {
                Text(marketPhase.displayName)
                    .font(TerminalFont.ticker(11))
                    .foregroundColor(marketPhase.color)

                Text("\(lunarData.phase.rawValue) · \(lunarData.formattedIllumination)")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()

            // Signal badge
            HStack(spacing: 4) {
                Image(systemName: marketPhase.signalIcon)
                    .font(.system(size: 10))

                Text(marketPhase.signalText)
                    .font(TerminalFont.data(9, weight: .semibold))
            }
            .foregroundColor(marketPhase.signalColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Rectangle()
                    .fill(marketPhase.signalColor.opacity(0.15))
            )
        }
        .padding(12)
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Lunar Data Card (Detailed)

/// Comprehensive lunar data for serious traders
struct LunarDataCard: View {

    let lunarData: LunarData
    @State private var showingDetail = false

    private var marketPhase: MarketCyclePhase {
        MarketCyclePhase.from(lunarData: lunarData)
    }

    var body: some View {
        Button(action: { showingDetail = true }) {
            LunarCycleView(lunarData: lunarData, showDetailedStats: true)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            LunarDetailSheet(lunarData: lunarData)
        }
    }
}

// MARK: - Lunar Detail Sheet

struct LunarDetailSheet: View {

    let lunarData: LunarData
    @Environment(\.dismiss) private var dismiss

    private var marketPhase: MarketCyclePhase {
        MarketCyclePhase.from(lunarData: lunarData)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Large moon visual
                    moonHeroSection

                    // Full cycle view
                    LunarCycleView(lunarData: lunarData, showDetailedStats: true)

                    // Moon sign analysis
                    moonSignSection

                    // Historical data section
                    historicalSection

                    // Notification settings
                    notificationSection
                }
                .padding()
            }
            .background(CosmicTheme.background)
            .navigationTitle("Lunar Market Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var moonHeroSection: some View {
        VStack(spacing: 16) {
            // Large moon with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                marketPhase.color.opacity(0.3),
                                marketPhase.color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                MoonVisual(
                    illumination: lunarData.illumination,
                    isWaxing: lunarData.isWaxing,
                    size: 120
                )
            }

            // Phase name
            Text(lunarData.phase.rawValue)
                .font(TerminalFont.headline(24))
                .foregroundColor(CosmicTheme.textPrimary)

            // Market phase
            Text(marketPhase.displayName)
                .font(TerminalFont.ticker(14))
                .foregroundColor(marketPhase.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Rectangle()
                        .fill(marketPhase.color.opacity(0.15))
                )
        }
    }

    private var moonSignSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Moon Sign Influence")

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZodiacSymbolView(sign: lunarData.moonSign, size: 32, color: elementColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Moon in \(lunarData.moonSign.displayName)")
                            .font(TerminalFont.ticker(14))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text("\(lunarData.moonSign.element.displayName) Sector Activated")
                            .font(TerminalFont.data(12))
                            .foregroundColor(elementColor)
                    }
                }

                Text(lunarData.moonSignInsight)
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(2)

                // Aligned stocks
                HStack(spacing: 8) {
                    Text("ALIGNED:")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(lunarData.alignedStockTypes)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
            .padding(16)
            .background(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
        }
    }

    private var elementColor: Color {
        switch lunarData.moonSign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var historicalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Historical Patterns")

            VStack(alignment: .leading, spacing: 12) {
                // Full moon stat
                statRow(
                    icon: "circle.fill",
                    label: "Full Moon Volatility",
                    value: "+0.8%",
                    detail: "S&P 500 shows higher volatility within ±2 days"
                )

                // New moon stat
                statRow(
                    icon: "circle",
                    label: "New Moon Returns",
                    value: "+0.3%",
                    detail: "Slightly higher average returns in 15 days following"
                )

                // Disclaimer
                Text(LunarMarketStats.disclaimer)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .italic()
                    .padding(.top, 8)
            }
            .padding(16)
            .background(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
        }
    }

    private func statRow(icon: String, label: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(CosmicTheme.gold)

                Text(label)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()

                Text(value)
                    .font(TerminalFont.price(13))
                    .foregroundColor(CosmicTheme.gold)
            }

            Text(detail)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
        }
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Lunar Alerts")

            VStack(spacing: 0) {
                notificationToggle(
                    title: "Full Moon Alerts",
                    subtitle: "24 hours before and on full moons",
                    isOn: Binding(
                        get: { MoonPhaseService.shared.notifyOnFullMoon },
                        set: {
                            MoonPhaseService.shared.notifyOnFullMoon = $0
                            MoonPhaseService.shared.scheduleNotifications()
                        }
                    )
                )

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(height: 0.5)

                notificationToggle(
                    title: "New Moon Alerts",
                    subtitle: "On new moon days — accumulation phase",
                    isOn: Binding(
                        get: { MoonPhaseService.shared.notifyOnNewMoon },
                        set: {
                            MoonPhaseService.shared.notifyOnNewMoon = $0
                            MoonPhaseService.shared.scheduleNotifications()
                        }
                    )
                )
            }
            .background(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
        }
    }

    private func notificationToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(subtitle)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .tint(CosmicTheme.gold)
        .padding(12)
    }
}

// MARK: - Preview

#Preview("Lunar Cycle View") {
    let mockData = LunarData(
        date: Date(),
        phase: .waxingGibbous,
        illumination: 0.73,
        age: 11.5,
        moonSign: .taurus,
        isWaxing: true
    )

    ScrollView {
        VStack(spacing: 24) {
            LunarCycleView(lunarData: mockData)

            LunarCycleStrip(lunarData: mockData)
        }
        .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("Full Moon Warning") {
    let mockData = LunarData(
        date: Date(),
        phase: .fullMoon,
        illumination: 0.98,
        age: 14.8,
        moonSign: .leo,
        isWaxing: false
    )

    ScrollView {
        LunarCycleView(lunarData: mockData)
            .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("New Moon Accumulation") {
    let mockData = LunarData(
        date: Date(),
        phase: .newMoon,
        illumination: 0.01,
        age: 0.5,
        moonSign: .capricorn,
        isWaxing: true
    )

    ScrollView {
        LunarCycleView(lunarData: mockData)
            .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("Lunar Detail Sheet") {
    let mockData = LunarData(
        date: Date(),
        phase: .waxingGibbous,
        illumination: 0.73,
        age: 11.5,
        moonSign: .taurus,
        isWaxing: true
    )

    LunarDetailSheet(lunarData: mockData)
}
