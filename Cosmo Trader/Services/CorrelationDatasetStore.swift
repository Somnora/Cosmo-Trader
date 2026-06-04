import Foundation

nonisolated struct CorrelationHistoricalDatasetSnapshot: Equatable {
    let requestedSymbols: [String]
    let datasetsBySymbol: [String: HistoricalPriceDataset]
    let unavailableProvenanceBySymbol: [String: FinancialDataProvenance]

    var priceHistoryBySymbol: [String: [OHLCData]] {
        datasetsBySymbol.mapValues(\.ohlcData)
    }

    var provenanceBySymbol: [String: FinancialDataProvenance] {
        datasetsBySymbol.mapValues(\.provenance)
            .merging(unavailableProvenanceBySymbol) { current, _ in current }
    }

    var completenessBySymbol: [String: HistoricalDatasetCompleteness] {
        datasetsBySymbol.mapValues(\.completeness)
    }

    var historyActivationSnapshot: ProviderHistoryActivationSnapshot {
        ProviderHistoryActivationSnapshot(
            symbols: requestedSymbols,
            datasetsBySymbol: datasetsBySymbol,
            unavailableProvenanceBySymbol: unavailableProvenanceBySymbol
        )
    }
}

nonisolated enum ProviderHistorySymbolStatusKind: String, Equatable {
    case live
    case cached
    case stale
    case partial
    case insufficient
    case unavailable
    case sample

    var displayName: String {
        switch self {
        case .live:
            return "Live"
        case .cached:
            return "Cached"
        case .stale:
            return "Stale"
        case .partial:
            return "Partial"
        case .insufficient:
            return "Insufficient"
        case .unavailable:
            return "Unavailable"
        case .sample:
            return "Sample"
        }
    }

    var isUsableForNumericClaims: Bool {
        self == .live || self == .cached
    }
}

nonisolated struct ProviderHistorySymbolStatus: Identifiable, Equatable {
    let symbol: String
    let status: ProviderHistorySymbolStatusKind
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness?

    var id: String { symbol }

    var isUsableForNumericClaims: Bool {
        status.isUsableForNumericClaims
    }
}

nonisolated struct ProviderHistoryActivationSnapshot: Equatable {
    let statuses: [ProviderHistorySymbolStatus]

    init(
        symbols: [String],
        datasetsBySymbol: [String: HistoricalPriceDataset],
        unavailableProvenanceBySymbol: [String: FinancialDataProvenance] = [:],
        staleAfter: TimeInterval = HistoricalPriceDataset.defaultStaleInterval
    ) {
        let normalizedSymbols = Self.normalizedSymbols(symbols)
        let normalizedDatasets = Dictionary(uniqueKeysWithValues: datasetsBySymbol.map { key, value in
            (key.uppercased(), value)
        })
        let normalizedUnavailable = Dictionary(uniqueKeysWithValues: unavailableProvenanceBySymbol.map { key, value in
            (key.uppercased(), value)
        })

        statuses = normalizedSymbols.map { symbol in
            Self.status(
                symbol: symbol,
                dataset: normalizedDatasets[symbol],
                unavailableProvenance: normalizedUnavailable[symbol],
                staleAfter: staleAfter
            )
        }
    }

    static func empty(symbols: [String] = []) -> ProviderHistoryActivationSnapshot {
        ProviderHistoryActivationSnapshot(symbols: symbols, datasetsBySymbol: [:])
    }

    var usableSymbols: [String] {
        statuses.filter(\.isUsableForNumericClaims).map(\.symbol)
    }

    var symbolsNeedingHistory: [String] {
        statuses.filter { !$0.isUsableForNumericClaims }.map(\.symbol)
    }

    var staleSymbols: [String] {
        statuses.filter { $0.status == .stale }.map(\.symbol)
    }

    var partialSymbols: [String] {
        statuses.filter { $0.status == .partial }.map(\.symbol)
    }

    var insufficientSymbols: [String] {
        statuses.filter { $0.status == .insufficient }.map(\.symbol)
    }

    var unavailableSymbols: [String] {
        statuses.filter { $0.status == .unavailable }.map(\.symbol)
    }

    var sampleSymbols: [String] {
        statuses.filter { $0.status == .sample }.map(\.symbol)
    }

    var usableCoverage: Double {
        guard !statuses.isEmpty else { return 0 }
        return Double(usableSymbols.count) / Double(statuses.count)
    }

    var aggregateProvenance: FinancialDataProvenance {
        guard !statuses.isEmpty else {
            return .unavailable(reason: "No symbols requested for provider-backed history")
        }

        let usable = statuses.filter(\.isUsableForNumericClaims)
        guard !usable.isEmpty else {
            if statuses.allSatisfy({ $0.status == .sample }) {
                return .sample(reason: "Only explicit sample history is available")
            }
            return .unavailable(reason: "Provider-backed history unavailable")
        }

        guard usable.count == statuses.count else {
            let missing = symbolsNeedingHistory.joined(separator: ", ")
            return .mixed(reason: "Provider-backed history is usable for \(usableSymbols.joined(separator: ", ")). Needs data: \(missing).")
        }

        let provenances = usable.map(\.provenance)
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

    private static func normalizedSymbols(_ symbols: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for symbol in symbols.map({ $0.uppercased() }) where !symbol.isEmpty && !seen.contains(symbol) {
            seen.insert(symbol)
            result.append(symbol)
        }
        return result.sorted()
    }

    private static func status(
        symbol: String,
        dataset: HistoricalPriceDataset?,
        unavailableProvenance: FinancialDataProvenance?,
        staleAfter: TimeInterval
    ) -> ProviderHistorySymbolStatus {
        guard let dataset else {
            return ProviderHistorySymbolStatus(
                symbol: symbol,
                status: .unavailable,
                provenance: unavailableProvenance ?? .unavailable(reason: "Provider-backed historical prices unavailable"),
                completeness: nil
            )
        }

        let sourceProvenance = dataset.provenance
        let displayProvenance = dataset.correlationDisplayProvenance

        if case .sample = sourceProvenance {
            return ProviderHistorySymbolStatus(symbol: symbol, status: .sample, provenance: displayProvenance, completeness: dataset.completeness)
        }

        guard sourceProvenance.isProviderBacked else {
            return ProviderHistorySymbolStatus(symbol: symbol, status: .unavailable, provenance: displayProvenance, completeness: dataset.completeness)
        }

        if sourceProvenance.isCachedStale(staleAfter: staleAfter) {
            return ProviderHistorySymbolStatus(symbol: symbol, status: .stale, provenance: displayProvenance, completeness: dataset.completeness)
        }

        switch dataset.completeness {
        case .complete:
            let status: ProviderHistorySymbolStatusKind = {
                if case .live = sourceProvenance { return .live }
                return .cached
            }()
            return ProviderHistorySymbolStatus(symbol: symbol, status: status, provenance: displayProvenance, completeness: dataset.completeness)
        case .partial:
            return ProviderHistorySymbolStatus(symbol: symbol, status: .partial, provenance: displayProvenance, completeness: dataset.completeness)
        case .insufficient:
            return ProviderHistorySymbolStatus(symbol: symbol, status: .insufficient, provenance: displayProvenance, completeness: dataset.completeness)
        }
    }
}

@MainActor
final class CorrelationDatasetStore {
    static let shared = CorrelationDatasetStore()

    private let historicalPriceService: HistoricalPriceService

    init() {
        self.historicalPriceService = .shared
    }

    init(historicalPriceService: HistoricalPriceService) {
        self.historicalPriceService = historicalPriceService
    }

    func dataset(symbol: String, timeframe: ChartTimeframe) async throws -> HistoricalPriceDataset {
        try await historicalPriceService.fetchHistoricalDataset(symbol: symbol, timeframe: timeframe)
    }

    func datasets(symbols: [String], timeframe: ChartTimeframe) async -> CorrelationHistoricalDatasetSnapshot {
        let requestedSymbols = Array(Set(symbols.map { $0.uppercased() })).sorted()
        var datasetsBySymbol: [String: HistoricalPriceDataset] = [:]
        var unavailableBySymbol: [String: FinancialDataProvenance] = [:]

        for symbol in requestedSymbols {
            do {
                let dataset = try await dataset(symbol: symbol, timeframe: timeframe)
                datasetsBySymbol[symbol] = dataset
            } catch {
                unavailableBySymbol[symbol] = .unavailable(reason: "Provider-backed historical prices unavailable")
            }
        }

        return CorrelationHistoricalDatasetSnapshot(
            requestedSymbols: requestedSymbols,
            datasetsBySymbol: datasetsBySymbol,
            unavailableProvenanceBySymbol: unavailableBySymbol
        )
    }

    func historyActivationSnapshot(
        symbols: [String],
        timeframe: ChartTimeframe
    ) async -> ProviderHistoryActivationSnapshot {
        await datasets(symbols: symbols, timeframe: timeframe).historyActivationSnapshot
    }
}
