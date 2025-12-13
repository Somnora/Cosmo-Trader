import SwiftUI

/// TickerTapeView
/// --------------
/// Bloomberg-style horizontal scrolling ticker tape.
/// Shows stock symbols with price changes in a continuous marquee.
///
/// Features:
/// - Auto-scrolling marquee animation
/// - Green/red color coding for up/down
/// - Configurable speed and content
/// - Can show user holdings or market overview

struct TickerTapeView: View {

    /// Stock data to display
    let stocks: [Stock]

    /// Scroll speed (points per second)
    var speed: Double = 30

    /// Height of the ticker tape
    var height: CGFloat = 32

    /// Show extended info (price alongside change)
    var showPrice: Bool = false

    /// Animation state
    @State private var offset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var isAnimating: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let viewWidth = geometry.size.width

            ZStack {
                // Background
                Rectangle()
                    .fill(CosmicTheme.secondaryBackground)

                // Top border
                VStack {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 0.5)
                    Spacer()
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 0.5)
                }

                // Scrolling content
                HStack(spacing: 0) {
                    // First copy of content
                    tickerContent
                        .background(
                            GeometryReader { contentGeometry in
                                Color.clear.onAppear {
                                    contentWidth = contentGeometry.size.width
                                }
                            }
                        )

                    // Second copy for seamless loop
                    tickerContent
                }
                .offset(x: offset)
                .onAppear {
                    isAnimating = true
                    startScrolling(viewWidth: viewWidth)
                }
                .onDisappear {
                    // Stop animation when view disappears to save resources
                    isAnimating = false
                    offset = 0
                }
                .onChange(of: stocks.count) { _, _ in
                    // Reset animation when stocks change
                    guard isAnimating else { return }
                    offset = 0
                    startScrolling(viewWidth: viewWidth)
                }
            }
        }
        .frame(height: height)
        .clipped()
    }

    // MARK: - Ticker Content

    private var tickerContent: some View {
        HStack(spacing: 0) {
            ForEach(stocks, id: \.symbol) { stock in
                tickerItem(for: stock)
            }
        }
    }

    private func tickerItem(for stock: Stock) -> some View {
        HStack(spacing: 0) {
            // Symbol with arrow (no space) - Format: "AAPL▲1.24%"
            Text(stock.symbol)
                .font(TerminalFont.data(12, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            // Arrow directly after symbol (no spacing)
            Text(stock.isPositive ? "▲" : "▼")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)

            // Percentage (no leading +/- since arrow indicates direction)
            Text(String(format: "%.2f%%", abs(stock.percentageChange)))
                .font(TerminalFont.data(12))
                .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)

            // Price (optional) - shown after change
            if showPrice {
                Text(" ")
                Text(stock.formattedPrice)
                    .font(TerminalFont.price(12))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Separator with spacing
            Text("  ")
                .font(TerminalFont.data(12))
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Animation

    private func startScrolling(viewWidth: CGFloat) {
        // Wait for content width to be measured
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Only start if still animating and content has width
            guard isAnimating, contentWidth > 0 else { return }

            // Calculate animation duration based on speed
            let duration = contentWidth / speed

            // Start from right edge
            offset = viewWidth

            // Animate to left (negative contentWidth)
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                offset = -contentWidth
            }
        }
    }
}

// MARK: - Compact Ticker Tape

/// A more compact single-line ticker for tight spaces
struct CompactTickerTape: View {

    let stocks: [Stock]
    var speed: Double = 40

    @State private var offset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var isAnimating: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let viewWidth = geometry.size.width

            HStack(spacing: 0) {
                tickerContent
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear.onAppear {
                                contentWidth = contentGeometry.size.width
                            }
                        }
                    )
                tickerContent
            }
            .offset(x: offset)
            .onAppear {
                isAnimating = true
                startAnimation(viewWidth: viewWidth)
            }
            .onDisappear {
                isAnimating = false
                offset = 0
            }
        }
        .frame(height: 20)
        .clipped()
    }

    private var tickerContent: some View {
        HStack(spacing: 16) {
            ForEach(stocks, id: \.symbol) { stock in
                HStack(spacing: 4) {
                    Text(stock.symbol)
                        .font(TerminalFont.data(10, weight: .medium))
                        .foregroundColor(CosmicTheme.textSecondary)

                    Text(stock.formattedPercentageChange)
                        .font(TerminalFont.data(10))
                        .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private func startAnimation(viewWidth: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard isAnimating, contentWidth > 0 else { return }
            let duration = contentWidth / speed
            offset = viewWidth

            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                offset = -contentWidth
            }
        }
    }
}

// MARK: - Static Ticker Strip

/// Non-scrolling ticker strip for when you want static display
struct StaticTickerStrip: View {

    let stocks: [Stock]
    var maxItems: Int = 5

    var body: some View {
        HStack(spacing: 0) {
            ForEach(stocks.prefix(maxItems), id: \.symbol) { stock in
                HStack(spacing: 4) {
                    Text(stock.symbol)
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(stock.formattedPercentageChange)
                        .font(TerminalFont.data(11))
                        .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                }
                .frame(maxWidth: .infinity)

                if stock.symbol != stocks.prefix(maxItems).last?.symbol {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(width: 0.5)
                }
            }
        }
        .padding(.vertical, 8)
        .background(CosmicTheme.secondaryBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview("Ticker Tape") {
    VStack(spacing: 20) {
        Text("TICKER TAPE")
            .font(TerminalFont.headline(16))
            .foregroundColor(CosmicTheme.textPrimary)

        TickerTapeView(stocks: MockStockData.featured)

        Text("COMPACT TICKER")
            .font(TerminalFont.headline(16))
            .foregroundColor(CosmicTheme.textPrimary)
            .padding(.top)

        CompactTickerTape(stocks: MockStockData.featured)
            .background(CosmicTheme.cardBackground)

        Text("STATIC STRIP")
            .font(TerminalFont.headline(16))
            .foregroundColor(CosmicTheme.textPrimary)
            .padding(.top)

        StaticTickerStrip(stocks: MockStockData.featured)
    }
    .padding()
    .background(CosmicTheme.background)
}

#Preview("Ticker with Prices") {
    VStack(spacing: 20) {
        TickerTapeView(stocks: MockStockData.featured, showPrice: true)

        TickerTapeView(stocks: MockStockData.featured, speed: 50)
    }
    .padding()
    .background(CosmicTheme.background)
}
