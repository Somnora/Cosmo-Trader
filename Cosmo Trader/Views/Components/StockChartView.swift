import SwiftUI
import Charts

// MARK: - StockChartView
// ======================
// Interactive price chart using Swift Charts.
// Supports multiple timeframes with terminal-style aesthetics.

struct StockChartView: View {

    // MARK: - Properties

    let stock: Stock
    @Binding var selectedTimeframe: ChartTimeframe

    // MARK: - State

    @State private var selectedPoint: PricePoint?
    @State private var chartData: [PricePoint] = []

    // MARK: - Computed

    private var isPositive: Bool {
        guard let first = chartData.first, let last = chartData.last else { return true }
        return last.price >= first.price
    }

    private var chartColor: Color {
        isPositive ? CosmicTheme.positive : CosmicTheme.negative
    }

    private var priceRange: ClosedRange<Double> {
        let prices = chartData.map(\.price).filter(\.isFinite)
        guard let minPrice = prices.min(), let maxPrice = prices.max() else { return 0...1 }

        let magnitude = max(max(abs(minPrice), abs(maxPrice)), 1)
        let spread = max(maxPrice - minPrice, magnitude * 0.01)
        let padding = spread * 0.1
        let lower = (minPrice - padding).isFinite ? (minPrice - padding) : 0
        let upper = (maxPrice + padding).isFinite ? (maxPrice + padding) : 1

        if lower == upper {
            return (lower - 1)...(upper + 1)
        }
        return lower...upper
    }

    private var performanceText: String {
        guard let first = chartData.first, let last = chartData.last else { return "" }
        guard first.price.isFinite, last.price.isFinite else { return "N/A" }
        let change = last.price - first.price
        let percentChange: Double
        if first.price == 0 {
            percentChange = 0
        } else {
            let calculated = (change / first.price) * 100
            percentChange = calculated.isFinite ? calculated : 0
        }
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@$%.2f (%@%.2f%%)", sign, abs(change), sign, percentChange)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Header with price info
            chartHeader

            // Main chart
            chartBody

            // Timeframe selector
            timeframeSelector
        }
        .onAppear {
            loadChartData()
        }
        .onChange(of: selectedTimeframe) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                loadChartData()
            }
        }
    }

    // MARK: - Chart Header

    private var chartHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                if let point = selectedPoint {
                    // Show selected point info
                    Text(formatPrice(point.price))
                        .font(TerminalFont.price(24))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(formatDate(point.date))
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textMuted)
                } else {
                    // Show current price
                    Text(stock.formattedPrice)
                        .font(TerminalFont.price(24))
                        .foregroundColor(CosmicTheme.textPrimary)

                    HStack(spacing: 6) {
                        Text(performanceText)
                            .font(TerminalFont.data(12, weight: .medium))
                            .foregroundColor(chartColor)

                        Text(selectedTimeframe.description)
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
            }

            Spacer()

            // Zodiac indicator
            VStack(alignment: .trailing, spacing: 4) {
                ZodiacSymbolView(
                    sign: stock.zodiacSign,
                    size: 20,
                    color: CosmicTheme.gold
                )

                Text(stock.zodiacSign.displayName)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Chart Body

    private var chartBody: some View {
        Chart(chartData) { point in
            // Area fill
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Price", point.price)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [chartColor.opacity(0.3), chartColor.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            // Line
            LineMark(
                x: .value("Time", point.date),
                y: .value("Price", point.price)
            )
            .foregroundStyle(chartColor)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)

            // Selected point indicator
            if let selected = selectedPoint, selected.id == point.id {
                PointMark(
                    x: .value("Time", point.date),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(chartColor)
                .symbolSize(100)

                RuleMark(x: .value("Time", point.date))
                    .foregroundStyle(CosmicTheme.textMuted.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: priceRange)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(CosmicTheme.border)
                AxisValueLabel()
                    .font(TerminalFont.data(9))
                    .foregroundStyle(CosmicTheme.textMuted)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(CosmicTheme.border)
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text(formatAxisPrice(price))
                            .font(TerminalFont.data(9))
                            .foregroundStyle(CosmicTheme.textMuted)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectPoint(nearestTo: date)
                                }
                            }
                            .onEnded { _ in
                                selectedPoint = nil
                            }
                    )
            }
        }
        .frame(height: 200)
    }

    // MARK: - Timeframe Selector

    private var timeframeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ChartTimeframe.allCases) { timeframe in
                Button(action: {
                    selectedTimeframe = timeframe
                }) {
                    Text(timeframe.rawValue)
                        .font(TerminalFont.data(12, weight: timeframe == selectedTimeframe ? .semibold : .regular))
                        .foregroundColor(timeframe == selectedTimeframe ? CosmicTheme.gold : CosmicTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            timeframe == selectedTimeframe ?
                            CosmicTheme.gold.opacity(0.15) : Color.clear
                        )
                }
            }
        }
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func loadChartData() {
        let points = stock.chartData(for: selectedTimeframe).filter { $0.price.isFinite }
        if points.count >= 2 {
            chartData = points
            return
        }

        let fallbackPrice = stock.currentPrice.isFinite ? stock.currentPrice : 0
        let now = Date()
        chartData = [
            PricePoint(date: now.addingTimeInterval(-60), price: fallbackPrice),
            PricePoint(date: now, price: fallbackPrice)
        ]
    }

    private func selectPoint(nearestTo date: Date) {
        guard !chartData.isEmpty else { return }
        selectedPoint = chartData.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private func formatPrice(_ price: Double) -> String {
        String(format: "$%.2f", price)
    }

    private func formatAxisPrice(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "$%.0f", price)
        } else if price >= 100 {
            return String(format: "$%.0f", price)
        } else {
            return String(format: "$%.1f", price)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedTimeframe {
        case .day:
            formatter.dateFormat = "h:mm a"
        case .week:
            formatter.dateFormat = "E h:mm a"
        case .month, .threeMonth:
            formatter.dateFormat = "MMM d"
        case .year, .all:
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Key Stats View
// ======================
// Displays key statistics grid for a stock.

struct StockKeyStatsView: View {

    let stats: StockKeyStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 20, height: 1)

                Text("KEY STATISTICS")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(height: 1)
            }

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statRow(label: "Open", value: stats.formattedOpen)
                statRow(label: "Market Cap", value: stats.formattedMarketCap)
                statRow(label: "Day Range", value: stats.formattedDayRange)
                statRow(label: "52W Range", value: stats.formattedWeek52Range)
                statRow(label: "Volume", value: stats.formattedVolume)
                statRow(label: "Avg Volume", value: stats.formattedAvgVolume)
                statRow(label: "P/E Ratio", value: stats.formattedPERatio)
                statRow(label: "Dividend", value: stats.formattedDividendYield)
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)

            Text(value)
                .font(TerminalFont.price(13))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(CosmicTheme.cardBackground.opacity(0.5))
    }
}

// MARK: - Preview

#Preview("Stock Chart") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        VStack {
            StockChartView(
                stock: Stock.sample,
                selectedTimeframe: .constant(.month)
            )
            .padding()

            Divider()

            StockKeyStatsView(stats: Stock.sample.keyStats)
                .padding()
        }
    }
    .preferredColorScheme(.dark)
}
