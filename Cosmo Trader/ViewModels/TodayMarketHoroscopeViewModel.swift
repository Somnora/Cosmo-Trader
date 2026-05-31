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

    func load(user: UserProfile?) async {
        let signature = signature(for: user)
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
            portfolioSummaries = await loadPortfolioSummaries(holdings: holdings)
            stockCandidate = await loadStockCandidate(for: user)
            marketWeather = await marketWeatherService.loadSummary(filterState: filterState)
        }

        summary = composer.compose(
            user: user,
            mood: mood,
            lunarData: lunarData,
            mercuryStatus: mercury.statusMessage,
            activeEventTitles: activeEvents,
            portfolioSummaries: portfolioSummaries,
            stockCandidate: stockCandidate,
            marketWeather: marketWeather
        )

        isLoading = false
    }

    func reload(user: UserProfile?) async {
        loadedSignature = nil
        await load(user: user)
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
        for stock in candidateStocks(from: user) {
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
                    completeness: dataset.completeness
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

        if let fallback = candidateStocks(from: user).first {
            return TodayStockCandidate(
                stock: fallback,
                summaries: [],
                provenance: .unavailable(reason: "Provider-backed historical prices unavailable"),
                completeness: .insufficient(reason: "Provider-backed historical prices unavailable")
            )
        }

        return nil
    }

    private func candidateStocks(from user: UserProfile?) -> [Stock] {
        guard let user else { return [] }

        var seen: Set<String> = []
        var candidates: [Stock] = []

        for holding in user.portfolio.filter(\.isOwned).sorted(by: { $0.marketValue > $1.marketValue }) {
            let symbol = holding.symbol.uppercased()
            guard !seen.contains(symbol) else { continue }
            seen.insert(symbol)
            candidates.append(holding)
        }

        for symbol in user.watchlist.map({ $0.uppercased() }) {
            guard !seen.contains(symbol),
                  let stock = MockStockData.knownStocks.first(where: { $0.symbol.uppercased() == symbol }) else {
                continue
            }
            seen.insert(symbol)
            candidates.append(stock)
        }

        return Array(candidates.prefix(4))
    }

    private func signature(for user: UserProfile?) -> String {
        guard let user else { return "no-user" }
        let holdings = user.portfolio
            .filter(\.isOwned)
            .map { "\($0.symbol.uppercased()):\($0.sharesOwned):\($0.marketValue)" }
            .sorted()
            .joined(separator: "|")
        let watchlist = user.watchlist
            .map { $0.uppercased() }
            .sorted()
            .joined(separator: "|")
        return "\(user.id.uuidString)|\(holdings)|\(watchlist)"
    }
}
