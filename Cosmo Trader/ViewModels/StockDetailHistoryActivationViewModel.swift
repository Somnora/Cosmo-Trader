import Foundation

enum StockDetailHistoryActivationState: Equatable {
    case idle
    case loading
    case loaded(source: HistoricalPriceSource, provenance: FinancialDataProvenance, completeness: HistoricalDatasetCompleteness, candleCount: Int)
    case unavailable(reason: String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var provenance: FinancialDataProvenance {
        switch self {
        case .loaded(_, let provenance, _, _):
            return provenance
        case .unavailable(let reason):
            return .unavailable(reason: reason)
        case .idle:
            return .unavailable(reason: "Provider-backed historical prices not loaded")
        case .loading:
            return .unavailable(reason: "Provider-backed historical prices loading")
        }
    }

    var title: String {
        switch self {
        case .idle:
            return "Provider history needed"
        case .loading:
            return "Loading provider history"
        case .loaded(_, let provenance, let completeness, _):
            if provenance.isCachedStale() {
                return "Stale cached history"
            }
            switch completeness {
            case .complete:
                return provenance.isCached ? "Cached provider history" : "Provider history loaded"
            case .partial:
                return "Partial provider history"
            case .insufficient:
                return "Insufficient provider history"
            }
        case .unavailable:
            return "Provider history unavailable"
        }
    }

    var message: String {
        switch self {
        case .idle:
            return "Load provider-backed history to unlock chart, technical, and cosmic context when enough data is available."
        case .loading:
            return "Requesting historical candles from the provider/cache pipeline."
        case .loaded(let source, let provenance, let completeness, let candleCount):
            if provenance.isCachedStale() {
                return "A stale provider-backed cache is available. Refresh to check for newer history."
            }
            switch completeness {
            case .complete:
                return "\(source.displayName) returned \(candleCount) candles. Chart context can refresh from this provider-backed history."
            case .partial(let reason):
                return "\(source.displayName) returned partial history. \(reason)"
            case .insufficient(let reason):
                return "\(source.displayName) returned too little history. \(reason)"
            }
        case .unavailable(let reason):
            return reason
        }
    }

    var actionTitle: String {
        switch self {
        case .idle, .unavailable:
            return "Load provider history"
        case .loading:
            return "Loading history"
        case .loaded:
            return "Refresh history"
        }
    }

    var contextRows: [StockDetailHistoryContextRow] {
        switch self {
        case .idle, .loading, .unavailable:
            return [
                StockDetailHistoryContextRow(title: "Chart", status: "Waiting for provider history"),
                StockDetailHistoryContextRow(title: "Technical lens", status: "Needs provider candles"),
                StockDetailHistoryContextRow(title: "Cosmic correlation", status: "Needs provider history and sample size")
            ]
        case .loaded(_, let provenance, let completeness, let candleCount):
            let hasProviderCandles = provenance.isProviderBacked && candleCount >= 2
            let numericCorrelationReady = hasProviderCandles
                && !provenance.isCachedStale()
                && completeness.allowsNumericCorrelationClaims

            return [
                StockDetailHistoryContextRow(
                    title: "Chart",
                    status: hasProviderCandles ? "Provider history available" : "Waiting for provider history"
                ),
                StockDetailHistoryContextRow(
                    title: "Technical lens",
                    status: numericCorrelationReady ? "Provider candles available" : "Needs complete fresh history"
                ),
                StockDetailHistoryContextRow(
                    title: "Cosmic correlation",
                    status: numericCorrelationReady ? "Gate can recheck sample size" : "Numeric claims remain gated"
                )
            ]
        }
    }
}

struct StockDetailHistoryContextRow: Equatable, Identifiable {
    var id: String { title }
    let title: String
    let status: String
}

@MainActor
@Observable
final class StockDetailHistoryActivationViewModel {
    typealias HistoryLoader = (String, ChartTimeframe) async throws -> HistoricalPriceResult

    var state: StockDetailHistoryActivationState = .idle

    private let loader: HistoryLoader

    init(loader: @escaping HistoryLoader = { symbol, timeframe in
        try await HistoricalPriceService.shared.fetchHistoricalPriceResult(
            symbol: symbol,
            timeframe: timeframe
        )
    }) {
        self.loader = loader
    }

    @discardableResult
    func refresh(symbol: String, timeframe: ChartTimeframe) async -> Bool {
        state = .loading

        do {
            let result = try await loader(symbol.uppercased(), timeframe)
            state = .loaded(
                source: result.source,
                provenance: result.provenance,
                completeness: result.completeness,
                candleCount: result.data.count
            )
            return true
        } catch {
            state = .unavailable(reason: "Provider-backed historical prices unavailable. Try again later.")
            return false
        }
    }
}
