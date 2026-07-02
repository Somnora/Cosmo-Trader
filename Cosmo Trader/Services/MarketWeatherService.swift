import Foundation

struct MarketWeatherSymbol: Identifiable, Equatable {
    let symbol: String
    let displayName: String

    var id: String { symbol }
}

struct MarketWeatherSummary: Equatable {
    let symbols: [MarketWeatherSymbol]
    let eventSummaries: [MarketWeatherEventSummary]
    let sectorBreadth: MarketSectorBreadthSummary?
    let includedSymbols: [String]
    let excludedSymbols: [String]
    let staleSymbols: [String]
    let partialSymbols: [String]
    let insufficientSymbols: [String]
    let coverage: Double
    let provenance: FinancialDataProvenance
    let disclaimer: String
}

struct MarketSectorBreadthSummary: Equatable {
    let sectors: [MarketWeatherSymbol]
    let eventName: String?
    let eventType: AstroOverlayEventKind?
    let eventCount: Int
    let sampleSize: Int
    let window: CorrelationWindow
    let averageSectorReturn: Double?
    let medianSectorReturn: Double?
    let advancingSectorRate: Double?
    let strongestSectors: [MarketSectorBreadthMove]
    let weakestSectors: [MarketSectorBreadthMove]
    let includedSymbols: [String]
    let excludedSymbols: [String]
    let staleSymbols: [String]
    let partialSymbols: [String]
    let insufficientSymbols: [String]
    let coverage: Double
    let provenance: FinancialDataProvenance
    let displayMode: CorrelationDisplayMode
    let disclaimer: String
}

struct MarketSectorBreadthMove: Identifiable, Equatable {
    let symbol: String
    let displayName: String
    let returnPercent: Double?

    var id: String { symbol }
}

struct MarketWeatherEventSummary: Identifiable, Equatable {
    let id: String
    let eventName: String
    let eventType: AstroOverlayEventKind
    let eventCount: Int
    let sampleSize: Int
    let window: CorrelationWindow
    let averageMarketReturn: Double?
    let medianMarketReturn: Double?
    let winRate: Double?
    let baselineMarketReturn: Double?
    let volatilityRatio: Double?
    let maxDrawdown: Double?
    let includedSymbols: [String]
    let excludedSymbols: [String]
    let staleSymbols: [String]
    let provenance: FinancialDataProvenance
    let confidence: CorrelationConfidence
    let displayMode: CorrelationDisplayMode
    let disclaimer: String
}

@MainActor
final class MarketWeatherService {
    static let shared = MarketWeatherService()

    static let v1Symbols: [MarketWeatherSymbol] = [
        MarketWeatherSymbol(symbol: "SPY", displayName: "S&P 500"),
        MarketWeatherSymbol(symbol: "QQQ", displayName: "Nasdaq 100"),
        MarketWeatherSymbol(symbol: "DIA", displayName: "Dow Industrials"),
        MarketWeatherSymbol(symbol: "IWM", displayName: "Russell 2000")
    ]

    static let sectorSymbols: [MarketWeatherSymbol] = [
        MarketWeatherSymbol(symbol: "XLK", displayName: "Technology"),
        MarketWeatherSymbol(symbol: "XLF", displayName: "Financials"),
        MarketWeatherSymbol(symbol: "XLE", displayName: "Energy"),
        MarketWeatherSymbol(symbol: "XLV", displayName: "Health Care"),
        MarketWeatherSymbol(symbol: "XLY", displayName: "Consumer Discretionary"),
        MarketWeatherSymbol(symbol: "XLP", displayName: "Consumer Staples"),
        MarketWeatherSymbol(symbol: "XLI", displayName: "Industrials"),
        MarketWeatherSymbol(symbol: "XLU", displayName: "Utilities"),
        MarketWeatherSymbol(symbol: "XLB", displayName: "Materials"),
        MarketWeatherSymbol(symbol: "XLRE", displayName: "Real Estate"),
        MarketWeatherSymbol(symbol: "XLC", displayName: "Communication Services")
    ]

    let supportedEventKinds: [AstroOverlayEventKind] = [
        .fullMoon,
        .newMoon,
        .mercuryRetrograde
    ]

    private let datasetStore: CorrelationDatasetStore
    private let overlayEventService: AstroOverlayEventService
    private let calendar = Calendar.current
    private let requiredCoverageForAnyContext = 0.5
    private let requiredCoverageForNumericClaims = 1.0
    private let requiredEventSymbolCoverage = 1.0
    private let requiredSectorCoverageForNumericClaims = 1.0
    private let requiredSectorEventCoverage = 1.0

    init(
        datasetStore: CorrelationDatasetStore? = nil,
        overlayEventService: AstroOverlayEventService? = nil
    ) {
        self.datasetStore = datasetStore ?? CorrelationDatasetStore.shared
        self.overlayEventService = overlayEventService ?? AstroOverlayEventService.shared
    }

    func loadSummary(
        timeframe: ChartTimeframe = .year,
        filterState: AstroOverlayFilterState,
        minimumSampleSize: Int = 10,
        staleAfter: TimeInterval = HistoricalPriceDataset.defaultStaleInterval
    ) async -> MarketWeatherSummary {
        let snapshot = await datasetStore.datasets(
            symbols: (Self.v1Symbols + Self.sectorSymbols).map(\.symbol),
            timeframe: timeframe
        )
        let allDates = snapshot.priceHistoryBySymbol.values.flatMap { $0.map(\.date) }
        let events: [AstroOverlayEvent]
        
        if let firstDate = allDates.min(), let lastDate = allDates.max() {
            events = overlayEventService.events(
                for: Self.marketProxyStock,
                from: firstDate,
                to: lastDate,
                filters: filterState
            )
            .filter { supportedEventKinds.contains($0.kind) }
        } else {
            events = []
        }

        return summary(
            datasetsBySymbol: snapshot.datasetsBySymbol,
            unavailableProvenanceBySymbol: snapshot.unavailableProvenanceBySymbol,
            events: events,
            filterState: filterState,
            minimumSampleSize: minimumSampleSize,
            staleAfter: staleAfter
        )
    }

    func summary(
        datasetsBySymbol: [String: HistoricalPriceDataset],
        unavailableProvenanceBySymbol: [String: FinancialDataProvenance] = [:],
        events: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState,
        minimumSampleSize: Int = 10,
        staleAfter: TimeInterval = HistoricalPriceDataset.defaultStaleInterval
    ) -> MarketWeatherSummary {
        let normalizedDatasets = Dictionary(uniqueKeysWithValues: datasetsBySymbol.map { key, value in
            (key.uppercased(), value)
        })
        let normalizedUnavailable = Dictionary(uniqueKeysWithValues: unavailableProvenanceBySymbol.map { key, value in
            (key.uppercased(), value)
        })
        let window = CorrelationWindow(daysBefore: 1, daysAfter: max(1, filterState.eventWindowDays))
        let lockedEvents = events.filter { supportedEventKinds.contains($0.kind) }
        let groupedEvents = Dictionary(grouping: lockedEvents) { $0.kind }
        let statuses = Self.v1Symbols.map { definition in
            datasetStatus(
                definition: definition,
                dataset: normalizedDatasets[definition.symbol],
                unavailableProvenance: normalizedUnavailable[definition.symbol],
                staleAfter: staleAfter
            )
        }
        let eligible = statuses.compactMap(\.eligibleDataset)
        let includedSymbols = eligible.map(\.symbol).sorted()
        let excludedSymbols = statuses.filter { $0.eligibleDataset == nil }.map(\.symbol).sorted()
        let staleSymbols = statuses.filter { $0.status == .stale }.map(\.symbol).sorted()
        let partialSymbols = statuses.filter { $0.status == .partial }.map(\.symbol).sorted()
        let insufficientSymbols = statuses.filter { $0.status == .insufficient }.map(\.symbol).sorted()
        let coverage = Double(includedSymbols.count) / Double(Self.v1Symbols.count)
        let provenance = aggregateProvenance(
            statuses: statuses,
            eligible: eligible,
            coverage: coverage
        )

        let eventSummaries = supportedEventKinds.map { kind in
            eventSummary(
                kind: kind,
                events: (groupedEvents[kind] ?? []).sorted { $0.markerDate < $1.markerDate },
                eligible: eligible,
                statuses: statuses,
                coverage: coverage,
                provenance: provenance,
                window: window,
                filterState: filterState,
                minimumSampleSize: minimumSampleSize
            )
        }
        let sectorBreadth = sectorBreadthSummary(
            datasetsBySymbol: normalizedDatasets,
            unavailableProvenanceBySymbol: normalizedUnavailable,
            groupedEvents: groupedEvents,
            window: window,
            filterState: filterState,
            minimumSampleSize: minimumSampleSize,
            staleAfter: staleAfter
        )

        return MarketWeatherSummary(
            symbols: Self.v1Symbols,
            eventSummaries: eventSummaries,
            sectorBreadth: sectorBreadth,
            includedSymbols: includedSymbols,
            excludedSymbols: excludedSymbols,
            staleSymbols: staleSymbols,
            partialSymbols: partialSymbols,
            insufficientSymbols: insufficientSymbols,
            coverage: coverage,
            provenance: provenance,
            disclaimer: "Historical market context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    private func sectorBreadthSummary(
        datasetsBySymbol: [String: HistoricalPriceDataset],
        unavailableProvenanceBySymbol: [String: FinancialDataProvenance],
        groupedEvents: [AstroOverlayEventKind: [AstroOverlayEvent]],
        window: CorrelationWindow,
        filterState: AstroOverlayFilterState,
        minimumSampleSize: Int,
        staleAfter: TimeInterval
    ) -> MarketSectorBreadthSummary {
        let statuses = Self.sectorSymbols.map { definition in
            datasetStatus(
                definition: definition,
                dataset: datasetsBySymbol[definition.symbol],
                unavailableProvenance: unavailableProvenanceBySymbol[definition.symbol],
                staleAfter: staleAfter
            )
        }
        let eligible = statuses.compactMap(\.eligibleDataset)
        let includedSymbols = eligible.map(\.symbol).sorted()
        let excludedSymbols = statuses.filter { $0.eligibleDataset == nil }.map(\.symbol).sorted()
        let staleSymbols = statuses.filter { $0.status == .stale }.map(\.symbol).sorted()
        let partialSymbols = statuses.filter { $0.status == .partial }.map(\.symbol).sorted()
        let insufficientSymbols = statuses.filter { $0.status == .insufficient }.map(\.symbol).sorted()
        let coverage = Double(includedSymbols.count) / Double(Self.sectorSymbols.count)
        let provenance = aggregateProvenance(
            statuses: statuses,
            eligible: eligible,
            coverage: coverage,
            requiredSymbolCount: Self.sectorSymbols.count,
            unavailableReason: "Provider-backed sector ETF history unavailable",
            mixedPrefix: "Sector breadth"
        )
        let allSample = !statuses.isEmpty && statuses.allSatisfy { $0.status == .sample }
        let preferredKind = preferredSectorEventKind(from: groupedEvents, eligible: eligible, filterState: filterState)
        let events = preferredKind.map { (groupedEvents[$0] ?? []).sorted { $0.markerDate < $1.markerDate } } ?? []

        guard !eligible.isEmpty else {
            return unavailableSectorBreadth(
                eventName: preferredKind?.displayName,
                eventType: preferredKind,
                eventCount: events.count,
                window: window,
                includedSymbols: includedSymbols,
                excludedSymbols: excludedSymbols,
                staleSymbols: staleSymbols,
                partialSymbols: partialSymbols,
                insufficientSymbols: insufficientSymbols,
                coverage: coverage,
                provenance: allSample ? .sample(reason: "Only explicit sample sector data is available") : provenance,
                displayMode: allSample ? .sampleOnly : .unavailable,
                disclaimer: allSample
                    ? "Sample sector history is labeled for preview only. No sector breadth claim is shown."
                    : "Provider-backed sector ETF history is unavailable. Sector breadth will appear when complete sector history is available."
            )
        }

        guard coverage >= requiredSectorCoverageForNumericClaims else {
            return unavailableSectorBreadth(
                eventName: preferredKind?.displayName,
                eventType: preferredKind,
                eventCount: events.count,
                window: window,
                includedSymbols: includedSymbols,
                excludedSymbols: excludedSymbols,
                staleSymbols: staleSymbols,
                partialSymbols: partialSymbols,
                insufficientSymbols: insufficientSymbols,
                coverage: coverage,
                provenance: provenance,
                displayMode: .partialCoverage,
                disclaimer: "Sector breadth has \(percentRate(coverage)) fresh provider-backed coverage. Full sector coverage is required before sector metrics appear."
            )
        }

        guard let preferredKind, !events.isEmpty else {
            return unavailableSectorBreadth(
                eventName: preferredKind?.displayName,
                eventType: preferredKind,
                eventCount: events.count,
                window: window,
                includedSymbols: includedSymbols,
                excludedSymbols: excludedSymbols,
                staleSymbols: staleSymbols,
                partialSymbols: partialSymbols,
                insufficientSymbols: insufficientSymbols,
                coverage: coverage,
                provenance: provenance,
                displayMode: .insufficientSample,
                disclaimer: "No matching cosmic events were found in the provider-backed sector range. No sector breadth claim is shown."
            )
        }

        let reactions = sectorReactions(
            eligible: eligible,
            events: events,
            filterState: filterState
        )

        guard reactions.count >= minimumSampleSize else {
            return unavailableSectorBreadth(
                eventName: preferredKind.displayName,
                eventType: preferredKind,
                eventCount: events.count,
                sampleSize: reactions.count,
                window: window,
                includedSymbols: includedSymbols,
                excludedSymbols: excludedSymbols,
                staleSymbols: staleSymbols,
                partialSymbols: partialSymbols,
                insufficientSymbols: insufficientSymbols,
                coverage: coverage,
                provenance: provenance,
                displayMode: .insufficientSample,
                disclaimer: "Awaiting more historical data. (10 observations required; currently has \(reactions.count))."
            )
        }

        let allSectorReturns = reactions.flatMap(\.sectorReturns)
        let returns = allSectorReturns.map(\.returnPercent)
        let sectorMoves = sectorBreadthMoves(from: allSectorReturns)
        return MarketSectorBreadthSummary(
            sectors: Self.sectorSymbols,
            eventName: preferredKind.displayName,
            eventType: preferredKind,
            eventCount: events.count,
            sampleSize: reactions.count,
            window: window,
            averageSectorReturn: average(returns),
            medianSectorReturn: median(returns),
            advancingSectorRate: winRate(returns),
            strongestSectors: Array(sectorMoves.prefix(3)),
            weakestSectors: Array(sectorMoves.suffix(3).reversed()),
            includedSymbols: includedSymbols,
            excludedSymbols: excludedSymbols,
            staleSymbols: staleSymbols,
            partialSymbols: partialSymbols,
            insufficientSymbols: insufficientSymbols,
            coverage: coverage,
            provenance: provenance,
            displayMode: .marketBackedResult,
            disclaimer: "Historical sector breadth context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    private func eventSummary(
        kind: AstroOverlayEventKind,
        events: [AstroOverlayEvent],
        eligible: [EligibleMarketDataset],
        statuses: [MarketDatasetStatus],
        coverage: Double,
        provenance: FinancialDataProvenance,
        window: CorrelationWindow,
        filterState: AstroOverlayFilterState,
        minimumSampleSize: Int
    ) -> MarketWeatherEventSummary {
        let excludedSymbols = statuses.filter { $0.eligibleDataset == nil }.map(\.symbol).sorted()
        let staleSymbols = statuses.filter { $0.status == .stale }.map(\.symbol).sorted()
        let allSample = !statuses.isEmpty && statuses.allSatisfy { $0.status == .sample }

        guard !eligible.isEmpty else {
            return unavailableEventSummary(
                kind: kind,
                eventCount: events.count,
                window: window,
                includedSymbols: [],
                excludedSymbols: excludedSymbols,
                staleSymbols: staleSymbols,
                provenance: allSample ? .sample(reason: "Only explicit sample market data is available") : provenance,
                displayMode: allSample ? .sampleOnly : .unavailable,
                disclaimer: allSample
                    ? "Sample market data is labeled for preview only. No historical market-weather claim is shown."
                    : "Provider-backed market ETF history is unavailable. Market Weather will appear when SPY, QQQ, DIA, and IWM history is available."
            )
        }

        guard coverage >= requiredCoverageForAnyContext else {
            return unavailableEventSummary(
                kind: kind,
                eventCount: events.count,
                window: window,
                includedSymbols: eligible.map(\.symbol).sorted(),
                excludedSymbols: excludedSymbols,
                staleSymbols: staleSymbols,
                provenance: provenance,
                displayMode: .insufficientSample,
                disclaimer: "Provider-backed market history covers \(percentRate(coverage)) of the V1 market basket. At least 50% coverage is required before market context appears."
            )
        }

        guard coverage >= requiredCoverageForNumericClaims else {
            return unavailableEventSummary(
                kind: kind,
                eventCount: events.count,
                window: window,
                includedSymbols: eligible.map(\.symbol).sorted(),
                excludedSymbols: excludedSymbols,
                staleSymbols: staleSymbols,
                provenance: provenance,
                displayMode: .partialCoverage,
                disclaimer: "Provider-backed market history covers \(percentRate(coverage)) of SPY, QQQ, DIA, and IWM. Full fresh coverage is required before headline market metrics appear."
            )
        }

        guard !events.isEmpty else {
            return unavailableEventSummary(
                kind: kind,
                eventCount: 0,
                window: window,
                includedSymbols: eligible.map(\.symbol).sorted(),
                excludedSymbols: excludedSymbols,
                staleSymbols: staleSymbols,
                provenance: provenance,
                displayMode: .insufficientSample,
                disclaimer: "No matching cosmic events were found in the provider-backed market range. No return claim is shown."
            )
        }

        let reactions = marketReactions(
            eligible: eligible,
            events: events,
            filterState: filterState
        )

        guard reactions.count >= minimumSampleSize else {
            return unavailableEventSummary(
                kind: kind,
                eventCount: events.count,
                sampleSize: reactions.count,
                window: window,
                includedSymbols: eligible.map(\.symbol).sorted(),
                excludedSymbols: excludedSymbols,
                staleSymbols: staleSymbols,
                provenance: provenance,
                displayMode: .insufficientSample,
                disclaimer: "Awaiting more historical data. (10 observations required; currently has \(reactions.count))."
            )
        }

        let returns = reactions.map(\.returnPercent)
        let eventVolatility = standardDeviation(returns)
        let baselineVolatility = average(eligible.map { volatilityPercent(for: $0.prices) })
        let volatilityRatio = baselineVolatility > 0 ? eventVolatility / baselineVolatility : nil

        return MarketWeatherEventSummary(
            id: kind.rawValue,
            eventName: kind.displayName,
            eventType: kind,
            eventCount: events.count,
            sampleSize: reactions.count,
            window: window,
            averageMarketReturn: average(returns),
            medianMarketReturn: median(returns),
            winRate: winRate(returns),
            baselineMarketReturn: baselineMarketReturn(
                for: eligible,
                averageWindowSize: averageWindowSize(for: reactions)
            ),
            volatilityRatio: volatilityRatio,
            maxDrawdown: reactions.map(\.maxDrawdownPercent).max(),
            includedSymbols: eligible.map(\.symbol).sorted(),
            excludedSymbols: excludedSymbols,
            staleSymbols: staleSymbols,
            provenance: provenance,
            confidence: confidence(for: reactions.count),
            displayMode: .marketBackedResult,
            disclaimer: "Historical market context only. Correlation does not imply causation and this is not financial advice."
        )
    }

    private func marketReactions(
        eligible: [EligibleMarketDataset],
        events: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState
    ) -> [MarketEventReaction] {
        let reactionsBySymbol = Dictionary(uniqueKeysWithValues: eligible.map { dataset in
            let reactions = AstroCorrelationService.shared.eventReactions(
                prices: dataset.prices,
                events: events,
                filterState: filterState
            )
            return (dataset.symbol, Dictionary(uniqueKeysWithValues: reactions.map { ($0.event.id, $0) }))
        })

        return events.compactMap { event in
            let reactions = eligible.compactMap { dataset in
                reactionsBySymbol[dataset.symbol]?[event.id]
            }

            guard Double(reactions.count) / Double(max(1, eligible.count)) >= requiredEventSymbolCoverage else {
                return nil
            }

            return MarketEventReaction(
                event: event,
                windowStart: reactions.map(\.windowStart).min() ?? event.startDate,
                windowEnd: reactions.map(\.windowEnd).max() ?? event.markerDate,
                returnPercent: average(reactions.map(\.returnPercent)),
                maxDrawdownPercent: average(reactions.map(\.maxDrawdownPercent)),
                volatilityPercent: average(reactions.map(\.volatilityPercent))
            )
        }
    }

    private func preferredSectorEventKind(
        from groupedEvents: [AstroOverlayEventKind: [AstroOverlayEvent]],
        eligible: [EligibleMarketDataset],
        filterState: AstroOverlayFilterState
    ) -> AstroOverlayEventKind? {
        supportedEventKinds
            .map { kind -> (kind: AstroOverlayEventKind, sampleSize: Int) in
                let events = (groupedEvents[kind] ?? []).sorted { $0.markerDate < $1.markerDate }
                let sampleSize = sectorReactions(
                    eligible: eligible,
                    events: events,
                    filterState: filterState
                ).count
                return (kind, sampleSize)
            }
            .sorted { lhs, rhs in
                if lhs.sampleSize != rhs.sampleSize { return lhs.sampleSize > rhs.sampleSize }
                return lhs.kind.displayName < rhs.kind.displayName
            }
            .first?
            .kind
    }

    private func sectorReactions(
        eligible: [EligibleMarketDataset],
        events: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState
    ) -> [SectorBreadthEventReaction] {
        guard !eligible.isEmpty else { return [] }

        let reactionsBySymbol = Dictionary(uniqueKeysWithValues: eligible.map { dataset in
            let reactions = AstroCorrelationService.shared.eventReactions(
                prices: dataset.prices,
                events: events,
                filterState: filterState
            )
            return (dataset.symbol, Dictionary(uniqueKeysWithValues: reactions.map { ($0.event.id, $0) }))
        })

        return events.compactMap { event in
            let sectorReturns = eligible.compactMap { dataset -> SectorReturn? in
                guard let reaction = reactionsBySymbol[dataset.symbol]?[event.id],
                      let definition = Self.sectorSymbols.first(where: { $0.symbol == dataset.symbol }) else {
                    return nil
                }

                return SectorReturn(
                    symbol: dataset.symbol,
                    displayName: definition.displayName,
                    returnPercent: reaction.returnPercent
                )
            }

            guard Double(sectorReturns.count) / Double(max(1, eligible.count)) >= requiredSectorEventCoverage else {
                return nil
            }

            return SectorBreadthEventReaction(event: event, sectorReturns: sectorReturns)
        }
    }

    private func sectorBreadthMoves(from returns: [SectorReturn]) -> [MarketSectorBreadthMove] {
        let grouped = Dictionary(grouping: returns) { $0.symbol }
        return grouped.compactMap { symbol, returns -> MarketSectorBreadthMove? in
            guard let displayName = returns.first?.displayName else { return nil }
            return MarketSectorBreadthMove(
                symbol: symbol,
                displayName: displayName,
                returnPercent: average(returns.map(\.returnPercent))
            )
        }
        .sorted { lhs, rhs in
            (lhs.returnPercent ?? -.greatestFiniteMagnitude) > (rhs.returnPercent ?? -.greatestFiniteMagnitude)
        }
    }

    private func datasetStatus(
        definition: MarketWeatherSymbol,
        dataset: HistoricalPriceDataset?,
        unavailableProvenance: FinancialDataProvenance?,
        staleAfter: TimeInterval
    ) -> MarketDatasetStatus {
        guard let dataset else {
            return MarketDatasetStatus(
                symbol: definition.symbol,
                provenance: unavailableProvenance ?? .unavailable(reason: "Provider-backed market history unavailable"),
                status: .unavailable,
                eligibleDataset: nil
            )
        }

        let sourceProvenance = dataset.provenance
        let displayProvenance = dataset.correlationDisplayProvenance

        if case .sample = sourceProvenance {
            return MarketDatasetStatus(symbol: definition.symbol, provenance: displayProvenance, status: .sample, eligibleDataset: nil)
        }

        guard sourceProvenance.isProviderBacked else {
            return MarketDatasetStatus(symbol: definition.symbol, provenance: displayProvenance, status: .unavailable, eligibleDataset: nil)
        }

        if sourceProvenance.isCachedStale(staleAfter: staleAfter) {
            return MarketDatasetStatus(symbol: definition.symbol, provenance: displayProvenance, status: .stale, eligibleDataset: nil)
        }

        switch dataset.completeness {
        case .complete:
            break
        case .partial:
            return MarketDatasetStatus(symbol: definition.symbol, provenance: displayProvenance, status: .partial, eligibleDataset: nil)
        case .insufficient:
            return MarketDatasetStatus(symbol: definition.symbol, provenance: displayProvenance, status: .insufficient, eligibleDataset: nil)
        }

        let prices = dataset.ohlcData
            .filter { $0.close.isFinite && $0.close > 0 }
            .sorted { $0.date < $1.date }

        guard prices.count >= 2 else {
            return MarketDatasetStatus(
                symbol: definition.symbol,
                provenance: .unavailable(reason: "Provider-backed market history returned fewer than two candles"),
                status: .insufficient,
                eligibleDataset: nil
            )
        }

        return MarketDatasetStatus(
            symbol: definition.symbol,
            provenance: displayProvenance,
            status: .eligible,
            eligibleDataset: EligibleMarketDataset(
                symbol: definition.symbol,
                prices: prices,
                provenance: displayProvenance
            )
        )
    }

    private func aggregateProvenance(
        statuses: [MarketDatasetStatus],
        eligible: [EligibleMarketDataset],
        coverage: Double,
        requiredSymbolCount: Int? = nil,
        unavailableReason: String = "Provider-backed market ETF history unavailable",
        mixedPrefix: String = "Market Weather"
    ) -> FinancialDataProvenance {
        let requiredCount = requiredSymbolCount ?? Self.v1Symbols.count
        guard !eligible.isEmpty else {
            if statuses.allSatisfy({ $0.status == .sample }) {
                return .sample(reason: "Only explicit sample market data is available")
            }
            return .unavailable(reason: unavailableReason)
        }

        guard eligible.count == requiredCount else {
            let excluded = statuses.filter { $0.eligibleDataset == nil }.map(\.symbol).sorted().joined(separator: ", ")
            return .mixed(reason: "\(mixedPrefix) has \(percentRate(coverage)) fresh provider-backed coverage. Excluded: \(excluded).")
        }

        let provenances = eligible.map(\.provenance)
        let fetchedAt = provenances.compactMap(\.fetchedAt).min() ?? Date()
        let allLive = provenances.allSatisfy { provenance in
            if case .live = provenance { return true }
            return false
        }

        if allLive {
            return .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        }

        let maxAge = provenances.compactMap { provenance -> TimeInterval? in
            if case .cached(_, _, let age) = provenance { return age }
            return nil
        }.max() ?? 0

        return .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt, age: maxAge)
    }

    private func unavailableEventSummary(
        kind: AstroOverlayEventKind,
        eventCount: Int,
        sampleSize: Int = 0,
        window: CorrelationWindow,
        includedSymbols: [String],
        excludedSymbols: [String],
        staleSymbols: [String],
        provenance: FinancialDataProvenance,
        displayMode: CorrelationDisplayMode,
        disclaimer: String
    ) -> MarketWeatherEventSummary {
        MarketWeatherEventSummary(
            id: kind.rawValue,
            eventName: kind.displayName,
            eventType: kind,
            eventCount: eventCount,
            sampleSize: sampleSize,
            window: window,
            averageMarketReturn: nil,
            medianMarketReturn: nil,
            winRate: nil,
            baselineMarketReturn: nil,
            volatilityRatio: nil,
            maxDrawdown: nil,
            includedSymbols: includedSymbols,
            excludedSymbols: excludedSymbols,
            staleSymbols: staleSymbols,
            provenance: provenance,
            confidence: .insufficient,
            displayMode: displayMode,
            disclaimer: disclaimer
        )
    }

    private func unavailableSectorBreadth(
        eventName: String?,
        eventType: AstroOverlayEventKind?,
        eventCount: Int,
        sampleSize: Int = 0,
        window: CorrelationWindow,
        includedSymbols: [String],
        excludedSymbols: [String],
        staleSymbols: [String],
        partialSymbols: [String],
        insufficientSymbols: [String],
        coverage: Double,
        provenance: FinancialDataProvenance,
        displayMode: CorrelationDisplayMode,
        disclaimer: String
    ) -> MarketSectorBreadthSummary {
        MarketSectorBreadthSummary(
            sectors: Self.sectorSymbols,
            eventName: eventName,
            eventType: eventType,
            eventCount: eventCount,
            sampleSize: sampleSize,
            window: window,
            averageSectorReturn: nil,
            medianSectorReturn: nil,
            advancingSectorRate: nil,
            strongestSectors: [],
            weakestSectors: [],
            includedSymbols: includedSymbols,
            excludedSymbols: excludedSymbols,
            staleSymbols: staleSymbols,
            partialSymbols: partialSymbols,
            insufficientSymbols: insufficientSymbols,
            coverage: coverage,
            provenance: provenance,
            displayMode: displayMode,
            disclaimer: disclaimer
        )
    }

    private func baselineMarketReturn(
        for datasets: [EligibleMarketDataset],
        averageWindowSize: Int
    ) -> Double? {
        guard !datasets.isEmpty else { return nil }
        return average(datasets.map { baselineReturnPercent(prices: $0.prices, averageWindowSize: averageWindowSize) })
    }

    private func baselineReturnPercent(prices: [OHLCData], averageWindowSize: Int) -> Double {
        let dailyReturns = zip(prices, prices.dropFirst()).compactMap { previous, current -> Double? in
            guard previous.close > 0 else { return nil }
            return ((current.close - previous.close) / previous.close) * 100
        }
        return average(dailyReturns) * Double(max(1, averageWindowSize))
    }

    private func averageWindowSize(for reactions: [MarketEventReaction]) -> Int {
        let counts = reactions.map { reaction in
            let days = calendar.dateComponents([.day], from: reaction.windowStart, to: reaction.windowEnd).day ?? 1
            return max(1, days)
        }
        return Int(round(average(counts.map(Double.init))))
    }

    private func volatilityPercent(for candles: [OHLCData]) -> Double {
        let returns = zip(candles, candles.dropFirst()).compactMap { previous, current -> Double? in
            guard previous.close > 0 else { return nil }
            return ((current.close - previous.close) / previous.close) * 100
        }
        return standardDeviation(returns)
    }

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }

    private func winRate(_ returns: [Double]) -> Double {
        guard !returns.isEmpty else { return 0 }
        let wins = returns.filter { $0 > 0 }.count
        return Double(wins) / Double(returns.count)
    }

    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = average(values)
        let variance = values.reduce(0) { partial, value in
            partial + pow(value - mean, 2)
        } / Double(values.count)
        return sqrt(variance)
    }

    private func confidence(for sampleSize: Int) -> CorrelationConfidence {
        switch sampleSize {
        case 12...:
            return .strong
        case 6...:
            return .moderate
        case 3...:
            return .thin
        default:
            return .insufficient
        }
    }

    private func percentRate(_ value: Double) -> String {
        guard value.isFinite else { return "N/A" }
        return String(format: "%.0f%%", value * 100)
    }

    private static let marketProxyStock = Stock(
        symbol: "SPY",
        name: "V1 Market Basket",
        currentPrice: 0,
        priceChange: 0,
        percentageChange: 0,
        sharesOwned: 0,
        foundedDate: nil,
        sector: "Market ETF"
    )
}

private enum MarketDatasetQuality: Equatable {
    case eligible
    case stale
    case partial
    case insufficient
    case unavailable
    case sample
}

private struct MarketDatasetStatus {
    let symbol: String
    let provenance: FinancialDataProvenance
    let status: MarketDatasetQuality
    let eligibleDataset: EligibleMarketDataset?
}

private struct EligibleMarketDataset {
    let symbol: String
    let prices: [OHLCData]
    let provenance: FinancialDataProvenance
}

private struct MarketEventReaction {
    let event: AstroOverlayEvent
    let windowStart: Date
    let windowEnd: Date
    let returnPercent: Double
    let maxDrawdownPercent: Double
    let volatilityPercent: Double
}

private struct SectorBreadthEventReaction {
    let event: AstroOverlayEvent
    let sectorReturns: [SectorReturn]
}

private struct SectorReturn {
    let symbol: String
    let displayName: String
    let returnPercent: Double
}
