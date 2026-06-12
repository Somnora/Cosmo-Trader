import Foundation

@MainActor
final class StockDetailHistoryActivationService {
    static let shared = StockDetailHistoryActivationService()

    typealias DatasetFetcher = (String, ChartTimeframe) async throws -> HistoricalPriceDataset

    private let staleAfter: TimeInterval

    init(staleAfter: TimeInterval = HistoricalPriceDataset.defaultStaleInterval) {
        self.staleAfter = staleAfter
    }

    func loadProviderHistory(
        symbol: String,
        timeframe: ChartTimeframe = .year,
        fetcher: DatasetFetcher = { symbol, timeframe in
            try await HistoricalPriceService.shared.fetchHistoricalDataset(
                symbol: symbol,
                timeframe: timeframe
            )
        }
    ) async -> StockDetailHistoryActivationResult {
        do {
            let dataset = try await fetcher(symbol.uppercased(), timeframe)
            return StockDetailHistoryActivationResult(
                state: .from(dataset: dataset, staleAfter: staleAfter),
                dataset: dataset
            )
        } catch {
            return StockDetailHistoryActivationResult(
                state: .unavailable(
                    symbol: symbol,
                    reason: "Provider-backed historical candles unavailable. Try refreshing again later."
                ),
                dataset: nil
            )
        }
    }
}
