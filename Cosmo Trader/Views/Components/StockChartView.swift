import SwiftUI
import Charts

enum StockChartDisplayMode: String, CaseIterable, Identifiable {
    case line = "LINE"
    case candle = "CANDLE"

    var id: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .line:
            return "Line chart"
        case .candle:
            return "Candle chart"
        }
    }
}

enum StockChartCandleEligibility {
    static let minimumCandleCount = 2

    static func validCandles(from candles: [OHLCData]) -> [OHLCData] {
        candles
            .filter { candle in
                candle.open.isFinite
                    && candle.high.isFinite
                    && candle.low.isFinite
                    && candle.close.isFinite
                    && candle.open > 0
                    && candle.high > 0
                    && candle.low > 0
                    && candle.close > 0
                    && candle.high >= max(candle.open, candle.close)
                    && candle.low <= min(candle.open, candle.close)
                    && candle.high > candle.low
            }
            .sorted { $0.date < $1.date }
    }

    static func canRenderCandles(
        candles: [OHLCData],
        provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness
    ) -> Bool {
        guard provenance.isProviderBacked else { return false }
        guard !provenance.isCachedStale() else { return false }
        guard case .complete = completeness else { return false }
        return validCandles(from: candles).count >= minimumCandleCount
    }
}

struct StockChartModeSelector: View {
    @Binding var selectedMode: StockChartDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StockChartDisplayMode.allCases) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    Text(mode.rawValue)
                        .font(TerminalFont.data(10, weight: selectedMode == mode ? .bold : .regular))
                        .foregroundColor(selectedMode == mode ? CosmicTheme.terminalBlack : CosmicTheme.textMuted)
                        .tracking(0.8)
                        .frame(minWidth: 64)
                        .padding(.vertical, 7)
                        .background(selectedMode == mode ? CosmicTheme.gold : Color.clear)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.accessibilityLabel)
                .accessibilityAddTraits(selectedMode == mode ? .isSelected : [])
            }
        }
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chart display mode")
    }
}

// MARK: - StockChartView
// ======================
// Interactive price chart using Swift Charts.
// Supports multiple timeframes with terminal-style aesthetics.

struct StockChartView: View {

    // MARK: - Properties

    let stock: Stock
    @Binding var selectedTimeframe: ChartTimeframe
    @Binding var selectedDisplayMode: StockChartDisplayMode

    // MARK: - State

    @State private var selectedPoint: PricePoint?
    @State private var chartData: [OHLCData] = []
    @State private var chartLoadState: ChartLoadState = .idle

    private enum ChartLoadState: Equatable {
        case idle
        case loading
        case loaded(provenance: FinancialDataProvenance, completeness: HistoricalDatasetCompleteness)
        case unavailable(String)
    }

    // MARK: - Computed

    private var pricePoints: [PricePoint] {
        chartData
            .map { PricePoint(date: $0.date, price: $0.close) }
            .filter { $0.price.isFinite && $0.price > 0 }
    }

    private var isPositive: Bool {
        guard let first = pricePoints.first, let last = pricePoints.last else { return true }
        return last.price >= first.price
    }

    private var chartColor: Color {
        isPositive ? CosmicTheme.positive : CosmicTheme.negative
    }

    private var priceRange: ClosedRange<Double> {
        let prices = chartData.flatMap { [$0.low, $0.high, $0.close] }.filter { $0.isFinite && $0 > 0 }
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
        guard let first = pricePoints.first, let last = pricePoints.last else { return "" }
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

    private var sourceText: String? {
        switch chartLoadState {
        case .loaded(let provenance, let completeness):
            return "\(provenance.detailText) • \(completeness.label)"
        case .unavailable:
            return "Historical data unavailable"
        case .idle, .loading:
            return nil
        }
    }

    private var chartProvenance: FinancialDataProvenance? {
        switch chartLoadState {
        case .loaded(let provenance, _):
            return provenance
        case .unavailable(let message):
            return .unavailable(reason: message)
        case .idle, .loading:
            return nil
        }
    }

    private var chartCompleteness: HistoricalDatasetCompleteness? {
        switch chartLoadState {
        case .loaded(_, let completeness):
            return completeness
        case .idle, .loading, .unavailable:
            return nil
        }
    }

    private var canRenderCandleMode: Bool {
        guard let chartProvenance, let chartCompleteness else { return false }
        return StockChartCandleEligibility.canRenderCandles(
            candles: chartData,
            provenance: chartProvenance,
            completeness: chartCompleteness
        )
    }

    private var effectiveDisplayMode: StockChartDisplayMode {
        canRenderCandleMode ? selectedDisplayMode : .line
    }

    private var candleData: [OHLCData] {
        StockChartCandleEligibility.validCandles(from: chartData)
    }

    private var candleBodyWidth: MarkDimension {
        let count = candleData.count
        if count > 160 { return .fixed(2) }
        if count > 80 { return .fixed(3) }
        if count > 35 { return .fixed(4) }
        return .fixed(6)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Header with price info
            chartHeader

            if canRenderCandleMode {
                HStack {
                    Text("HISTORICAL PRICE VIEW")
                        .font(TerminalFont.data(9, weight: .bold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)

                    Spacer()

                    StockChartModeSelector(selectedMode: $selectedDisplayMode)
                }
                .padding(.horizontal, 4)
            }

            // Main chart
            chartBody

            // Timeframe selector
            timeframeSelector
        }
        .task(id: "\(stock.symbol)-\(selectedTimeframe.rawValue)") {
            await loadChartData()
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

                    if !performanceText.isEmpty {
                        HStack(spacing: 6) {
                            Text(performanceText)
                                .font(TerminalFont.data(12, weight: .medium))
                                .foregroundColor(chartColor)

                            Text(selectedTimeframe.description)
                                .font(TerminalFont.data(10))
                                .foregroundColor(CosmicTheme.textMuted)
                        }
                    }

                    if let chartProvenance {
                        HStack(spacing: 6) {
                            DataSourceIndicator(provenance: chartProvenance, size: .compact)

                            if let sourceText {
                                Text(sourceText)
                                    .font(TerminalFont.data(9))
                                    .foregroundColor(CosmicTheme.textMuted)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Zodiac indicator
            VStack(alignment: .trailing, spacing: 4) {
                if let foundedZodiacSign = stock.foundedZodiacSign {
                    ZodiacSymbolView(
                        sign: foundedZodiacSign,
                        size: 20,
                        color: CosmicTheme.gold
                    )
                } else {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Text(stock.foundedZodiacSign?.displayName ?? "Unknown")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Chart Body

    @ViewBuilder
    private var chartBody: some View {
        switch chartLoadState {
        case .idle, .loading:
            unavailableChartState(
                icon: "chart.line.uptrend.xyaxis",
                title: "Loading provider chart data",
                message: "Historical price data will appear when provider data is available."
            )
        case .unavailable(let message):
            unavailableChartState(
                icon: "chart.line.downtrend.xyaxis",
                title: "Historical price data unavailable",
                message: message
            )
        case .loaded:
            if pricePoints.count >= 2 {
                priceChart
            } else {
                unavailableChartState(
                    icon: "chart.line.downtrend.xyaxis",
                    title: "Historical price data unavailable",
                    message: "Chart will appear when provider data is available."
                )
            }
        }
    }

    private var priceChart: some View {
        Chart {
            if effectiveDisplayMode == .candle {
                ForEach(candleData) { candle in
                    RuleMark(
                        x: .value("Time", candle.date),
                        yStart: .value("Low", candle.low),
                        yEnd: .value("High", candle.high)
                    )
                    .foregroundStyle(candle.close >= candle.open ? CosmicTheme.positive.opacity(0.72) : CosmicTheme.negative.opacity(0.72))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                    RectangleMark(
                        x: .value("Time", candle.date),
                        yStart: .value("Open", min(candle.open, candle.close)),
                        yEnd: .value("Close", max(candle.open, candle.close)),
                        width: candleBodyWidth
                    )
                    .foregroundStyle(candle.close >= candle.open ? CosmicTheme.positive.opacity(0.9) : CosmicTheme.negative.opacity(0.9))
                }
            } else {
                ForEach(pricePoints) { point in
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
                }
            }

            // Selected point indicator
            if let selected = selectedPoint {
                PointMark(
                    x: .value("Time", selected.date),
                    y: .value("Price", selected.price)
                )
                .foregroundStyle(CosmicTheme.gold)
                .symbolSize(100)

                RuleMark(x: .value("Time", selected.date))
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

    private func unavailableChartState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)

            Text(title)
                .font(TerminalFont.data(12, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            Text(message)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding(12)
        .background(CosmicTheme.cardBackground.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
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

    @MainActor
    private func loadChartData() async {
        selectedPoint = nil
        chartData = []
        chartLoadState = .loading

        do {
            let result = try await HistoricalPriceService.shared.fetchHistoricalPriceResult(
                symbol: stock.symbol,
                timeframe: selectedTimeframe
            )
            let candles = result.data
                .filter { $0.close.isFinite && $0.close > 0 }
                .sorted { $0.date < $1.date }

            guard candles.count >= 2 else {
                chartData = []
                chartLoadState = .unavailable("Chart will appear when provider data is available.")
                return
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                chartData = candles
                chartLoadState = .loaded(provenance: result.provenance, completeness: result.completeness)
            }
        } catch {
            chartData = []
            chartLoadState = .unavailable("Chart will appear when provider data is available.")
        }
    }

    private func selectPoint(nearestTo date: Date) {
        let points = pricePoints
        guard !points.isEmpty else { return }
        selectedPoint = points.min(by: {
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
        case .month, .threeMonth, .sixMonth:
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

    let stats: StockKeyStats?

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

            if let stats {
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    statRow(label: "Open", value: stats.formattedOpen, provenance: stats.provenance(for: .open))
                    statRow(label: "Market Cap", value: stats.formattedMarketCap, provenance: stats.provenance(for: .marketCap))
                    statRow(label: "Day Range", value: stats.formattedDayRange, provenance: stats.provenance(for: .dayRange))
                    statRow(label: "52W Range", value: stats.formattedWeek52Range, provenance: stats.provenance(for: .week52Range))
                    statRow(label: "Volume", value: stats.formattedVolume, provenance: stats.provenance(for: .volume))
                    statRow(label: "Avg Volume", value: stats.formattedAvgVolume, provenance: stats.provenance(for: .avgVolume))
                    statRow(label: "P/E Ratio", value: stats.formattedPERatio, provenance: stats.provenance(for: .peRatio))
                    statRow(label: "Dividend", value: stats.formattedDividendYield, provenance: stats.provenance(for: .dividendYield))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Key statistics unavailable")
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("Fundamentals will appear when provider data is available.")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(3)

                    DataSourceIndicator(
                        provenance: .unavailable(reason: "Provider fundamentals unavailable"),
                        size: .compact
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(CosmicTheme.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
                )
            }
        }
    }

    private func statRow(label: String, value: String, provenance: FinancialDataProvenance) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)

            Text(value)
                .font(TerminalFont.price(13))
                .foregroundColor(value == "Unavailable" ? CosmicTheme.textMuted : CosmicTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(provenance.shortLabel.uppercased())
                .font(TerminalFont.data(7, weight: .bold))
                .foregroundColor(provenance.color)
                .tracking(0.6)
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
                selectedTimeframe: .constant(.month),
                selectedDisplayMode: .constant(.line)
            )
            .padding()

            Divider()

            StockKeyStatsView(stats: StockKeyStats.previewSample)
                .padding()
        }
    }
    .preferredColorScheme(.dark)
}
