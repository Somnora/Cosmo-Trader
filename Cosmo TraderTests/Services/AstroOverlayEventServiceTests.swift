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
}
