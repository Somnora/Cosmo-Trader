import Foundation
import Testing
@testable import Cosmo_Trader

struct AstroCorrelationServiceTests {

    @Test("Correlation service calculates return percent correctly")
    func correlationServiceCalculatesReturnPercent() {
        let event = pointEvent(on: "2025-01-02")
        let reactions = AstroCorrelationService.shared.eventReactions(
            prices: prices([100, 110, 120, 130, 140]),
            events: [event],
            filterState: AstroOverlayFilterState(eventWindowDays: 3)
        )

        #expect(reactions.count == 1)
        #expect(abs((reactions.first?.returnPercent ?? 0) - 40) < 0.001)
    }

    @Test("Range event uses start and end dates")
    func rangeEventUsesStartAndEndDates() {
        let event = rangeEvent(start: "2025-01-02", end: "2025-01-04")
        let reactions = AstroCorrelationService.shared.eventReactions(
            prices: prices([100, 110, 120, 140, 150]),
            events: [event],
            filterState: AstroOverlayFilterState()
        )

        #expect(reactions.count == 1)
        #expect(abs((reactions.first?.returnPercent ?? 0) - 27.2727) < 0.01)
    }

    @Test("Point event uses configured window days")
    func pointEventUsesConfiguredWindowDays() {
        let event = pointEvent(on: "2025-01-03")
        let reactions = AstroCorrelationService.shared.eventReactions(
            prices: prices([100, 110, 120, 130, 140, 150]),
            events: [event],
            filterState: AstroOverlayFilterState(eventWindowDays: 1)
        )

        #expect(reactions.count == 1)
        #expect(abs((reactions.first?.returnPercent ?? 0) - 18.1818) < 0.01)
    }

    @Test("Volatility calculation is non-negative")
    func volatilityCalculationIsNonNegative() {
        let event = pointEvent(on: "2025-01-02")
        let reactions = AstroCorrelationService.shared.eventReactions(
            prices: prices([100, 98, 105, 101, 110]),
            events: [event],
            filterState: AstroOverlayFilterState(eventWindowDays: 3)
        )

        #expect((reactions.first?.volatilityPercent ?? -1) >= 0)
    }

    @Test("Volume ratio returns nil when volume is missing")
    func volumeRatioReturnsNilWhenVolumeMissing() {
        let event = pointEvent(on: "2025-01-02")
        let reactions = AstroCorrelationService.shared.eventReactions(
            prices: prices([100, 110, 120, 130, 140], volume: 0),
            events: [event],
            filterState: AstroOverlayFilterState(eventWindowDays: 3)
        )

        #expect(reactions.first?.volumeRatio == nil)
    }

    @Test("Summary occurrence count matches valid event reactions")
    func summaryOccurrenceCountMatchesValidReactions() {
        let summaries = AstroCorrelationService.shared.summaries(
            prices: prices([100, 110, 120, 130, 140, 150, 160]),
            events: [pointEvent(on: "2025-01-02"), pointEvent(on: "2025-01-04")],
            filterState: AstroOverlayFilterState(eventWindowDays: 1)
        )

        #expect(summaries.first?.occurrenceCount == 2)
    }

    @Test("No division by zero with empty price data")
    func noDivisionByZeroWithEmptyPriceData() {
        let reactions = AstroCorrelationService.shared.eventReactions(
            prices: [],
            events: [pointEvent(on: "2025-01-02")],
            filterState: AstroOverlayFilterState()
        )

        let summaries = AstroCorrelationService.shared.summaries(
            prices: [],
            events: [pointEvent(on: "2025-01-02")],
            filterState: AstroOverlayFilterState()
        )

        #expect(reactions.isEmpty)
        #expect(summaries.isEmpty)
    }

    @Test("Stock summaries produce metrics only for provider-backed sufficient samples")
    func stockSummariesProduceMetricsOnlyForProviderBackedSufficientSamples() {
        let summaries = AstroCorrelationService.shared.stockSummaries(
            symbol: "AAPL",
            prices: prices([100, 104, 102, 108, 106, 112, 110, 116, 114, 120]),
            events: [
                pointEvent(on: "2025-01-02"),
                pointEvent(on: "2025-01-04"),
                pointEvent(on: "2025-01-06")
            ],
            filterState: AstroOverlayFilterState(eventWindowDays: 1),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10")),
            minimumSampleSize: 3
        )

        let summary = summaries.first
        #expect(isMarketBacked(summary))
        #expect(summary?.confidence.rawValue == CorrelationConfidence.thin.rawValue)
        #expect(summary?.sampleSize == 3)
        #expect(summary?.averageReturn != nil)
        #expect(summary?.medianReturn != nil)
        #expect(summary?.winRate != nil)
        #expect(summary?.baselineReturn != nil)
        #expect(summary?.provenance.isProviderBacked == true)
    }

    @Test("Stock summaries with thin event coverage withhold numeric claims")
    func stockSummariesWithThinEventCoverageWithholdNumericClaims() {
        let summaries = AstroCorrelationService.shared.stockSummaries(
            symbol: "AAPL",
            prices: prices([100, 104, 102, 108, 106, 112]),
            events: [pointEvent(on: "2025-01-02")],
            filterState: AstroOverlayFilterState(eventWindowDays: 1),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10"))
        )

        let summary = summaries.first
        #expect(isInsufficientSample(summary))
        #expect(summary?.confidence.rawValue == CorrelationConfidence.insufficient.rawValue)
        #expect(summary?.sampleSize == 1)
        #expect(summary?.averageReturn == nil)
        #expect(summary?.medianReturn == nil)
        #expect(summary?.winRate == nil)
        #expect(summary?.baselineReturn == nil)
        #expect(summary?.disclaimer.contains("Awaiting more historical data") == true)
    }

    @Test("Stock summaries with unavailable provenance do not expose numeric claims")
    func stockSummariesWithUnavailableProvenanceDoNotExposeNumericClaims() {
        let summaries = AstroCorrelationService.shared.stockSummaries(
            symbol: "AAPL",
            prices: prices([100, 104, 102, 108, 106, 112]),
            events: [pointEvent(on: "2025-01-02")],
            filterState: AstroOverlayFilterState(eventWindowDays: 1),
            provenance: .unavailable(reason: "Provider-backed history unavailable")
        )

        let summary = summaries.first
        #expect(isUnavailable(summary))
        #expect(summary?.confidence.rawValue == CorrelationConfidence.unavailable.rawValue)
        #expect(summary?.sampleSize == 0)
        #expect(summary?.averageReturn == nil)
        #expect(summary?.winRate == nil)
        #expect(summary?.provenance.isProviderBacked == false)
    }

    @Test("Stock summaries with sample provenance do not expose numeric claims")
    func stockSummariesWithSampleProvenanceDoNotExposeNumericClaims() {
        let summaries = AstroCorrelationService.shared.stockSummaries(
            symbol: "AAPL",
            prices: prices([100, 104, 102, 108, 106, 112]),
            events: [pointEvent(on: "2025-01-02")],
            filterState: AstroOverlayFilterState(eventWindowDays: 1),
            provenance: .sample(reason: "DEBUG screenshot fixture")
        )

        let summary = summaries.first
        #expect(isSampleOnly(summary))
        #expect(summary?.confidence.rawValue == CorrelationConfidence.unavailable.rawValue)
        #expect(summary?.sampleSize == 0)
        #expect(summary?.averageReturn == nil)
        #expect(summary?.winRate == nil)
        #expect(summary?.disclaimer.contains("Sample chart data") == true)
    }

    @Test("Stock summaries with partial dataset completeness do not expose numeric claims")
    func stockSummariesWithPartialDatasetCompletenessDoNotExposeNumericClaims() {
        let summaries = AstroCorrelationService.shared.stockSummaries(
            symbol: "AAPL",
            prices: prices([100, 104, 102, 108, 106, 112, 110, 116, 114, 120]),
            events: [
                pointEvent(on: "2025-01-02"),
                pointEvent(on: "2025-01-04"),
                pointEvent(on: "2025-01-06")
            ],
            filterState: AstroOverlayFilterState(eventWindowDays: 1),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10")),
            completeness: .partial(reason: "Provider returned a limited portion of the requested range")
        )

        let summary = summaries.first
        #expect(isPartialDataset(summary))
        #expect(summary?.averageReturn == nil)
        #expect(summary?.winRate == nil)
        #expect(summary?.disclaimer.contains("Partial historical dataset") == true)
        #expect(summary?.provenance.indicatorLabel == "Partial history")
    }

    @Test("Stock summaries with insufficient dataset completeness do not expose numeric claims")
    func stockSummariesWithInsufficientDatasetCompletenessDoNotExposeNumericClaims() {
        let summaries = AstroCorrelationService.shared.stockSummaries(
            symbol: "AAPL",
            prices: prices([100, 104, 102, 108, 106, 112]),
            events: [
                pointEvent(on: "2025-01-02"),
                pointEvent(on: "2025-01-04"),
                pointEvent(on: "2025-01-06")
            ],
            filterState: AstroOverlayFilterState(eventWindowDays: 1),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10")),
            completeness: .insufficient(reason: "Provider returned fewer than two historical candles")
        )

        let summary = summaries.first
        #expect(isInsufficientDataset(summary))
        #expect(summary?.averageReturn == nil)
        #expect(summary?.winRate == nil)
        #expect(summary?.disclaimer.contains("Insufficient historical dataset") == true)
    }

    @Test("Historical dataset with empty candles is insufficient and unusable for chart claims")
    func historicalDatasetWithEmptyCandlesIsInsufficientAndUnusable() {
        let requestedRange = DateInterval(start: date("2025-01-01"), end: date("2025-03-01"))
        let dataset = HistoricalPriceDataset.providerBacked(
            symbol: "AAPL",
            candles: [],
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2025-03-01"),
            requestedRange: requestedRange,
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-03-01"))
        )

        #expect(dataset.candles.isEmpty)
        #expect(dataset.isUsableForCorrelation == false)
        #expect(dataset.completeness.label == "Insufficient")
        #expect(dataset.correlationDisplayProvenance.isProviderBacked == false)
        #expect(dataset.correlationDisplayProvenance.indicatorLabel == "Unavailable")
    }

    @Test("Historical dataset with one candle is insufficient and cannot drive overlay metrics")
    func historicalDatasetWithOneCandleIsInsufficient() {
        let requestedRange = DateInterval(start: date("2025-01-01"), end: date("2025-03-01"))
        let dataset = HistoricalPriceDataset.providerBacked(
            symbol: "AAPL",
            candles: prices([100]),
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2025-03-01"),
            requestedRange: requestedRange,
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-03-01"))
        )

        let summaries = AstroCorrelationService.shared.stockSummaries(
            symbol: "AAPL",
            prices: dataset.ohlcData,
            events: [pointEvent(on: "2025-01-01"), pointEvent(on: "2025-01-02"), pointEvent(on: "2025-01-03")],
            filterState: AstroOverlayFilterState(eventWindowDays: 1),
            provenance: dataset.correlationDisplayProvenance,
            completeness: dataset.completeness
        )

        #expect(dataset.candles.count == 1)
        #expect(dataset.isUsableForCorrelation == false)
        #expect(isInsufficientDataset(summaries.first))
        #expect(summaries.first?.averageReturn == nil)
        #expect(summaries.first?.winRate == nil)
    }

    @Test("Stale cached candles remain provider-backed but are labeled stale")
    func staleCachedCandlesRemainProviderBackedButLabeledStale() {
        let staleAge = FinancialDataProvenance.defaultCachedStaleInterval + 60
        let fetchedAt = date("2025-01-01")
        let requestedRange = DateInterval(start: date("2025-01-01"), end: date("2025-01-10"))
        let dataset = HistoricalPriceDataset.providerBacked(
            symbol: "AAPL",
            candles: prices([100, 101, 102, 103, 104, 105, 106, 107, 108, 109]),
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: fetchedAt,
            requestedRange: requestedRange,
            provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt, age: staleAge)
        )

        #expect(dataset.provenance.isProviderBacked)
        #expect(dataset.provenance.isCachedStale())
        #expect(dataset.freshness() == .cachedStale(age: staleAge))
        #expect(dataset.correlationDisplayProvenance.isProviderBacked)
    }

    @Test("Partial provider-backed candles become mixed provenance and hide numeric chart claims")
    func partialProviderBackedCandlesHideNumericChartClaims() {
        let requestedRange = DateInterval(start: date("2025-01-01"), end: date("2025-04-01"))
        let dataset = HistoricalPriceDataset.providerBacked(
            symbol: "AAPL",
            candles: [
                OHLCData(date: date("2025-03-20"), open: 100, high: 101, low: 99, close: 100, volume: 1_000),
                OHLCData(date: date("2025-03-21"), open: 101, high: 102, low: 100, close: 101, volume: 1_000)
            ],
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: date("2025-04-01"),
            requestedRange: requestedRange,
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-04-01"))
        )

        let summaries = AstroCorrelationService.shared.stockSummaries(
            symbol: "AAPL",
            prices: dataset.ohlcData,
            events: [pointEvent(on: "2025-03-20"), pointEvent(on: "2025-03-21"), pointEvent(on: "2025-03-22")],
            filterState: AstroOverlayFilterState(eventWindowDays: 1),
            provenance: dataset.correlationDisplayProvenance,
            completeness: dataset.completeness
        )

        #expect(dataset.completeness.label == "Partial")
        #expect(dataset.correlationDisplayProvenance.indicatorLabel == "Partial history")
        #expect(isPartialDataset(summaries.first))
        #expect(summaries.first?.averageReturn == nil)
        #expect(summaries.first?.medianReturn == nil)
        #expect(summaries.first?.baselineReturn == nil)
    }

    private func pointEvent(on value: String) -> AstroOverlayEvent {
        let eventDate = date(value)
        return AstroOverlayEvent(
            id: "point-\(value)",
            kind: .fullMoon,
            title: "Full Moon",
            subtitle: nil,
            startDate: eventDate,
            endDate: nil,
            markerDate: eventDate,
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

    private func prices(_ closes: [Double], volume: Int = 1_000) -> [OHLCData] {
        closes.enumerated().map { index, close in
            OHLCData(
                date: Calendar.current.date(byAdding: .day, value: index, to: date("2025-01-01")) ?? date("2025-01-01"),
                open: close,
                high: close + 1,
                low: max(0.01, close - 1),
                close: close,
                volume: volume
            )
        }
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }

    private func isMarketBacked(_ summary: StockCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .marketBackedResult = summary.displayMode { return true }
        return false
    }

    private func isInsufficientSample(_ summary: StockCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .insufficientSample = summary.displayMode { return true }
        return false
    }

    private func isUnavailable(_ summary: StockCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .unavailable = summary.displayMode { return true }
        return false
    }

    private func isPartialDataset(_ summary: StockCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .partialDataset = summary.displayMode { return true }
        return false
    }

    private func isInsufficientDataset(_ summary: StockCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .insufficientDataset = summary.displayMode { return true }
        return false
    }

    private func isSampleOnly(_ summary: StockCosmicCorrelationSummary?) -> Bool {
        guard let summary else { return false }
        if case .sampleOnly = summary.displayMode { return true }
        return false
    }
}
