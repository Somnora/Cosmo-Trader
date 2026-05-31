import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct MarketWeatherServiceTests {
    private let service = MarketWeatherService()
    private let filterState = AstroOverlayFilterState(
        enabledKinds: [.fullMoon, .newMoon, .mercuryRetrograde],
        showEstimatedEvents: true,
        eventWindowDays: 1
    )

    @Test("Live market datasets produce source-labeled market weather metrics")
    func liveMarketDatasetsProduceMetrics() {
        let summary = service.summary(
            datasetsBySymbol: liveDatasets(),
            events: events(kind: .fullMoon, offsets: [1, 4, 7]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let fullMoon = summary.eventSummaries.first { $0.eventType == .fullMoon }
        #expect(summary.coverage == 1)
        #expect(summary.includedSymbols == ["DIA", "IWM", "QQQ", "SPY"])
        #expect(isMarketBacked(fullMoon))
        #expect(fullMoon?.averageMarketReturn != nil)
        #expect(fullMoon?.winRate != nil)
        #expect(fullMoon?.provenance.isProviderBacked == true)
        #expect(fullMoon?.disclaimer.contains("not financial advice") == true)
    }

    @Test("Cached stale market datasets do not produce numeric market claims")
    func staleMarketDatasetsWithholdMetrics() {
        let summary = service.summary(
            datasetsBySymbol: staleDatasets(),
            events: events(kind: .fullMoon, offsets: [1, 4, 7]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let fullMoon = summary.eventSummaries.first { $0.eventType == .fullMoon }
        #expect(summary.coverage == 0)
        #expect(summary.staleSymbols == ["DIA", "IWM", "QQQ", "SPY"])
        #expect(!isMarketBacked(fullMoon))
        expectNoMetrics(fullMoon)
    }

    @Test("Unavailable market datasets do not synthesize fake market weather")
    func unavailableMarketDatasetsWithholdMetrics() {
        let summary = service.summary(
            datasetsBySymbol: [:],
            unavailableProvenanceBySymbol: unavailableProvenance(),
            events: events(kind: .newMoon, offsets: [1, 4, 7]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let newMoon = summary.eventSummaries.first { $0.eventType == .newMoon }
        #expect(summary.coverage == 0)
        #expect(summary.excludedSymbols == ["DIA", "IWM", "QQQ", "SPY"])
        #expect(!isMarketBacked(newMoon))
        expectNoMetrics(newMoon)
    }

    @Test("Insufficient market event sample withholds headline metrics")
    func insufficientSampleWithholdsMetrics() {
        let summary = service.summary(
            datasetsBySymbol: liveDatasets(),
            events: events(kind: .mercuryRetrograde, offsets: [1]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let mercury = summary.eventSummaries.first { $0.eventType == .mercuryRetrograde }
        #expect(summary.coverage == 1)
        #expect(isInsufficientSample(mercury))
        #expect(mercury?.sampleSize == 1)
        expectNoMetrics(mercury)
    }

    @Test("Partial market basket coverage stays context-only")
    func partialCoverageStaysContextOnly() {
        var datasets = liveDatasets()
        datasets.removeValue(forKey: "IWM")

        let summary = service.summary(
            datasetsBySymbol: datasets,
            unavailableProvenanceBySymbol: ["IWM": .unavailable(reason: "Provider-backed market history unavailable")],
            events: events(kind: .fullMoon, offsets: [1, 4, 7]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let fullMoon = summary.eventSummaries.first { $0.eventType == .fullMoon }
        #expect(summary.coverage == 0.75)
        #expect(summary.excludedSymbols == ["IWM"])
        #expect(isPartialCoverage(fullMoon))
        expectNoMetrics(fullMoon)
    }

    @Test("Sample market datasets are labeled and never produce market weather metrics")
    func sampleMarketDatasetsWithholdMetrics() {
        let summary = service.summary(
            datasetsBySymbol: sampleDatasets(),
            events: events(kind: .fullMoon, offsets: [1, 4, 7]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let fullMoon = summary.eventSummaries.first { $0.eventType == .fullMoon }
        #expect(summary.coverage == 0)
        #expect(summary.provenance == .sample(reason: "Only explicit sample market data is available"))
        #expect(fullMoon?.displayMode == .sampleOnly)
        expectNoMetrics(fullMoon)
    }

    @Test("Partial historical market datasets do not produce numeric market claims")
    func partialHistoricalDatasetsWithholdMetrics() {
        let summary = service.summary(
            datasetsBySymbol: partialHistoricalDatasets(),
            events: events(kind: .fullMoon, offsets: [1, 4, 7]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let fullMoon = summary.eventSummaries.first { $0.eventType == .fullMoon }
        #expect(summary.coverage == 0)
        #expect(summary.partialSymbols == ["DIA", "IWM", "QQQ", "SPY"])
        #expect(!isMarketBacked(fullMoon))
        expectNoMetrics(fullMoon)
    }

    @Test("Insufficient historical market datasets do not produce numeric market claims")
    func insufficientHistoricalDatasetsWithholdMetrics() {
        let summary = service.summary(
            datasetsBySymbol: insufficientHistoricalDatasets(),
            events: events(kind: .fullMoon, offsets: [1, 4, 7]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let fullMoon = summary.eventSummaries.first { $0.eventType == .fullMoon }
        #expect(summary.coverage == 0)
        #expect(summary.insufficientSymbols == ["DIA", "IWM", "QQQ", "SPY"])
        #expect(!isMarketBacked(fullMoon))
        expectNoMetrics(fullMoon)
    }

    @Test("Market weather copy avoids trading-instruction language")
    func marketWeatherCopyIsComplianceSafe() {
        let summary = service.summary(
            datasetsBySymbol: liveDatasets(),
            events: events(kind: .fullMoon, offsets: [1, 4, 7]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let copy = ([summary.disclaimer] + summary.eventSummaries.flatMap { event in
            [event.disclaimer, event.eventName]
        }).joined(separator: "\n").lowercased()

        for banned in [
            "buy signal",
            "sell signal",
            "take profits",
            "reduce exposure",
            "reduce position",
            "position size",
            "smaller position",
            "delay major decisions",
            "high-risk positions",
            "expected upside",
            "expected downside"
        ] {
            #expect(!copy.contains(banned))
        }
    }

    @Test("Today integration adds Market Weather without bypassing gates")
    func todayIntegrationAddsMarketWeatherContext() {
        let composer = TodayMarketHoroscopeComposer()
        let marketWeather = service.summary(
            datasetsBySymbol: liveDatasets(),
            events: events(kind: .fullMoon, offsets: [1, 4, 7]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let summary = composer.compose(
            user: nil,
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: ["Full Moon"],
            portfolioSummaries: [],
            stockCandidate: nil,
            marketWeather: marketWeather
        )

        #expect(summary.marketContext.displayMode == .marketBacked)
        #expect(summary.marketContext.metrics.map(\.label).contains("AVG MKT"))
        #expect(summary.dataCoverage.rows.contains { $0.label == "Market weather" })
        #expect(summary.marketContext.provenance.isProviderBacked)
    }

    @Test("Today integration labels stale Market Weather as context-only")
    func todayIntegrationWithStaleMarketWeatherWithholdsMetrics() {
        let composer = TodayMarketHoroscopeComposer()
        let marketWeather = service.summary(
            datasetsBySymbol: staleDatasets(),
            events: events(kind: .fullMoon, offsets: [1, 4, 7]),
            filterState: filterState,
            minimumSampleSize: 3
        )

        let summary = composer.compose(
            user: nil,
            mood: mood(value: nil, provenance: .unavailable(reason: "Provider-backed market factors unavailable")),
            lunarData: lunarData(),
            mercuryStatus: "Mercury Direct",
            activeEventTitles: [],
            portfolioSummaries: [],
            stockCandidate: nil,
            marketWeather: marketWeather
        )

        #expect(summary.marketContext.displayMode == .stale)
        #expect(summary.marketContext.metrics.isEmpty)
        #expect(summary.marketContext.detail.contains("stale"))
    }

    private func liveDatasets() -> [String: HistoricalPriceDataset] {
        Dictionary(uniqueKeysWithValues: MarketWeatherService.v1Symbols.map { definition in
            (
                definition.symbol,
                dataset(
                    symbol: definition.symbol,
                    prices: prices([100, 102, 104, 103, 105, 107, 106, 108, 110]),
                    provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2026-05-30"))
                )
            )
        })
    }

    private func staleDatasets() -> [String: HistoricalPriceDataset] {
        Dictionary(uniqueKeysWithValues: MarketWeatherService.v1Symbols.map { definition in
            (
                definition.symbol,
                dataset(
                    symbol: definition.symbol,
                    prices: prices([100, 102, 104, 103, 105, 107, 106, 108, 110]),
                    provenance: .cached(
                        provider: FinancialDataProvenance.finnhubProvider,
                        fetchedAt: date("2026-05-28"),
                        age: FinancialDataProvenance.defaultCachedStaleInterval * 2
                    )
                )
            )
        })
    }

    private func sampleDatasets() -> [String: HistoricalPriceDataset] {
        Dictionary(uniqueKeysWithValues: MarketWeatherService.v1Symbols.map { definition in
            (
                definition.symbol,
                dataset(
                    symbol: definition.symbol,
                    prices: prices([100, 102, 104, 103, 105, 107, 106, 108, 110]),
                    provenance: .sample(reason: "Preview fixture")
                )
            )
        })
    }

    private func partialHistoricalDatasets() -> [String: HistoricalPriceDataset] {
        Dictionary(uniqueKeysWithValues: MarketWeatherService.v1Symbols.map { definition in
            (
                definition.symbol,
                dataset(
                    symbol: definition.symbol,
                    prices: prices([100, 102, 104, 103, 105, 107, 106, 108, 110]),
                    provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2026-05-30")),
                    requestedRange: DateInterval(start: date("2026-01-01"), end: date("2026-03-31"))
                )
            )
        })
    }

    private func insufficientHistoricalDatasets() -> [String: HistoricalPriceDataset] {
        Dictionary(uniqueKeysWithValues: MarketWeatherService.v1Symbols.map { definition in
            (
                definition.symbol,
                dataset(
                    symbol: definition.symbol,
                    prices: prices([100]),
                    provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2026-05-30"))
                )
            )
        })
    }

    private func unavailableProvenance() -> [String: FinancialDataProvenance] {
        Dictionary(uniqueKeysWithValues: MarketWeatherService.v1Symbols.map { definition in
            (
                definition.symbol,
                .unavailable(reason: "Provider-backed market history unavailable")
            )
        })
    }

    private func dataset(
        symbol: String,
        prices: [OHLCData],
        provenance: FinancialDataProvenance,
        requestedRange: DateInterval? = nil
    ) -> HistoricalPriceDataset {
        HistoricalPriceDataset.providerBacked(
            symbol: symbol,
            candles: prices,
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2026-05-30"),
            requestedRange: requestedRange ?? DateInterval(start: date("2026-01-01"), end: date("2026-01-09")),
            provenance: provenance
        )
    }

    private func prices(_ closes: [Double]) -> [OHLCData] {
        closes.enumerated().map { offset, close in
            let day = Calendar.current.date(byAdding: .day, value: offset, to: date("2026-01-01")) ?? date("2026-01-01")
            return OHLCData(
                date: day,
                open: close,
                high: close + 1,
                low: close - 1,
                close: close,
                volume: 1_000_000 + offset
            )
        }
    }

    private func events(kind: AstroOverlayEventKind, offsets: [Int]) -> [AstroOverlayEvent] {
        offsets.map { offset in
            let eventDate = Calendar.current.date(byAdding: .day, value: offset, to: date("2026-01-01")) ?? date("2026-01-01")
            return AstroOverlayEvent(
                id: "\(kind.rawValue)-\(offset)",
                kind: kind,
                title: kind.displayName,
                subtitle: nil,
                startDate: eventDate,
                endDate: kind == .mercuryRetrograde ? Calendar.current.date(byAdding: .day, value: 1, to: eventDate) : nil,
                markerDate: eventDate,
                intensity: .high,
                affectedElements: [],
                affectedSectors: [],
                iconSystemName: kind.iconSystemName,
                source: kind == .mercuryRetrograde ? .verifiedEphemeris : .calculatedMoonPhase,
                isEstimated: false
            )
        }
    }

    private func mood(value: Int?, provenance: FinancialDataProvenance) -> CosmicMoodData {
        CosmicMoodData(
            date: date("2026-05-30"),
            value: value,
            factors: [],
            label: value == nil ? "Market data unavailable" : nil,
            provenance: provenance,
            marketDataCoverage: value == nil ? 0 : 1,
            unavailableFactorWeight: value == nil ? 1 : 0,
            displayMode: value == nil ? .unavailable : .marketBackedScore
        )
    }

    private func lunarData() -> LunarData {
        LunarData(
            date: date("2026-05-30"),
            phase: .fullMoon,
            illumination: 0.98,
            age: 14.5,
            moonSign: .taurus,
            isWaxing: false
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

    private func isMarketBacked(_ summary: MarketWeatherEventSummary?) -> Bool {
        guard let summary else { return false }
        if case .marketBackedResult = summary.displayMode { return true }
        return false
    }

    private func isPartialCoverage(_ summary: MarketWeatherEventSummary?) -> Bool {
        guard let summary else { return false }
        if case .partialCoverage = summary.displayMode { return true }
        return false
    }

    private func isInsufficientSample(_ summary: MarketWeatherEventSummary?) -> Bool {
        guard let summary else { return false }
        if case .insufficientSample = summary.displayMode { return true }
        return false
    }

    private func expectNoMetrics(_ summary: MarketWeatherEventSummary?) {
        #expect(summary?.averageMarketReturn == nil)
        #expect(summary?.medianMarketReturn == nil)
        #expect(summary?.winRate == nil)
        #expect(summary?.baselineMarketReturn == nil)
        #expect(summary?.volatilityRatio == nil)
        #expect(summary?.maxDrawdown == nil)
    }
}
