import Foundation

struct PortfolioCorrelationHoldingImpact: Identifiable, Equatable {
    let id: String
    let symbol: String
    let portfolioWeight: Double
    let includedWeight: Double
    let marketValue: Double
    let sampleSize: Int
    let averageReturn: Double?
    let medianReturn: Double?
    let winRate: Double?
    let provenance: FinancialDataProvenance
    let confidence: CorrelationConfidence
    let displayMode: CorrelationDisplayMode
}

struct PortfolioCosmicCorrelationSummary: Identifiable, Equatable {
    let id: String
    let eventName: String
    let eventType: AstroOverlayEventKind
    let eventCount: Int
    let sampleSize: Int
    let window: CorrelationWindow
    let averagePortfolioReturn: Double?
    let medianPortfolioReturn: Double?
    let winRate: Double?
    let baselinePortfolioReturn: Double?
    let volatilityRatio: Double?
    let maxDrawdown: Double?
    let affectedHoldings: [PortfolioCorrelationHoldingImpact]
    let unavailableHoldings: [String]
    let includedPortfolioWeight: Double
    let excludedPortfolioWeight: Double
    let provenance: FinancialDataProvenance
    let confidence: CorrelationConfidence
    let displayMode: CorrelationDisplayMode
    let disclaimer: String
}

final class PortfolioCosmicCorrelationService {
    static let shared = PortfolioCosmicCorrelationService()

    let supportedEventKinds: [AstroOverlayEventKind] = [
        .fullMoon,
        .newMoon,
        .mercuryRetrograde
    ]

    private let calendar = Calendar.current
    private let minimumEventWeightCoverage = 0.5

    private init() {}

    func summaries(
        holdings: [Stock],
        priceHistoryBySymbol: [String: [OHLCData]],
        provenanceBySymbol: [String: FinancialDataProvenance],
        events: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState,
        minimumSampleSize: Int = 3
    ) -> [PortfolioCosmicCorrelationSummary] {
        let weightedHoldings = holdings
            .filter(\.isOwned)
            .compactMap { holding -> WeightedHolding? in
                let marketValue = holding.marketValue
                guard marketValue > 0 else { return nil }
                return WeightedHolding(
                    stock: holding,
                    symbol: holding.symbol.uppercased(),
                    marketValue: marketValue
                )
            }

        let totalPortfolioValue = weightedHoldings.reduce(0) { $0 + $1.marketValue }
        let window = CorrelationWindow(daysBefore: 1, daysAfter: max(1, filterState.eventWindowDays))
        let lockedEvents = events.filter { supportedEventKinds.contains($0.kind) }
        let groupedEvents = Dictionary(grouping: lockedEvents) { $0.kind }

        guard totalPortfolioValue > 0 else {
            return supportedEventKinds.map { kind in
                unavailableSummary(
                    kind: kind,
                    eventCount: groupedEvents[kind]?.count ?? 0,
                    window: window,
                    unavailableHoldings: holdings.filter(\.isOwned).map { $0.symbol.uppercased() }.sorted(),
                    provenance: .unavailable(reason: "No initialized portfolio market value"),
                    displayMode: .unavailable,
                    disclaimer: "Add holdings with price or cost-basis values before portfolio correlation context can be calculated."
                )
            }
        }

        let eligibility = weightedHoldings.map { holding in
            holdingEligibility(
                holding: holding,
                totalPortfolioValue: totalPortfolioValue,
                priceHistoryBySymbol: priceHistoryBySymbol,
                provenanceBySymbol: provenanceBySymbol
            )
        }

        let eligibleHoldings = eligibility.compactMap(\.eligibleHolding)
        let unavailableSymbols = eligibility
            .filter { $0.eligibleHolding == nil }
            .map(\.symbol)
            .sorted()
        let includedValue = eligibleHoldings.reduce(0) { $0 + $1.marketValue }
        let includedPortfolioWeight = totalPortfolioValue > 0 ? includedValue / totalPortfolioValue : 0
        let excludedPortfolioWeight = max(0, 1 - includedPortfolioWeight)
        let providerProvenance = aggregateProviderProvenance(for: eligibleHoldings)

        return supportedEventKinds.map { kind in
            let kindEvents = (groupedEvents[kind] ?? []).sorted { $0.markerDate < $1.markerDate }

            guard !eligibleHoldings.isEmpty else {
                let sampleOnly = eligibility.allSatisfy { status in
                    if case .sample = status.provenance { return true }
                    return false
                }
                return unavailableSummary(
                    kind: kind,
                    eventCount: kindEvents.count,
                    window: window,
                    unavailableHoldings: unavailableSymbols,
                    provenance: sampleOnly
                        ? .sample(reason: "Only explicit sample or stored portfolio data is available")
                        : .unavailable(reason: "Provider-backed holding history unavailable"),
                    displayMode: sampleOnly ? .sampleOnly : .unavailable,
                    disclaimer: sampleOnly
                        ? "Sample portfolio data is labeled for preview only. No historical correlation claim is shown."
                        : "Provider-backed historical prices are required before portfolio correlation context is shown."
                )
            }

            guard !kindEvents.isEmpty else {
                return PortfolioCosmicCorrelationSummary(
                    id: kind.rawValue,
                    eventName: kind.displayName,
                    eventType: kind,
                    eventCount: 0,
                    sampleSize: 0,
                    window: window,
                    averagePortfolioReturn: nil,
                    medianPortfolioReturn: nil,
                    winRate: nil,
                    baselinePortfolioReturn: nil,
                    volatilityRatio: nil,
                    maxDrawdown: nil,
                    affectedHoldings: holdingImpacts(
                        for: eligibleHoldings,
                        kindEvents: [],
                        filterState: filterState,
                        totalPortfolioValue: totalPortfolioValue,
                        includedValue: includedValue,
                        minimumSampleSize: minimumSampleSize
                    ),
                    unavailableHoldings: unavailableSymbols,
                    includedPortfolioWeight: includedPortfolioWeight,
                    excludedPortfolioWeight: excludedPortfolioWeight,
                    provenance: providerProvenance,
                    confidence: .insufficient,
                    displayMode: .insufficientSample,
                    disclaimer: "No matching cosmic events were found in the provider-backed price range. No return claim is shown."
                )
            }

            let portfolioReactions = portfolioReactions(
                eligibleHoldings: eligibleHoldings,
                events: kindEvents,
                filterState: filterState,
                includedValue: includedValue
            )
            let impacts = holdingImpacts(
                for: eligibleHoldings,
                kindEvents: kindEvents,
                filterState: filterState,
                totalPortfolioValue: totalPortfolioValue,
                includedValue: includedValue,
                minimumSampleSize: minimumSampleSize
            )

            guard portfolioReactions.count >= minimumSampleSize else {
                return PortfolioCosmicCorrelationSummary(
                    id: kind.rawValue,
                    eventName: kind.displayName,
                    eventType: kind,
                    eventCount: kindEvents.count,
                    sampleSize: portfolioReactions.count,
                    window: window,
                    averagePortfolioReturn: nil,
                    medianPortfolioReturn: nil,
                    winRate: nil,
                    baselinePortfolioReturn: nil,
                    volatilityRatio: nil,
                    maxDrawdown: nil,
                    affectedHoldings: impacts,
                    unavailableHoldings: unavailableSymbols,
                    includedPortfolioWeight: includedPortfolioWeight,
                    excludedPortfolioWeight: excludedPortfolioWeight,
                    provenance: providerProvenance,
                    confidence: .insufficient,
                    displayMode: .insufficientSample,
                    disclaimer: "Not enough portfolio-level observations for this event. No return claim is shown."
                )
            }

            let returns = portfolioReactions.map(\.returnPercent)
            let eventVolatility = standardDeviation(returns)
            let baselineVolatility = baselinePortfolioVolatility(for: eligibleHoldings, includedValue: includedValue)
            let volatilityRatio = baselineVolatility > 0 ? eventVolatility / baselineVolatility : nil

            return PortfolioCosmicCorrelationSummary(
                id: kind.rawValue,
                eventName: kind.displayName,
                eventType: kind,
                eventCount: kindEvents.count,
                sampleSize: portfolioReactions.count,
                window: window,
                averagePortfolioReturn: average(returns),
                medianPortfolioReturn: median(returns),
                winRate: winRate(returns),
                baselinePortfolioReturn: baselinePortfolioReturn(
                    for: eligibleHoldings,
                    includedValue: includedValue,
                    averageWindowSize: averageWindowSize(for: portfolioReactions)
                ),
                volatilityRatio: volatilityRatio,
                maxDrawdown: portfolioReactions.map(\.maxDrawdownPercent).max(),
                affectedHoldings: impacts,
                unavailableHoldings: unavailableSymbols,
                includedPortfolioWeight: includedPortfolioWeight,
                excludedPortfolioWeight: excludedPortfolioWeight,
                provenance: providerProvenance,
                confidence: confidence(for: portfolioReactions.count),
                displayMode: .marketBackedResult,
                disclaimer: "Historical portfolio context only. Correlation does not imply causation and this is not financial advice."
            )
        }
    }

    private func holdingEligibility(
        holding: WeightedHolding,
        totalPortfolioValue: Double,
        priceHistoryBySymbol: [String: [OHLCData]],
        provenanceBySymbol: [String: FinancialDataProvenance]
    ) -> HoldingEligibility {
        let provenance = provenanceBySymbol[holding.symbol] ?? .unavailable(reason: "Provider-backed historical prices unavailable")
        guard provenance.isProviderBacked else {
            return HoldingEligibility(symbol: holding.symbol, provenance: provenance, eligibleHolding: nil)
        }

        let prices = (priceHistoryBySymbol[holding.symbol] ?? [])
            .filter { $0.close.isFinite && $0.close > 0 }
            .sorted { $0.date < $1.date }
        guard prices.count >= 2 else {
            return HoldingEligibility(
                symbol: holding.symbol,
                provenance: .unavailable(reason: "Provider-backed historical prices unavailable"),
                eligibleHolding: nil
            )
        }

        return HoldingEligibility(
            symbol: holding.symbol,
            provenance: provenance,
            eligibleHolding: EligibleHolding(
                symbol: holding.symbol,
                marketValue: holding.marketValue,
                portfolioWeight: holding.marketValue / totalPortfolioValue,
                prices: prices,
                provenance: provenance
            )
        )
    }

    private func portfolioReactions(
        eligibleHoldings: [EligibleHolding],
        events: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState,
        includedValue: Double
    ) -> [PortfolioEventReaction] {
        guard includedValue > 0 else { return [] }

        let reactionsBySymbol = Dictionary(uniqueKeysWithValues: eligibleHoldings.map { holding in
            let reactions = AstroCorrelationService.shared.eventReactions(
                prices: holding.prices,
                events: events,
                filterState: filterState
            )
            return (holding.symbol, Dictionary(uniqueKeysWithValues: reactions.map { ($0.event.id, $0) }))
        })

        return events.compactMap { event in
            var weightedReturn = 0.0
            var weightedDrawdown = 0.0
            var weightedVolatility = 0.0
            var contributingValue = 0.0
            var windowStart: Date?
            var windowEnd: Date?

            for holding in eligibleHoldings {
                guard let reaction = reactionsBySymbol[holding.symbol]?[event.id] else { continue }
                weightedReturn += reaction.returnPercent * holding.marketValue
                weightedDrawdown += reaction.maxDrawdownPercent * holding.marketValue
                weightedVolatility += reaction.volatilityPercent * holding.marketValue
                contributingValue += holding.marketValue
                windowStart = minDate(windowStart, reaction.windowStart)
                windowEnd = maxDate(windowEnd, reaction.windowEnd)
            }

            guard contributingValue > 0,
                  contributingValue / includedValue >= minimumEventWeightCoverage else {
                return nil
            }

            return PortfolioEventReaction(
                event: event,
                windowStart: windowStart ?? event.startDate,
                windowEnd: windowEnd ?? event.markerDate,
                returnPercent: weightedReturn / contributingValue,
                maxDrawdownPercent: weightedDrawdown / contributingValue,
                volatilityPercent: weightedVolatility / contributingValue,
                contributingWeight: contributingValue / includedValue
            )
        }
    }

    private func holdingImpacts(
        for eligibleHoldings: [EligibleHolding],
        kindEvents: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState,
        totalPortfolioValue: Double,
        includedValue: Double,
        minimumSampleSize: Int
    ) -> [PortfolioCorrelationHoldingImpact] {
        eligibleHoldings
            .sorted { $0.marketValue > $1.marketValue }
            .map { holding in
                let reactions = AstroCorrelationService.shared.eventReactions(
                    prices: holding.prices,
                    events: kindEvents,
                    filterState: filterState
                )
                let returns = reactions.map(\.returnPercent)
                let hasSufficientSample = returns.count >= minimumSampleSize

                return PortfolioCorrelationHoldingImpact(
                    id: holding.symbol,
                    symbol: holding.symbol,
                    portfolioWeight: totalPortfolioValue > 0 ? holding.marketValue / totalPortfolioValue : 0,
                    includedWeight: includedValue > 0 ? holding.marketValue / includedValue : 0,
                    marketValue: holding.marketValue,
                    sampleSize: returns.count,
                    averageReturn: hasSufficientSample ? average(returns) : nil,
                    medianReturn: hasSufficientSample ? median(returns) : nil,
                    winRate: hasSufficientSample ? winRate(returns) : nil,
                    provenance: holding.provenance,
                    confidence: hasSufficientSample ? confidence(for: returns.count) : .insufficient,
                    displayMode: hasSufficientSample ? .marketBackedResult : .insufficientSample
                )
            }
    }

    private func aggregateProviderProvenance(for holdings: [EligibleHolding]) -> FinancialDataProvenance {
        guard !holdings.isEmpty else {
            return .unavailable(reason: "Provider-backed holding history unavailable")
        }

        let provenances = holdings.map(\.provenance)
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

    private func unavailableSummary(
        kind: AstroOverlayEventKind,
        eventCount: Int,
        window: CorrelationWindow,
        unavailableHoldings: [String],
        provenance: FinancialDataProvenance,
        displayMode: CorrelationDisplayMode,
        disclaimer: String
    ) -> PortfolioCosmicCorrelationSummary {
        PortfolioCosmicCorrelationSummary(
            id: kind.rawValue,
            eventName: kind.displayName,
            eventType: kind,
            eventCount: eventCount,
            sampleSize: 0,
            window: window,
            averagePortfolioReturn: nil,
            medianPortfolioReturn: nil,
            winRate: nil,
            baselinePortfolioReturn: nil,
            volatilityRatio: nil,
            maxDrawdown: nil,
            affectedHoldings: [],
            unavailableHoldings: unavailableHoldings,
            includedPortfolioWeight: 0,
            excludedPortfolioWeight: unavailableHoldings.isEmpty ? 0 : 1,
            provenance: provenance,
            confidence: .unavailable,
            displayMode: displayMode,
            disclaimer: disclaimer
        )
    }

    private func baselinePortfolioReturn(
        for holdings: [EligibleHolding],
        includedValue: Double,
        averageWindowSize: Int
    ) -> Double? {
        guard includedValue > 0 else { return nil }
        let weighted = holdings.reduce(0.0) { partial, holding in
            partial + baselineReturnPercent(prices: holding.prices, averageWindowSize: averageWindowSize) * holding.marketValue
        }
        return weighted / includedValue
    }

    private func baselinePortfolioVolatility(
        for holdings: [EligibleHolding],
        includedValue: Double
    ) -> Double {
        guard includedValue > 0 else { return 0 }
        let weighted = holdings.reduce(0.0) { partial, holding in
            partial + volatilityPercent(for: holding.prices) * holding.marketValue
        }
        return weighted / includedValue
    }

    private func baselineReturnPercent(prices: [OHLCData], averageWindowSize: Int) -> Double {
        let dailyReturns = zip(prices, prices.dropFirst()).compactMap { previous, current -> Double? in
            guard previous.close > 0 else { return nil }
            return ((current.close - previous.close) / previous.close) * 100
        }
        return average(dailyReturns) * Double(max(1, averageWindowSize))
    }

    private func averageWindowSize(for reactions: [PortfolioEventReaction]) -> Int {
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

    private func minDate(_ lhs: Date?, _ rhs: Date) -> Date {
        guard let lhs else { return rhs }
        return min(lhs, rhs)
    }

    private func maxDate(_ lhs: Date?, _ rhs: Date) -> Date {
        guard let lhs else { return rhs }
        return max(lhs, rhs)
    }
}

private struct WeightedHolding {
    let stock: Stock
    let symbol: String
    let marketValue: Double
}

private struct EligibleHolding {
    let symbol: String
    let marketValue: Double
    let portfolioWeight: Double
    let prices: [OHLCData]
    let provenance: FinancialDataProvenance
}

private struct HoldingEligibility {
    let symbol: String
    let provenance: FinancialDataProvenance
    let eligibleHolding: EligibleHolding?
}

private struct PortfolioEventReaction {
    let event: AstroOverlayEvent
    let windowStart: Date
    let windowEnd: Date
    let returnPercent: Double
    let maxDrawdownPercent: Double
    let volatilityPercent: Double
    let contributingWeight: Double
}
