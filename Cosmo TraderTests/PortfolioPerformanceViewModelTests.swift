import Testing
import Foundation
@testable import Cosmo_Trader

// Pure-function coverage for the portfolio performance chart's assembly:
// weighting, date alignment / forward-fill, benchmark rebasing, and
// provenance aggregation. No network — exercises the nonisolated statics.
struct PortfolioPerformanceViewModelTests {

    private let epoch = Date(timeIntervalSince1970: 1_700_000_000)

    private func day(_ offset: Int) -> Date {
        epoch.addingTimeInterval(Double(offset) * 86_400)
    }

    private func candle(_ date: Date, _ close: Double) -> OHLCData {
        OHLCData(date: date, open: close, high: close, low: close, close: close, volume: 0)
    }

    // MARK: - buildPortfolioSeries

    @Test
    func weightsHoldingsByShares() {
        let a = [candle(day(0), 100), candle(day(1), 110)]
        let b = [candle(day(0), 50), candle(day(1), 60)]

        let series = PortfolioPerformanceViewModel.buildPortfolioSeries(
            holdings: [(shares: 2, candles: a), (shares: 1, candles: b)]
        )

        #expect(series.count == 2)
        #expect(series[0].value == 250)   // 2*100 + 1*50
        #expect(series[1].value == 280)   // 2*110 + 1*60
    }

    @Test
    func startsWhereEveryHoldingHasHistory() {
        // Holding B only starts on day 1; the series must begin at day 1 so a
        // holding appearing late never produces a phantom jump.
        let a = [candle(day(0), 100), candle(day(1), 100), candle(day(2), 100)]
        let b = [candle(day(1), 50), candle(day(2), 50)]

        let series = PortfolioPerformanceViewModel.buildPortfolioSeries(
            holdings: [(shares: 1, candles: a), (shares: 1, candles: b)]
        )

        #expect(series.count == 2)
        #expect(series.first?.date == day(1))
        #expect(series.allSatisfy { $0.value == 150 })
    }

    @Test
    func forwardFillsMissingDates() {
        // A trades on days 0 and 2; B trades on days 0, 1, 2. On day 1, A's
        // most recent close (day 0) is carried forward.
        let a = [candle(day(0), 100), candle(day(2), 120)]
        let b = [candle(day(0), 10), candle(day(1), 10), candle(day(2), 10)]

        let series = PortfolioPerformanceViewModel.buildPortfolioSeries(
            holdings: [(shares: 1, candles: a), (shares: 1, candles: b)]
        )

        // Union of dates {0,1,2}.
        #expect(series.count == 3)
        #expect(series[0].value == 110)   // 100 + 10
        #expect(series[1].value == 110)   // forward-filled 100 + 10
        #expect(series[2].value == 130)   // 120 + 10
    }

    @Test
    func returnsEmptyWhenNoHoldings() {
        #expect(PortfolioPerformanceViewModel.buildPortfolioSeries(holdings: []).isEmpty)
    }

    @Test
    func returnsEmptyWhenSinglePoint() {
        let a = [candle(day(0), 100)]
        #expect(PortfolioPerformanceViewModel.buildPortfolioSeries(holdings: [(shares: 1, candles: a)]).isEmpty)
    }

    // MARK: - scaleBenchmark

    @Test
    func rebasesBenchmarkToPortfolioStart() {
        // Benchmark up 10% across the range; rebased onto a $250 start.
        let benchmark = [candle(day(0), 400), candle(day(1), 440)]

        let scaled = PortfolioPerformanceViewModel.scaleBenchmark(
            benchmark,
            toStartValue: 250,
            alignedTo: [day(0), day(1)]
        )

        #expect(scaled.count == 2)
        #expect(scaled[0].value == 250)
        #expect(abs(scaled[1].value - 275) < 0.0001)   // 250 * 440/400
    }

    // MARK: - closeAsOf

    @Test
    func closeAsOfCarriesForwardAndClampsToStart() {
        let sorted = [candle(day(0), 10), candle(day(2), 20)]

        #expect(PortfolioPerformanceViewModel.closeAsOf(day(-1), in: sorted) == 10) // before start → first
        #expect(PortfolioPerformanceViewModel.closeAsOf(day(1), in: sorted) == 10)  // between → carry
        #expect(PortfolioPerformanceViewModel.closeAsOf(day(2), in: sorted) == 20)  // exact
        #expect(PortfolioPerformanceViewModel.closeAsOf(day(9), in: sorted) == 20)  // after → last
    }

    // MARK: - aggregateProvenance

    @Test
    func allLiveAggregatesToLive() {
        let result = PortfolioPerformanceViewModel.aggregateProvenance([
            .live(provider: "Yahoo Finance", fetchedAt: day(0)),
            .live(provider: "Yahoo Finance", fetchedAt: day(1))
        ])
        if case .live = result {} else { Issue.record("expected .live, got \(result)") }
    }

    @Test
    func mixedFreshnessAggregatesToCached() {
        let result = PortfolioPerformanceViewModel.aggregateProvenance([
            .live(provider: "Yahoo Finance", fetchedAt: day(1)),
            .cached(provider: "Yahoo Finance", fetchedAt: day(0), age: 3600)
        ])
        if case .cached = result {} else { Issue.record("expected .cached, got \(result)") }
    }

    @Test
    func anyUnavailableAggregatesToMixed() {
        let result = PortfolioPerformanceViewModel.aggregateProvenance([
            .cached(provider: "Yahoo Finance", fetchedAt: day(0), age: 3600),
            .unavailable(reason: "no history")
        ])
        if case .mixed = result {} else { Issue.record("expected .mixed, got \(result)") }
    }

    @Test
    func emptyAggregatesToUnavailable() {
        let result = PortfolioPerformanceViewModel.aggregateProvenance([])
        if case .unavailable = result {} else { Issue.record("expected .unavailable, got \(result)") }
    }
}
