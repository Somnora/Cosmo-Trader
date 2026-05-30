import Foundation
import Testing
@testable import Cosmo_Trader

struct HistoricalPriceCacheTests {

    @Test("Historical price cache persists provider-backed datasets as cached provenance")
    func historicalPriceCachePersistsProviderBackedDatasets() throws {
        let cacheURL = temporaryCacheURL()
        let fetchedAt = date("2025-01-10")
        let now = date("2025-01-11")
        let cache = HistoricalPriceCache(directoryURL: cacheURL, nowProvider: { now })
        defer { try? cache.removeAll() }

        let dataset = providerDataset(symbol: "AAPL", fetchedAt: fetchedAt)
        try cache.store(dataset: dataset, timeframe: .month, resolution: "D")

        let cached = try #require(cache.dataset(symbol: "AAPL", timeframe: .month, resolution: "D"))

        #expect(cached.symbol == "AAPL")
        #expect(cached.provider == FinancialDataProvenance.finnhubProvider)
        #expect(cached.fetchedAt == fetchedAt)
        #expect(cached.ohlcData.map(\.close) == [100, 105, 110])
        #expect(cached.completeness.isUsableForCorrelation)
        if case .cached(let provider, let cachedFetchedAt, let age) = cached.provenance {
            #expect(provider == FinancialDataProvenance.finnhubProvider)
            #expect(cachedFetchedAt == fetchedAt)
            #expect(age == now.timeIntervalSince(fetchedAt))
        } else {
            Issue.record("Cached disk dataset should return cached provenance")
        }
    }

    @Test("Historical price cache refuses sample datasets")
    func historicalPriceCacheRefusesSampleDatasets() throws {
        let cacheURL = temporaryCacheURL()
        let cache = HistoricalPriceCache(directoryURL: cacheURL)
        defer { try? cache.removeAll() }

        let sample = HistoricalPriceDataset(
            symbol: "AAPL",
            candles: prices([100, 105, 110]).map(HistoricalPricePoint.init(candle:)),
            provider: "Preview",
            fetchedAt: date("2025-01-10"),
            requestedRange: DateInterval(start: date("2025-01-01"), end: date("2025-01-10")),
            actualRange: DateInterval(start: date("2025-01-01"), end: date("2025-01-03")),
            provenance: .sample(reason: "Preview fixture"),
            completeness: .complete
        )

        try cache.store(dataset: sample, timeframe: .month, resolution: "D")

        #expect(cache.dataset(symbol: "AAPL", timeframe: .month, resolution: "D") == nil)
    }

    @MainActor
    @Test("Historical price service writes live provider data to durable cache")
    func historicalPriceServiceWritesProviderDataToDurableCache() async throws {
        let cacheURL = temporaryCacheURL()
        let now = date("2025-01-10")
        let cache = HistoricalPriceCache(directoryURL: cacheURL, nowProvider: { now })
        defer { try? cache.removeAll() }

        var fetchCount = 0
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { now },
            candleFetcher: { _, _, _, _ in
                fetchCount += 1
                return candleResponse(closes: [100, 105, 110])
            }
        )

        let result = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .month)

        #expect(fetchCount == 1)
        #expect(result.source == .provider)
        #expect(result.provenance == .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: now))
        #expect(result.dataset.isUsableForCorrelation)

        let cached = try #require(cache.dataset(symbol: "AAPL", timeframe: .month, resolution: "D", now: now))
        #expect(cached.ohlcData.map(\.close) == [100, 105, 110])
    }

    @MainActor
    @Test("Historical price service uses fresh durable cache without refetching")
    func historicalPriceServiceUsesFreshDurableCacheWithoutRefetching() async throws {
        let cacheURL = temporaryCacheURL()
        let now = date("2025-01-10")
        let cache = HistoricalPriceCache(directoryURL: cacheURL, nowProvider: { now })
        defer { try? cache.removeAll() }
        try cache.store(
            dataset: providerDataset(symbol: "AAPL", fetchedAt: now),
            timeframe: .month,
            resolution: "D"
        )

        var didFetch = false
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { now },
            candleFetcher: { _, _, _, _ in
                didFetch = true
                throw HistoricalPriceError.noHistoricalData
            }
        )

        let result = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .month)

        #expect(!didFetch)
        #expect(result.source == .cache)
        #expect(result.provenance.isCached)
        #expect(result.data.map(\.close) == [100, 105, 110])
    }

    @MainActor
    @Test("Historical price service falls back to stale durable cache on provider failure")
    func historicalPriceServiceFallsBackToStaleDurableCacheOnProviderFailure() async throws {
        let cacheURL = temporaryCacheURL()
        let fetchedAt = date("2025-01-01")
        let now = date("2025-01-10")
        let cache = HistoricalPriceCache(directoryURL: cacheURL, nowProvider: { now })
        defer { try? cache.removeAll() }
        try cache.store(
            dataset: providerDataset(symbol: "AAPL", fetchedAt: fetchedAt),
            timeframe: .month,
            resolution: "D"
        )

        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            cacheDuration: 1,
            nowProvider: { now },
            candleFetcher: { _, _, _, _ in
                throw HistoricalPriceError.noHistoricalData
            }
        )

        let result = try await service.fetchHistoricalPriceResult(symbol: "AAPL", timeframe: .month)

        #expect(result.source == .cache)
        #expect(result.data.map(\.close) == [100, 105, 110])
        if case .cached(_, let cachedFetchedAt, let age) = result.provenance {
            #expect(cachedFetchedAt == fetchedAt)
            #expect(age == now.timeIntervalSince(fetchedAt))
        } else {
            Issue.record("Stale fallback should keep cached provider provenance")
        }
    }

    @MainActor
    @Test("Correlation dataset store reports unavailable symbols without sample data")
    func correlationDatasetStoreReportsUnavailableSymbolsWithoutSampleData() async {
        let cacheURL = temporaryCacheURL()
        let cache = HistoricalPriceCache(directoryURL: cacheURL)
        defer { try? cache.removeAll() }
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            candleFetcher: { _, _, _, _ in
                throw HistoricalPriceError.noHistoricalData
            }
        )
        let store = CorrelationDatasetStore(historicalPriceService: service)

        let snapshot = await store.datasets(symbols: ["AAPL"], timeframe: .month)

        #expect(snapshot.datasetsBySymbol.isEmpty)
        #expect(snapshot.priceHistoryBySymbol.isEmpty)
        #expect(snapshot.provenanceBySymbol["AAPL"] == .unavailable(reason: "Provider-backed historical prices unavailable"))
    }

    private func providerDataset(symbol: String, fetchedAt: Date) -> HistoricalPriceDataset {
        HistoricalPriceDataset.providerBacked(
            symbol: symbol,
            candles: prices([100, 105, 110]),
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: fetchedAt,
            requestedRange: DateInterval(start: date("2025-01-01"), end: date("2025-01-10")),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        )
    }

    private func prices(_ closes: [Double]) -> [OHLCData] {
        closes.enumerated().map { index, close in
            OHLCData(
                date: Calendar.current.date(byAdding: .day, value: index, to: date("2025-01-01")) ?? date("2025-01-01"),
                open: close,
                high: close + 1,
                low: max(0.01, close - 1),
                close: close,
                volume: 1_000
            )
        }
    }

    private func candleResponse(closes: [Double]) -> FinnhubCandleResponse {
        let timestamps = closes.indices.map { index in
            Int((Calendar.current.date(byAdding: .day, value: index, to: date("2025-01-01")) ?? date("2025-01-01")).timeIntervalSince1970)
        }
        return FinnhubCandleResponse(
            s: "ok",
            t: timestamps,
            o: closes,
            h: closes.map { $0 + 1 },
            l: closes.map { max(0.01, $0 - 1) },
            c: closes,
            v: closes.map { _ in 1_000 }
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }

    private func temporaryCacheURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("cosmo-historical-price-cache-tests-\(UUID().uuidString)", isDirectory: true)
    }
}
