import Foundation

nonisolated struct CorrelationHistoricalDatasetSnapshot: Equatable {
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

    func dataset(
        symbol: String,
        timeframe: ChartTimeframe,
        forceRefresh: Bool = false
    ) async throws -> HistoricalPriceDataset {
        try await historicalPriceService.fetchHistoricalDataset(
            symbol: symbol,
            timeframe: timeframe,
            forceRefresh: forceRefresh
        )
    }

    func datasets(symbols: [String], timeframe: ChartTimeframe) async -> CorrelationHistoricalDatasetSnapshot {
        var datasetsBySymbol: [String: HistoricalPriceDataset] = [:]
        var unavailableBySymbol: [String: FinancialDataProvenance] = [:]

        for symbol in symbols.map({ $0.uppercased() }) {
            do {
                let dataset = try await dataset(symbol: symbol, timeframe: timeframe)
                datasetsBySymbol[symbol] = dataset
            } catch {
                unavailableBySymbol[symbol] = .unavailable(reason: "Provider-backed historical prices unavailable")
            }
        }

        return CorrelationHistoricalDatasetSnapshot(
            datasetsBySymbol: datasetsBySymbol,
            unavailableProvenanceBySymbol: unavailableBySymbol
        )
    }
}
