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

                        // Element allocation bar chart
                        if !holdings.isEmpty {
                            elementAllocationSection
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
                Text(stock.formattedPercentage)
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
