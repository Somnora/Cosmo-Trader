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
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: date("2025-01-10"))
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
        #expect(summary?.disclaimer.contains("No return claim") == true)
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
