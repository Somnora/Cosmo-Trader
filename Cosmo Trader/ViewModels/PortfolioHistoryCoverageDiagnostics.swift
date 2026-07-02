import Foundation

enum PortfolioHistoryCoverageStatus: String, CaseIterable, Equatable {
    case usable
    case stale
    case partial
    case insufficient
    case unavailable

    var label: String {
        switch self {
        case .usable:
            return "Usable"
        case .stale:
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
        case .usable:
            return "Provider-backed history can count toward portfolio correlation coverage."
        case .stale:
            return "Cached provider-backed history is stale under the current freshness policy."
        case .partial:
            return "Provider returned some history, but the required range is incomplete."
        case .insufficient:
            return "Provider returned too little history for correlation context."
        case .unavailable:
            return "Provider-backed history has not loaded for this holding."
        }
    }
}

struct PortfolioHistoryCoverageRow: Identifiable, Equatable {
    let symbol: String
    let marketValue: Double
    let portfolioWeight: Double
    let status: PortfolioHistoryCoverageStatus
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness?

    var id: String { symbol }

    var formattedWeight: String {
        "\(Int((portfolioWeight * 100).rounded()))%"
    }

    var statusDetail: String {
        if let reason = completeness?.reason, !reason.isEmpty {
            return reason
        }
        return status.detail
    }
}

struct PortfolioHistoryCoverageDiagnostics: Equatable {
    static let unlockThreshold = 0.70

    let rows: [PortfolioHistoryCoverageRow]
    let totalPortfolioValue: Double

    static let empty = PortfolioHistoryCoverageDiagnostics(rows: [], totalPortfolioValue: 0)

    var totalHoldings: Int {
        rows.count
    }

    var usableHoldingsCount: Int {
        count(.usable)
    }

    var staleHoldingsCount: Int {
        count(.stale)
    }

    var partialHoldingsCount: Int {
        count(.partial)
    }

    var insufficientHoldingsCount: Int {
        count(.insufficient)
    }

    var unavailableHoldingsCount: Int {
        count(.unavailable)
    }

    var usablePortfolioWeight: Double {
        rows
            .filter { $0.status == .usable }
            .reduce(0) { $0 + $1.portfolioWeight }
    }

    var remainingWeightToUnlock: Double {
        max(0, Self.unlockThreshold - usablePortfolioWeight)
    }

    var formattedUsableCoverage: String {
        formatPercent(usablePortfolioWeight)
    }

    var formattedRemainingWeightToUnlock: String {
        formatPercent(remainingWeightToUnlock)
    }

    var needsHistorySymbols: [String] {
        rows
            .filter { $0.status != .usable }
            .map(\.symbol)
            .sorted()
    }

    var isCorrelationCoverageReady: Bool {
        usablePortfolioWeight >= Self.unlockThreshold
    }

    var unlockText: String {
        if rows.isEmpty {
            return "Add holdings with usable market value, then load provider-backed history."
        }

        if isCorrelationCoverageReady {
            return "70% usable coverage is met. Portfolio correlation still depends on provider freshness and minimum event sample size."
        }

        return "70% usable coverage is required; \(formattedRemainingWeightToUnlock) more usable market value coverage is needed before headline portfolio correlation metrics appear."
    }

    func count(_ status: PortfolioHistoryCoverageStatus) -> Int {
        rows.filter { $0.status == status }.count
    }

    static func make(
        holdings: [Stock],
        datasetSnapshot: CorrelationHistoricalDatasetSnapshot,
        staleAfter staleInterval: TimeInterval = FinancialDataProvenance.defaultCachedStaleInterval
    ) -> PortfolioHistoryCoverageDiagnostics {
        let ownedHoldings = holdings
            .filter(\.isOwned)
            .filter { $0.marketValue > 0 }
        let totalValue = ownedHoldings.reduce(0) { $0 + $1.marketValue }

        guard totalValue > 0 else {
            return .empty
        }

        let rows = ownedHoldings
            .map { holding -> PortfolioHistoryCoverageRow in
                let symbol = holding.symbol.uppercased()
                let marketValue = holding.marketValue
                let weight = marketValue / totalValue

                if let dataset = datasetSnapshot.datasetsBySymbol[symbol] {
                    let status = status(for: dataset, staleAfter: staleInterval)
                    return PortfolioHistoryCoverageRow(
                        symbol: symbol,
                        marketValue: marketValue,
                        portfolioWeight: weight,
                        status: status,
                        provenance: displayProvenance(for: dataset, status: status),
                        completeness: dataset.completeness
                    )
                }

                return PortfolioHistoryCoverageRow(
                    symbol: symbol,
                    marketValue: marketValue,
                    portfolioWeight: weight,
                    status: .unavailable,
                    provenance: datasetSnapshot.unavailableProvenanceBySymbol[symbol]
                        ?? .unavailable(reason: "Provider-backed historical prices unavailable"),
                    completeness: nil
                )
            }
            .sorted { lhs, rhs in
                if lhs.status == rhs.status {
                    if lhs.marketValue == rhs.marketValue { return lhs.symbol < rhs.symbol }
                    return lhs.marketValue > rhs.marketValue
                }
                return statusSortOrder(lhs.status) < statusSortOrder(rhs.status)
            }

        return PortfolioHistoryCoverageDiagnostics(rows: rows, totalPortfolioValue: totalValue)
    }

    private static func status(
        for dataset: HistoricalPriceDataset,
        staleAfter staleInterval: TimeInterval
    ) -> PortfolioHistoryCoverageStatus {
        guard dataset.provenance.isProviderBacked else {
            return .unavailable
        }

        if dataset.provenance.isCachedStale(staleAfter: staleInterval) {
            return .stale
        }

        switch dataset.completeness {
        case .complete:
            return dataset.candles.count >= 2 ? .usable : .insufficient
        case .partial:
            return .partial
        case .insufficient:
            return .insufficient
        }
    }

    private static func displayProvenance(
        for dataset: HistoricalPriceDataset,
        status: PortfolioHistoryCoverageStatus
    ) -> FinancialDataProvenance {
        switch status {
        case .usable, .stale:
            return dataset.provenance
        case .partial:
            return dataset.correlationDisplayProvenance
        case .insufficient:
            return dataset.correlationDisplayProvenance
        case .unavailable:
            return dataset.provenance.isProviderBacked
                ? dataset.correlationDisplayProvenance
                : dataset.provenance
        }
    }

    private static func statusSortOrder(_ status: PortfolioHistoryCoverageStatus) -> Int {
        switch status {
        case .usable:
            return 0
        case .stale:
            return 1
        case .partial:
            return 2
        case .insufficient:
            return 3
        case .unavailable:
            return 4
        }
    }

    private func formatPercent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
