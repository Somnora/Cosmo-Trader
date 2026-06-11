import Foundation

struct PortfolioDistributionSlice: Equatable, Identifiable {
    let id: String
    let label: String
    let value: Double
    let percentage: Double
}

struct PortfolioIntelligenceSummary: Equatable {
    let holdingsCount: Int
    let totalStoredValue: Double
    let totalStoredValueProvenance: FinancialDataProvenance
    let providerQuoteCoverage: Double
    let providerQuoteValue: Double
    let providerQuoteProvenance: FinancialDataProvenance
    let topHoldingSymbol: String?
    let topHoldingConcentration: Double
    let sectorDistribution: [PortfolioDistributionSlice]
    let elementDistribution: [PortfolioDistributionSlice]
    let zodiacDistribution: [PortfolioDistributionSlice]
    let verifiedAstrologyCoverage: Double
    let unknownFoundedCount: Int
    let unknownFoundedValue: Double
    let historyCoverage: Double
    let historyProvenance: FinancialDataProvenance
    let correlationReadinessCopy: String

    var hasHoldings: Bool { holdingsCount > 0 }

    var allowsPortfolioCorrelationHeadlineMetrics: Bool {
        historyCoverage >= 0.70 && historyProvenance.isProviderBacked
    }

    static func make(
        holdings: [Stock],
        quoteProvenanceBySymbol: [String: FinancialDataProvenance],
        correlationSummaries: [PortfolioCosmicCorrelationSummary]
    ) -> PortfolioIntelligenceSummary {
        let ownedHoldings = holdings
            .filter(\.isOwned)
            .filter { $0.marketValue > 0 }
        let totalStoredValue = ownedHoldings.reduce(0) { $0 + $1.marketValue }
        let totalStoredValueProvenance: FinancialDataProvenance = totalStoredValue > 0
            ? .sample(reason: "Stored portfolio value from user holdings setup; provider quote coverage is shown separately")
            : .unavailable(reason: "No initialized portfolio holdings")

        let providerQuoteValue = ownedHoldings.reduce(0) { partial, holding in
            let provenance = quoteProvenanceBySymbol[holding.symbol.uppercased()]
            return (provenance?.isProviderBacked == true) ? partial + holding.marketValue : partial
        }
        let providerQuoteCoverage = totalStoredValue > 0 ? providerQuoteValue / totalStoredValue : 0
        let providerQuoteProvenance = aggregateQuoteProvenance(
            holdings: ownedHoldings,
            quoteProvenanceBySymbol: quoteProvenanceBySymbol,
            coverage: providerQuoteCoverage
        )

        let topHolding = ownedHoldings.max { $0.marketValue < $1.marketValue }
        let topHoldingConcentration = totalStoredValue > 0 ? (topHolding?.marketValue ?? 0) / totalStoredValue : 0

        let verifiedAstrologyHoldings = ownedHoldings.filter { $0.foundedZodiacSign != nil }
        let verifiedAstrologyValue = verifiedAstrologyHoldings.reduce(0) { $0 + $1.marketValue }
        let unknownFoundedHoldings = ownedHoldings.filter { $0.foundedZodiacSign == nil }
        let unknownFoundedValue = unknownFoundedHoldings.reduce(0) { $0 + $1.marketValue }
        let verifiedAstrologyCoverage = totalStoredValue > 0 ? verifiedAstrologyValue / totalStoredValue : 0

        let historyCoverage = correlationSummaries.map(\.includedPortfolioWeight).max() ?? 0
        let historyProvenance = aggregateHistoryProvenance(
            summaries: correlationSummaries,
            coverage: historyCoverage
        )

        return PortfolioIntelligenceSummary(
            holdingsCount: ownedHoldings.count,
            totalStoredValue: totalStoredValue,
            totalStoredValueProvenance: totalStoredValueProvenance,
            providerQuoteCoverage: providerQuoteCoverage,
            providerQuoteValue: providerQuoteValue,
            providerQuoteProvenance: providerQuoteProvenance,
            topHoldingSymbol: topHolding?.symbol.uppercased(),
            topHoldingConcentration: topHoldingConcentration,
            sectorDistribution: distribution(
                items: ownedHoldings.compactMap { holding in
                    let label = holding.sector.trimmingCharacters(in: .whitespacesAndNewlines)
                    return label.isEmpty ? nil : (label, holding.marketValue)
                },
                totalValue: totalStoredValue
            ),
            elementDistribution: distribution(
                items: verifiedAstrologyHoldings.compactMap { holding in
                    guard let element = holding.foundedElement else { return nil }
                    return (element.displayName, holding.marketValue)
                },
                totalValue: verifiedAstrologyValue
            ),
            zodiacDistribution: distribution(
                items: verifiedAstrologyHoldings.compactMap { holding in
                    guard let sign = holding.foundedZodiacSign else { return nil }
                    return (sign.displayName, holding.marketValue)
                },
                totalValue: verifiedAstrologyValue
            ),
            verifiedAstrologyCoverage: verifiedAstrologyCoverage,
            unknownFoundedCount: unknownFoundedHoldings.count,
            unknownFoundedValue: unknownFoundedValue,
            historyCoverage: historyCoverage,
            historyProvenance: historyProvenance,
            correlationReadinessCopy: correlationReadinessCopy(
                holdingsCount: ownedHoldings.count,
                historyCoverage: historyCoverage,
                historyProvenance: historyProvenance
            )
        )
    }

    static func shouldShowDailyPL(provenance: FinancialDataProvenance) -> Bool {
        provenance.isProviderBacked
    }

    private static func aggregateQuoteProvenance(
        holdings: [Stock],
        quoteProvenanceBySymbol: [String: FinancialDataProvenance],
        coverage: Double
    ) -> FinancialDataProvenance {
        guard !holdings.isEmpty else {
            return .unavailable(reason: "No holdings available for provider quote coverage")
        }

        let provenances = holdings.compactMap { quoteProvenanceBySymbol[$0.symbol.uppercased()] }
        let providerProvenances = provenances.filter(\.isProviderBacked)
        guard coverage > 0, !providerProvenances.isEmpty else {
            return .unavailable(reason: "Provider quotes unavailable for portfolio holdings")
        }

        guard coverage >= 0.999, providerProvenances.count == holdings.count else {
            return .mixed(reason: "Provider quotes cover \(percent(coverage)) of stored portfolio value")
        }

        let fetchedDates = providerProvenances.compactMap(\.fetchedAt)
        let fetchedAt = fetchedDates.min() ?? Date()
        let allLive = providerProvenances.allSatisfy { provenance in
            if case .live = provenance { return true }
            return false
        }
        if allLive {
            return .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        }

        let allCached = providerProvenances.allSatisfy(\.isCached)
        if allCached {
            return .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        }

        return .mixed(reason: "Provider quotes combine live and cached fields across all holdings")
    }

    private static func aggregateHistoryProvenance(
        summaries: [PortfolioCosmicCorrelationSummary],
        coverage: Double
    ) -> FinancialDataProvenance {
        guard !summaries.isEmpty else {
            return .unavailable(reason: "Provider-backed holding history unavailable")
        }

        if let marketBacked = summaries.first(where: { $0.displayMode == .marketBackedResult }) {
            return marketBacked.provenance
        }

        if let partial = summaries.first(where: { $0.includedPortfolioWeight == coverage }) {
            return partial.provenance
        }

        return summaries.first?.provenance ?? .unavailable(reason: "Provider-backed holding history unavailable")
    }

    private static func distribution(
        items: [(String, Double)],
        totalValue: Double
    ) -> [PortfolioDistributionSlice] {
        guard totalValue > 0 else { return [] }

        let values = items.reduce(into: [String: Double]()) { partial, item in
            partial[item.0, default: 0] += item.1
        }

        return values
            .map { label, value in
                PortfolioDistributionSlice(
                    id: label,
                    label: label,
                    value: value,
                    percentage: value / totalValue
                )
            }
            .sorted {
                if $0.value == $1.value { return $0.label < $1.label }
                return $0.value > $1.value
            }
    }

    private static func correlationReadinessCopy(
        holdingsCount: Int,
        historyCoverage: Double,
        historyProvenance: FinancialDataProvenance
    ) -> String {
        guard holdingsCount > 0 else {
            return "Add holdings before portfolio correlation context can be calculated."
        }

        if historyCoverage < 0.50 {
            return "Provider-backed history needs to cover at least 50% of stored portfolio value before portfolio context appears."
        }

        if historyCoverage < 0.70 {
            return "Portfolio correlation stays context-only until provider-backed history covers at least 70% of stored portfolio value."
        }

        if !historyProvenance.isProviderBacked {
            return "History coverage is high, but provenance still blocks headline portfolio metrics."
        }

        return "History coverage clears the portfolio threshold. Sample size and event gates still control numeric metrics."
    }

    static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", max(0, min(1, value)) * 100)
    }
}
