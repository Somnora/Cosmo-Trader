import SwiftUI
import Charts

// MARK: - PortfolioChartView
// ==========================
// Shows portfolio value over time with benchmark comparison.
// Terminal-style aesthetic with cosmic insights.

struct PortfolioChartView: View {

    // MARK: - Properties

    let portfolio: [Stock]
    let userSign: ZodiacSign
    @Binding var selectedTimeframe: ChartTimeframe

    // MARK: - State

    @State private var portfolioData: [PortfolioPoint] = []
    @State private var benchmarkData: [PortfolioPoint] = []
    @State private var selectedPoint: PortfolioPoint?

    // MARK: - Computed

    private var currentValue: Double {
        portfolio.reduce(0) { $0 + $1.totalValue }
    }

    private var hasProviderBackedHistory: Bool {
        portfolioData.count >= 2 && benchmarkData.count >= 2
    }

    private var portfolioReturn: Double {
        guard let first = portfolioData.first, first.value > 0 else { return 0 }
        return ((portfolioData.last?.value ?? 0) - first.value) / first.value * 100
    }

    private var benchmarkReturn: Double {
        guard let first = benchmarkData.first, first.value > 0 else { return 0 }
        return ((benchmarkData.last?.value ?? 0) - first.value) / first.value * 100
    }

    private var outperformance: Double {
        portfolioReturn - benchmarkReturn
    }

    private var isOutperforming: Bool {
        outperformance > 0
    }

    private var chartColor: Color {
        portfolioReturn >= 0 ? CosmicTheme.positive : CosmicTheme.negative
    }

    /// Tightened Y-axis domain so the area mark doesn't fill the entire chart frame.
    /// Pads the data range by ~10% above and below, with a floor that
    /// keeps tightly-clustered values from collapsing all axis labels
    /// onto a single integer thousand.
    private var chartYDomain: ClosedRange<Double> {
        let allValues = portfolioData.map(\.value) + benchmarkData.map(\.value)
        guard let lo = allValues.min(), let hi = allValues.max(), hi > lo else {
            let fallback = max(currentValue, 1)
            return (fallback * 0.95)...(fallback * 1.05)
        }
        let rawSpan = hi - lo
        let mid = (hi + lo) / 2
        // Floor the span at ~3% of the midpoint so a flat-ish portfolio
        // still gets enough spread for the y-axis labels to differ.
        let span = max(rawSpan, mid * 0.03)
        let pad = span * 0.10
        let center = (hi + lo) / 2
        let halfSpan = span / 2
        return max(0, center - halfSpan - pad)...(center + halfSpan + pad)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 18) {
            // Header
            chartHeader

            // Performance comparison
            performanceComparison

            // Chart
            chartBody

            // Timeframe selector
            timeframeSelector

            // Cosmic insight
            cosmicInsight
        }
        .onAppear {
            loadData()
        }
        .onChange(of: selectedTimeframe) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                loadData()
            }
        }
    }

    // MARK: - Header

    private var chartHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedPoint == nil ? "PERIOD CHANGE" : "VALUE AT")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                if let point = selectedPoint {
                    Text(formatCurrency(point.value))
                        .font(TerminalFont.price(24))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(formatDate(point.date))
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textMuted)
                } else {
                    if hasProviderBackedHistory {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(formatPercent(portfolioReturn))
                                .font(TerminalFont.price(24, weight: .semibold))
                                .foregroundColor(chartColor)

                            Text(selectedTimeframe.description)
                                .font(TerminalFont.data(11))
                                .foregroundColor(CosmicTheme.textMuted)
                        }
                    } else {
                        Text(formatCurrency(currentValue))
                            .font(TerminalFont.price(24, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)
                        Text("Portfolio history unavailable")
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
            }

            Spacer()

            // Zodiac composition indicator
            HStack(spacing: 6) {
                ZodiacSymbolView(
                    sign: userSign,
                    size: 14,
                    color: CosmicTheme.gold
                )

                Text(userSign.displayName.uppercased())
                    .font(TerminalFont.data(9, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(CosmicTheme.gold)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(CosmicTheme.gold.opacity(0.10))
            )
            .overlay(
                Capsule()
                    .stroke(CosmicTheme.gold.opacity(0.25), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Performance Comparison

    private var performanceComparison: some View {
        HStack(spacing: 16) {
            // Portfolio
            performanceCard(
                label: "YOUR COSMIC PORTFOLIO",
                value: hasProviderBackedHistory ? portfolioReturn : nil,
                icon: "sparkles"
            )

            // Benchmark
            performanceCard(
                label: "S&P 500",
                value: hasProviderBackedHistory ? benchmarkReturn : nil,
                icon: "chart.line.uptrend.xyaxis"
            )
        }
    }

    private func performanceCard(label: String, value: Double?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textSecondary)

                Text(label)
                    .font(TerminalFont.data(9, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .tracking(0.8)
                    .lineLimit(1)
            }

            Text(value.map(formatPercent) ?? "Unavailable")
                .font(TerminalFont.price(16))
                .foregroundColor(value.map { $0 >= 0 ? CosmicTheme.positive : CosmicTheme.negative } ?? CosmicTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CosmicTheme.panelElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.borderStrong, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Chart Body

    @ViewBuilder
    private var chartBody: some View {
        if hasProviderBackedHistory {
            portfolioChart
        } else {
            unavailableChartState
        }
    }

    private var portfolioChart: some View {
        Chart {
            // Benchmark line (subtle)
            ForEach(benchmarkData) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Value", point.value),
                    series: .value("Series", "Benchmark")
                )
                .foregroundStyle(CosmicTheme.textSecondary.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                .interpolationMethod(.catmullRom)
            }

            // Portfolio area
            ForEach(portfolioData) { point in
                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Baseline", chartYDomain.lowerBound),
                    yEnd: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [chartColor.opacity(0.3), chartColor.opacity(0.05), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Portfolio line
            ForEach(portfolioData) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Value", point.value),
                    series: .value("Series", "Portfolio")
                )
                .foregroundStyle(chartColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }

            // Selected point
            if let selected = selectedPoint {
                PointMark(
                    x: .value("Time", selected.date),
                    y: .value("Value", selected.value)
                )
                .foregroundStyle(chartColor)
                .symbolSize(100)

                RuleMark(x: .value("Time", selected.date))
                    .foregroundStyle(CosmicTheme.textMuted.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: chartYDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(CosmicTheme.border)
                AxisValueLabel()
                    .font(TerminalFont.data(9))
                    .foregroundStyle(CosmicTheme.textMuted)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(CosmicTheme.border)
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(formatAxisValue(val))
                            .font(TerminalFont.data(9))
                            .foregroundStyle(CosmicTheme.textMuted)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .padding(.trailing, 8)
                .padding(.bottom, 4)
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

    private var unavailableChartState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)
            Text("Portfolio performance history unavailable")
                .font(TerminalFont.data(12, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
            Text("Chart and benchmark comparison will appear when provider-backed historical holdings data is available.")
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
            ForEach([ChartTimeframe.week, .month, .threeMonth, .sixMonth, .year, .all], id: \.self) { timeframe in
                Button(action: {
                    selectedTimeframe = timeframe
                }) {
                    Text(timeframe.rawValue)
                        .font(TerminalFont.data(11, weight: timeframe == selectedTimeframe ? .semibold : .regular))
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

    // MARK: - Cosmic Insight

    private var cosmicInsight: some View {
        HStack(spacing: 10) {
            Image(systemName: isOutperforming ? "star.fill" : "moon.fill")
                .font(.caption)
                .foregroundColor(hasProviderBackedHistory && isOutperforming ? CosmicTheme.gold : CosmicTheme.textMuted)

            Text(hasProviderBackedHistory ? generateInsight() : "Portfolio-vs-benchmark insight will appear when real historical holdings data is available.")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .italic()
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hasProviderBackedHistory && isOutperforming ? CosmicTheme.gold.opacity(0.08) : CosmicTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(hasProviderBackedHistory && isOutperforming ? CosmicTheme.gold.opacity(0.2) : CosmicTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func loadData() {
        selectedPoint = nil
        portfolioData = []
        benchmarkData = []
    }

    private func selectPoint(nearestTo date: Date) {
        guard !portfolioData.isEmpty else { return }
        selectedPoint = portfolioData.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private func generateInsight() -> String {
        let diff = abs(outperformance)

        if isOutperforming {
            if diff > 5 {
                return "Your \(userSign.displayName) allocation is outperforming by +\(String(format: "%.1f", diff))%."
            } else if diff > 2 {
                return "Outperforming the S&P 500. \(userSign.element.displayName) exposure is helping."
            } else {
                return "Slightly ahead of the benchmark. Portfolio structure is holding steady."
            }
        } else {
            if diff > 5 {
                return "The market is testing your \(userSign.displayName) exposure. Review rebalancing."
            } else if diff > 2 {
                return "Trailing the S&P 500. Patience is useful if the long-term thesis still holds."
            } else {
                return "Tracking close to the benchmark. Exposure is roughly balanced."
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    private func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, value)
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
        case .year, .twoYear, .all:
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: date)
    }

    /// Formats a y-axis tick using a span-aware precision. When the
    /// visible value range is small (e.g., a portfolio bouncing between
    /// $8.9K and $9.3K), every tick collapsed to "$9K" with the prior
    /// `%.0fK` rule. Use the chart's domain to pick enough digits that
    /// adjacent labels read distinctly.
    private func formatAxisValue(_ value: Double) -> String {
        let span = chartYDomain.upperBound - chartYDomain.lowerBound
        if value >= 1_000_000 {
            let unit = value / 1_000_000
            let digits = span / 1_000_000 < 5 ? 2 : 1
            return String(format: "$%.\(digits)fM", unit)
        } else if value >= 1_000 {
            let unit = value / 1_000
            // Pick digit count from the *visible* span so labels don't all
            // round to the same integer thousand.
            let spanK = span / 1_000
            let digits: Int
            if spanK < 1 { digits = 2 }
            else if spanK < 10 { digits = 1 }
            else { digits = 0 }
            return String(format: "$%.\(digits)fK", unit)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}

// MARK: - Portfolio Point Model

struct PortfolioPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Preview

#Preview("Portfolio Chart") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        PortfolioChartView(
            portfolio: Stock.samples.filter { $0.isOwned },
            userSign: .leo,
            selectedTimeframe: .constant(.month)
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
