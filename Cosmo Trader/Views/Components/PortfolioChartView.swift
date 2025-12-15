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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
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
                Text("PORTFOLIO VALUE")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                if let point = selectedPoint {
                    Text(formatCurrency(point.value))
                        .font(TerminalFont.price(28))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(formatDate(point.date))
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textMuted)
                } else {
                    Text(formatCurrency(currentValue))
                        .font(TerminalFont.price(28))
                        .foregroundColor(CosmicTheme.textPrimary)

                    HStack(spacing: 6) {
                        Text(formatPercent(portfolioReturn))
                            .font(TerminalFont.data(13, weight: .semibold))
                            .foregroundColor(chartColor)

                        Text(selectedTimeframe.description)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
            }

            Spacer()

            // Zodiac composition indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text("YOUR SIGN")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(0.5)

                ZodiacSymbolView(
                    sign: userSign,
                    size: 24,
                    color: CosmicTheme.gold
                )
            }
        }
    }

    // MARK: - Performance Comparison

    private var performanceComparison: some View {
        HStack(spacing: 16) {
            // Portfolio
            performanceCard(
                label: "YOUR COSMIC PORTFOLIO",
                value: portfolioReturn,
                icon: "sparkles"
            )

            // Benchmark
            performanceCard(
                label: "S&P 500",
                value: benchmarkReturn,
                icon: "chart.line.uptrend.xyaxis"
            )
        }
    }

    private func performanceCard(label: String, value: Double, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)

                Text(label)
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(1)
            }

            Text(formatPercent(value))
                .font(TerminalFont.price(16))
                .foregroundColor(value >= 0 ? CosmicTheme.positive : CosmicTheme.negative)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CosmicTheme.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Chart Body

    private var chartBody: some View {
        Chart {
            // Benchmark line (subtle)
            ForEach(benchmarkData) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Value", point.value),
                    series: .value("Series", "Benchmark")
                )
                .foregroundStyle(CosmicTheme.textMuted.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .interpolationMethod(.catmullRom)
            }

            // Portfolio area
            ForEach(portfolioData) { point in
                AreaMark(
                    x: .value("Time", point.date),
                    y: .value("Value", point.value)
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
                    .foregroundStyle(CosmicTheme.textMuted.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
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
        .frame(height: 180)
    }

    // MARK: - Timeframe Selector

    private var timeframeSelector: some View {
        HStack(spacing: 0) {
            ForEach([ChartTimeframe.week, .month, .threeMonth, .year, .all], id: \.self) { timeframe in
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
                .foregroundColor(isOutperforming ? CosmicTheme.gold : CosmicTheme.textMuted)

            Text(generateInsight())
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .italic()

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isOutperforming ? CosmicTheme.gold.opacity(0.08) : CosmicTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isOutperforming ? CosmicTheme.gold.opacity(0.2) : CosmicTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func loadData() {
        portfolioData = generatePortfolioData()
        benchmarkData = generateBenchmarkData()
    }

    private func generatePortfolioData() -> [PortfolioPoint] {
        let calendar = Calendar.current
        let now = Date()
        let seed = portfolio.map { $0.symbol.hashValue }.reduce(0, +) + selectedTimeframe.hashValue
        var generator = SeededRandomGenerator(seed: UInt64(abs(seed)))

        let pointCount: Int
        let component: Calendar.Component
        let interval: Int

        switch selectedTimeframe {
        case .day:
            pointCount = 78
            component = .minute
            interval = 5
        case .week:
            pointCount = 35
            component = .hour
            interval = 4
        case .month:
            pointCount = 30
            component = .day
            interval = 1
        case .threeMonth:
            pointCount = 90
            component = .day
            interval = 1
        case .year:
            pointCount = 52
            component = .weekOfYear
            interval = 1
        case .all:
            pointCount = 60
            component = .month
            interval = 1
        }

        var points: [PortfolioPoint] = []
        let currentVal = currentValue

        // Simulate portfolio growth
        let avgReturn = portfolio.isEmpty ? 0 : portfolio.map { $0.percentageChange }.reduce(0, +) / Double(portfolio.count)
        let totalReturn = avgReturn * Double(selectedTimeframe.tradingDays) / 252 * 8 // Annualized extrapolation

        let startValue = currentVal / (1 + totalReturn / 100)
        var value = startValue

        for i in 0..<pointCount {
            let pointsFromEnd = pointCount - 1 - i
            let date = calendar.date(byAdding: component, value: -pointsFromEnd * interval, to: now) ?? now

            let progress = Double(i) / Double(pointCount - 1)
            let drift = (currentVal - value) * (0.02 + progress * 0.08)
            let noise = Double.random(in: -1...1, using: &generator) * value * 0.01

            value += drift + noise
            value = max(value, currentVal * 0.5)

            points.append(PortfolioPoint(date: date, value: value))
        }

        if !points.isEmpty {
            points[points.count - 1] = PortfolioPoint(date: now, value: currentVal)
        }

        return points
    }

    private func generateBenchmarkData() -> [PortfolioPoint] {
        guard let startValue = portfolioData.first?.value else { return [] }

        // S&P 500 average annual return ~10%
        let seed = selectedTimeframe.hashValue + 12345
        var generator = SeededRandomGenerator(seed: UInt64(abs(seed)))

        let dailyReturn = 0.10 / 252 // 10% annual / 252 trading days
        let periodReturn = dailyReturn * Double(selectedTimeframe.tradingDays)

        var points: [PortfolioPoint] = []
        var value = startValue

        for portfolioPoint in portfolioData {
            let progress = Double(points.count) / Double(portfolioData.count - 1)
            let drift = (startValue * (1 + periodReturn) - value) * (0.02 + progress * 0.08)
            let noise = Double.random(in: -1...1, using: &generator) * value * 0.005

            value += drift + noise

            points.append(PortfolioPoint(date: portfolioPoint.date, value: value))
        }

        return points
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
                return "Your \(userSign.displayName) intuition is crushing the market! +\(String(format: "%.1f", diff))% cosmic alpha."
            } else if diff > 2 {
                return "Outperforming the S&P 500. The stars favor your \(userSign.element.displayName) selections."
            } else {
                return "Slightly ahead of the benchmark. Your cosmic portfolio holds steady."
            }
        } else {
            if diff > 5 {
                return "The market tests your \(userSign.displayName) resolve. Consider cosmic rebalancing."
            } else if diff > 2 {
                return "Trailing the S&P 500. Patience - the cosmos rewards long-term vision."
            } else {
                return "Tracking close to the benchmark. Cosmic equilibrium maintained."
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
        case .month, .threeMonth:
            formatter.dateFormat = "MMM d"
        case .year, .all:
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: date)
    }

    private func formatAxisValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
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
