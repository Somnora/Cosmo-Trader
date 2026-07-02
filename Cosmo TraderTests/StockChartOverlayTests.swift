import Foundation
import Testing
import SwiftUI
@testable import Cosmo_Trader

@MainActor
struct StockChartOverlayTests {

    @Test("nearestCandle returns nil for empty data in StockChartView")
    func nearestCandleReturnsNilWhenEmpty() {
        let chartView = makeChartView()
        #expect(chartView.nearestCandle(to: date("2025-01-15"), in: []) == nil)
    }

    @Test("nearestCandle picks the closest candle by date in StockChartView")
    func nearestCandlePicksClosestCandle() {
        let chartView = makeChartView()
        let data = candles(on: ["2025-01-10", "2025-01-15", "2025-01-20"])

        let nearest = chartView.nearestCandle(to: date("2025-01-16"), in: data)
        #expect(nearest?.date == date("2025-01-15"))
    }

    @Test("nearestEvent returns nil when no events fall within tolerance in StockChartView")
    func nearestEventReturnsNilOutsideTolerance() {
        let chartView = makeChartView()
        let events = [pointEvent(on: "2025-01-01")]

        let result = chartView.nearestEvent(to: date("2025-02-01"), within: 60 * 60 * 24, in: events)
        #expect(result == nil)
    }

    @Test("nearestEvent returns the point event closest to the scrub date in StockChartView")
    func nearestEventReturnsClosestPointEvent() {
        let chartView = makeChartView()
        let events = [
            pointEvent(on: "2025-01-05"),
            pointEvent(on: "2025-01-12"),
            pointEvent(on: "2025-01-20")
        ]

        let result = chartView.nearestEvent(to: date("2025-01-13"), within: 60 * 60 * 24 * 30, in: events)
        #expect(result?.markerDate == date("2025-01-12"))
    }

    @Test("nearestEvent treats range events as distance zero when scrub date is inside in StockChartView")
    func nearestEventInsideRangeReturnsRange() {
        let chartView = makeChartView()
        let events = [
            pointEvent(on: "2025-01-05"),
            rangeEvent(start: "2025-01-10", end: "2025-01-20"),
            pointEvent(on: "2025-01-25")
        ]

        let result = chartView.nearestEvent(to: date("2025-01-15"), within: 60 * 60 * 24, in: events)
        #expect(result?.kind == .mercuryRetrograde)
    }

    @Test("nearestEvent prefers the closer point event over a far range event in StockChartView")
    func nearestEventPrefersCloserPointEvent() {
        let chartView = makeChartView()
        let events = [
            rangeEvent(start: "2025-01-01", end: "2025-01-03"),
            pointEvent(on: "2025-01-14")
        ]

        let result = chartView.nearestEvent(to: date("2025-01-15"), within: 60 * 60 * 24 * 5, in: events)
        #expect(result?.markerDate == date("2025-01-14"))
    }

    @Test("emoji mapping returns expected custom symbols for StockChartView markers")
    func emojiMappingReturnsExpectedSymbols() {
        let chartView = makeChartView()
        
        let newMoon = pointEvent(on: "2025-01-01", kind: .newMoon)
        let fullMoon = pointEvent(on: "2025-01-01", kind: .fullMoon)
        let firstQuarter = pointEvent(on: "2025-01-01", kind: .firstQuarter)
        let lastQuarter = pointEvent(on: "2025-01-01", kind: .lastQuarter)
        let mercuryRx = rangeEvent(start: "2025-01-01", end: "2025-01-03")
        let anniversary = pointEvent(on: "2025-01-01", kind: .companyFoundingAnniversary)
        let birthMonth = rangeEvent(start: "2025-01-01", end: "2025-01-31", kind: .companyBirthMonth)

        #expect(chartView.emoji(for: newMoon) == "🌑")
        #expect(chartView.emoji(for: fullMoon) == "🌕")
        #expect(chartView.emoji(for: firstQuarter) == "🌓")
        #expect(chartView.emoji(for: lastQuarter) == "🌗")
        #expect(chartView.emoji(for: mercuryRx) == "☿")
        #expect(chartView.emoji(for: anniversary) == "🎂")
        #expect(chartView.emoji(for: birthMonth) == nil) // Birth month has no curve-marker emoji, is range-only
    }

    @Test("selectedReaction maps correctly in StockChartView")
    func selectedReactionMapsCorrectly() {
        let chartView = makeChartView()
        let eventA = pointEvent(on: "2025-01-05", kind: .newMoon)
        let eventB = pointEvent(on: "2025-01-12", kind: .fullMoon)

        let reactionA = AstroEventPriceReaction(
            id: "\(eventA.id)-reaction",
            event: eventA,
            windowStart: date("2025-01-04"),
            windowEnd: date("2025-01-08"),
            startPrice: 100,
            endPrice: 105,
            returnPercent: 5.0,
            maxDrawdownPercent: 1.0,
            volatilityPercent: 2.0,
            volumeRatio: 1.0
        )
        let reactionB = AstroEventPriceReaction(
            id: "\(eventB.id)-reaction",
            event: eventB,
            windowStart: date("2025-01-11"),
            windowEnd: date("2025-01-15"),
            startPrice: 105,
            endPrice: 103,
            returnPercent: -1.9,
            maxDrawdownPercent: 3.0,
            volatilityPercent: 2.5,
            volumeRatio: 1.2
        )
        let reactions = [reactionA, reactionB]

        #expect(chartView.selectedReaction(for: eventA, in: reactions)?.returnPercent == 5.0)
        #expect(chartView.selectedReaction(for: eventB, in: reactions)?.returnPercent == -1.9)
        #expect(chartView.selectedReaction(for: nil, in: reactions) == nil)
    }

    // MARK: - Helpers

    private func makeChartView() -> StockChartView {
        let stock = Stock(
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
        return StockChartView(
            stock: stock,
            selectedTimeframe: .constant(.month),
            selectedDisplayMode: .constant(.line)
        )
    }

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

    private func pointEvent(on value: String, kind: AstroOverlayEventKind = .fullMoon) -> AstroOverlayEvent {
        let day = date(value)
        return AstroOverlayEvent(
            id: "point-\(value)-\(kind.rawValue)",
            kind: kind,
            title: kind.displayName,
            subtitle: nil,
            startDate: day,
            endDate: nil,
            markerDate: day,
            intensity: .high,
            affectedElements: [],
            affectedSectors: [],
            iconSystemName: kind.iconSystemName,
            source: .calculatedMoonPhase,
            isEstimated: false
        )
    }

    private func rangeEvent(start: String, end: String, kind: AstroOverlayEventKind = .mercuryRetrograde) -> AstroOverlayEvent {
        AstroOverlayEvent(
            id: "range-\(start)-\(kind.rawValue)",
            kind: kind,
            title: kind.displayName,
            subtitle: nil,
            startDate: date(start),
            endDate: date(end),
            markerDate: date(start),
            intensity: .high,
            affectedElements: [],
            affectedSectors: [],
            iconSystemName: kind.iconSystemName,
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
