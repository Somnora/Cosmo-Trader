import Foundation

enum StockDetailHistoryDisplayMode: Equatable {
    case notLoaded
    case loading
    case providerBacked
    case cached
    case stale
    case partial
    case insufficient
    case unavailable
    case sampleOnly
}

struct StockDetailHistorySectionStatus: Equatable, Identifiable {
    let id: String
    let title: String
    let detail: String
}

struct StockDetailHistoryActivationState: Equatable {
    let symbol: String
    let displayMode: StockDetailHistoryDisplayMode
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness
    let candleCount: Int
    let headline: String
    let detail: String
    let actionTitle: String?
    let sectionStatuses: [StockDetailHistorySectionStatus]

    var shouldShowAction: Bool {
        actionTitle != nil
    }

    var isProviderBacked: Bool {
        provenance.isProviderBacked
    }

    static func notLoaded(symbol: String) -> StockDetailHistoryActivationState {
        StockDetailHistoryActivationState(
            symbol: symbol.uppercased(),
            displayMode: .notLoaded,
            provenance: .unavailable(reason: "Provider-backed historical candles have not loaded yet"),
            completeness: .insufficient(reason: "Provider-backed historical candles have not loaded yet"),
            candleCount: 0,
            headline: "Provider history not loaded",
            detail: "Chart, technical context, and cosmic correlation need provider-backed daily candles.",
            actionTitle: "LOAD PROVIDER HISTORY",
            sectionStatuses: blockedStatuses(reason: "Waiting for provider-backed candles.")
        )
    }

    static func loading(symbol: String) -> StockDetailHistoryActivationState {
        StockDetailHistoryActivationState(
            symbol: symbol.uppercased(),
            displayMode: .loading,
            provenance: .unavailable(reason: "Loading provider-backed historical candles"),
            completeness: .insufficient(reason: "Loading provider-backed historical candles"),
            candleCount: 0,
            headline: "Loading provider history",
            detail: "Requesting provider-backed daily candles. No sample history is created.",
            actionTitle: nil,
            sectionStatuses: [
                status("Chart", "Refreshing provider-backed candles."),
                status("Technical context", "Waiting for complete daily candle history."),
                status("Cosmic correlation", "Waiting for complete historical event windows.")
            ]
        )
    }

    static func unavailable(symbol: String, reason: String) -> StockDetailHistoryActivationState {
        StockDetailHistoryActivationState(
            symbol: symbol.uppercased(),
            displayMode: .unavailable,
            provenance: .unavailable(reason: reason),
            completeness: .insufficient(reason: reason),
            candleCount: 0,
            headline: "Provider history unavailable",
            detail: reason,
            actionTitle: "RETRY PROVIDER HISTORY",
            sectionStatuses: blockedStatuses(reason: "Provider-backed candles are unavailable.")
        )
    }

    static func from(
        dataset: HistoricalPriceDataset,
        staleAfter staleInterval: TimeInterval = HistoricalPriceDataset.defaultStaleInterval
    ) -> StockDetailHistoryActivationState {
        let symbol = dataset.symbol.uppercased()
        let candleCount = dataset.candles.count

        guard dataset.provenance.isProviderBacked else {
            let mode: StockDetailHistoryDisplayMode
            if case .sample = dataset.provenance {
                mode = .sampleOnly
            } else {
                mode = .unavailable
            }

            return StockDetailHistoryActivationState(
                symbol: symbol,
                displayMode: mode,
                provenance: dataset.provenance,
                completeness: dataset.completeness,
                candleCount: candleCount,
                headline: "Provider history unavailable",
                detail: "Stock Detail requires provider-backed or cached provider-backed candles.",
                actionTitle: "LOAD PROVIDER HISTORY",
                sectionStatuses: blockedStatuses(reason: "Provider-backed candles are unavailable.")
            )
        }

        if case .insufficient(let reason) = dataset.completeness {
            return StockDetailHistoryActivationState(
                symbol: symbol,
                displayMode: .insufficient,
                provenance: dataset.correlationDisplayProvenance,
                completeness: dataset.completeness,
                candleCount: candleCount,
                headline: "Insufficient provider history",
                detail: reason,
                actionTitle: "REFRESH HISTORY",
                sectionStatuses: blockedStatuses(reason: "Not enough daily candles for chart context, technical metrics, or correlation.")
            )
        }

        if case .partial(let reason) = dataset.completeness {
            return StockDetailHistoryActivationState(
                symbol: symbol,
                displayMode: .partial,
                provenance: dataset.correlationDisplayProvenance,
                completeness: dataset.completeness,
                candleCount: candleCount,
                headline: "Partial provider history",
                detail: reason,
                actionTitle: "REFRESH HISTORY",
                sectionStatuses: [
                    status("Chart", "Can show limited provider-backed candles when available."),
                    status("Technical context", "Blocked until complete daily history is available."),
                    status("Cosmic correlation", "Blocked until complete historical event windows are available.")
                ]
            )
        }

        if dataset.provenance.isCachedStale(staleAfter: staleInterval) {
            return StockDetailHistoryActivationState(
                symbol: symbol,
                displayMode: .stale,
                provenance: dataset.provenance,
                completeness: dataset.completeness,
                candleCount: candleCount,
                headline: "Stale cached history",
                detail: "Cached provider-backed candles are older than the freshness policy.",
                actionTitle: "REFRESH HISTORY",
                sectionStatuses: [
                    status("Chart", "May show cached historical candles with a stale label."),
                    status("Technical context", "Blocked until fresh or cached-fresh daily history is available."),
                    status("Cosmic correlation", "Blocked until fresh or cached-fresh event windows are available.")
                ]
            )
        }

        if dataset.provenance.isCached {
            return StockDetailHistoryActivationState(
                symbol: symbol,
                displayMode: .cached,
                provenance: dataset.provenance,
                completeness: dataset.completeness,
                candleCount: candleCount,
                headline: "Cached provider history ready",
                detail: "\(candleCount) cached provider-backed daily candles are available.",
                actionTitle: "REFRESH HISTORY",
                sectionStatuses: readyStatuses(candleCount: candleCount)
            )
        }

        return StockDetailHistoryActivationState(
            symbol: symbol,
            displayMode: .providerBacked,
            provenance: dataset.provenance,
            completeness: dataset.completeness,
            candleCount: candleCount,
            headline: "Provider history ready",
            detail: "\(candleCount) provider-backed daily candles are available.",
            actionTitle: nil,
            sectionStatuses: readyStatuses(candleCount: candleCount)
        )
    }

    private static func readyStatuses(candleCount: Int) -> [StockDetailHistorySectionStatus] {
        [
            status("Chart", "\(candleCount) provider-backed candles available."),
            status("Technical context", "Provider-backed technical context can calculate when candle count requirements are met."),
            status("Cosmic correlation", "Historical event windows can calculate when sample-size gates are met.")
        ]
    }

    private static func blockedStatuses(reason: String) -> [StockDetailHistorySectionStatus] {
        [
            status("Chart", reason),
            status("Technical context", reason),
            status("Cosmic correlation", reason)
        ]
    }

    private static func status(_ title: String, _ detail: String) -> StockDetailHistorySectionStatus {
        StockDetailHistorySectionStatus(
            id: title.lowercased().replacingOccurrences(of: " ", with: "-"),
            title: title,
            detail: detail
        )
    }
}

struct StockDetailHistoryActivationResult: Equatable {
    let state: StockDetailHistoryActivationState
    let dataset: HistoricalPriceDataset?
}
