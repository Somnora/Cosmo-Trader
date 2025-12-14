import SwiftUI

// MARK: - PortfolioView
// ======================
// Bloomberg Terminal aesthetic. Data only. No decoration.
// If it looks "designed" it's wrong.

struct PortfolioView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var selectedStock: Stock?
    @State private var lastPriceUpdate: Date = Date()
    @State private var isFetchingPrices: Bool = false
    @State private var stockAPI = StockAPIService.shared
    @State private var showRebalancingSuggestions: Bool = false

    // MARK: - Computed Properties

    private var user: UserProfile {
        appState.currentUser ?? .sampleWithHoldings
    }

    private var holdings: [Stock] {
        user.portfolio.filter { $0.sharesOwned > 0 }
    }

    private var elementBreakdown: [(element: ZodiacSign.Element, percentage: Double, value: Double)] {
        let totalValue = user.totalPortfolioValue
        guard totalValue > 0 else { return [] }

        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in holdings {
            let element = stock.zodiacSign.element
            elementValues[element, default: 0] += stock.totalValue
        }

        return ZodiacSign.Element.allCases.compactMap { element in
            let value = elementValues[element] ?? 0
            let percentage = (value / totalValue) * 100
            guard percentage > 0 else { return nil }
            return (element: element, percentage: percentage, value: value)
        }.sorted { $0.percentage > $1.percentage }
    }

    private var timestampText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return "Last updated: \(formatter.string(from: lastPriceUpdate)) ET"
    }

    /// Weighted portfolio compatibility result
    private var portfolioCompatibility: PortfolioCompatibilityResult {
        PortfolioCompatibilityService.calculateWeightedCompatibility(
            portfolio: user.portfolio,
            userSign: user.sunSign
        )
    }

    /// Rebalancing suggestions
    private var rebalancingSuggestions: [RebalancingSuggestion] {
        PortfolioCompatibilityService.generateRebalancingSuggestions(
            result: portfolioCompatibility,
            userSign: user.sunSign
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Flat black background
                CosmicTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // Portfolio value header
                        portfolioHeader

                        dividerLine

                        // Cosmic Portfolio Health section
                        if !holdings.isEmpty {
                            cosmicHealthSection
                            dividerLine
                        }

                        // Element allocation bar chart
                        if !holdings.isEmpty {
                            elementAllocationSection
                            dividerLine
                        }

                        // Rebalancing suggestions
                        if !rebalancingSuggestions.isEmpty && showRebalancingSuggestions {
                            rebalancingSection
                            dividerLine
                        }

                        // Holdings table
                        holdingsSection

                        // Timestamp footer
                        footerSection
                    }
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await fetchLivePrices()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PORTFOLIO")
                        .font(TerminalFont.data(14))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .tracking(2)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(item: $selectedStock) { stock in
                StockDetailView(stock: stock)
            }
        }
        .task {
            await fetchLivePrices()
        }
    }

    // MARK: - Divider

    private var dividerLine: some View {
        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)
    }

    // MARK: - Portfolio Header

    private var portfolioHeader: some View {
        HStack(spacing: 0) {
            // Portfolio value
            VStack(alignment: .leading, spacing: 2) {
                Text("PORTFOLIO VALUE")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                Text(user.formattedPortfolioValue)
                    .font(TerminalFont.price(24))
                    .foregroundColor(CosmicTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(width: 1)

            // Daily P/L
            VStack(alignment: .trailing, spacing: 2) {
                Text("DAILY P/L")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                HStack(spacing: 4) {
                    Text(user.formattedDailyChange)
                        .font(TerminalFont.price(18))
                    Text("(\(user.formattedDailyChangePercent))")
                        .font(TerminalFont.price(14))
                }
                .foregroundColor(user.isPortfolioPositive ? CosmicTheme.positive : CosmicTheme.negative)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    // MARK: - Cosmic Health Section

    private var cosmicHealthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with toggle
            HStack {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 1)
                        .frame(width: 20)

                    Text("COSMIC PORTFOLIO HEALTH")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)

                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 1)
                }

                Spacer()

                // Suggestions toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showRebalancingSuggestions.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showRebalancingSuggestions ? "lightbulb.fill" : "lightbulb")
                            .font(.caption)
                        Text(showRebalancingSuggestions ? "HIDE" : "TIPS")
                            .font(TerminalFont.data(9))
                    }
                    .foregroundColor(showRebalancingSuggestions ? CosmicTheme.gold : CosmicTheme.textMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Main health display
            HStack(spacing: 0) {
                // Big score display
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEIGHTED SCORE")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f", portfolioCompatibility.overallScore))
                            .font(TerminalFont.price(36))
                            .foregroundStyle(cosmicScoreGradient)

                        Text("%")
                            .font(TerminalFont.price(18))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }

                    // Rating badge
                    HStack(spacing: 4) {
                        Text(portfolioCompatibility.rating.emoji)
                            .font(.caption)

                        Text(portfolioCompatibility.rating.displayName.uppercased())
                            .font(TerminalFont.data(9, weight: .semibold))
                            .foregroundColor(cosmicRatingColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cosmicRatingColor.opacity(0.15))
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Dominant sign & element
                VStack(alignment: .trailing, spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("DOMINANT SIGN")
                            .font(TerminalFont.data(9))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)

                        HStack(spacing: 6) {
                            ZodiacSymbolView(
                                sign: portfolioCompatibility.dominantSign,
                                size: 16,
                                color: CosmicTheme.gold
                            )
                            Text(portfolioCompatibility.dominantSign.displayName)
                                .font(TerminalFont.data(14, weight: .semibold))
                                .foregroundColor(CosmicTheme.textPrimary)
                        }
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("DOMINANT ELEMENT")
                            .font(TerminalFont.data(9))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)

                        HStack(spacing: 6) {
                            Text(portfolioCompatibility.dominantElement.emoji)
                                .font(.caption)
                            Text(portfolioCompatibility.dominantElement.displayName)
                                .font(TerminalFont.data(12))
                                .foregroundColor(portfolioCompatibility.dominantElement.color)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 12)

            // Cosmic insight
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold.opacity(0.7))

                Text(portfolioCompatibility.cosmicInsight)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private var cosmicScoreGradient: LinearGradient {
        let score = portfolioCompatibility.overallScore
        if score >= 85 {
            return CosmicTheme.goldGradient
        } else if score >= 65 {
            return LinearGradient(
                colors: [CosmicTheme.accentBlue, CosmicTheme.cosmicPurple],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [CosmicTheme.textPrimary, CosmicTheme.textSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var cosmicRatingColor: Color {
        switch portfolioCompatibility.rating {
        case .cosmicSoulmates: return CosmicTheme.gold
        case .highCompatibility: return CosmicTheme.accentBlue
        case .neutral: return CosmicTheme.textSecondary
        case .challenging: return .orange
        case .cosmicClash: return CosmicTheme.negative
        }
    }

    // MARK: - Rebalancing Section

    private var rebalancingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("COSMIC REBALANCING")

            VStack(alignment: .leading, spacing: 6) {
                Text("To improve cosmic alignment, consider:")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .padding(.horizontal, 12)

                ForEach(rebalancingSuggestions.prefix(4)) { suggestion in
                    suggestionRow(suggestion)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func suggestionRow(_ suggestion: RebalancingSuggestion) -> some View {
        HStack(spacing: 10) {
            Text(suggestion.icon)
                .font(.caption)
                .frame(width: 20)

            Text(suggestion.message)
                .font(TerminalFont.data(11))
                .foregroundColor(suggestionColor(for: suggestion.priority))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Priority indicator
            Circle()
                .fill(suggestionColor(for: suggestion.priority))
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(suggestionColor(for: suggestion.priority).opacity(0.05))
        )
    }

    private func suggestionColor(for priority: RebalancingSuggestion.Priority) -> Color {
        switch priority {
        case .high: return CosmicTheme.gold
        case .medium: return CosmicTheme.textSecondary
        case .low: return CosmicTheme.textMuted
        }
    }

    // MARK: - Element Allocation Section

    private var elementAllocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("ELEMENT ALLOCATION")

            // Horizontal bar chart
            VStack(spacing: 4) {
                ForEach(elementBreakdown, id: \.element) { item in
                    elementBar(item)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func elementBar(_ item: (element: ZodiacSign.Element, percentage: Double, value: Double)) -> some View {
        HStack(spacing: 8) {
            // Element glyph (small, muted gold)
            ZodiacSymbolView(
                sign: item.element.signs.first ?? .aries,
                size: 12,
                color: CosmicTheme.gold
            )
            .frame(width: 16)

            // Element name
            Text(item.element.displayName.uppercased())
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .frame(width: 50, alignment: .leading)

            // Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 8)

                    Rectangle()
                        .fill(item.element.color)
                        .frame(width: geometry.size.width * CGFloat(item.percentage / 100), height: 8)
                }
            }
            .frame(height: 8)

            // Percentage
            Text(String(format: "%.1f%%", item.percentage))
                .font(TerminalFont.price(11))
                .foregroundColor(CosmicTheme.textPrimary)
                .frame(width: 45, alignment: .trailing)
        }
        .frame(height: 20)
    }

    // MARK: - Holdings Section

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("HOLDINGS")

            if holdings.isEmpty {
                emptyState
            } else {
                // Table header
                tableHeader
                dividerLine

                // Holdings rows
                ForEach(holdings) { stock in
                    holdingRow(stock)
                    dividerLine
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("SYMBOL")
                .frame(width: 60, alignment: .leading)
            Text("NAME")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("PRICE")
                .frame(width: 70, alignment: .trailing)
            Text("CHG%")
                .frame(width: 60, alignment: .trailing)
            Text("ALLOC")
                .frame(width: 50, alignment: .trailing)
        }
        .font(TerminalFont.data(9))
        .foregroundColor(CosmicTheme.textMuted)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(CosmicTheme.cardBackground)
    }

    private func holdingRow(_ stock: Stock) -> some View {
        Button(action: { selectedStock = stock }) {
            HStack(spacing: 0) {
                // Symbol with zodiac glyph
                HStack(spacing: 4) {
                    ZodiacSymbolView(
                        sign: stock.zodiacSign,
                        size: 10,
                        color: CosmicTheme.gold.opacity(0.7)
                    )
                    Text(stock.symbol)
                        .font(TerminalFont.ticker(11))
                        .foregroundColor(CosmicTheme.textPrimary)
                }
                .frame(width: 60, alignment: .leading)

                // Name
                Text(stock.name)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Price
                Text(stock.formattedPrice)
                    .font(TerminalFont.price(11))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .frame(width: 70, alignment: .trailing)

                // Change %
                Text(stock.formattedPercentageChange)
                    .font(TerminalFont.price(11))
                    .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                    .frame(width: 60, alignment: .trailing)

                // Allocation bar
                allocationBar(for: stock)
                    .frame(width: 50)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func allocationBar(for stock: Stock) -> some View {
        let totalValue = user.totalPortfolioValue
        let allocation = totalValue > 0 ? (stock.totalValue / totalValue) * 100 : 0
        let barWidth = min(allocation / 50, 1.0) // Max bar at 50% allocation

        return HStack(spacing: 2) {
            // Mini bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 30, height: 6)
                Rectangle()
                    .fill(CosmicTheme.textSecondary)
                    .frame(width: 30 * CGFloat(barWidth), height: 6)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("NO HOLDINGS")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textMuted)
            Text("Add positions to track your portfolio")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            Text(timestampText)
                .font(TerminalFont.timestamp(10))
                .foregroundColor(CosmicTheme.textMuted)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }

    // MARK: - Actions

    private func fetchLivePrices() async {
        guard !holdings.isEmpty else { return }
        isFetchingPrices = true

        let symbols = holdings.map { $0.symbol }
        let quotes = await stockAPI.getMultipleQuotes(symbols: symbols)

        if !quotes.isEmpty {
            await MainActor.run {
                appState.updatePortfolioPrices(with: quotes)
                lastPriceUpdate = Date()
            }
        }

        isFetchingPrices = false
    }
}

// MARK: - Preview

#Preview("Portfolio View") {
    PortfolioView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}
