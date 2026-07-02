import SwiftUI

// MARK: - ZodiacLeaderboardView
// ==============================
// Terminal-style leaderboard for weekly zodiac performance.
// Rankings stay unavailable until provider-backed weekly returns exist.
// Bloomberg aesthetic with cosmic flair.

struct ZodiacLeaderboardView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var selectedSign: ZodiacSign?
    @State private var showingSignDetail: Bool = false
    @State private var isFetching: Bool = false

    // MARK: - Computed Properties

    private var user: UserProfile? {
        appState.currentUser
    }

    /// Safe user sign for rendering (falls back to Aries if no user)
    private var safeUserSign: ZodiacSign {
        user?.sunSign ?? .aries
    }

    private var updatedStocks: [Stock] {
        let cachedQuotes = StockAPIService.shared.getAllCachedQuotes()
        return MockStockData.knownStocks.compactMap { stock in
            if let cached = cachedQuotes[stock.symbol.uppercased()] {
                return stock.withQuote(cached.quote)
            }
            return nil
        }
    }

    private var leaderboard: [(rank: Int, performance: ZodiacWeeklyPerformance)] {
        guard !updatedStocks.isEmpty else { return [] }
        return ZodiacPerformanceService.getLeaderboard(stocks: updatedStocks)
    }

    private var commentary: String {
        guard !updatedStocks.isEmpty else {
            return "Weekly zodiac performance will appear when provider-backed stock returns are connected."
        }
        let performances = leaderboard.map(\.performance)
        return ZodiacPerformanceService.generateWeeklyCommentary(performances: performances, userSign: safeUserSign)
    }

    private var userSignContext: (rank: Int, insight: String, isOutperforming: Bool) {
        guard !updatedStocks.isEmpty else {
            return (rank: 0, insight: "No provider-backed weekly return data yet.", isOutperforming: false)
        }
        let performances = leaderboard.map(\.performance)
        return ZodiacPerformanceService.getUserSignContext(userSign: safeUserSign, performances: performances)
    }

    private var elementPerformance: [(element: ZodiacSign.Element, avgReturn: Double)] {
        guard !updatedStocks.isEmpty else { return [] }
        let performances = leaderboard.map(\.performance)
        return ZodiacPerformanceService.calculateElementPerformance(from: performances)
    }

    private var streaks: [ZodiacStreak] {
        guard !updatedStocks.isEmpty else { return [] }
        return ZodiacPerformanceService.detectStreaks()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // Header commentary
                        headerSection

                        dividerLine

                        // User's sign highlight
                        userSignSection

                        dividerLine

                        // Main leaderboard
                        leaderboardSection

                        dividerLine

                        // Element breakdown
                        elementSection

                        // Streaks section (if any)
                        if !streaks.isEmpty {
                            dividerLine
                            streaksSection
                        }

                        // Timestamp
                        timestampSection
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("WEEKLY COSMIC PERFORMANCE")
                            .font(TerminalFont.data(12))
                            .foregroundColor(CosmicTheme.textPrimary)
                            .tracking(1)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedSign) { sign in
                SignDetailSheet(sign: sign, performance: leaderboard.first { $0.performance.sign == sign }?.performance)
            }
            .task {
                await fetchLeaderboardQuotes()
            }
        }
    }

    private func fetchLeaderboardQuotes() async {
        guard !isFetching else { return }
        isFetching = true
        let symbols = MockStockData.knownStocks.map(\.symbol)
        let quotes = await StockAPIService.shared.getMultipleQuotes(symbols: symbols)
        if !quotes.isEmpty {
            let cached = StockAPIService.shared.getAllCachedQuotes()
            let stocks = MockStockData.knownStocks.compactMap { stock -> Stock? in
                if let cacheEntry = cached[stock.symbol.uppercased()] {
                    return stock.withQuote(cacheEntry.quote)
                }
                return nil
            }
            let performances = ZodiacPerformanceService.calculateWeeklyPerformance(stocks: stocks)
            ZodiacPerformanceService.saveWeeklySnapshot(performances: performances)
        }
        isFetching = false
    }

    // MARK: - Divider

    private var dividerLine: some View {
        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(CosmicTheme.gold)

                Text("This Week in the Cosmos")
                    .font(TerminalFont.headline(16))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                // Week indicator
                Text(weekRangeText)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            // Commentary
            Text(commentary)
                .font(TerminalFont.data(13))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
    }

    private var weekRangeText: String {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return "This Week"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }

    // MARK: - User Sign Section

    private var userSignSection: some View {
        HStack(spacing: 16) {
            // User's sign badge
            ZStack {
                Circle()
                    .fill(safeUserSign.element.color.opacity(0.2))
                    .frame(width: 48, height: 48)

                ZodiacSymbolView(
                    sign: safeUserSign,
                    size: 24,
                    color: safeUserSign.element.color
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("YOUR SIGN")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)

                    Text(userSignContext.rank > 0 ? "#\(userSignContext.rank)" : "N/A")
                        .font(TerminalFont.data(12, weight: .bold))
                        .foregroundColor(userSignContext.isOutperforming ? CosmicTheme.positive : CosmicTheme.textSecondary)
                }

                Text(userSignContext.insight)
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            Spacer()
        }
        .padding(16)
        .background(safeUserSign.element.color.opacity(0.05))
    }

    // MARK: - Leaderboard Section

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            sectionHeader("ZODIAC RANKINGS")

            if leaderboard.isEmpty {
                unavailableState("Provider-backed weekly returns are unavailable. Rankings are hidden until real performance data exists.")
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            } else {
                tableHeader

                dividerLine

                ForEach(leaderboard, id: \.performance.id) { item in
                    leaderboardRow(rank: item.rank, performance: item.performance)
                    dividerLine
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("#")
                .frame(width: 30, alignment: .center)
            Text("SIGN")
                .frame(width: 100, alignment: .leading)
            Text("RETURN")
                .frame(width: 70, alignment: .trailing)
            Text("STOCKS")
                .frame(width: 50, alignment: .trailing)
            Spacer()
        }
        .font(TerminalFont.data(9))
        .foregroundColor(CosmicTheme.textMuted)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(CosmicTheme.cardBackground)
    }

    private func leaderboardRow(rank: Int, performance: ZodiacWeeklyPerformance) -> some View {
        let isUserSign = performance.sign == safeUserSign

        return Button(action: {
            selectedSign = performance.sign
        }) {
            HStack(spacing: 0) {
                // Rank with trophy for #1
                HStack(spacing: 2) {
                    if rank == 1 {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.gold)
                    }
                    Text("\(rank)")
                        .font(TerminalFont.data(12, weight: rank <= 3 ? .bold : .regular))
                        .foregroundColor(rankColor(rank))
                }
                .frame(width: 30, alignment: .center)

                // Sign symbol and name
                HStack(spacing: 8) {
                    ZodiacSymbolView(
                        sign: performance.sign,
                        size: 14,
                        color: performance.sign.element.color
                    )

                    Text(performance.sign.displayName)
                        .font(TerminalFont.data(12, weight: isUserSign ? .bold : .regular))
                        .foregroundColor(isUserSign ? CosmicTheme.gold : CosmicTheme.textPrimary)
                }
                .frame(width: 100, alignment: .leading)

                // Return percentage
                Text(performance.formattedReturn)
                    .font(TerminalFont.price(12))
                    .foregroundColor(performance.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                    .frame(width: 70, alignment: .trailing)

                // Stock count
                Text("\(performance.stockCount)")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textMuted)
                    .frame(width: 50, alignment: .trailing)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isUserSign ? safeUserSign.element.color.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return CosmicTheme.gold
        case 2: return Color.gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return CosmicTheme.textSecondary
        }
    }

    // MARK: - Element Section

    private var elementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("ELEMENT PERFORMANCE")

            if elementPerformance.isEmpty {
                unavailableState("Element performance needs provider-backed weekly returns.")
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            } else {
                HStack(spacing: 0) {
                    ForEach(elementPerformance, id: \.element) { item in
                        elementCard(element: item.element, avgReturn: item.avgReturn)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
    }

    private func unavailableState(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
            Text(message)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func elementCard(element: ZodiacSign.Element, avgReturn: Double) -> some View {
        VStack(spacing: 6) {
            Image(systemName: element.sfSymbol)
                .font(.title3)
                .foregroundColor(element.color)

            Text(element.displayName.uppercased())
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)

            Text(String(format: "%+.1f%%", avgReturn))
                .font(TerminalFont.price(12))
                .foregroundColor(avgReturn >= 0 ? CosmicTheme.positive : CosmicTheme.negative)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(element.color.opacity(0.1))
        )
    }

    // MARK: - Streaks Section

    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("COSMIC STREAKS")

            VStack(spacing: 6) {
                ForEach(streaks.prefix(3), id: \.sign) { streak in
                    streakRow(streak)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private func streakRow(_ streak: ZodiacStreak) -> some View {
        HStack(spacing: 10) {
            ZodiacSymbolView(sign: streak.sign, size: 14, color: streak.sign.element.color)

            Text(streak.description)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)

            Spacer()

            // Week count badge
            Text("\(streak.weekCount)W")
                .font(TerminalFont.data(10, weight: .bold))
                .foregroundColor(CosmicTheme.background)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(streakColor(streak))
                )
        }
        .padding(.vertical, 6)
    }

    private func streakColor(_ streak: ZodiacStreak) -> Color {
        switch streak.streakType {
        case .winning, .top3: return CosmicTheme.positive
        case .losing, .bottom3: return CosmicTheme.negative
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)
                .frame(width: 20)

            Text(title)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Timestamp

    private var timestampSection: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            Text("Data updates with market prices • Pull to refresh")
                .font(TerminalFont.timestamp(10))
                .foregroundColor(CosmicTheme.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
        }
    }
}

// MARK: - Sign Detail Sheet

struct SignDetailSheet: View {
    let sign: ZodiacSign
    let performance: ZodiacWeeklyPerformance?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Sign header
                        signHeader

                        if let perf = performance {
                            // Performance summary
                            performanceSummary(perf)

                            // Top/Bottom performers
                            if let top = perf.topPerformer {
                                stockHighlight(title: "TOP PERFORMER", stock: top, isTop: true)
                            }

                            if let bottom = perf.bottomPerformer, bottom.symbol != perf.topPerformer?.symbol {
                                stockHighlight(title: "BOTTOM PERFORMER", stock: bottom, isTop: false)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var signHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(sign.element.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                ZodiacSymbolView(sign: sign, size: 40, color: sign.element.color)
            }

            Text(sign.displayName)
                .font(TerminalFont.headline(20))
                .foregroundColor(CosmicTheme.textPrimary)

            Text("\(sign.element.displayName) • \(sign.modality.displayName)")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
        }
    }

    private func performanceSummary(_ perf: ZodiacWeeklyPerformance) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEEKLY RETURN")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(perf.formattedReturn)
                        .font(TerminalFont.price(28))
                        .foregroundColor(perf.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("STOCKS TRACKED")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text("\(perf.stockCount)")
                        .font(TerminalFont.price(28))
                        .foregroundColor(CosmicTheme.textPrimary)
                }
            }

            // Rating badge
            HStack(spacing: 6) {
                Image(systemName: perf.performanceRating.sfSymbol)
                Text(perf.performanceRating.rawValue.uppercased())
                    .font(TerminalFont.data(11, weight: .semibold))
            }
            .foregroundColor(perf.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill((perf.isPositive ? CosmicTheme.positive : CosmicTheme.negative).opacity(0.1))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func stockHighlight(title: String, stock: Stock, isTop: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.symbol)
                        .font(TerminalFont.ticker(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(stock.name)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(stock.formattedPrice)
                        .font(TerminalFont.price(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(stock.formattedPercentageChange)
                        .font(TerminalFont.price(12))
                        .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill((isTop ? CosmicTheme.positive : CosmicTheme.negative).opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke((isTop ? CosmicTheme.positive : CosmicTheme.negative).opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview("Zodiac Leaderboard") {
    ZodiacLeaderboardView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}
