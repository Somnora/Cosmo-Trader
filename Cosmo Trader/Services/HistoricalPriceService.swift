import Foundation

enum HistoricalPriceError: LocalizedError, Equatable {
    case noHistoricalData
    case invalidDateRange

    var errorDescription: String? {
        switch self {
        case .noHistoricalData:
            return "Historical data unavailable. Try again later."
        case .invalidDateRange:
            return "Historical date range unavailable."
        }
    }
}

enum HistoricalPriceSource: Equatable {
    case provider
    case cache

    var displayName: String {
        switch self {
        case .provider:
            return "Provider data"
        case .cache:
            return "Cached provider data"
        }
    }
}

struct HistoricalPriceResult: Equatable {
    let dataset: HistoricalPriceDataset
    let source: HistoricalPriceSource

    var data: [OHLCData] { dataset.ohlcData }
    var fetchedAt: Date { dataset.fetchedAt }
    var provenance: FinancialDataProvenance { dataset.provenance }
    var requestedRange: DateInterval { dataset.requestedRange }
    var actualRange: DateInterval? { dataset.actualRange }
    var completeness: HistoricalDatasetCompleteness { dataset.completeness }
}

@MainActor
@Observable
final class HistoricalPriceService {
    static let shared = HistoricalPriceService()

    typealias CandleFetcher = (String, String, Date, Date) async throws -> FinnhubCandleResponse

    private var memoryCache: [String: HistoricalPriceDataset] = [:]
    private let defaultCacheDuration: TimeInterval
    private let deepHistoryCacheDuration: TimeInterval
    private let historicalPriceCache: HistoricalPriceCache
    private let nowProvider: () -> Date
    private let candleFetcher: CandleFetcher

    /// Provider label stamped on every dataset this service produces.
    /// Must always describe where `candleFetcher` actually gets its data,
    /// so the two are only ever set together.
    let providerName: String

    private init(
        historicalPriceCache: HistoricalPriceCache = .shared,
        cacheDuration: TimeInterval = 3600,
        deepHistoryCacheDuration: TimeInterval = FinancialDataProvenance.defaultCachedStaleInterval,
        nowProvider: @escaping () -> Date = Date.init,
        providerName: String = FinancialDataProvenance.yahooProvider,
        candleFetcher: @escaping CandleFetcher = { symbol, resolution, from, to in
            // Yahoo Finance serves historical candles (free, no API key);
            // Finnhub's free tier blocks /stock/candle.
            try await YahooFinanceService.shared.fetchCandles(
                symbol: symbol,
                resolution: resolution,
                from: from,
                to: to
            )
        }
    ) {
        self.historicalPriceCache = historicalPriceCache
        self.defaultCacheDuration = cacheDuration
        self.deepHistoryCacheDuration = deepHistoryCacheDuration
        self.nowProvider = nowProvider
        self.providerName = providerName
        self.candleFetcher = candleFetcher
    }

    static func testingInstance(
        historicalPriceCache: HistoricalPriceCache,
        cacheDuration: TimeInterval = 3600,
        deepHistoryCacheDuration: TimeInterval = FinancialDataProvenance.defaultCachedStaleInterval,
        nowProvider: @escaping () -> Date = Date.init,
        providerName: String = FinancialDataProvenance.yahooProvider,
        candleFetcher: @escaping CandleFetcher
    ) -> HistoricalPriceService {
        HistoricalPriceService(
            historicalPriceCache: historicalPriceCache,
            cacheDuration: cacheDuration,
            deepHistoryCacheDuration: deepHistoryCacheDuration,
            nowProvider: nowProvider,
            providerName: providerName,
            candleFetcher: candleFetcher
        )
    }

    func fetchHistoricalPrices(
        symbol: String,
        timeframe: ChartTimeframe
    ) async throws -> [OHLCData] {
        try await fetchHistoricalPriceResult(symbol: symbol, timeframe: timeframe).data
    }

    func fetchHistoricalPriceResult(
        symbol: String,
        timeframe: ChartTimeframe
    ) async throws -> HistoricalPriceResult {
        let request = requestParameters(for: timeframe)
        let normalizedSymbol = symbol.uppercased()
        let requestedRange = DateInterval(start: min(request.from, request.to), end: max(request.from, request.to))
        let key = cacheKey(symbol: normalizedSymbol, timeframe: timeframe, resolution: request.resolution)
        let now = nowProvider()
        let maximumCacheAge = cacheDuration(for: timeframe)

        if let memoryDataset = memoryCache[key],
           now.timeIntervalSince(memoryDataset.fetchedAt) < maximumCacheAge {
            return HistoricalPriceResult(
                dataset: memoryDataset.withProvenance(
                    .cached(provider: memoryDataset.provider, fetchedAt: memoryDataset.fetchedAt, now: now)
                ),
                source: .cache
            )
        }

        let durableDataset = historicalPriceCache.dataset(
            symbol: normalizedSymbol,
            timeframe: timeframe,
            resolution: request.resolution,
            now: now
        )
        if let durableDataset,
           now.timeIntervalSince(durableDataset.fetchedAt) < maximumCacheAge {
            memoryCache[key] = durableDataset
            return HistoricalPriceResult(dataset: durableDataset, source: .cache)
        }

        do {
            let response = try await candleFetcher(
                normalizedSymbol,
                request.resolution,
                request.from,
                request.to
            )

            let data = response.toOHLCData()
                .filter { candle in
                    candle.open.isFinite
                        && candle.high.isFinite
                        && candle.low.isFinite
                        && candle.close.isFinite
                        && candle.close > 0
                }
                .sorted { $0.date < $1.date }

            guard !data.isEmpty else {
                if let durableDataset {
                    memoryCache[key] = durableDataset
                    return HistoricalPriceResult(dataset: durableDataset, source: .cache)
                }
                throw HistoricalPriceError.noHistoricalData
            }

            let fetchedAt = nowProvider()
            let dataset = HistoricalPriceDataset.providerBacked(
                symbol: normalizedSymbol,
                candles: data,
                provider: providerName,
                fetchedAt: fetchedAt,
                requestedRange: requestedRange,
                provenance: .live(provider: providerName, fetchedAt: fetchedAt),
                expectation: HistoricalDatasetExpectation(
                    resolution: HistoricalCandleResolution(token: request.resolution),
                    metadata: response.metadata ?? .unknown
                )
            )

            memoryCache[key] = dataset
            // A payload the provider downgraded is not worth persisting: keeping
            // it on disk would hold the wrong candle shape for the whole cache
            // window instead of letting the next call try again.
            if dataset.completeness.isUsableForCorrelation {
                try? historicalPriceCache.store(
                    dataset: dataset,
                    timeframe: timeframe,
                    resolution: request.resolution
                )
            }

            return HistoricalPriceResult(dataset: dataset, source: .provider)
        } catch {
            if let durableDataset {
                memoryCache[key] = durableDataset
                return HistoricalPriceResult(dataset: durableDataset, source: .cache)
            }
            if let memoryDataset = memoryCache[key] {
                let cachedDataset = memoryDataset.withProvenance(
                    .cached(provider: memoryDataset.provider, fetchedAt: memoryDataset.fetchedAt, now: now)
                )
                return HistoricalPriceResult(dataset: cachedDataset, source: .cache)
            }
            throw error
        }
    }

    func fetchHistoricalDataset(
        symbol: String,
        timeframe: ChartTimeframe
    ) async throws -> HistoricalPriceDataset {
        try await fetchHistoricalPriceResult(symbol: symbol, timeframe: timeframe).dataset
    }

    func requestParameters(for timeframe: ChartTimeframe) -> (resolution: String, from: Date, to: Date) {
        let calendar = Calendar.current
        let to = nowProvider()

        switch timeframe {
        case .day:
            return ("5", calendar.date(byAdding: .day, value: -1, to: to) ?? to, to)
        case .week:
            return ("60", calendar.date(byAdding: .day, value: -7, to: to) ?? to, to)
        case .month:
            return ("D", calendar.date(byAdding: .day, value: -30, to: to) ?? to, to)
        case .threeMonth:
            return ("D", calendar.date(byAdding: .day, value: -90, to: to) ?? to, to)
        case .sixMonth:
            return ("D", calendar.date(byAdding: .day, value: -180, to: to) ?? to, to)
        case .year:
            return ("D", calendar.date(byAdding: .day, value: -365, to: to) ?? to, to)
        case .twoYear:
            return ("D", calendar.date(byAdding: .year, value: -2, to: to) ?? to, to)
        case .all:
            return ("W", calendar.date(byAdding: .year, value: -5, to: to) ?? to, to)
        case .twentyYear:
            return ("D", calendar.date(byAdding: .year, value: -20, to: to) ?? to, to)
        }
    }

    /// Deep history is a large, near immutable payload: twenty years of daily
    /// candles runs to roughly half a megabyte and gains one bar a day, so
    /// refetching it on the hourly cadence the shallow timeframes use would
    /// move all of it for nothing. It holds for a day instead, the same window
    /// `FinancialDataProvenance` already treats as the point cached market data
    /// goes stale.
    private func cacheDuration(for timeframe: ChartTimeframe) -> TimeInterval {
        switch timeframe {
        case .twentyYear:
            return deepHistoryCacheDuration
        case .day, .week, .month, .threeMonth, .sixMonth, .year, .twoYear, .all:
            return defaultCacheDuration
        }
    }

    private func cacheKey(symbol: String, timeframe: ChartTimeframe, resolution: String) -> String {
        "\(symbol.uppercased())-\(timeframe.rawValue)-\(resolution)"
    }
}
