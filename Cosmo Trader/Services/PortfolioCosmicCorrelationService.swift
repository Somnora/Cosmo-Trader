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
    /// Deliberately absent at the portfolio level for now.
    ///
    /// Baseline return and volatility are linear in the holding weights, so a
    /// value-weighted average of per-holding baselines is exactly the quantity
    /// the event statistic reports. A win rate is not linear: averaging each
    /// holding's up-rate is not the rate at which the portfolio itself closed
    /// up, because it throws away diversification. Publishing it anyway would
    /// put a number on screen that does not answer the question next to it, so
    /// it stays nil until the baseline windows are evaluated at portfolio
    /// level with the same fixed weights the event windows use.
    let baselineWinRate: Double?
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
    private let minimumPortfolioCoverageForAnyContext = 0.5
    private let minimumPortfolioCoverageForNumericClaims = 0.7
    private let minimumEventWeightCoverage = 0.5

    private init() {}

    func summaries(
        holdings: [Stock],
        priceHistoryBySymbol: [String: [OHLCData]],
        provenanceBySymbol: [String: FinancialDataProvenance],
        completenessBySymbol: [String: HistoricalDatasetCompleteness] = [:],
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
                provenanceBySymbol: provenanceBySymbol,
                completenessBySymbol: completenessBySymbol
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

            guard includedPortfolioWeight >= minimumPortfolioCoverageForAnyContext else {
                return portfolioCoverageSummary(
                    kind: kind,
                    eventCount: kindEvents.count,
                    window: window,
                    eligibleHoldings: eligibleHoldings,
                    unavailableHoldings: unavailableSymbols,
                    includedPortfolioWeight: includedPortfolioWeight,
                    excludedPortfolioWeight: excludedPortfolioWeight,
                    totalPortfolioValue: totalPortfolioValue,
                    includedValue: includedValue,
                    requiredCoverage: minimumPortfolioCoverageForAnyContext,
                    displayMode: .insufficientSample,
                    reasonSuffix: "coverage is required for portfolio context"
                )
            }

            guard includedPortfolioWeight >= minimumPortfolioCoverageForNumericClaims else {
                return portfolioCoverageSummary(
                    kind: kind,
                    eventCount: kindEvents.count,
                    window: window,
                    eligibleHoldings: eligibleHoldings,
                    unavailableHoldings: unavailableSymbols,
                    includedPortfolioWeight: includedPortfolioWeight,
                    excludedPortfolioWeight: excludedPortfolioWeight,
                    totalPortfolioValue: totalPortfolioValue,
                    includedValue: includedValue,
                    requiredCoverage: minimumPortfolioCoverageForNumericClaims,
                    displayMode: .partialCoverage,
                    reasonSuffix: "coverage is required for headline portfolio metrics. Partial context only"
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
            baselineWinRate: nil,
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
            baselineWinRate: nil,
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
            let averageVolatility = average(portfolioReactions.map(\.volatilityPercent))
            let baseline = portfolioBaseline(
                for: eligibleHoldings,
                includedValue: includedValue,
                kindEvents: kindEvents,
                filterState: filterState,
                windowLength: averageWindowSize(for: portfolioReactions)
            )
            let volatilityRatio = (baseline?.volatilityPercent).flatMap { baselineVolatility in
                baselineVolatility > 0 ? averageVolatility / baselineVolatility : nil
            }

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
                baselinePortfolioReturn: baseline?.averageReturnPercent,
                baselineWinRate: nil,
                volatilityRatio: volatilityRatio,
                maxDrawdown: portfolioReactions.map(\.maxDrawdownPercent).max(),
                affectedHoldings: impacts,
                unavailableHoldings: unavailableSymbols,
                includedPortfolioWeight: includedPortfolioWeight,
                excludedPortfolioWeight: excludedPortfolioWeight,
                provenance: providerProvenance,
                confidence: CorrelationBaselineCalculator.confidence(returns: returns),
                displayMode: .marketBackedResult,
                disclaimer: "Historical portfolio context only. Correlation does not imply causation and this is not financial advice."
            )
        }
    }

    private func portfolioCoverageSummary(
        kind: AstroOverlayEventKind,
        eventCount: Int,
        window: CorrelationWindow,
        eligibleHoldings: [EligibleHolding],
        unavailableHoldings: [String],
        includedPortfolioWeight: Double,
        excludedPortfolioWeight: Double,
        totalPortfolioValue: Double,
        includedValue: Double,
        requiredCoverage: Double,
        displayMode: CorrelationDisplayMode,
        reasonSuffix: String
    ) -> PortfolioCosmicCorrelationSummary {
        let requiredCoverage = String(format: "%.0f%%", requiredCoverage * 100)
        let actualCoverage = String(format: "%.0f%%", includedPortfolioWeight * 100)
        let reason = "Only \(actualCoverage) of portfolio value has provider-backed historical prices; \(requiredCoverage) \(reasonSuffix)"

        return PortfolioCosmicCorrelationSummary(
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
            baselineWinRate: nil,
            volatilityRatio: nil,
            maxDrawdown: nil,
            affectedHoldings: eligibleHoldings.map { holding in
                PortfolioCorrelationHoldingImpact(
                    id: holding.symbol,
                    symbol: holding.symbol,
                    portfolioWeight: totalPortfolioValue > 0 ? holding.marketValue / totalPortfolioValue : 0,
                    includedWeight: includedValue > 0 ? holding.marketValue / includedValue : 0,
                    marketValue: holding.marketValue,
                    sampleSize: 0,
                    averageReturn: nil,
                    medianReturn: nil,
                    winRate: nil,
                    provenance: holding.provenance,
                    confidence: .insufficient,
                    displayMode: .insufficientSample
                )
            },
            unavailableHoldings: unavailableHoldings,
            includedPortfolioWeight: includedPortfolioWeight,
            excludedPortfolioWeight: excludedPortfolioWeight,
            provenance: .mixed(reason: reason),
            confidence: .insufficient,
            displayMode: displayMode,
            disclaimer: "\(reason). No portfolio-level return claim is shown."
        )
    }

    private func holdingEligibility(
        holding: WeightedHolding,
        totalPortfolioValue: Double,
        priceHistoryBySymbol: [String: [OHLCData]],
        provenanceBySymbol: [String: FinancialDataProvenance],
        completenessBySymbol: [String: HistoricalDatasetCompleteness]
    ) -> HoldingEligibility {
        let provenance = provenanceBySymbol[holding.symbol] ?? .unavailable(reason: "Provider-backed historical prices unavailable")
        guard provenance.isProviderBacked else {
            return HoldingEligibility(symbol: holding.symbol, provenance: provenance, eligibleHolding: nil)
        }

        let completeness = completenessBySymbol[holding.symbol] ?? .complete
        guard completeness.allowsNumericCorrelationClaims else {
            return HoldingEligibility(
                symbol: holding.symbol,
                provenance: qualityProvenance(for: provenance, completeness: completeness),
                eligibleHolding: nil
            )
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

    private func qualityProvenance(
        for provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness
    ) -> FinancialDataProvenance {
        guard provenance.isProviderBacked else { return provenance }

        switch completeness {
        case .complete:
            return provenance
        case .partial(let reason):
            return .mixed(reason: "Partial historical dataset. \(reason)")
        case .insufficient(let reason):
            return .unavailable(reason: "Insufficient historical dataset. \(reason)")
        }
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
            var candleCounts: [Double] = []

            for holding in eligibleHoldings {
                guard let reaction = reactionsBySymbol[holding.symbol]?[event.id] else { continue }
                weightedReturn += reaction.returnPercent * holding.marketValue
                weightedDrawdown += reaction.maxDrawdownPercent * holding.marketValue
                weightedVolatility += reaction.volatilityPercent * holding.marketValue
                contributingValue += holding.marketValue
                candleCounts.append(Double(reaction.candleCount))
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
                contributingWeight: contributingValue / includedValue,
                candleCount: max(2, Int(round(average(candleCounts))))
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
                    confidence: hasSufficientSample
                        ? CorrelationBaselineCalculator.confidence(returns: returns)
                        : .insufficient,
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
            baselineWinRate: nil,
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

    /// What the portfolio did over comparable stretches this event never
    /// touched, weighted the same way the event windows are weighted.
    ///
    /// Return and volatility are linear in the weights, so a value-weighted
    /// average of per-holding baselines is exactly the quantity the event
    /// statistic reports. Holdings without enough clean history drop out and
    /// the remaining weights renormalize, so a single short series no longer
    /// silently contributes a zero.
    private func portfolioBaseline(
        for holdings: [EligibleHolding],
        includedValue: Double,
        kindEvents: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState,
        windowLength: Int
    ) -> CorrelationBaseline? {
        guard includedValue > 0 else { return nil }

        let excludedIntervals = kindEvents.map { event in
            AstroCorrelationService.priceWindow(for: event, filterState: filterState, calendar: calendar)
        }

        var contributingValue = 0.0
        var weightedReturn = 0.0
        var weightedVolatility = 0.0
        var windowCount = 0

        for holding in holdings {
            guard let baseline = CorrelationBaselineCalculator.baseline(
                prices: holding.prices,
                excluding: excludedIntervals,
                windowLength: windowLength
            ) else { continue }

            contributingValue += holding.marketValue
            weightedReturn += baseline.averageReturnPercent * holding.marketValue
            weightedVolatility += baseline.volatilityPercent * holding.marketValue
            windowCount = max(windowCount, baseline.windowCount)
        }

        guard contributingValue > 0 else { return nil }

        return CorrelationBaseline(
            averageReturnPercent: weightedReturn / contributingValue,
            winRate: nil,
            volatilityPercent: weightedVolatility / contributingValue,
            windowCount: windowCount,
            windowLength: windowLength
        )
    }

    private func averageWindowSize(for reactions: [PortfolioEventReaction]) -> Int {
        guard !reactions.isEmpty else { return 2 }
        return Int(round(average(reactions.map { Double($0.candleCount) })))
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
    /// Trading candles the contributing holdings actually saw in this window,
    /// so the baseline is measured over stretches of the same length. Calendar
    /// days would stretch every window by roughly the weekends inside it.
    let candleCount: Int
}
