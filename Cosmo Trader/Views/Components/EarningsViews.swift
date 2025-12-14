import SwiftUI

// MARK: - Earnings Calendar Card
// ===============================
// Shows upcoming earnings for portfolio stocks

struct EarningsCalendarCard: View {
    let holdings: [Stock]
    @State private var earningsService = EarningsService.shared
    @State private var showFullCalendar = false

    private var upcomingEarnings: [EarningsEvent] {
        earningsService.getEarningsForPortfolio(stocks: holdings)
            .filter { $0.daysUntil >= 0 }
            .prefix(3)
            .map { $0 }
    }

    private var thisWeekCount: Int {
        earningsService.getEarningsForPortfolio(stocks: holdings)
            .filter { $0.isThisWeek }
            .count
    }

    var body: some View {
        if !upcomingEarnings.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(CosmicTheme.cosmicPurple.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16))
                            .foregroundColor(CosmicTheme.cosmicPurple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Earnings Calendar")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(CosmicTheme.textPrimary)

                        if thisWeekCount > 0 {
                            Text("\(thisWeekCount) report\(thisWeekCount > 1 ? "s" : "") this week")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.cosmicPurple)
                        }
                    }

                    Spacer()

                    Button(action: { showFullCalendar = true }) {
                        Text("View All")
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.gold)
                    }
                }

                // Earnings list
                VStack(spacing: 10) {
                    ForEach(upcomingEarnings) { event in
                        EarningsEventRow(event: event, holdings: holdings)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.border, lineWidth: 0.5)
                    )
            )
            .sheet(isPresented: $showFullCalendar) {
                EarningsCalendarSheet(holdings: holdings)
            }
            .onAppear {
                AnalyticsService.shared.track(.earningsCalendarViewed)
            }
        }
    }
}

// MARK: - Earnings Event Row
// ==========================
// Single row in the earnings calendar

struct EarningsEventRow: View {
    let event: EarningsEvent
    let holdings: [Stock]
    @State private var showHoroscope = false

    private var stock: Stock? {
        holdings.first { $0.symbol == event.symbol }
    }

    var body: some View {
        Button(action: { showHoroscope = true }) {
            HStack(spacing: 12) {
                // Date badge
                VStack(spacing: 2) {
                    if event.isToday {
                        Text("TODAY")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    } else {
                        Text(event.reportDate, format: .dateTime.weekday(.abbreviated))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(CosmicTheme.gold)

                        Text(event.reportDate, format: .dateTime.day())
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }
                .frame(width: 40)

                // Stock info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(event.symbol)
                            .font(TerminalFont.data(13, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)

                        if let stock = stock {
                            ZodiacSymbolView(
                                sign: stock.zodiacSign,
                                size: 12,
                                color: elementColor(for: stock.zodiacSign)
                            )
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: event.timing.icon)
                            .font(.system(size: 9))
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(event.timing.rawValue)
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                Spacer()

                // Consensus EPS
                if let consensus = event.formattedConsensus {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Est. EPS")
                            .font(TerminalFont.data(9))
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(consensus)
                            .font(TerminalFont.price(12))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(event.isToday ? Color.orange.opacity(0.1) : CosmicTheme.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showHoroscope) {
            if let stock = stock {
                EarningsHoroscopeSheet(stock: stock, earningsDate: event.reportDate)
            }
        }
    }

    private func elementColor(for sign: ZodiacSign) -> Color {
        switch sign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Full Earnings Calendar Sheet
// ====================================

struct EarningsCalendarSheet: View {
    let holdings: [Stock]
    @State private var earningsService = EarningsService.shared
    @Environment(\.dismiss) private var dismiss

    private var allEarnings: [EarningsEvent] {
        earningsService.getEarningsForPortfolio(stocks: holdings)
            .filter { $0.daysUntil >= 0 }
    }

    private var groupedByWeek: [(String, [EarningsEvent])] {
        _ = Calendar.current  // Reserved for future date calculations
        let grouped = Dictionary(grouping: allEarnings) { event -> String in
            if event.isThisWeek {
                return "This Week"
            } else if event.daysUntil <= 14 {
                return "Next Week"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return "Week of \(formatter.string(from: event.reportDate))"
            }
        }

        return grouped.sorted { lhs, rhs in
            // Sort by earliest event in each group
            guard let lhsFirst = lhs.value.first, let rhsFirst = rhs.value.first else {
                return false
            }
            return lhsFirst.reportDate < rhsFirst.reportDate
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection

                    // Calendar sections
                    ForEach(groupedByWeek, id: \.0) { weekName, events in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(weekName.uppercased())
                                .font(TerminalFont.data(11, weight: .semibold))
                                .foregroundColor(CosmicTheme.textMuted)
                                .padding(.horizontal, 4)

                            VStack(spacing: 8) {
                                ForEach(events) { event in
                                    EarningsEventRow(event: event, holdings: holdings)
                                }
                            }
                        }
                    }

                    // Disclaimer
                    disclaimerSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("Earnings Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                CosmicTheme.cosmicPurple.opacity(0.3),
                                CosmicTheme.cosmicPurple.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 44))
                    .foregroundColor(CosmicTheme.cosmicPurple)
            }

            VStack(spacing: 6) {
                Text("Earnings Season")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("\(allEarnings.count) upcoming reports in your portfolio")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .padding(.vertical, 16)
    }

    private var disclaimerSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .foregroundColor(.orange)

            Text("Earnings dates are estimated and may change. Horoscopes are for entertainment only and should not influence investment decisions.")
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)
                .italic()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.08))
        )
    }
}

// MARK: - Earnings Horoscope Sheet
// =================================
// Full cosmic horoscope for a specific earnings event

struct EarningsHoroscopeSheet: View {
    let stock: Stock
    let earningsDate: Date
    @State private var earningsService = EarningsService.shared
    @Environment(\.dismiss) private var dismiss

    private var horoscope: EarningsHoroscope {
        earningsService.getEarningsHoroscope(for: stock, earningsDate: earningsDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection

                    // Main horoscope
                    horoscopeSection

                    // Cosmic factors
                    cosmicFactorsSection

                    // Trading insight
                    tradingInsightSection

                    // Disclaimer
                    disclaimerSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("Earnings Horoscope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            AnalyticsService.shared.track(.earningsHoroscopeViewed)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Stock with zodiac
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(elementColor.opacity(0.2))
                        .frame(width: 70, height: 70)

                    ZodiacSymbolView(
                        sign: stock.zodiacSign,
                        size: 36,
                        color: elementColor
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.symbol)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(stock.name)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textSecondary)

                    HStack(spacing: 6) {
                        Text(stock.zodiacSign.symbol)
                        Text(stock.zodiacSign.displayName)
                            .font(TerminalFont.data(12))
                            .foregroundColor(elementColor)
                    }
                }

                Spacer()
            }

            // Earnings date
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("REPORTS")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(earningsDate, style: .date)
                        .font(TerminalFont.headline(14))
                        .foregroundColor(CosmicTheme.textPrimary)
                }

                Spacer()

                // Sentiment badge
                HStack(spacing: 6) {
                    Image(systemName: horoscope.sentiment.icon)
                        .font(.caption)

                    Text(horoscope.sentiment.rawValue.uppercased())
                        .font(TerminalFont.data(10, weight: .bold))
                }
                .foregroundColor(horoscope.sentiment.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(horoscope.sentiment.color.opacity(0.15))
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.secondaryBackground)
            )

            // Mercury retrograde warning
            if horoscope.isMercuryRetrograde {
                mercuryRetrogradeWarning
            }
        }
    }

    private var mercuryRetrogradeWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.body)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("MERCURY RETROGRADE ACTIVE")
                    .font(TerminalFont.data(10, weight: .bold))
                    .foregroundColor(.orange)

                Text("Communication mishaps more likely during earnings calls")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Horoscope Section

    private var horoscopeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Cosmic Reading", icon: "sparkles")

            Text(horoscope.horoscopeText)
                .font(.body)
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(6)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.cardBackground)
                )
        }
    }

    // MARK: - Cosmic Factors Section

    private var cosmicFactorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Cosmic Factors", icon: "moon.stars.fill")

            VStack(spacing: 10) {
                ForEach(horoscope.cosmicFactors) { factor in
                    cosmicFactorRow(factor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private func cosmicFactorRow(_ factor: CosmicFactor) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(factor.influence.color.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: factor.icon)
                    .font(.caption)
                    .foregroundColor(factor.influence.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(factor.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Spacer()

                    Text(factor.influence.rawValue)
                        .font(TerminalFont.data(9, weight: .bold))
                        .foregroundColor(factor.influence.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(factor.influence.color.opacity(0.15))
                        )
                }

                Text(factor.description)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(3)
            }
        }
    }

    // MARK: - Trading Insight Section

    private var tradingInsightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Trading Wisdom", icon: "lightbulb.fill")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundColor(CosmicTheme.gold.opacity(0.5))

                Text(horoscope.tradingInsight)
                    .font(.body)
                    .italic()
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.gold.opacity(0.08))
            )
        }
    }

    // MARK: - Disclaimer Section

    private var disclaimerSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .foregroundColor(.orange)

            Text("This is for entertainment purposes only. Cosmic factors do not influence actual earnings outcomes. Always make investment decisions based on fundamental analysis, not astrological readings.")
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)
                .italic()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.08))
        )
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)

            Text(title)
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textPrimary)
        }
    }

    private var elementColor: Color {
        switch stock.zodiacSign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Earnings Badge for Stock Rows
// =====================================
// Compact badge shown on stock rows with upcoming earnings

struct EarningsBadge: View {
    let daysUntil: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(size: 9))

            if daysUntil == 0 {
                Text("TODAY")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            } else {
                Text("\(daysUntil)D")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            }
        }
        .foregroundColor(daysUntil == 0 ? .orange : CosmicTheme.cosmicPurple)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(daysUntil == 0 ? Color.orange.opacity(0.15) : CosmicTheme.cosmicPurple.opacity(0.15))
        )
    }
}

// MARK: - Stock Detail Earnings Section
// =====================================
// Section for StockDetailView showing next earnings

struct StockEarningsSection: View {
    let stock: Stock
    @State private var earningsService = EarningsService.shared
    @State private var showHoroscope = false

    private var nextEarnings: EarningsEvent? {
        earningsService.getNextEarnings(for: stock.symbol)
    }

    var body: some View {
        if let earnings = nextEarnings {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(CosmicTheme.cosmicPurple)

                    Text("UPCOMING EARNINGS")
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Spacer()

                    if earnings.isToday {
                        Text("TODAY")
                            .font(TerminalFont.data(10, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.15))
                            )
                    }
                }

                // Earnings details
                Button(action: { showHoroscope = true }) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(earnings.formattedDate)
                                    .font(TerminalFont.headline(16))
                                    .foregroundColor(CosmicTheme.textPrimary)

                                HStack(spacing: 6) {
                                    Image(systemName: earnings.timing.icon)
                                        .font(.caption)
                                    Text(earnings.timing.rawValue)
                                        .font(TerminalFont.data(11))
                                }
                                .foregroundColor(CosmicTheme.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(earnings.fiscalQuarter + " \(earnings.fiscalYear)")
                                    .font(TerminalFont.data(11))
                                    .foregroundColor(CosmicTheme.textMuted)

                                if let consensus = earnings.formattedConsensus {
                                    HStack(spacing: 4) {
                                        Text("Est:")
                                            .font(TerminalFont.data(10))
                                            .foregroundColor(CosmicTheme.textMuted)
                                        Text(consensus)
                                            .font(TerminalFont.price(14))
                                            .foregroundColor(CosmicTheme.textPrimary)
                                    }
                                }
                            }
                        }

                        // View horoscope prompt
                        HStack {
                            Text("View Earnings Horoscope")
                                .font(TerminalFont.data(12))
                                .foregroundColor(CosmicTheme.gold)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.textMuted)
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(CosmicTheme.secondaryBackground)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(
                Rectangle()
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(CosmicTheme.border, lineWidth: 0.5)
                    )
            )
            .sheet(isPresented: $showHoroscope) {
                EarningsHoroscopeSheet(stock: stock, earningsDate: earnings.reportDate)
            }
        }
    }
}

// MARK: - Previews

#Preview("Earnings Calendar Card") {
    VStack {
        EarningsCalendarCard(holdings: Stock.samples)
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Earnings Horoscope Sheet") {
    EarningsHoroscopeSheet(
        stock: Stock.samples.first!,
        earningsDate: Date().addingTimeInterval(86400 * 3)
    )
    .preferredColorScheme(.dark)
}

#Preview("Stock Earnings Section") {
    StockEarningsSection(stock: Stock.samples.first!)
        .background(CosmicTheme.background)
        .preferredColorScheme(.dark)
}
