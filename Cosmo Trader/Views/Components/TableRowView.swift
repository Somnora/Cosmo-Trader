import SwiftUI

/// TableRowView
/// ------------
/// Dense data row for terminal-style stock lists.
/// Format: [Glyph] AAPL  Apple Inc.  [Sparkline]  $184.92 ▲1.2%
///
/// Design:
/// - Alternating subtle backgrounds (every other row 5% lighter)
/// - Thin bottom border
/// - Sharp corners, dense padding
/// - Monospace numbers for alignment

// MARK: - Table Row View

struct TableRowView: View {

    /// Stock data to display
    let stock: Stock

    /// Row index for alternating background
    var rowIndex: Int = 0

    /// Show sparkline chart
    var showSparkline: Bool = true

    /// Show zodiac glyph
    var showGlyph: Bool = true

    /// Tap action
    var onTap: (() -> Void)? = nil

    /// Computed alternating background
    private var rowBackground: Color {
        rowIndex % 2 == 0
            ? CosmicTheme.cardBackground
            : CosmicTheme.cardBackground.opacity(0.6)
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 0) {
                // Zodiac glyph
                if showGlyph {
                    glyphSection
                }

                // Symbol and name
                stockInfoSection

                Spacer(minLength: 8)

                // Sparkline
                if showSparkline {
                    sparklineSection
                }

                // Price and change
                priceSection
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(rowBackground)
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 0.5)
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var glyphSection: some View {
        Group {
            if let foundedZodiacSign = stock.foundedZodiacSign {
                ZodiacSymbolView(
                    sign: foundedZodiacSign,
                    size: 16,
                    color: elementColor
                )
            } else {
                Text("?")
                    .font(TerminalFont.data(14, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .frame(width: 28)
    }

    private var stockInfoSection: some View {
        HStack(spacing: 8) {
            // Ticker symbol
            Text(stock.symbol)
                .font(TerminalFont.ticker(13))
                .foregroundColor(CosmicTheme.textPrimary)
                .frame(width: 50, alignment: .leading)

            // Company name
            Text(stock.name)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: 120, alignment: .leading)
        }
    }

    private var sparklineSection: some View {
        Group {
            if stock.priceHistory.count >= 2 {
                MiniSparkline(
                    data: stock.priceHistory,
                    size: CGSize(width: 40, height: 18)
                )
            } else {
                Text("N/A")
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .frame(width: 40, height: 18)
            }
        }
        .padding(.horizontal, 8)
    }

    private var priceSection: some View {
        HStack(spacing: 8) {
            // Price
            Text(stock.formattedPrice)
                .font(TerminalFont.price(13))
                .foregroundColor(CosmicTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)

            // Change with arrow
            HStack(spacing: 2) {
                Text(stock.isPositive ? "▲" : "▼")
                    .font(.system(size: 8, weight: .bold))

                Text(stock.formattedPercentageChange)
                    .font(TerminalFont.data(11))
            }
            .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
            .frame(width: 65, alignment: .trailing)
        }
    }

    private var elementColor: Color {
        guard let foundedElement = stock.foundedElement else {
            return CosmicTheme.textMuted
        }

        switch foundedElement {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Dense Table Row

/// Even more compact row for very dense lists
struct DenseTableRow: View {

    let stock: Stock
    var rowIndex: Int = 0
    var onTap: (() -> Void)? = nil

    private var rowBackground: Color {
        rowIndex % 2 == 0
            ? CosmicTheme.cardBackground
            : CosmicTheme.secondaryBackground
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 8) {
                // Symbol
                Text(stock.symbol)
                    .font(TerminalFont.ticker(11))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .frame(width: 44, alignment: .leading)

                // Zodiac glyph (tiny)
                if let foundedZodiacSign = stock.foundedZodiacSign {
                    ZodiacSymbolView(sign: foundedZodiacSign, size: 10, color: CosmicTheme.textMuted)
                } else {
                    Text("?")
                        .font(TerminalFont.data(10, weight: .semibold))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()

                // Price
                Text(stock.formattedPrice)
                    .font(TerminalFont.price(11))
                    .foregroundColor(CosmicTheme.textPrimary)

                // Change
                Text(stock.formattedPercentageChange)
                    .font(TerminalFont.data(10))
                    .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                    .frame(width: 55, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(rowBackground)
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(CosmicTheme.border.opacity(0.5))
                        .frame(height: 0.5)
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Table Header Row

/// Header row for table columns
struct TableHeaderRow: View {

    var columns: [String] = ["Symbol", "Name", "", "Price", "Change"]
    var showSparklineColumn: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            // Glyph column spacer
            Spacer()
                .frame(width: 28)

            // Symbol
            Text(columns[0].uppercased())
                .frame(width: 50, alignment: .leading)

            // Name
            Text(columns[1].uppercased())
                .frame(maxWidth: 120, alignment: .leading)

            Spacer()

            // Sparkline column (empty header)
            if showSparklineColumn {
                Spacer()
                    .frame(width: 56)
            }

            // Price
            Text(columns[3].uppercased())
                .frame(width: 70, alignment: .trailing)

            // Change
            Text(columns[4].uppercased())
                .frame(width: 65, alignment: .trailing)
        }
        .font(TerminalFont.data(9, weight: .medium))
        .foregroundColor(CosmicTheme.textMuted)
        .tracking(0.5)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CosmicTheme.secondaryBackground)
        .overlay(
            VStack {
                Spacer()
                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(height: 0.5)
            }
        )
    }
}

// MARK: - Table View Container

/// Complete table with header and rows
struct StockTableView: View {

    let stocks: [Stock]
    var showHeader: Bool = true
    var showSparklines: Bool = true
    var onStockTap: ((Stock) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            if showHeader {
                TableHeaderRow(showSparklineColumn: showSparklines)
            }

            ForEach(Array(stocks.enumerated()), id: \.element.id) { index, stock in
                TableRowView(
                    stock: stock,
                    rowIndex: index,
                    showSparkline: showSparklines,
                    showGlyph: true,
                    onTap: { onStockTap?(stock) }
                )
            }
        }
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Watchlist Row Variant

/// Row variant specifically for watchlist display
struct WatchlistTableRow: View {

    let stock: Stock
    var rowIndex: Int = 0
    var isInWatchlist: Bool = true
    var onTap: (() -> Void)? = nil
    var onToggleWatchlist: (() -> Void)? = nil

    private var rowBackground: Color {
        rowIndex % 2 == 0
            ? CosmicTheme.cardBackground
            : CosmicTheme.cardBackground.opacity(0.6)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main content (tappable)
            Button(action: { onTap?() }) {
                HStack(spacing: 8) {
                    // Glyph
                    Group {
                        if let foundedZodiacSign = stock.foundedZodiacSign {
                            ZodiacSymbolView(
                                sign: foundedZodiacSign,
                                size: 14,
                                color: CosmicTheme.textMuted
                            )
                        } else {
                            Text("?")
                                .font(TerminalFont.data(12, weight: .semibold))
                                .foregroundColor(CosmicTheme.textMuted)
                        }
                    }
                    .frame(width: 24)

                    // Symbol
                    Text(stock.symbol)
                        .font(TerminalFont.ticker(12))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .frame(width: 45, alignment: .leading)

                    // Name
                    Text(stock.name)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    // Price
                    Text(stock.formattedPrice)
                        .font(TerminalFont.price(12))
                        .foregroundColor(CosmicTheme.textPrimary)

                    // Change
                    Text(stock.formattedPercentageChange)
                        .font(TerminalFont.data(10))
                        .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                        .frame(width: 55, alignment: .trailing)
                }
            }
            .buttonStyle(.plain)

            // Watchlist toggle
            Button(action: { onToggleWatchlist?() }) {
                Image(systemName: isInWatchlist ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundColor(isInWatchlist ? CosmicTheme.gold : CosmicTheme.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackground)
        .overlay(
            VStack {
                Spacer()
                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(height: 0.5)
            }
        )
    }
}

// MARK: - Preview

#Preview("Table Rows") {
    ScrollView {
        VStack(spacing: 24) {
            Text("TABLE ROWS")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            // Full table with header
            VStack(spacing: 0) {
                SectionHeaderView(title: "Holdings")

                StockTableView(stocks: Array(MockStockData.featured.prefix(5)))
            }

            // Dense variant
            VStack(spacing: 0) {
                SectionHeaderView(title: "Dense View")

                ForEach(Array(MockStockData.featured.prefix(5).enumerated()), id: \.element.id) { index, stock in
                    DenseTableRow(stock: stock, rowIndex: index)
                }
            }
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )

            // Watchlist variant
            VStack(spacing: 0) {
                SectionHeaderView(title: "Watchlist")

                ForEach(Array(MockStockData.featured.prefix(4).enumerated()), id: \.element.id) { index, stock in
                    WatchlistTableRow(
                        stock: stock,
                        rowIndex: index,
                        isInWatchlist: index < 2
                    )
                }
            }
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
        }
        .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("Single Row") {
    VStack(spacing: 0) {
        TableRowView(stock: MockStockData.featured[0], rowIndex: 0)
        TableRowView(stock: MockStockData.featured[1], rowIndex: 1)
        TableRowView(stock: MockStockData.featured[2], rowIndex: 2)
    }
    .overlay(
        Rectangle()
            .stroke(CosmicTheme.border, lineWidth: 0.5)
    )
    .padding()
    .background(CosmicTheme.background)
}
