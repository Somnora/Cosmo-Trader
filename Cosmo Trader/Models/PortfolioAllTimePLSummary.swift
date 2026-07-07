import Foundation

// MARK: - PortfolioAllTimePLSummary
// =================================
// Real all-time (unrealized) P/L across the portfolio, computed only from
// holdings whose facts are honest on both sides of the subtraction:
//
//   current side — a provider-backed quote this session (live or cached);
//                  stored/import prices never price the "now" leg,
//   cost side    — a user-entered or imported cost basis; holdings
//                  without one are excluded, never guessed.
//
// Partial coverage is the common case (imports often lack cost basis), so
// the summary carries explicit exclusion buckets and the UI must label
// coverage rather than imply the number spans the whole portfolio.

// MainActor (project default): the inputs are Stock values, which are
// main-actor isolated, and every consumer is a view.
struct PortfolioAllTimePLSummary: Equatable {
    /// Owned holdings considered (sharesOwned > 0).
    let ownedHoldingCount: Int
    /// Symbols whose P/L is inside the total.
    let includedSymbols: [String]
    /// Owned symbols excluded because no cost basis is stored.
    let missingCostBasisSymbols: [String]
    /// Owned symbols with cost basis but no provider-backed quote yet.
    let missingQuoteSymbols: [String]
    /// Σ(current value − cost basis) over included holdings; nil when
    /// nothing qualifies.
    let totalProfitLoss: Double?
    /// Σ cost basis over included holdings (denominator for the percent).
    let includedCostBasis: Double
    /// Worst-of aggregation over included holdings' quote provenance.
    let provenance: FinancialDataProvenance

    var hasResult: Bool { totalProfitLoss != nil }

    /// Percent return on included cost basis. Nil without a result or when
    /// every included holding has a zero basis (gifted/award shares).
    var profitLossPercent: Double? {
        guard let totalProfitLoss, includedCostBasis > 0 else { return nil }
        return (totalProfitLoss / includedCostBasis) * 100
    }

    var isPositive: Bool { (totalProfitLoss ?? 0) >= 0 }

    var isPartialCoverage: Bool {
        hasResult && includedSymbols.count < ownedHoldingCount
    }

    var formattedProfitLoss: String {
        guard let totalProfitLoss else { return "—" }
        let sign = totalProfitLoss >= 0 ? "+" : ""
        return sign + Self.formatCurrency(totalProfitLoss)
    }

    var formattedPercent: String? {
        guard let percent = profitLossPercent else { return nil }
        let sign = percent >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, percent)
    }

    /// Coverage line rendered beside the number, e.g. "4 OF 6 HOLDINGS".
    var coverageLabel: String {
        "\(includedSymbols.count) OF \(ownedHoldingCount) HOLDINGS"
    }

    /// Honest explanation when no number can be shown, in priority order.
    var unavailableReason: String? {
        guard !hasResult else { return nil }
        if ownedHoldingCount == 0 {
            return "Add holdings to track all-time P/L."
        }
        if missingCostBasisSymbols.count == ownedHoldingCount {
            return "Add cost basis to your holdings to unlock all-time P/L."
        }
        return "Waiting on provider quotes for holdings with cost basis."
    }

    static func make(
        holdings: [Stock],
        quoteProvenanceBySymbol: [String: FinancialDataProvenance]
    ) -> PortfolioAllTimePLSummary {
        let owned = holdings
            .filter(\.isOwned)
            .sorted { $0.symbol < $1.symbol }

        var included: [String] = []
        var missingCostBasis: [String] = []
        var missingQuote: [String] = []
        var totalPL: Double = 0
        var totalBasis: Double = 0
        var includedProvenances: [FinancialDataProvenance] = []

        for holding in owned {
            let symbol = holding.symbol.uppercased()
            guard let costBasis = holding.totalCostBasis else {
                missingCostBasis.append(symbol)
                continue
            }
            guard let quoteProvenance = quoteProvenanceBySymbol[symbol],
                  quoteProvenance.isProviderBacked,
                  holding.currentPrice > 0 else {
                missingQuote.append(symbol)
                continue
            }

            included.append(symbol)
            totalPL += holding.totalValue - costBasis
            totalBasis += costBasis
            includedProvenances.append(quoteProvenance)
        }

        return PortfolioAllTimePLSummary(
            ownedHoldingCount: owned.count,
            includedSymbols: included,
            missingCostBasisSymbols: missingCostBasis,
            missingQuoteSymbols: missingQuote,
            totalProfitLoss: included.isEmpty ? nil : totalPL,
            includedCostBasis: totalBasis,
            provenance: aggregateProvenance(
                includedProvenances,
                unavailableReason: "All-time P/L needs cost basis and a provider-backed quote on at least one holding"
            )
        )
    }

    /// Worst-of aggregation (mirrors PortfolioView.aggregateQuoteProvenance
    /// semantics for the provider-backed cases): all live → live at the
    /// newest fetch, otherwise cached at the newest fetch.
    private static func aggregateProvenance(
        _ provenances: [FinancialDataProvenance],
        unavailableReason: String
    ) -> FinancialDataProvenance {
        guard !provenances.isEmpty else {
            return .unavailable(reason: unavailableReason)
        }

        let liveFetches = provenances.compactMap { provenance -> Date? in
            guard case .live(_, let fetchedAt) = provenance else { return nil }
            return fetchedAt
        }
        if liveFetches.count == provenances.count, let newest = liveFetches.max() {
            return .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: newest)
        }

        let cachedFetches = provenances.compactMap { provenance -> Date? in
            switch provenance {
            case .live(_, let fetchedAt), .cached(_, let fetchedAt, _):
                return fetchedAt
            default:
                return nil
            }
        }
        if let newest = cachedFetches.max() {
            return .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: newest)
        }

        return .unavailable(reason: unavailableReason)
    }

    private static func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
