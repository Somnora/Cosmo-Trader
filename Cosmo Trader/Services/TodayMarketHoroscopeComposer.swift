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
        stockCandidate: TodayStockCandidate?,
        marketWeather: MarketWeatherSummary? = nil
    ) -> TodayMarketHoroscopeSummary {
        let cosmicContext = makeCosmicContext(
            mood: mood,
            lunarData: lunarData,
            mercuryStatus: mercuryStatus,
            activeEventTitles: activeEventTitles
        )
        let marketContext = makeMarketContext(summary: marketWeather)
        let portfolioContext = makePortfolioContext(
            user: user,
            summaries: portfolioSummaries
        )
        let stockContext = stockCandidate.map(makeStockContext(candidate:)) ?? stockSetupContext()
        let provenance = aggregateProvenance(
            cosmic: cosmicContext.provenance,
            market: marketContext.provenance,
            portfolio: portfolioContext.provenance,
            stock: stockContext.provenance
        )
        let dataCoverage = makeDataCoverage(
            mood: mood,
            marketContext: marketContext,
            portfolioContext: portfolioContext,
            stockContext: stockContext
        )
        let primaryAction = makePrimaryAction(
            marketContext: marketContext,
            portfolioContext: portfolioContext,
            stockContext: stockContext
        )

        return TodayMarketHoroscopeSummary(
            date: date,
            cosmicContext: cosmicContext,
            marketContext: marketContext,
            portfolioContext: portfolioContext,
            stockContext: stockContext,
            dataCoverage: dataCoverage,
            primaryAction: primaryAction,
            provenance: provenance,
            disclaimer: "Historical context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    func makeMarketContext(summary: MarketWeatherSummary?) -> TodayMarketContext {
        guard let summary,
              let eventSummary = preferredMarketSummary(from: summary.eventSummaries) else {
            return TodayMarketContext(
                headline: "Market Weather unavailable",
                detail: "SPY, QQQ, DIA, and IWM history is required before Today can show broad market-weather context.",
                eventName: nil,
                windowLabel: nil,
                eventCount: 0,
                sampleSize: 0,
                includedSymbols: [],
                excludedSymbols: MarketWeatherService.v1Symbols.map(\.symbol),
                staleSymbols: [],
                coverage: 0,
                metrics: [],
                sectorBreadth: nil,
                provenance: .unavailable(reason: "Provider-backed market ETF history unavailable"),
                displayMode: .unavailable,
                activation: marketActivation(for: .unavailable)
            )
        }

        let displayMode = marketDisplayMode(for: eventSummary, summary: summary)
        let metrics = displayMode == .marketBacked ? marketMetrics(for: eventSummary) : []

        return TodayMarketContext(
            headline: marketHeadline(for: eventSummary, displayMode: displayMode),
            detail: marketDetail(for: eventSummary, summary: summary, displayMode: displayMode),
            eventName: eventSummary.eventName,
            windowLabel: eventSummary.window.displayName,
            eventCount: eventSummary.eventCount,
            sampleSize: eventSummary.sampleSize,
            includedSymbols: summary.includedSymbols,
            excludedSymbols: summary.excludedSymbols,
            staleSymbols: summary.staleSymbols,
            coverage: summary.coverage,
            metrics: metrics,
            sectorBreadth: summary.sectorBreadth.map(makeSectorBreadthContext(summary:)),
            provenance: eventSummary.provenance,
            displayMode: displayMode,
            activation: marketActivation(for: displayMode)
        )
    }

    func makeSectorBreadthContext(summary: MarketSectorBreadthSummary) -> TodayMarketSectorBreadth {
        let metrics: [TodayMetric]
        if summary.displayMode == .marketBackedResult,
           summary.provenance.isProviderBacked,
           !summary.provenance.isCachedStale() {
            metrics = [
                TodayMetric(label: "ADV SECTORS", value: percentRate(summary.advancingSectorRate)),
                TodayMetric(label: "AVG SECTOR", value: percent(summary.averageSectorReturn))
            ]
        } else {
            metrics = []
        }

        return TodayMarketSectorBreadth(
            headline: sectorBreadthHeadline(for: summary),
            detail: sectorBreadthDetail(for: summary),
            eventName: summary.eventName,
            sampleSize: summary.sampleSize,
            coverage: summary.coverage,
            includedSymbols: summary.includedSymbols,
            excludedSymbols: summary.excludedSymbols,
            staleSymbols: summary.staleSymbols,
            metrics: metrics,
            provenance: summary.provenance,
            displayMode: summary.displayMode
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
                displayMode: .setupRequired,
                activation: portfolioActivation(for: .setupRequired)
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
                displayMode: .unavailable,
                activation: portfolioActivation(for: .unavailable)
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
            displayMode: displayMode,
            activation: portfolioActivation(for: displayMode)
        )
    }

    func makeStockContext(candidate: TodayStockCandidate) -> TodayStockContext {
        let stock = candidate.stock

        guard let summary = preferredStockSummary(from: candidate.summaries) else {
            let displayMode = stockDisplayMode(for: candidate.provenance, completeness: candidate.completeness)
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
                displayMode: displayMode,
                activation: stockActivation(for: displayMode, hasCandidate: true)
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
            displayMode: displayMode,
            activation: stockActivation(for: displayMode, hasCandidate: true)
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
        marketContext: TodayMarketContext,
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
                label: "Market weather",
                value: "\(percentRate(marketContext.coverage)) fresh",
                provenance: marketContext.provenance
            ),
            TodayDataCoverageRow(
                label: "Sector breadth",
                value: marketContext.sectorBreadth.map { "\(percentRate($0.coverage)) sector coverage" } ?? "Unavailable",
                provenance: marketContext.sectorBreadth?.provenance ?? .unavailable(reason: "Provider-backed sector ETF history unavailable")
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
            || marketContext.displayMode == .marketBacked
            || stockContext?.displayMode == .marketBacked
        let headline = hasProviderBackedContext
            ? "Source labels are active"
            : "Waiting on provider-backed history"
        let detail = hasProviderBackedContext
            ? "Numeric context appears only where provider-backed or cached-fresh historical datasets pass sample-size, completeness, freshness, and coverage gates."
            : "Today stays in cosmic or unavailable mode until provider-backed history clears the market, stock, and portfolio gates."

        return TodayDataCoverage(
            headline: headline,
            detail: detail,
            rows: rows,
            explainers: dataLabelExplainers()
        )
    }

    private func makePrimaryAction(
        marketContext: TodayMarketContext,
        portfolioContext: TodayPortfolioContext,
        stockContext: TodayStockContext?
    ) -> TodayActivationPrompt? {
        if portfolioContext.displayMode == .setupRequired {
            return portfolioContext.activation
        }

        if let stockContext,
           stockContext.symbol == "WATCH",
           stockContext.displayMode != .marketBacked {
            return stockContext.activation
        }

        if marketContext.displayMode != .marketBacked {
            return marketContext.activation
        }

        if portfolioContext.displayMode != .marketBacked {
            return portfolioContext.activation
        }

        if let stockContext,
           stockContext.displayMode != .marketBacked {
            return stockContext.activation
        }

        return nil
    }

    func stockSetupContext() -> TodayStockContext {
        TodayStockContext(
            symbol: "WATCH",
            name: "Watchlist setup",
            headline: "Stock lens needs a ticker",
            detail: "Add a watchlist symbol or portfolio holding. Today will check provider-backed history before showing any stock pattern.",
            eventName: nil,
            windowLabel: nil,
            eventCount: 0,
            sampleSize: 0,
            metrics: [],
            provenance: .unavailable(reason: "No portfolio or watchlist stock available"),
            displayMode: .unavailable,
            activation: stockActivation(for: .unavailable, hasCandidate: false)
        )
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

    private func preferredMarketSummary(from summaries: [MarketWeatherEventSummary]) -> MarketWeatherEventSummary? {
        summaries.sorted { lhs, rhs in
            let lhsScore = marketModeRank(lhs.displayMode)
            let rhsScore = marketModeRank(rhs.displayMode)
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

    private func marketDisplayMode(
        for eventSummary: MarketWeatherEventSummary,
        summary: MarketWeatherSummary
    ) -> TodayMarketContext.DisplayMode {
        switch eventSummary.displayMode {
        case .marketBackedResult:
            return summary.coverage >= 1 ? .marketBacked : .partialContext
        case .partialCoverage, .partialDataset:
            return summary.staleSymbols.isEmpty ? .partialContext : .stale
        case .insufficientSample:
            return summary.staleSymbols.isEmpty ? .insufficientSample : .stale
        case .sampleOnly:
            return .sampleOnly
        case .insufficientDataset, .unavailable:
            return summary.staleSymbols.isEmpty ? .unavailable : .stale
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

    private func marketHeadline(
        for summary: MarketWeatherEventSummary,
        displayMode: TodayMarketContext.DisplayMode
    ) -> String {
        switch displayMode {
        case .marketBacked:
            return "\(summary.eventName) market weather is ready"
        case .partialContext:
            return "Partial Market Weather only"
        case .stale:
            return "Market Weather is stale"
        case .insufficientSample:
            return "Not enough \(summary.eventName) market observations"
        case .sampleOnly:
            return "Sample market history is labeled"
        case .unavailable:
            return "Market Weather unavailable"
        }
    }

    private func marketDetail(
        for eventSummary: MarketWeatherEventSummary,
        summary: MarketWeatherSummary,
        displayMode: TodayMarketContext.DisplayMode
    ) -> String {
        let coverage = percentRate(summary.coverage)
        switch displayMode {
        case .marketBacked:
            return "SPY, QQQ, DIA, and IWM have provider-backed fresh history. Metrics use the \(eventSummary.window.displayName) event window."
        case .partialContext:
            let excluded = summary.excludedSymbols.isEmpty ? "none" : summary.excludedSymbols.joined(separator: ", ")
            return "Fresh provider-backed market history covers \(coverage) of the V1 market basket. Excluded: \(excluded). Full fresh coverage is required before headline market metrics appear."
        case .stale:
            let stale = summary.staleSymbols.joined(separator: ", ")
            return "Cached market history is stale for \(stale). Market Weather stays context-only until fresh provider-backed history is available."
        case .insufficientSample:
            return "The market basket has provider-backed history, but this event does not have enough observations for a headline metric."
        case .sampleOnly, .unavailable:
            return eventSummary.disclaimer
        }
    }

    private func sectorBreadthHeadline(for summary: MarketSectorBreadthSummary) -> String {
        switch summary.displayMode {
        case .marketBackedResult:
            return "Sector breadth context is ready"
        case .partialCoverage, .partialDataset:
            return "Sector breadth is partial context only"
        case .insufficientSample:
            return "Sector breadth needs more observations"
        case .insufficientDataset:
            return "Sector breadth history is insufficient"
        case .sampleOnly:
            return "Sample sector history is labeled"
        case .unavailable:
            return "Sector breadth unavailable"
        }
    }

    private func sectorBreadthDetail(for summary: MarketSectorBreadthSummary) -> String {
        let coverage = percentRate(summary.coverage)
        switch summary.displayMode {
        case .marketBackedResult:
            return "Sector ETFs have complete fresh provider-backed history for \(summary.eventName ?? "the selected event"). Historical context only."
        case .partialCoverage, .partialDataset:
            let excluded = summary.excludedSymbols.isEmpty ? "none" : summary.excludedSymbols.joined(separator: ", ")
            return "Sector ETF coverage is \(coverage). Excluded: \(excluded). Full sector coverage is required before sector metrics appear."
        case .insufficientSample:
            return "Sector ETF history exists, but this event does not have enough observations for a sector metric."
        case .insufficientDataset, .sampleOnly, .unavailable:
            return summary.disclaimer
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

    private func marketActivation(for displayMode: TodayMarketContext.DisplayMode) -> TodayActivationPrompt? {
        switch displayMode {
        case .marketBacked:
            return nil
        case .partialContext:
            return TodayActivationPrompt(
                title: "Complete the market basket",
                detail: "Market Weather needs SPY, QQQ, DIA, and IWM provider-backed history before headline market metrics appear.",
                actionItems: [
                    "Refresh SPY / QQQ / DIA / IWM history",
                    "Keep unavailable ETFs out of numeric claims",
                    "Preserve the 100% basket gate"
                ],
                primaryActionTitle: "REFRESH MARKET CONTEXT",
                secondaryActionTitle: nil
            )
        case .stale:
            return TodayActivationPrompt(
                title: "Refresh stale market history",
                detail: "Cached provider-backed history is saved locally, but fresh SPY, QQQ, DIA, and IWM datasets are required for numeric market context.",
                actionItems: [
                    "Refresh SPY / QQQ / DIA / IWM history",
                    "Use cached history as context until fresh data clears",
                    "Keep stale data out of headline market metrics"
                ],
                primaryActionTitle: "REFRESH MARKET CONTEXT",
                secondaryActionTitle: nil
            )
        case .insufficientSample:
            return TodayActivationPrompt(
                title: "Need more market observations",
                detail: "The app found provider-backed history, but not enough matching events yet. Refresh can check the latest provider range.",
                actionItems: [
                    "Refresh provider-backed market history",
                    "Wait for enough Full Moon, New Moon, or Mercury Retrograde samples",
                    "Keep thin samples out of numeric claims"
                ],
                primaryActionTitle: "REFRESH MARKET CONTEXT",
                secondaryActionTitle: nil
            )
        case .unavailable:
            return TodayActivationPrompt(
                title: "Fetch provider-backed market history",
                detail: "Market Weather will appear after SPY, QQQ, DIA, and IWM history is available from the provider/cache path.",
                actionItems: [
                    "Fetch SPY / QQQ / DIA / IWM history",
                    "Show loading and provider/cache errors here",
                    "Do not create sample market data"
                ],
                primaryActionTitle: "FETCH MARKET HISTORY",
                secondaryActionTitle: nil
            )
        case .sampleOnly:
            return TodayActivationPrompt(
                title: "Replace sample context with provider data",
                detail: "Sample data is demo context only. Refresh uses the real provider/cache path and never creates fake market history.",
                actionItems: [
                    "Fetch provider-backed market history",
                    "Keep sample context visibly labeled",
                    "Require all four market ETFs before metrics"
                ],
                primaryActionTitle: "FETCH MARKET HISTORY",
                secondaryActionTitle: nil
            )
        }
    }

    private func portfolioActivation(for displayMode: TodayPortfolioContext.DisplayMode) -> TodayActivationPrompt? {
        switch displayMode {
        case .marketBacked:
            return nil
        case .setupRequired:
            return TodayActivationPrompt(
                title: "Add your first holding",
                detail: "Open Portfolio to add a holding manually or import a portfolio. You can also start with a watchlist if you are not ready to add holdings.",
                actionItems: [
                    "Add holding manually",
                    "Import portfolio",
                    "Add watchlist symbols"
                ],
                primaryActionTitle: "ADD HOLDING",
                secondaryActionTitle: "IMPORT PORTFOLIO",
                tertiaryActionTitle: "ADD WATCHLIST SYMBOLS"
            )
        case .partialContext, .insufficientCoverage, .insufficientSample, .unavailable:
            return TodayActivationPrompt(
                title: "Refresh portfolio history",
                detail: "Portfolio context unlocks when provider-backed holding history clears coverage, completeness, freshness, and sample-size gates.",
                actionItems: [
                    "Add holding manually",
                    "Import portfolio",
                    "Add watchlist symbols"
                ],
                primaryActionTitle: "ADD HOLDING",
                secondaryActionTitle: "IMPORT PORTFOLIO",
                tertiaryActionTitle: "ADD WATCHLIST SYMBOLS"
            )
        case .sampleOnly:
            return TodayActivationPrompt(
                title: "Replace sample portfolio context",
                detail: "Sample data is demo context only. Add/import real holdings so Today can evaluate actual portfolio exposure.",
                actionItems: [
                    "Add holding manually",
                    "Import portfolio",
                    "Add watchlist symbols"
                ],
                primaryActionTitle: "ADD HOLDING",
                secondaryActionTitle: "IMPORT PORTFOLIO",
                tertiaryActionTitle: "ADD WATCHLIST SYMBOLS"
            )
        }
    }

    private func stockActivation(
        for displayMode: TodayStockContext.DisplayMode,
        hasCandidate: Bool
    ) -> TodayActivationPrompt? {
        switch displayMode {
        case .marketBacked:
            return nil
        case .partialDataset, .insufficientDataset, .insufficientSample, .unavailable:
            return TodayActivationPrompt(
                title: hasCandidate ? "Refresh stock history" : "Add a stock to watch",
                detail: hasCandidate
                    ? "Stock context appears after provider-backed history clears completeness and sample-size gates."
                    : "Add watchlist symbols or holdings. Today will use provider-backed history before showing stock-level patterns.",
                actionItems: hasCandidate
                    ? [
                        "Refresh provider-backed stock history",
                        "Open Discover/Search to add symbols",
                        "Wait for enough historical event samples"
                    ]
                    : [
                        "Add symbol",
                        "Open Discover/Search",
                        "Provider-backed stock history unlocks this lens"
                    ],
                primaryActionTitle: hasCandidate ? "REFRESH TODAY CONTEXT" : "ADD WATCHLIST SYMBOLS",
                secondaryActionTitle: hasCandidate ? "OPEN DISCOVER / SEARCH" : "OPEN DISCOVER / SEARCH"
            )
        case .sampleOnly:
            return TodayActivationPrompt(
                title: "Replace sample stock context",
                detail: "Sample data is demo context only. Add watchlist symbols or holdings to request provider-backed stock history.",
                actionItems: [
                    "Add symbol",
                    "Open Discover/Search",
                    "Provider-backed stock history unlocks this lens"
                ],
                primaryActionTitle: "ADD WATCHLIST SYMBOLS",
                secondaryActionTitle: "OPEN DISCOVER / SEARCH"
            )
        }
    }

    private func dataLabelExplainers() -> [TodayDataLabelExplainer] {
        [
            TodayDataLabelExplainer(
                label: "Unavailable",
                detail: "Provider has not returned enough data yet."
            ),
            TodayDataLabelExplainer(
                label: "Sample data",
                detail: "Demo context only, not market data."
            ),
            TodayDataLabelExplainer(
                label: "Stored data",
                detail: "Saved locally from your setup."
            ),
            TodayDataLabelExplainer(
                label: "Cached/stale",
                detail: "Provider-backed data saved earlier."
            ),
            TodayDataLabelExplainer(
                label: "Partial",
                detail: "Some required data is missing."
            ),
            TodayDataLabelExplainer(
                label: "Insufficient",
                detail: "Not enough history for a reliable context view."
            )
        ]
    }

    private func marketMetrics(for summary: MarketWeatherEventSummary) -> [TodayMetric] {
        [
            TodayMetric(label: "AVG MKT", value: percent(summary.averageMarketReturn)),
            TodayMetric(label: "WIN", value: percentRate(summary.winRate)),
            TodayMetric(label: "SAMPLE", value: "\(summary.sampleSize)")
        ]
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
        market: FinancialDataProvenance,
        portfolio: FinancialDataProvenance,
        stock: FinancialDataProvenance?
    ) -> FinancialDataProvenance {
        let provenances = [cosmic, market, portfolio] + [stock].compactMap { $0 }
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

    private func marketModeRank(_ mode: CorrelationDisplayMode) -> Int {
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
