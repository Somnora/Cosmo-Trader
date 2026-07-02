import Foundation

nonisolated enum PortfolioHistorySymbolState: Equatable {
    case live
    case cachedFresh
    case cachedStale
    case partial
    case insufficient
    case unavailable

    var label: String {
        switch self {
        case .live:
            return "Live"
        case .cachedFresh:
            return "Cached"
        case .cachedStale:
            return "Stale"
        case .partial:
            return "Partial"
        case .insufficient:
            return "Insufficient"
        case .unavailable:
            return "Unavailable"
        }
    }

    var detail: String {
        switch self {
        case .live:
            return "Provider-backed history loaded"
        case .cachedFresh:
            return "Cached provider history loaded"
        case .cachedStale:
            return "Provider history is cached and stale"
        case .partial:
            return "Provider returned only part of the requested range"
        case .insufficient:
            return "Provider returned too little history"
        case .unavailable:
            return "Provider history not loaded yet"
        }
    }

    var isUsableForPortfolioCorrelation: Bool {
        switch self {
        case .live, .cachedFresh, .cachedStale:
            return true
        case .partial, .insufficient, .unavailable:
            return false
        }
    }
}

nonisolated struct PortfolioHistorySymbolStatus: Identifiable, Equatable {
    let id: String
    let symbol: String
    let portfolioWeight: Double
    let state: PortfolioHistorySymbolState
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness

    var label: String { state.label }
    var detail: String { state.detail }

    var isUsableForPortfolioCorrelation: Bool {
        state.isUsableForPortfolioCorrelation
            && provenance.isProviderBacked
            && completeness.allowsNumericCorrelationClaims
    }
}

@MainActor
@Observable
final class PortfolioCorrelationViewModel {
    var summaries: [PortfolioCosmicCorrelationSummary] = []
    var historySymbolStatuses: [PortfolioHistorySymbolStatus] = []
    var isLoading = false
    var errorMessage: String?
    var eventCount = 0
    var historicalPriceProvenance: FinancialDataProvenance = .unavailable(reason: "Portfolio historical data unavailable")
    var historyCoverageDiagnostics: PortfolioHistoryCoverageDiagnostics = .empty

    let checkedEventKinds: [AstroOverlayEventKind]
    let filterState = AstroOverlayFilterState(
        enabledKinds: [.fullMoon, .newMoon, .mercuryRetrograde],
        showEstimatedEvents: true,
        eventWindowDays: 3
    )
    let timeframe: ChartTimeframe = .year

    private let datasetStore: CorrelationDatasetStore
    private let portfolioCorrelationService: PortfolioCosmicCorrelationService
    private let overlayEventService: AstroOverlayEventService
    private var loadedSignature: String?

    convenience init() {
        self.init(
            datasetStore: .shared,
            portfolioCorrelationService: .shared,
            overlayEventService: .shared
        )
    }

    convenience init(datasetStore: CorrelationDatasetStore) {
        self.init(
            datasetStore: datasetStore,
            portfolioCorrelationService: .shared,
            overlayEventService: .shared
        )
    }

    init(
        datasetStore: CorrelationDatasetStore,
        portfolioCorrelationService: PortfolioCosmicCorrelationService,
        overlayEventService: AstroOverlayEventService
    ) {
        self.datasetStore = datasetStore
        self.portfolioCorrelationService = portfolioCorrelationService
        self.overlayEventService = overlayEventService
        self.checkedEventKinds = portfolioCorrelationService.supportedEventKinds
    }

    var windowLabel: String {
        CorrelationWindow(daysBefore: 1, daysAfter: max(1, filterState.eventWindowDays)).displayName
    }

    var includedPortfolioWeight: Double {
        summaries.map(\.includedPortfolioWeight).max() ?? 0
    }

    var excludedPortfolioWeight: Double {
        summaries.map(\.excludedPortfolioWeight).max() ?? 0
    }

    var providerBackedHistoryWeight: Double {
        historySymbolStatuses
            .filter(\.isUsableForPortfolioCorrelation)
            .reduce(0) { $0 + $1.portfolioWeight }
    }

    var unavailableHoldings: [String] {
        if !historySymbolStatuses.isEmpty {
            return historySymbolStatuses
                .filter { !$0.isUsableForPortfolioCorrelation }
                .map(\.symbol)
                .sorted()
        }

        return Array(Set(summaries.flatMap(\.unavailableHoldings))).sorted()
    }

    var usableHistorySymbols: [String] {
        historySymbolStatuses
            .filter(\.isUsableForPortfolioCorrelation)
            .map(\.symbol)
            .sorted()
    }

    var historyActivationTitle: String {
        if isLoading { return "Loading provider history" }
        if providerBackedHistoryWeight >= 0.70 { return "Refresh provider history" }
        if providerBackedHistoryWeight > 0 { return "Load more provider history" }
        return "Load provider history"
    }

    var historyActivationDetail: String {
        if historySymbolStatuses.isEmpty {
            return "Provider-backed holding history unlocks Today, Portfolio Intelligence, and portfolio correlation."
        }

        let needed = unavailableHoldings.prefix(5).joined(separator: ", ")
        if needed.isEmpty {
            return "History loaded for tracked holdings. Refresh checks the provider/cache path again."
        }

        return "History needed for \(needed). Refresh checks the provider/cache path and never creates sample candles."
    }

    var hasMarketBackedResult: Bool {
        summaries.contains { summary in
            summary.displayMode == .marketBackedResult
        }
    }

    func load(holdings: [Stock], force: Bool = false) async {
        let ownedHoldings = holdings
            .filter(\.isOwned)
            .filter { $0.marketValue > 0 }
        let signature = ownedHoldings
            .map { "\($0.symbol.uppercased()):\($0.sharesOwned):\($0.marketValue)" }
            .sorted()
            .joined(separator: "|")

        guard !signature.isEmpty else {
            summaries = []
            historySymbolStatuses = []
            eventCount = 0
            historicalPriceProvenance = .unavailable(reason: "No initialized portfolio holdings")
            historyCoverageDiagnostics = .empty
            errorMessage = nil
            loadedSignature = signature
            return
        }

        if !force,
           loadedSignature == signature,
           (isLoading || !summaries.isEmpty || !historyCoverageDiagnostics.rows.isEmpty) {
            return
        }

        loadedSignature = signature
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let datasetSnapshot = await datasetStore.datasets(
            symbols: ownedHoldings.map(\.symbol),
            timeframe: timeframe
        )
        historyCoverageDiagnostics = PortfolioHistoryCoverageDiagnostics.make(
            holdings: ownedHoldings,
            datasetSnapshot: datasetSnapshot
        )
        historySymbolStatuses = Self.makeHistoryStatuses(
            holdings: ownedHoldings,
            snapshot: datasetSnapshot
        )
        let priceHistoryBySymbol = datasetSnapshot.priceHistoryBySymbol
        let provenanceBySymbol = datasetSnapshot.provenanceBySymbol
        let completenessBySymbol = datasetSnapshot.completenessBySymbol

        let allDates = priceHistoryBySymbol.values.flatMap { $0.map(\.date) }
        let events: [AstroOverlayEvent]
        if let firstDate = allDates.min(),
           let lastDate = allDates.max(),
           let representativeHolding = ownedHoldings.first {
            events = overlayEventService.events(
                for: representativeHolding,
                from: firstDate,
                to: lastDate,
                filters: filterState
            )
            .filter { portfolioCorrelationService.supportedEventKinds.contains($0.kind) }
        } else {
            events = []
        }

        let nextSummaries = portfolioCorrelationService.summaries(
            holdings: ownedHoldings,
            priceHistoryBySymbol: priceHistoryBySymbol,
            provenanceBySymbol: provenanceBySymbol,
            completenessBySymbol: completenessBySymbol,
            events: events,
            filterState: filterState
        )

        summaries = nextSummaries
        eventCount = events.count
        historicalPriceProvenance = aggregateHistoryProvenance(
            from: historySymbolStatuses,
            fallbackSummaries: nextSummaries
        )
        if nextSummaries.allSatisfy({ $0.displayMode == .unavailable }) {
            errorMessage = "Portfolio correlation context will appear when provider-backed holding history is available."
        }
    }

    func reload(holdings: [Stock]) async {
        loadedSignature = nil
        await load(holdings: holdings)
    }

    static func makeHistoryStatuses(
        holdings: [Stock],
        snapshot: CorrelationHistoricalDatasetSnapshot
    ) -> [PortfolioHistorySymbolStatus] {
        let ownedHoldings = holdings
            .filter(\.isOwned)
            .filter { $0.marketValue > 0 }
        let totalValue = ownedHoldings.reduce(0) { $0 + $1.marketValue }
        guard totalValue > 0 else { return [] }

        return ownedHoldings
            .sorted { lhs, rhs in
                if lhs.marketValue == rhs.marketValue {
                    return lhs.symbol.uppercased() < rhs.symbol.uppercased()
                }
                return lhs.marketValue > rhs.marketValue
            }
            .map { holding in
                let symbol = holding.symbol.uppercased()
                let portfolioWeight = holding.marketValue / totalValue

                guard let dataset = snapshot.datasetsBySymbol[symbol] else {
                    return PortfolioHistorySymbolStatus(
                        id: symbol,
                        symbol: symbol,
                        portfolioWeight: portfolioWeight,
                        state: .unavailable,
                        provenance: snapshot.unavailableProvenanceBySymbol[symbol]
                            ?? .unavailable(reason: "Provider-backed historical prices unavailable"),
                        completeness: .insufficient(reason: "Provider-backed historical prices unavailable")
                    )
                }

                let state = historyState(for: dataset)
                return PortfolioHistorySymbolStatus(
                    id: symbol,
                    symbol: symbol,
                    portfolioWeight: portfolioWeight,
                    state: state,
                    provenance: dataset.correlationDisplayProvenance,
                    completeness: dataset.completeness
                )
            }
    }

    private static func historyState(for dataset: HistoricalPriceDataset) -> PortfolioHistorySymbolState {
        guard dataset.provenance.isProviderBacked else {
            return .unavailable
        }

        switch dataset.completeness {
        case .partial:
            return .partial
        case .insufficient:
            return .insufficient
        case .complete:
            switch dataset.freshness() {
            case .live:
                return .live
            case .cachedFresh:
                return .cachedFresh
            case .cachedStale:
                return .cachedStale
            case .unavailable:
                return .unavailable
            }
        }
    }

    private func aggregateHistoryProvenance(
        from statuses: [PortfolioHistorySymbolStatus],
        fallbackSummaries: [PortfolioCosmicCorrelationSummary]
    ) -> FinancialDataProvenance {
        let eligible = statuses.filter(\.isUsableForPortfolioCorrelation)
        if !eligible.isEmpty {
            let fetchedDates = eligible.compactMap(\.provenance.fetchedAt)
            let conservativeFetchedAt = fetchedDates.min() ?? Date()
            let allLive = eligible.allSatisfy { status in
                if case .live = status.provenance { return true }
                return false
            }

            if allLive {
                return .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: conservativeFetchedAt)
            }

            return .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: conservativeFetchedAt)
        }

        if statuses.contains(where: { $0.state == .partial }) {
            return .mixed(reason: "Partial historical datasets are available, but complete provider-backed history is required for portfolio metrics")
        }

        if statuses.contains(where: { $0.state == .insufficient }) {
            return .unavailable(reason: "Provider returned insufficient historical data for portfolio holdings")
        }

        return aggregateProvenance(from: fallbackSummaries)
    }

    private func aggregateProvenance(from summaries: [PortfolioCosmicCorrelationSummary]) -> FinancialDataProvenance {
        let eligible = summaries.filter {
            ($0.displayMode == .marketBackedResult || $0.displayMode == .insufficientSample)
                && $0.provenance.isProviderBacked
        }
        guard !eligible.isEmpty else {
            return summaries.first?.provenance ?? .unavailable(reason: "Portfolio historical data unavailable")
        }

        let provenances = eligible.map(\.provenance)
        let fetchedDates = provenances.compactMap(\.fetchedAt)
        let conservativeFetchedAt = fetchedDates.min() ?? Date()

        let allLive = provenances.allSatisfy { provenance in
            if case .live = provenance { return true }
            return false
        }

        if allLive {
            return .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: conservativeFetchedAt)
        }

        return .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: conservativeFetchedAt)
    }
}
