import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct AstroOverlayEventServiceTests {

    @Test("Moon phase generation returns full and new moon events in a 90 day range")
    func moonPhaseGenerationReturnsFullAndNewMoonEvents() {
        let stock = makeStock()
        let filters = AstroOverlayFilterState(
            enabledKinds: [.newMoon, .fullMoon],
            showEstimatedEvents: true,
            eventWindowDays: 3
        )

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: date("2025-01-01"),
            to: date("2025-04-01"),
            filters: filters
        )

        #expect(events.contains { $0.kind == .newMoon })
        #expect(events.contains { $0.kind == .fullMoon })
    }

    @Test("Overlay event feed includes chart marker kinds with visible icon metadata")
    func overlayEventFeedIncludesChartMarkerKindsWithIconMetadata() {
        let stock = makeStock()
        let filters = AstroOverlayFilterState(
            enabledKinds: [.newMoon, .fullMoon, .mercuryRetrograde],
            showEstimatedEvents: true,
            eventWindowDays: 3
        )

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: date("2025-01-01"),
            to: date("2025-12-31"),
            filters: filters
        )

        #expect(events.contains { $0.kind == .newMoon })
        #expect(events.contains { $0.kind == .fullMoon })
        #expect(events.contains { $0.kind == .mercuryRetrograde })
        #expect(events.allSatisfy { !$0.iconSystemName.isEmpty })
    }

    @Test("Company birth month repeats once per year in the selected range")
    func companyBirthMonthRepeatsOncePerYear() {
        let stock = makeStock()
        let filters = AstroOverlayFilterState(
            enabledKinds: [.companyBirthMonth],
            showEstimatedEvents: true,
            eventWindowDays: 3
        )

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: date("2024-01-01"),
            to: date("2026-12-31"),
            filters: filters
        )

        #expect(events.count == 3)
        #expect(events.allSatisfy { $0.kind == .companyBirthMonth })
    }

    @Test("Company founding anniversary uses founding month and day")
    func companyFoundingAnniversaryUsesFoundingDate() {
        let stock = makeStock()
        let filters = AstroOverlayFilterState(
            enabledKinds: [.companyFoundingAnniversary],
            showEstimatedEvents: true,
            eventWindowDays: 3
        )

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: date("2026-01-01"),
            to: date("2026-12-31"),
            filters: filters
        )

        let event = events.first
        #expect(event?.kind == .companyFoundingAnniversary)
        #expect(Calendar.current.component(.month, from: event?.markerDate ?? Date()) == 4)
        #expect(Calendar.current.component(.day, from: event?.markerDate ?? Date()) == 1)
    }

    @Test("Mercury retrograde provider returns only overlapping windows")
    func mercuryRetrogradeProviderReturnsOverlaps() {
        let provider = MercuryRetrogradeEphemerisProvider.shared
        let windows = provider.windows(from: date("2025-07-01"), to: date("2025-07-31"))

        #expect(windows.count == 1)
        #expect(windows.first?.id == "2025-07")
    }

    @Test("showEstimatedEvents false filters estimated Mercury events")
    func showEstimatedEventsFalseFiltersEstimatedEvents() {
        let stock = makeStock()
        let filters = AstroOverlayFilterState(
            enabledKinds: [.mercuryRetrograde],
            showEstimatedEvents: false,
            eventWindowDays: 3
        )

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: date("2025-07-01"),
            to: date("2025-07-31"),
            filters: filters
        )

        #expect(events.isEmpty)
    }

    @Test("Unknown founding date suppresses company-specific overlay events")
    func unknownFoundingDateSuppressesCompanySpecificOverlayEvents() {
        let stock = makeUnknownDateStock()
        let filters = AstroOverlayFilterState(
            enabledKinds: [.companyBirthMonth, .companyFoundingAnniversary, .moonInSign],
            showEstimatedEvents: true,
            eventWindowDays: 3
        )

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: date("2025-01-01"),
            to: date("2025-12-31"),
            filters: filters
        )

        #expect(events.isEmpty)
    }

    @Test("ETF symbols suppress company-specific overlay events")
    func etfSymbolsSuppressCompanySpecificOverlayEvents() {
        let stock = Stock(
            symbol: "SPY",
            name: "SPDR S&P 500 ETF Trust",
            currentPrice: 500,
            priceChange: 1,
            percentageChange: 0.2,
            foundedDate: date("1993-01-22"),
            sector: "ETF"
        )
        let filters = AstroOverlayFilterState(
            enabledKinds: [.companyBirthMonth, .companyFoundingAnniversary, .moonInSign],
            showEstimatedEvents: true,
            eventWindowDays: 3
        )

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: date("2025-01-01"),
            to: date("2025-12-31"),
            filters: filters
        )

        #expect(events.isEmpty)
    }

    @Test("Quarter moon filter generates first and last quarter events")
    func quarterMoonFilterGeneratesFirstAndLastQuarterEvents() {
        let stock = makeStock()
        let filters = AstroOverlayFilterState(
            enabledKinds: [.firstQuarter, .lastQuarter],
            showEstimatedEvents: true,
            eventWindowDays: 3
        )

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: date("2025-01-01"),
            to: date("2025-04-01"),
            filters: filters
        )

        #expect(events.contains { $0.kind == .firstQuarter })
        #expect(events.contains { $0.kind == .lastQuarter })
        #expect(events.allSatisfy { $0.kind == .firstQuarter || $0.kind == .lastQuarter })
    }

    @Test("Mercury retrograde provider includes estimated 2030 windows")
    func mercuryRetrogradeProviderIncludesEstimated2030Windows() {
        let provider = MercuryRetrogradeEphemerisProvider.shared
        let windows = provider.windows(from: date("2030-12-01"), to: date("2030-12-31"))

        #expect(windows.count == 1)
        #expect(windows.first?.id == "2030-12")
        #expect(windows.first?.isEstimated == true)
    }

    @Test("Filter state includes only enabled event types")
    func filterStateIncludesOnlyEnabledEventTypes() {
        let stock = makeStock()
        let filters = AstroOverlayFilterState(
            enabledKinds: [.companyBirthMonth],
            showEstimatedEvents: true,
            eventWindowDays: 3
        )

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: date("2025-01-01"),
            to: date("2025-12-31"),
            filters: filters
        )

        #expect(!events.isEmpty)
        #expect(events.allSatisfy { $0.kind == .companyBirthMonth })
    }

    @Test("Event generation returns events sorted by marker date")
    func eventGenerationReturnsSortedEvents() {
        let stock = makeStock()
        let filters = AstroOverlayFilterState()

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: date("2025-01-01"),
            to: date("2025-12-31"),
            filters: filters
        )

        #expect(events == events.sorted { $0.markerDate < $1.markerDate })
    }

    private func makeStock() -> Stock {
        Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 180,
            priceChange: 1,
            percentageChange: 0.5,
            foundedMonth: 4,
            foundedDay: 1,
            foundedYear: 1976,
            sector: "Technology"
        )
    }

    private func makeUnknownDateStock() -> Stock {
        Stock(
            symbol: "ZZZZ",
            name: "Unknown Listing",
            currentPrice: 10,
            priceChange: 0,
            percentageChange: 0,
            foundedDate: nil,
            sector: "Unknown"
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
}

// MARK: - Chart View Model Helpers
// Covers the scrub helpers added to HistoricalAstroChartViewModel so the
// chart overlay can snap to the nearest candle and select the nearest event.

@MainActor
struct HistoricalAstroChartViewModelHelperTests {

    @Test("nearestCandle returns nil for empty data")
    func nearestCandleReturnsNilWhenEmpty() {
        let viewModel = HistoricalAstroChartViewModel()
        #expect(viewModel.nearestCandle(to: date("2025-01-15")) == nil)
    }

    @Test("nearestCandle picks the closest candle by date")
    func nearestCandlePicksClosestCandle() {
        let viewModel = HistoricalAstroChartViewModel()
        viewModel.ohlcData = candles(on: ["2025-01-10", "2025-01-15", "2025-01-20"])

        let nearest = viewModel.nearestCandle(to: date("2025-01-16"))
        #expect(nearest?.date == date("2025-01-15"))
    }

    @Test("nearestEvent returns nil when no events fall within tolerance")
    func nearestEventReturnsNilOutsideTolerance() {
        let viewModel = HistoricalAstroChartViewModel()
        viewModel.overlayEvents = [pointEvent(on: "2025-01-01")]

        let result = viewModel.nearestEvent(to: date("2025-02-01"), within: 60 * 60 * 24)
        #expect(result == nil)
    }

    @Test("nearestEvent returns the point event closest to the scrub date")
    func nearestEventReturnsClosestPointEvent() {
        let viewModel = HistoricalAstroChartViewModel()
        viewModel.overlayEvents = [
            pointEvent(on: "2025-01-05"),
            pointEvent(on: "2025-01-12"),
            pointEvent(on: "2025-01-20")
        ]

        let result = viewModel.nearestEvent(to: date("2025-01-13"), within: 60 * 60 * 24 * 30)
        #expect(result?.markerDate == date("2025-01-12"))
    }

    @Test("nearestEvent treats range events as distance zero when scrub date is inside")
    func nearestEventInsideRangeReturnsRange() {
        let viewModel = HistoricalAstroChartViewModel()
        viewModel.overlayEvents = [
            pointEvent(on: "2025-01-05"),
            rangeEvent(start: "2025-01-10", end: "2025-01-20"),
            pointEvent(on: "2025-01-25")
        ]

        let result = viewModel.nearestEvent(to: date("2025-01-15"), within: 60 * 60 * 24)
        #expect(result?.kind == .mercuryRetrograde)
    }

    @Test("nearestEvent prefers the closer point event over a far range event")
    func nearestEventPrefersCloserPointEvent() {
        let viewModel = HistoricalAstroChartViewModel()
        viewModel.overlayEvents = [
            rangeEvent(start: "2025-01-01", end: "2025-01-03"),
            pointEvent(on: "2025-01-14")
        ]

        let result = viewModel.nearestEvent(to: date("2025-01-15"), within: 60 * 60 * 24 * 5)
        #expect(result?.markerDate == date("2025-01-14"))
    }

    @Test("overlayColor mapping returns a distinct color per primary kind")
    func overlayColorMappingIsDistinctPerKind() {
        // Sanity: the chart, chips, and summary cards rely on different colors
        // per kind to read at a glance. Asserting key pairs differ is enough.
        #expect(AstroOverlayEventKind.newMoon.overlayColor != AstroOverlayEventKind.mercuryRetrograde.overlayColor)
        #expect(AstroOverlayEventKind.mercuryRetrograde.overlayColor != AstroOverlayEventKind.companyFoundingAnniversary.overlayColor)
        #expect(AstroOverlayEventKind.fullMoon.overlayColor != AstroOverlayEventKind.newMoon.overlayColor)
    }

    @Test("Stock detail history refresh requests provider-backed history")
    func stockDetailHistoryRefreshRequestsProviderBackedHistory() async throws {
        let cacheURL = temporaryCacheURL()
        let now = date("2025-01-10")
        let cache = HistoricalPriceCache(directoryURL: cacheURL, nowProvider: { now })
        defer { try? cache.removeAll() }
        try cache.store(
            dataset: providerDataset(symbol: "AAPL", fetchedAt: now, closes: Array(repeating: 100.0, count: 20)),
            timeframe: .month,
            resolution: "D"
        )

        var fetchCount = 0
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            cacheDuration: 3600,
            nowProvider: { now },
            candleFetcher: { _, _, _, _ in
                fetchCount += 1
                return candleResponse(closes: Array(200..<220).map(Double.init))
            }
        )
        let viewModel = HistoricalAstroChartViewModel(
            datasetStore: CorrelationDatasetStore(historicalPriceService: service)
        )

        await viewModel.load(stock: stockForHistoryActivation(), timeframe: .month)
        #expect(fetchCount == 0)
        #expect(viewModel.historicalPriceProvenance.isCached)

        let refreshed = await viewModel.refreshProviderHistory()

        #expect(refreshed)
        #expect(fetchCount == 1)
        #expect(viewModel.ohlcData.map(\.close) == Array(200..<220).map(Double.init))
        #expect(viewModel.historicalPriceProvenance == .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: now))
        #expect(viewModel.canShowHistoricalChart)
        #expect(viewModel.historySurfaceStatuses.allSatisfy { $0.isAvailable })
    }

    @Test("Stock detail history refresh does not create sample candles")
    func stockDetailHistoryRefreshDoesNotCreateSampleCandles() async {
        let cacheURL = temporaryCacheURL()
        let cache = HistoricalPriceCache(directoryURL: cacheURL)
        defer { try? cache.removeAll() }
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            candleFetcher: { _, _, _, _ in
                throw HistoricalPriceError.noHistoricalData
            }
        )
        let viewModel = HistoricalAstroChartViewModel(
            datasetStore: CorrelationDatasetStore(historicalPriceService: service)
        )

        await viewModel.load(stock: stockForHistoryActivation(), timeframe: .month)
        let refreshed = await viewModel.refreshProviderHistory()

        #expect(!refreshed)
        #expect(viewModel.ohlcData.isEmpty)
        #expect(viewModel.summaries.isEmpty)
        #expect(viewModel.historicalPriceProvenance == .unavailable(reason: "Historical price data unavailable"))
        #expect(!viewModel.canShowHistoricalChart)
        #expect(!viewModel.canShowCorrelationMetrics)
        if case .unavailable(let message) = viewModel.historyLoadState {
            #expect(message == "Provider-backed history unavailable. Try again later.")
        } else {
            Issue.record("Provider failure should keep an unavailable history load state")
        }
    }

    @Test("Insufficient history keeps stock detail surfaces unavailable")
    func insufficientHistoryKeepsStockDetailSurfacesUnavailable() async {
        let now = date("2025-01-10")
        let cacheURL = temporaryCacheURL()
        let cache = HistoricalPriceCache(directoryURL: cacheURL)
        defer { try? cache.removeAll() }
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { now },
            candleFetcher: { _, _, _, _ in
                candleResponse(closes: [100])
            }
        )
        let viewModel = HistoricalAstroChartViewModel(
            datasetStore: CorrelationDatasetStore(historicalPriceService: service)
        )

        await viewModel.load(stock: stockForHistoryActivation(), timeframe: .month)

        #expect(viewModel.ohlcData.count == 1)
        #expect(!viewModel.canShowHistoricalChart)
        #expect(!viewModel.canShowCorrelationMetrics)
        #expect(viewModel.needsProviderHistoryActivation)
        #expect(viewModel.historySurfaceStatuses.allSatisfy { !$0.isAvailable })
        #expect(viewModel.historicalPriceProvenance.indicatorLabel == "Unavailable")
        if case .insufficient = viewModel.historicalDatasetCompleteness {
            #expect(viewModel.historyActivationMessage.contains("Insufficient provider history"))
        } else {
            Issue.record("One-candle history should be marked insufficient")
        }
    }

    @Test("Partial history keeps numeric stock detail correlation gated")
    func partialHistoryKeepsNumericStockDetailCorrelationGated() async {
        let now = date("2025-01-10")
        let cacheURL = temporaryCacheURL()
        let cache = HistoricalPriceCache(directoryURL: cacheURL)
        defer { try? cache.removeAll() }
        let service = HistoricalPriceService.testingInstance(
            historicalPriceCache: cache,
            nowProvider: { now },
            candleFetcher: { _, _, _, _ in
                candleResponse(closes: Array(100..<106).map(Double.init))
            }
        )
        let viewModel = HistoricalAstroChartViewModel(
            datasetStore: CorrelationDatasetStore(historicalPriceService: service)
        )

        await viewModel.load(stock: stockForHistoryActivation(), timeframe: .month)

        #expect(viewModel.ohlcData.count == 6)
        #expect(!viewModel.canShowHistoricalChart)
        #expect(!viewModel.canShowCorrelationMetrics)
        #expect(viewModel.needsProviderHistoryActivation)
        #expect(viewModel.historyActivationTitle == "Refresh provider history")
        #expect(viewModel.historyActivationMessage.contains("Partial provider history"))
        #expect(viewModel.historySurfaceStatuses.contains { $0.label == "Chart" && !$0.isAvailable })
        #expect(viewModel.historySurfaceStatuses.contains { $0.label == "Cosmic correlation" && !$0.isAvailable })
        if case .partial = viewModel.historicalDatasetCompleteness {
            #expect(viewModel.historicalPriceProvenance.indicatorLabel == "Partial history")
        } else {
            Issue.record("Limited returned range should be marked partial")
        }
    }

    @Test("Stale cached history is labeled stale")
    func staleCachedHistoryIsLabeledStale() async throws {
        let cacheURL = temporaryCacheURL()
        let fetchedAt = date("2025-01-01")
        let now = date("2025-01-10")
        let cache = HistoricalPriceCache(directoryURL: cacheURL, nowProvider: { now })
        defer { try? cache.removeAll() }
        try cache.store(
            dataset: providerDataset(symbol: "AAPL", fetchedAt: fetchedAt, closes: Array(repeating: 100.0, count: 20)),
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
        let viewModel = HistoricalAstroChartViewModel(
            datasetStore: CorrelationDatasetStore(historicalPriceService: service)
        )

        await viewModel.load(stock: stockForHistoryActivation(), timeframe: .month)

        #expect(viewModel.historicalPriceProvenance.indicatorLabel == "Finnhub stale")
        #expect(viewModel.historicalPriceProvenance.isCachedStale())
        #expect(viewModel.needsProviderHistoryActivation)
        #expect(viewModel.historyActivationTitle == "Refresh history")
    }

    // MARK: - Helpers

    private func candles(on values: [String]) -> [OHLCData] {
        values.map { value in
            let day = date(value)
            return OHLCData(
                date: day,
                open: 100,
                high: 101,
                low: 99,
                close: 100,
                volume: 1_000
            )
        }
    }

    private func pointEvent(on value: String) -> AstroOverlayEvent {
        let day = date(value)
        return AstroOverlayEvent(
            id: "point-\(value)",
            kind: .fullMoon,
            title: "Full Moon",
            subtitle: nil,
            startDate: day,
            endDate: nil,
            markerDate: day,
            intensity: .high,
            affectedElements: [],
            affectedSectors: [],
            iconSystemName: "moon.circle.fill",
            source: .calculatedMoonPhase,
            isEstimated: false
        )
    }

    private func rangeEvent(start: String, end: String) -> AstroOverlayEvent {
        AstroOverlayEvent(
            id: "range-\(start)",
            kind: .mercuryRetrograde,
            title: "Mercury Retrograde",
            subtitle: nil,
            startDate: date(start),
            endDate: date(end),
            markerDate: date(start),
            intensity: .high,
            affectedElements: [],
            affectedSectors: [],
            iconSystemName: "arrow.uturn.backward.circle.fill",
            source: .curatedDataset,
            isEstimated: true
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

    private func stockForHistoryActivation() -> Stock {
        Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 100,
            priceChange: 0,
            percentageChange: 0,
            foundedDate: date("1976-04-01"),
            sector: "Technology"
        )
    }

    private func providerDataset(symbol: String, fetchedAt: Date, closes: [Double]) -> HistoricalPriceDataset {
        HistoricalPriceDataset.providerBacked(
            symbol: symbol,
            candles: prices(closes: closes),
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: fetchedAt,
            requestedRange: DateInterval(start: date("2024-12-11"), end: date("2025-01-10")),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        )
    }

    private func prices(closes: [Double]) -> [OHLCData] {
        closes.enumerated().map { index, close in
            let day = Calendar.current.date(byAdding: .day, value: index, to: date("2024-12-15")) ?? date("2024-12-15")
            return OHLCData(
                date: day,
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
            Int((Calendar.current.date(byAdding: .day, value: index, to: date("2024-12-15")) ?? date("2024-12-15")).timeIntervalSince1970)
        }
        return FinnhubCandleResponse(
            s: "ok",
            t: timestamps,
            o: closes,
            h: closes.map { $0 + 1 },
            l: closes.map { max(0.01, $0 - 1) },
            c: closes,
            v: Array(repeating: 1_000, count: closes.count)
        )
    }

    private func temporaryCacheURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("HistoricalAstroChartViewModelTests-\(UUID().uuidString)", isDirectory: true)
    }
}
