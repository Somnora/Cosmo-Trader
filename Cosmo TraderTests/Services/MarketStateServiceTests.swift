import Foundation
import Testing
@testable import Cosmo_Trader

struct MarketStateServiceTests {

    @Test("Short history produces no snapshot rather than a thin one")
    func shortHistoryProducesNoSnapshot() {
        let snapshot = MarketStateService.snapshot(
            symbol: "SPY",
            prices: prices(rising(count: 100)),
            provenance: liveProvenance()
        )

        #expect(snapshot == nil)
    }

    @Test("Snapshot reports every state reading with historical context")
    func snapshotReportsReadingsWithContext() {
        let snapshot = MarketStateService.snapshot(
            symbol: "spy",
            prices: prices(rising(count: 600)),
            provenance: liveProvenance()
        )

        #expect(snapshot?.symbol == "SPY")
        #expect(snapshot?.sessionCount == 600)
        #expect(snapshot?.readings.count == 5)
        #expect(snapshot?.readings.allSatisfy { !$0.context.isEmpty } == true)
        #expect(snapshot?.readings.contains { $0.id == "drawdown20" } == true)
    }

    @Test("Drawdown reading measures distance from the recent high")
    func drawdownReadingMeasuresDistanceFromHigh() {
        // Rises for 500 sessions, then gives back 10% over the last ten.
        var closes = rising(count: 500)
        let peak = closes[closes.count - 1]
        for step in 1...10 {
            closes.append(peak * (1 - 0.01 * Double(step)))
        }

        let snapshot = MarketStateService.snapshot(
            symbol: "SPY",
            prices: prices(closes),
            provenance: liveProvenance()
        )
        let drawdown = snapshot?.readings.first { $0.id == "drawdown20" }

        #expect(drawdown?.value.hasPrefix("-") == true)
        // Furthest below its 20-day high it has ever been in this series.
        #expect((drawdown?.shareBelow ?? 1) < 0.01)
    }

    @Test("A random walk is reported as an ordinary session")
    func randomWalkReadsAsOrdinary() {
        // Where the market sits relative to its 20-day high says nothing about
        // the next week, because nothing in a random walk says anything about
        // the next week. This is the case the real data overwhelmingly
        // resembles, and the card has to be willing to report it.
        let snapshot = MarketStateService.snapshot(
            symbol: "SPY",
            prices: prices(randomWalk(count: 2000)),
            provenance: liveProvenance()
        )

        let history = snapshot?.history
        #expect(history != nil)
        #expect(history?.isDistinguishableFromOrdinary == false)
    }

    @Test("A genuinely predictable market is reported as distinguishable")
    func predictableMarketReadsAsDistinguishable() {
        // The counterpart to the random walk, and the reason that test means
        // something: in a strictly alternating series the drawdown band fixes
        // the next move exactly, so the verdict must be able to say so. A
        // verdict that always reads 'ordinary' would pass the test above
        // without measuring anything.
        let snapshot = MarketStateService.snapshot(
            symbol: "SPY",
            prices: prices(alternating(count: 900)),
            provenance: liveProvenance()
        )

        #expect(snapshot?.history?.isDistinguishableFromOrdinary == true)
    }

    @Test("History is withheld when too few comparable sessions exist")
    func historyWithheldWhenFewComparableSessions() {
        // Monotonic rise: every session sits at its 20-day high, so the other
        // two bands never fill and there is nothing to compare against.
        let snapshot = MarketStateService.snapshot(
            symbol: "SPY",
            prices: prices(rising(count: 600)),
            provenance: liveProvenance()
        )

        #expect(snapshot?.history == nil)
    }

    @Test("The margin of error discounts overlapping forward windows")
    func marginOfErrorDiscountsOverlappingWindows() {
        // Overlapping five-session windows sampled daily share four fifths of
        // their observations. If the discount were dropped the interval would
        // shrink by roughly sqrt(5) and ordinary weeks would start reading as
        // findings, so the half-width has to stay wide enough to notice.
        let snapshot = MarketStateService.snapshot(
            symbol: "SPY",
            prices: prices(alternating(count: 900)),
            provenance: liveProvenance()
        )

        let history = snapshot?.history
        #expect((history?.differenceHalfWidthPercent ?? 0) > 0)
        #expect(history?.horizonSessions == MarketStateService.forwardHorizonSessions)
    }

    // MARK: - Fixtures

    private func rising(count: Int) -> [Double] {
        (0..<count).map { 100 * pow(1.001, Double($0)) }
    }

    /// Deterministic pseudo-random walk. Seeded so the suite never flakes.
    private func randomWalk(count: Int) -> [Double] {
        var state: UInt64 = 0x5DEECE66D
        var closes: [Double] = [100]
        for _ in 1..<count {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let unit = Double(state >> 11) / Double(UInt64(1) << 53)
            closes.append(closes[closes.count - 1] * (1 + (unit - 0.5) * 0.02))
        }
        return closes
    }

    private func alternating(count: Int) -> [Double] {
        var closes: [Double] = [100]
        for index in 1..<count {
            closes.append(closes[index - 1] * (index.isMultiple(of: 2) ? 0.99 : 1.01))
        }
        return closes
    }

    private func prices(_ closes: [Double]) -> [OHLCData] {
        closes.enumerated().map { index, close in
            OHLCData(
                date: Calendar.current.date(
                    byAdding: .day,
                    value: index,
                    to: Date(timeIntervalSince1970: 1_136_073_600)
                ) ?? Date(timeIntervalSince1970: 1_136_073_600),
                open: close,
                high: close * 1.005,
                low: close * 0.995,
                close: close,
                volume: 1_000
            )
        }
    }

    private func liveProvenance() -> FinancialDataProvenance {
        .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: Date())
    }
}
