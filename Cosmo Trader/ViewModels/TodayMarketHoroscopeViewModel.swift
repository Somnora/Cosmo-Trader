import Foundation

@MainActor
@Observable
final class TodayMarketHoroscopeViewModel {
    var summary: TodayMarketHoroscopeSummary?
    var isLoading = false
    var errorMessage: String?

    private let composer: TodayMarketHoroscopeComposer
    private let datasetStore: CorrelationDatasetStore
    private let portfolioCorrelationService: PortfolioCosmicCorrelationService
    private let astroCorrelationService: AstroCorrelationService
    private let marketWeatherService: MarketWeatherService
    private let overlayEventService: AstroOverlayEventService
    private let filterState = AstroOverlayFilterState(
        enabledKinds: [.fullMoon, .newMoon, .mercuryRetrograde],
        showEstimatedEvents: true,
        eventWindowDays: 3
    )
    private let timeframe: ChartTimeframe = .year
    private var loadedSignature: String?

    init(
        composer: TodayMarketHoroscopeComposer? = nil,
        datasetStore: CorrelationDatasetStore? = nil,
        portfolioCorrelationService: PortfolioCosmicCorrelationService? = nil,
        astroCorrelationService: AstroCorrelationService? = nil,
        marketWeatherService: MarketWeatherService? = nil,
        overlayEventService: AstroOverlayEventService? = nil
    ) {
        self.composer = composer ?? TodayMarketHoroscopeComposer.shared
        self.datasetStore = datasetStore ?? CorrelationDatasetStore.shared
        self.portfolioCorrelationService = portfolioCorrelationService ?? PortfolioCosmicCorrelationService.shared
        self.astroCorrelationService = astroCorrelationService ?? AstroCorrelationService.shared
        self.marketWeatherService = marketWeatherService ?? MarketWeatherService.shared
        self.overlayEventService = overlayEventService ?? AstroOverlayEventService.shared
    }

    func load(user: UserProfile?, firstRunSetupSkipped: Bool = false) async {
        let signature = signature(for: user, firstRunSetupSkipped: firstRunSetupSkipped)
        if loadedSignature == signature, summary != nil {
            return
        }

        loadedSignature = signature
        isLoading = true
        errorMessage = nil

        let lunarData = MoonPhaseService.shared.getCurrentLunarData()
        let mercury = MercuryRetrogradeService.shared
        mercury.refreshStatus()
        let mood = CosmicMoodService.shared.getCurrentMood()
        let activeEvents = AstroAlertService.shared.activeEvents.map(\.title)

        let portfolioSummaries: [PortfolioCosmicCorrelationSummary]
        let stockCandidate: TodayStockCandidate?
        let marketWeather: MarketWeatherSummary?

        if AppState.isScreenshotMode {
            portfolioSummaries = []
            stockCandidate = nil
            marketWeather = nil
        } else {
            let holdings = user?.portfolio.filter(\.isOwned) ?? []
            // The three context loads are independent; run them concurrently
            // so Today paints after the slowest one instead of their sum.
            async let portfolioTask = loadPortfolioSummaries(holdings: holdings)
            async let stockTask = loadStockCandidate(for: user)
            async let weatherTask = marketWeatherService.loadSummary(filterState: filterState)
            portfolioSummaries = await portfolioTask
            stockCandidate = await stockTask
            marketWeather = await weatherTask
        }

        summary = composer.compose(
            user: user,
            mood: mood,
            lunarData: lunarData,
            mercuryStatus: mercury.statusMessage,
            activeEventTitles: activeEvents,
            portfolioSummaries: portfolioSummaries,
            stockCandidate: stockCandidate,
            marketWeather: marketWeather,
            firstRunSetupSkipped: firstRunSetupSkipped
        )

        isLoading = false
    }

    func reload(user: UserProfile?, firstRunSetupSkipped: Bool = false) async {
        loadedSignature = nil
        await load(user: user, firstRunSetupSkipped: firstRunSetupSkipped)
    }

    private func loadPortfolioSummaries(holdings: [Stock]) async -> [PortfolioCosmicCorrelationSummary] {
        let ownedHoldings = holdings
            .filter(\.isOwned)
            .filter { $0.marketValue > 0 }
        guard !ownedHoldings.isEmpty else { return [] }

        let snapshot = await datasetStore.datasets(
            symbols: ownedHoldings.map(\.symbol),
            timeframe: timeframe
        )
        let allDates = snapshot.priceHistoryBySymbol.values.flatMap { $0.map(\.date) }
        let events: [AstroOverlayEvent]

        if let firstDate = allDates.min(),
           let lastDate = allDates.max(),
           let representative = ownedHoldings.first {
            events = overlayEventService.events(
                for: representative,
                from: firstDate,
                to: lastDate,
                filters: filterState
            )
            .filter { portfolioCorrelationService.supportedEventKinds.contains($0.kind) }
        } else {
            events = []
        }

        return portfolioCorrelationService.summaries(
            holdings: ownedHoldings,
            priceHistoryBySymbol: snapshot.priceHistoryBySymbol,
            provenanceBySymbol: snapshot.provenanceBySymbol,
            completenessBySymbol: snapshot.completenessBySymbol,
            events: events,
            filterState: filterState
        )
    }

    private func loadStockCandidate(for user: UserProfile?) async -> TodayStockCandidate? {
        let candidates = candidateStocks(from: user)
        for candidateInput in candidates {
            let stock = candidateInput.stock
            let symbol = stock.symbol.uppercased()

            do {
                let dataset = try await datasetStore.dataset(symbol: symbol, timeframe: timeframe)
                let prices = dataset.ohlcData
                let events: [AstroOverlayEvent]
                if let firstDate = prices.first?.date, let lastDate = prices.last?.date {
                    events = overlayEventService.events(
                        for: stock,
                        from: firstDate,
                        to: lastDate,
                        filters: filterState
                    )
                    .filter { portfolioCorrelationService.supportedEventKinds.contains($0.kind) }
                } else {
                    events = []
                }

                let summaries = astroCorrelationService.stockSummaries(
                    symbol: symbol,
                    prices: prices,
                    events: events,
                    filterState: filterState,
                    provenance: dataset.correlationDisplayProvenance,
                    completeness: dataset.completeness
                )

                let candidate = TodayStockCandidate(
                    stock: stock,
                    summaries: summaries,
                    provenance: dataset.correlationDisplayProvenance,
                    completeness: dataset.completeness,
                    source: candidateInput.source
                )

                if summaries.contains(where: { $0.displayMode == .marketBackedResult }) {
                    return candidate
                }

                if summaries.contains(where: { $0.displayMode == .insufficientSample }) {
                    return candidate
                }
            } catch {
                continue
            }
        }

        if let fallback = candidates.first {
            return TodayStockCandidate(
                stock: fallback.stock,
                summaries: [],
                provenance: .unavailable(reason: "Provider-backed historical prices unavailable"),
                completeness: .insufficient(reason: "Provider-backed historical prices unavailable"),
                source: fallback.source
            )
        }

        return nil
    }

    func candidateStocks(from user: UserProfile?) -> [(stock: Stock, source: TodayStockCandidateSource)] {
        guard let user else { return [] }

        var seen: Set<String> = []
        var candidates: [(stock: Stock, source: TodayStockCandidateSource)] = []

        // Watchlist-first users should get a Today stock lens without
        // needing portfolio holdings. Use known company metadata only; this
        // never supplies fake quote or history data.
        for symbol in user.watchlist.map({ $0.uppercased() }) {
            guard !seen.contains(symbol),
                  let stock = MockStockData.knownStocks.first(where: { $0.symbol.uppercased() == symbol }) else {
                continue
            }
            seen.insert(symbol)
            candidates.append((stock, .watchlist))
        }

        for holding in user.portfolio.filter(\.isOwned).sorted(by: { $0.marketValue > $1.marketValue }) {
            let symbol = holding.symbol.uppercased()
            guard !seen.contains(symbol) else { continue }
            seen.insert(symbol)
            candidates.append((holding, .portfolio))
        }

        return Array(candidates.prefix(4))
    }

    private func signature(for user: UserProfile?, firstRunSetupSkipped: Bool) -> String {
        guard let user else { return "no-user|setupSkipped:\(firstRunSetupSkipped)" }
        let holdings = user.portfolio
            .filter(\.isOwned)
            .map { "\($0.symbol.uppercased()):\($0.sharesOwned):\($0.marketValue)" }
            .sorted()
            .joined(separator: "|")
        let watchlist = user.watchlist
            .map { $0.uppercased() }
            .sorted()
            .joined(separator: "|")
        return "\(user.id.uuidString)|\(holdings)|\(watchlist)|setupSkipped:\(firstRunSetupSkipped)"
    }
}
