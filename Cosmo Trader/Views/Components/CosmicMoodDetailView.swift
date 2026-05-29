import SwiftUI

// MARK: - Cosmic Mood Detail View
// ================================
// Full detail view showing the Cosmic Mood Index gauge, contributing factors,
// historical context, and trading insights.

struct CosmicMoodDetailView: View {

    // MARK: - Properties

    let moodData: CosmicMoodData

    // MARK: - State

    @State private var selectedCategory: MoodFactorCategory?
    @State private var showHistoryChart: Bool = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Main gauge
                gaugeSection

                // Trading signal
                tradingSignalCard

                // Contributing factors
                factorsSection

                // Historical insight
                historicalInsightSection

                // Mood history mini chart
                if showHistoryChart {
                    moodHistorySection
                }

                // Disclaimer
                disclaimer

                Spacer(minLength: 40)
            }
            .padding(20)
        }
    }

    // MARK: - Gauge Section

    private var gaugeSection: some View {
        VStack(spacing: 16) {
            CosmicMoodGauge(moodData: moodData, size: .large)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Trading Signal Card

    private var tradingSignalCard: some View {
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: moodData.displaySymbol)
                    .font(.title2)
                    .foregroundColor(moodData.displayColor)

                Text(moodData.moodLevel?.tradingSignal ?? moodData.label)
                    .font(TerminalFont.headline(16))
                    .foregroundColor(moodData.displayColor)

                Spacer()

                // Contrarian indicator
                if isContrarianOpportunity {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                        Text("Contrarian")
                            .font(TerminalFont.data(10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(moodData.displayColor)
                    )
                }
            }

            Text(moodData.moodLevel?.marketInsight ?? "Provider-backed market factors are unavailable. This panel is cosmic context only, not a market sentiment score.")
                .font(TerminalFont.body(13))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(moodData.displayColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(moodData.displayColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var isContrarianOpportunity: Bool {
        guard moodData.isMarketBacked, let moodLevel = moodData.moodLevel else { return false }
        return moodLevel == .void || moodLevel == .supernova
    }

    // MARK: - Factors Section

    private var factorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(CosmicTheme.gold)

                Text("Contributing Factors")
                    .font(TerminalFont.headline(16))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                // Category filter
                Menu {
                    Button("All Factors") { selectedCategory = nil }
                    ForEach(MoodFactorCategory.allCases, id: \.self) { category in
                        Button(category.rawValue) { selectedCategory = category }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCategory?.rawValue ?? "All")
                            .font(TerminalFont.data(11))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }

            // Category pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryPill(nil, label: "All")
                    ForEach(MoodFactorCategory.allCases, id: \.self) { category in
                        categoryPill(category, label: category.rawValue)
                    }
                }
            }

            // Factors list
            VStack(spacing: 12) {
                ForEach(filteredFactors) { factor in
                    factorRow(factor)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private var filteredFactors: [MoodFactor] {
        if let category = selectedCategory {
            return moodData.factors.filter { $0.category == category }
        }
        return moodData.factors
    }

    private func categoryPill(_ category: MoodFactorCategory?, label: String) -> some View {
        let isSelected = selectedCategory == category

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 4) {
                if let cat = category {
                    Image(systemName: cat.icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(TerminalFont.data(11, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .white : CosmicTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? (category?.color ?? CosmicTheme.gold) : CosmicTheme.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private func factorRow(_ factor: MoodFactor) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(factor.category.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Text(factor.icon)
                    .font(.system(size: 18))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(factor.name)
                        .font(TerminalFont.data(13, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("·")
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(factor.category.rawValue)
                        .font(TerminalFont.data(10))
                        .foregroundColor(factor.category.color)
                }

                Text(factor.description)
                    .font(TerminalFont.body(11))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(2)
            }

            Spacer()

            // Value indicator
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: factorDirectionIcon(factor))
                        .font(.caption2)
                    Text(factor.value.map { "\(abs($0))" } ?? "N/A")
                        .font(TerminalFont.price(14))
                }
                .foregroundColor(factor.color)

                // Weight indicator
                Text(String(format: "%.0f%% weight", factor.weight * 100))
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    private func factorDirectionIcon(_ factor: MoodFactor) -> String {
        guard let value = factor.value else { return "exclamationmark.triangle" }
        if value > 0 { return "arrow.up" }
        if value < 0 { return "arrow.down" }
        return "minus"
    }

    // MARK: - Historical Insight Section

    @ViewBuilder
    private var historicalInsightSection: some View {
        if moodData.isMarketBacked, let moodLevel = moodData.moodLevel {
            historicalInsightSection(for: moodLevel)
        } else {
            unavailableHistoricalContext
        }
    }

    private func historicalInsightSection(for moodLevel: CosmicMoodLevel) -> some View {
        let insight = HistoricalInsight.insight(for: moodLevel)

        return VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(CosmicTheme.nebulaBlue)

                Text("Historical Context")
                    .font(TerminalFont.headline(16))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showHistoryChart.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showHistoryChart ? "chart.xyaxis.line" : "chart.line.uptrend.xyaxis")
                            .font(.caption)
                        Text(showHistoryChart ? "Hide" : "Chart")
                            .font(TerminalFont.data(11))
                    }
                    .foregroundColor(CosmicTheme.nebulaBlue)
                }
            }

            // Insight card
            HStack(alignment: .top, spacing: 16) {
                // Return indicator
                VStack(spacing: 4) {
                    Text(insight.formattedReturn)
                        .font(TerminalFont.price(24))
                        .foregroundColor(historicalReturnColor(insight.historicalReturn))

                    Text(insight.timeframe)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .frame(width: 80)

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.title)
                        .font(TerminalFont.headline(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(insight.description)
                        .font(TerminalFont.body(12))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(3)

                    Text(insight.sampleSize)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                        .italic()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.secondaryBackground)
            )

            // Contrarian wisdom quote
            if insight.isContrarianSignal {
                HStack(spacing: 12) {
                    Image(systemName: "quote.opening")
                        .font(.title3)
                        .foregroundColor(CosmicTheme.gold.opacity(0.6))

                    Text(contrarianQuote)
                        .font(TerminalFont.body(12))
                        .italic()
                        .foregroundColor(CosmicTheme.textSecondary)

                    Image(systemName: "quote.closing")
                        .font(.title3)
                        .foregroundColor(CosmicTheme.gold.opacity(0.6))
                }
                .padding(12)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private var contrarianQuote: String {
        if let moodLevel = moodData.moodLevel, moodLevel == .void || moodLevel == .eclipse {
            return "Be greedy when others are fearful."
        } else {
            return "Be fearful when others are greedy."
        }
    }

    private var unavailableHistoricalContext: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(CosmicTheme.textMuted)

                Text("Historical Context")
                    .font(TerminalFont.headline(16))
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            Text("Historical context unavailable")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textPrimary)

            Text("Provider-backed market history is required before Cosmo shows market sentiment scores or historical return context.")
                .font(TerminalFont.body(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func historicalReturnColor(_ value: Double?) -> Color {
        guard let value else { return CosmicTheme.textMuted }
        return value >= 0 ? CosmicTheme.positive : CosmicTheme.negative
    }

    // MARK: - Mood History Section

    private var moodHistorySection: some View {
        let entries = CosmicMoodService.shared.getMoodHistory(days: 30)

        return VStack(alignment: .leading, spacing: 12) {
            Text("30-Day Mood History")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textPrimary)

            if entries.isEmpty || !moodData.isMarketBacked || moodData.value == nil {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(CosmicTheme.textMuted)
                    Text("Mood history unavailable")
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                    Text("History will appear when provider-backed market data is connected.")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                MoodHistoryChart(
                    entries: entries,
                    currentValue: moodData.value ?? 50
                )
                .frame(height: 120)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)

            Text("The Cosmic Mood Index is an entertainment lens. Market-history factors show unavailable states until provider data is connected. Not financial advice.")
                .font(TerminalFont.body(10))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CosmicTheme.background.opacity(0.5))
        )
    }
}

// MARK: - Mood History Chart

struct MoodHistoryChart: View {
    let entries: [MoodHistoryEntry]
    let currentValue: Int

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // Background zones
                moodZones(width: width, height: height)

                // Chart line
                chartPath(width: width, height: height)
                    .stroke(
                        LinearGradient(
                            colors: [CosmicTheme.nebulaBlue, CosmicTheme.accentBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )

                // Current value dot
                if let lastEntry = entries.last {
                    let x = width
                    let y = height - (CGFloat(lastEntry.value) / 100 * height)

                    Circle()
                        .fill(lastEntry.moodLevel.color)
                        .frame(width: 8, height: 8)
                        .position(x: x - 4, y: y)
                }
            }
        }
    }

    private func moodZones(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Supernova zone (81-100)
            Rectangle()
                .fill(Color.orange.opacity(0.1))
                .frame(height: height * 0.2)

            // Radiant zone (61-80)
            Rectangle()
                .fill(CosmicTheme.gold.opacity(0.08))
                .frame(height: height * 0.2)

            // Twilight zone (41-60)
            Rectangle()
                .fill(CosmicTheme.accentBlue.opacity(0.06))
                .frame(height: height * 0.2)

            // Eclipse zone (21-40)
            Rectangle()
                .fill(Color.blue.opacity(0.08))
                .frame(height: height * 0.2)

            // Void zone (0-20)
            Rectangle()
                .fill(Color.blue.opacity(0.12))
                .frame(height: height * 0.2)
        }
    }

    private func chartPath(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        guard entries.count > 1 else { return path }

        let stepX = width / CGFloat(entries.count - 1)

        for (index, entry) in entries.enumerated() {
            let x = CGFloat(index) * stepX
            let y = height - (CGFloat(entry.value) / 100 * height)

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

// MARK: - Cosmic Mood Detail Sheet

struct CosmicMoodDetailSheet: View {
    let moodData: CosmicMoodData

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CosmicMoodDetailView(moodData: moodData)
                .background(CosmicTheme.background)
                .navigationTitle("Cosmic Mood")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundColor(CosmicTheme.gold)
                    }

                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            Image(systemName: moodData.displaySymbol)
                                .foregroundColor(moodData.displayColor)
                            Text("Cosmic Mood")
                                .font(.headline)
                                .foregroundColor(CosmicTheme.textPrimary)
                        }
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview("Cosmic Mood Detail") {
    let service = CosmicMoodService.shared
    let moodData = service.getCurrentMood()

    return CosmicMoodDetailSheet(moodData: moodData)
}

#Preview("Extreme Fear") {
    let mockData = CosmicMoodData(
        date: Date(),
        value: 12,
        factors: [
            MoodFactor(name: "Moon Phase", category: .cosmic, value: -20, weight: 0.15, description: "Full moon heightens volatility", icon: "🌕"),
            MoodFactor(name: "Volatility", category: .volatility, value: -35, weight: 0.20, description: "VIX elevated at 32", icon: "waveform.path.ecg"),
            MoodFactor(name: "Market Trend", category: .market, value: -40, weight: 0.20, description: "Markets down 5% this week", icon: "chart.line.downtrend.xyaxis")
        ],
        change: -8
    )

    return CosmicMoodDetailSheet(moodData: mockData)
}
