import Foundation

final class TodayMarketHoroscopeComposer {
    static let shared = TodayMarketHoroscopeComposer()

    private let numericPortfolioCoverageThreshold = 0.70

    init() {}

    func compose(
        date: Date = Date(),
        user: UserProfile?,
        mood: CosmicMoodData,
        lunarData: LunarData,
        mercuryStatus: String,
        activeEventTitles: [String],
        portfolioSummaries: [PortfolioCosmicCorrelationSummary],
        stockCandidate: TodayStockCandidate?
    ) -> TodayMarketHoroscopeSummary {
        let cosmicContext = makeCosmicContext(
            mood: mood,
            lunarData: lunarData,
            mercuryStatus: mercuryStatus,
            activeEventTitles: activeEventTitles
        )
        let portfolioContext = makePortfolioContext(
            user: user,
            summaries: portfolioSummaries
        )
        let stockContext = stockCandidate.map(makeStockContext(candidate:))
        let provenance = aggregateProvenance(
            cosmic: cosmicContext.provenance,
            portfolio: portfolioContext.provenance,
            stock: stockContext?.provenance
        )
        let dataCoverage = makeDataCoverage(
            mood: mood,
            portfolioContext: portfolioContext,
            stockContext: stockContext
        )

        return TodayMarketHoroscopeSummary(
            date: date,
            cosmicContext: cosmicContext,
            portfolioContext: portfolioContext,
            stockContext: stockContext,
            dataCoverage: dataCoverage,
            provenance: provenance,
            disclaimer: "Historical context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    func makePortfolioContext(
        user: UserProfile?,
        summaries: [PortfolioCosmicCorrelationSummary]
    ) -> TodayPortfolioContext {
        guard let user, user.portfolio.contains(where: \.isOwned) else {
            return TodayPortfolioContext(
                headline: "Portfolio context needs holdings",
                detail: "Add holdings or import a portfolio so Today can map cosmic timing against your actual exposure.",
                eventName: nil,
                windowLabel: nil,
                eventCount: 0,
                sampleSize: 0,
                includedPortfolioWeight: 0,
                excludedPortfolioWeight: 0,
                unavailableHoldings: [],
                metrics: [],
                provenance: .unavailable(reason: "Portfolio holdings unavailable"),
                displayMode: .setupRequired
            )
        }

        guard let summary = preferredPortfolioSummary(from: summaries) else {
            return TodayPortfolioContext(
                headline: "Portfolio history unavailable",
                detail: "Portfolio correlation context will appear when provider-backed holding history is available.",
                eventName: nil,
                windowLabel: nil,
                eventCount: 0,
                sampleSize: 0,
                includedPortfolioWeight: 0,
                excludedPortfolioWeight: 1,
                unavailableHoldings: user.portfolio.filter(\.isOwned).map { $0.symbol.uppercased() }.sorted(),
                metrics: [],
                provenance: .unavailable(reason: "Portfolio historical data unavailable"),
                displayMode: .unavailable
            )
        }

        let displayMode = portfolioDisplayMode(for: summary)
        let metrics = displayMode == .marketBacked ? portfolioMetrics(for: summary) : []

        return TodayPortfolioContext(
            headline: portfolioHeadline(for: summary, displayMode: displayMode),
            detail: portfolioDetail(for: summary, displayMode: displayMode),
            eventName: summary.eventName,
            windowLabel: summary.window.displayName,
            eventCount: summary.eventCount,
            sampleSize: summary.sampleSize,
            includedPortfolioWeight: summary.includedPortfolioWeight,
            excludedPortfolioWeight: summary.excludedPortfolioWeight,
            unavailableHoldings: summary.unavailableHoldings,
            metrics: metrics,
            provenance: summary.provenance,
            displayMode: displayMode
        )
    }

    func makeStockContext(candidate: TodayStockCandidate) -> TodayStockContext {
        let stock = candidate.stock

        guard let summary = preferredStockSummary(from: candidate.summaries) else {
            return TodayStockContext(
                symbol: stock.symbol.uppercased(),
                name: stock.name,
                headline: "\(stock.symbol.uppercased()) historical context pending",
                detail: "Historical price data unavailable. Stock correlation context will appear when provider-backed history is available.",
                eventName: nil,
                windowLabel: nil,
                eventCount: 0,
                sampleSize: 0,
                metrics: [],
                provenance: candidate.provenance,
                displayMode: stockDisplayMode(for: candidate.provenance, completeness: candidate.completeness)
            )
        }

        let displayMode = stockDisplayMode(for: summary)
        let metrics = displayMode == .marketBacked ? stockMetrics(for: summary) : []

        return TodayStockContext(
            symbol: summary.symbol,
            name: stock.name,
            headline: stockHeadline(for: summary, displayMode: displayMode),
            detail: stockDetail(for: summary, displayMode: displayMode),
            eventName: summary.eventName,
            windowLabel: summary.window.displayName,
            eventCount: summary.eventCount,
            sampleSize: summary.sampleSize,
            metrics: metrics,
            provenance: summary.provenance,
            displayMode: displayMode
        )
    }

    private func makeCosmicContext(
        mood: CosmicMoodData,
        lunarData: LunarData,
        mercuryStatus: String,
        activeEventTitles: [String]
    ) -> TodayCosmicContext {
        let eventText = activeEventTitles.isEmpty
            ? "No major active cosmic alert is overriding the daily lens."
            : "Active context: \(activeEventTitles.prefix(3).joined(separator: ", "))."
        let marketTone = mood.isMarketBacked
            ? mood.marketToneText
            : "Market data unavailable"

        let detail: String
        if mood.isMarketBacked {
            detail = "Provider-backed market tone is \(marketTone). The \(lunarData.phase.rawValue.lowercased()) moon in \(lunarData.moonSign.displayName) adds cosmic timing context. \(eventText)"
        } else {
            detail = "Provider-backed market tone is unavailable. Today uses the \(lunarData.phase.rawValue.lowercased()) moon in \(lunarData.moonSign.displayName), Mercury status, and portfolio history where available. \(eventText)"
        }

        return TodayCosmicContext(
            headline: "Today reads as \(lunarData.phase.rawValue.lowercased()) \(mood.isMarketBacked ? "market context" : "cosmic context")",
            detail: detail,
            lunarLabel: "\(lunarData.phase.rawValue) / \(lunarData.moonSign.displayName)",
            mercuryLabel: mercuryStatus,
            marketToneLabel: mood.marketToneText,
            activeEvents: Array(activeEventTitles.prefix(3)),
            provenance: mood.provenance
        )
    }

    private func makeDataCoverage(
        mood: CosmicMoodData,
        portfolioContext: TodayPortfolioContext,
        stockContext: TodayStockContext?
    ) -> TodayDataCoverage {
        var rows: [TodayDataCoverageRow] = [
            TodayDataCoverageRow(
                label: "Market tone",
                value: mood.marketToneText,
                provenance: mood.provenance
            ),
            TodayDataCoverageRow(
                label: "Portfolio history",
                value: "\(percentRate(portfolioContext.includedPortfolioWeight)) included",
                provenance: portfolioContext.provenance
            )
        ]

        if let stockContext {
            rows.append(
                TodayDataCoverageRow(
                    label: "\(stockContext.symbol) history",
                    value: stockContext.displayMode.coverageLabel,
                    provenance: stockContext.provenance
                )
            )
        } else {
            rows.append(
                TodayDataCoverageRow(
                    label: "Stock lens",
                    value: "No candidate",
                    provenance: .unavailable(reason: "No portfolio or watchlist stock available")
                )
            )
        }

        let hasProviderBackedContext = portfolioContext.displayMode == .marketBacked
            || stockContext?.displayMode == .marketBacked
        let headline = hasProviderBackedContext
            ? "Source labels are active"
            : "Waiting on provider-backed history"
        let detail = hasProviderBackedContext
            ? "Numeric context appears only where provider-backed or cached historical datasets pass sample-size, completeness, and coverage gates."
            : "Today stays in cosmic or unavailable mode until provider-backed history clears the stock and portfolio gates."

        return TodayDataCoverage(headline: headline, detail: detail, rows: rows)
    }

    private func preferredPortfolioSummary(from summaries: [PortfolioCosmicCorrelationSummary]) -> PortfolioCosmicCorrelationSummary? {
        summaries.sorted { lhs, rhs in
            let lhsScore = portfolioModeRank(lhs.displayMode)
            let rhsScore = portfolioModeRank(rhs.displayMode)
            if lhsScore != rhsScore { return lhsScore < rhsScore }
            if lhs.sampleSize != rhs.sampleSize { return lhs.sampleSize > rhs.sampleSize }
            return lhs.eventName < rhs.eventName
        }
        .first
    }

    private func preferredStockSummary(from summaries: [StockCosmicCorrelationSummary]) -> StockCosmicCorrelationSummary? {
        summaries.sorted { lhs, rhs in
            let lhsScore = stockModeRank(lhs.displayMode)
            let rhsScore = stockModeRank(rhs.displayMode)
            if lhsScore != rhsScore { return lhsScore < rhsScore }
            if lhs.sampleSize != rhs.sampleSize { return lhs.sampleSize > rhs.sampleSize }
            return lhs.eventName < rhs.eventName
        }
        .first
    }

    private func portfolioDisplayMode(for summary: PortfolioCosmicCorrelationSummary) -> TodayPortfolioContext.DisplayMode {
        switch summary.displayMode {
        case .marketBackedResult:
            return summary.includedPortfolioWeight >= numericPortfolioCoverageThreshold ? .marketBacked : .partialContext
        case .partialCoverage:
            return .partialContext
        case .insufficientSample:
            return summary.includedPortfolioWeight < 0.5 ? .insufficientCoverage : .insufficientSample
        case .sampleOnly:
            return .sampleOnly
        case .partialDataset:
            return .partialContext
        case .insufficientDataset, .unavailable:
            return .unavailable
        }
    }

    private func stockDisplayMode(for summary: StockCosmicCorrelationSummary) -> TodayStockContext.DisplayMode {
        switch summary.displayMode {
        case .marketBackedResult:
            return .marketBacked
        case .partialCoverage, .partialDataset:
            return .partialDataset
        case .insufficientDataset:
            return .insufficientDataset
        case .insufficientSample:
            return .insufficientSample
        case .sampleOnly:
            return .sampleOnly
        case .unavailable:
            return .unavailable
        }
    }

    private func stockDisplayMode(
        for provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness
    ) -> TodayStockContext.DisplayMode {
        if case .sample = provenance {
            return .sampleOnly
        }
        guard provenance.isProviderBacked else { return .unavailable }

        switch completeness {
        case .complete:
            return .insufficientSample
        case .partial:
            return .partialDataset
        case .insufficient:
            return .insufficientDataset
        }
    }

    private func portfolioHeadline(
        for summary: PortfolioCosmicCorrelationSummary,
        displayMode: TodayPortfolioContext.DisplayMode
    ) -> String {
        switch displayMode {
        case .marketBacked:
            return "\(summary.eventName) portfolio context is ready"
        case .partialContext:
            return "Partial portfolio context only"
        case .insufficientCoverage:
            return "Portfolio history coverage is too thin"
        case .insufficientSample:
            return "Not enough \(summary.eventName) observations"
        case .sampleOnly:
            return "Sample portfolio history is labeled"
        case .setupRequired:
            return "Portfolio context needs holdings"
        case .unavailable:
            return "Portfolio history unavailable"
        }
    }

    private func portfolioDetail(
        for summary: PortfolioCosmicCorrelationSummary,
        displayMode: TodayPortfolioContext.DisplayMode
    ) -> String {
        let coverage = percentRate(summary.includedPortfolioWeight)
        switch displayMode {
        case .marketBacked:
            return "Provider-backed history covers \(coverage) of portfolio value. Metrics are value-weighted across holdings and use the \(summary.window.displayName) event window."
        case .partialContext:
            return "Provider-backed history covers \(coverage) of portfolio value. Coverage must reach 70% before headline return metrics appear."
        case .insufficientCoverage:
            return "Provider-backed history covers \(coverage) of portfolio value. At least 50% coverage is required before portfolio context appears."
        case .insufficientSample:
            return "The portfolio has provider-backed coverage, but this event does not have enough observations for a headline metric."
        case .sampleOnly, .unavailable:
            return summary.disclaimer
        case .setupRequired:
            return "Add holdings or import a portfolio so Today can map cosmic timing against your actual exposure."
        }
    }

    private func stockHeadline(
        for summary: StockCosmicCorrelationSummary,
        displayMode: TodayStockContext.DisplayMode
    ) -> String {
        switch displayMode {
        case .marketBacked:
            return "\(summary.symbol) \(summary.eventName) context is ready"
        case .partialDataset:
            return "\(summary.symbol) history is partial"
        case .insufficientDataset:
            return "\(summary.symbol) history is insufficient"
        case .insufficientSample:
            return "\(summary.symbol) needs more \(summary.eventName) observations"
        case .sampleOnly:
            return "\(summary.symbol) sample history is labeled"
        case .unavailable:
            return "\(summary.symbol) history unavailable"
        }
    }

    private func stockDetail(
        for summary: StockCosmicCorrelationSummary,
        displayMode: TodayStockContext.DisplayMode
    ) -> String {
        switch displayMode {
        case .marketBacked:
            return "Provider-backed history found \(summary.sampleSize) observations for \(summary.eventName) using the \(summary.window.displayName) window."
        case .partialDataset, .insufficientDataset, .insufficientSample, .sampleOnly, .unavailable:
            return summary.disclaimer
        }
    }

    private func portfolioMetrics(for summary: PortfolioCosmicCorrelationSummary) -> [TodayMetric] {
        [
            TodayMetric(label: "AVG PORT", value: percent(summary.averagePortfolioReturn)),
            TodayMetric(label: "WIN", value: percentRate(summary.winRate)),
            TodayMetric(label: "SAMPLE", value: "\(summary.sampleSize)")
        ]
    }

    private func stockMetrics(for summary: StockCosmicCorrelationSummary) -> [TodayMetric] {
        [
            TodayMetric(label: "AVG", value: percent(summary.averageReturn)),
            TodayMetric(label: "WIN", value: percentRate(summary.winRate)),
            TodayMetric(label: "SAMPLE", value: "\(summary.sampleSize)")
        ]
    }

    private func aggregateProvenance(
        cosmic: FinancialDataProvenance,
        portfolio: FinancialDataProvenance,
        stock: FinancialDataProvenance?
    ) -> FinancialDataProvenance {
        let provenances = [cosmic, portfolio] + [stock].compactMap { $0 }
        let providerBacked = provenances.filter(\.isProviderBacked)

        if providerBacked.count == provenances.count, !providerBacked.isEmpty {
            let fetchedAt = providerBacked.compactMap(\.fetchedAt).min() ?? Date()
            let allLive = providerBacked.allSatisfy { provenance in
                if case .live = provenance { return true }
                return false
            }
            return allLive
                ? .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
                : .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        }

        if providerBacked.isEmpty {
            return .unavailable(reason: "Provider-backed market and historical datasets unavailable")
        }

        return .mixed(reason: "Today combines provider-backed, cosmic, and unavailable datasets. See section labels for source state.")
    }

    private func portfolioModeRank(_ mode: CorrelationDisplayMode) -> Int {
        switch mode {
        case .marketBackedResult: return 0
        case .partialCoverage: return 1
        case .insufficientSample: return 2
        case .partialDataset: return 3
        case .insufficientDataset: return 4
        case .unavailable: return 5
        case .sampleOnly: return 6
        }
    }

    private func stockModeRank(_ mode: CorrelationDisplayMode) -> Int {
        switch mode {
        case .marketBackedResult: return 0
        case .insufficientSample: return 1
        case .partialCoverage, .partialDataset: return 2
        case .insufficientDataset: return 3
        case .unavailable: return 4
        case .sampleOnly: return 5
        }
    }

    private func percent(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "N/A" }
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }

    private func percentRate(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "N/A" }
        return String(format: "%.0f%%", value * 100)
    }
}

private extension TodayStockContext.DisplayMode {
    var coverageLabel: String {
        switch self {
        case .marketBacked:
            return "Ready"
        case .partialDataset:
            return "Partial"
        case .insufficientDataset:
            return "Insufficient"
        case .insufficientSample:
            return "Thin sample"
        case .unavailable:
            return "Unavailable"
        case .sampleOnly:
            return "Sample"
        }
    }
}
