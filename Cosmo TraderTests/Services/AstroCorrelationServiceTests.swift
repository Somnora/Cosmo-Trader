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
}
