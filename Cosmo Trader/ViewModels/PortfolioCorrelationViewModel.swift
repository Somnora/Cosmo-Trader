import Foundation

@MainActor
@Observable
final class PortfolioCorrelationViewModel {
    var summaries: [PortfolioCosmicCorrelationSummary] = []
    var isLoading = false
    var errorMessage: String?
    var eventCount = 0
    var historicalPriceProvenance: FinancialDataProvenance = .unavailable(reason: "Portfolio historical data unavailable")

    let checkedEventKinds: [AstroOverlayEventKind] = PortfolioCosmicCorrelationService.shared.supportedEventKinds
    let filterState = AstroOverlayFilterState(
        enabledKinds: [.fullMoon, .newMoon, .mercuryRetrograde],
        showEstimatedEvents: true,
        eventWindowDays: 3
    )
    let timeframe: ChartTimeframe = .year

    private var loadedSignature: String?

    var windowLabel: String {
        CorrelationWindow(daysBefore: 1, daysAfter: max(1, filterState.eventWindowDays)).displayName
    }

    var includedPortfolioWeight: Double {
        summaries.map(\.includedPortfolioWeight).max() ?? 0
    }

    var excludedPortfolioWeight: Double {
        summaries.map(\.excludedPortfolioWeight).max() ?? 0
    }

    var unavailableHoldings: [String] {
        Array(Set(summaries.flatMap(\.unavailableHoldings))).sorted()
    }

    var hasMarketBackedResult: Bool {
        summaries.contains { summary in
            summary.displayMode == .marketBackedResult
        }
    }

    func load(holdings: [Stock]) async {
        let ownedHoldings = holdings
            .filter(\.isOwned)
            .filter { $0.marketValue > 0 }
        let signature = ownedHoldings
            .map { "\($0.symbol.uppercased()):\($0.sharesOwned):\($0.marketValue)" }
            .sorted()
            .joined(separator: "|")

        guard !signature.isEmpty else {
            summaries = []
            eventCount = 0
            historicalPriceProvenance = .unavailable(reason: "No initialized portfolio holdings")
            errorMessage = nil
            loadedSignature = signature
            return
        }

        if loadedSignature == signature, !summaries.isEmpty {
            return
        }

        loadedSignature = signature
        isLoading = true
        errorMessage = nil

        let datasetSnapshot = await CorrelationDatasetStore.shared.datasets(
            symbols: ownedHoldings.map(\.symbol),
            timeframe: timeframe
        )
        let priceHistoryBySymbol = datasetSnapshot.priceHistoryBySymbol
        let provenanceBySymbol = datasetSnapshot.provenanceBySymbol
        let completenessBySymbol = datasetSnapshot.completenessBySymbol

        let allDates = priceHistoryBySymbol.values.flatMap { $0.map(\.date) }
        let events: [AstroOverlayEvent]
        if let firstDate = allDates.min(),
           let lastDate = allDates.max(),
           let representativeHolding = ownedHoldings.first {
            events = AstroOverlayEventService.shared.events(
                for: representativeHolding,
                from: firstDate,
                to: lastDate,
                filters: filterState
            )
            .filter { checkedEventKinds.contains($0.kind) }
        } else {
            events = []
        }

        let nextSummaries = PortfolioCosmicCorrelationService.shared.summaries(
            holdings: ownedHoldings,
            priceHistoryBySymbol: priceHistoryBySymbol,
            provenanceBySymbol: provenanceBySymbol,
            completenessBySymbol: completenessBySymbol,
            events: events,
            filterState: filterState
        )

        summaries = nextSummaries
        eventCount = events.count
        historicalPriceProvenance = aggregateProvenance(from: nextSummaries)
        if nextSummaries.allSatisfy({ $0.displayMode == .unavailable }) {
            errorMessage = "Portfolio correlation context will appear when provider-backed holding history is available."
        }

        isLoading = false
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
