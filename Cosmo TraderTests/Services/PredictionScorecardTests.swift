import Foundation
import Testing
@testable import Cosmo_Trader

struct PredictionScorecardTests {

    @Test("Hit rate counts only hits and misses")
    func hitRateCountsOnlyHitsAndMisses() {
        let scorecard = PredictionScorecard.make(from: [
            record(day: "2026-07-01", results: [.hit]),
            record(day: "2026-07-02", results: [.miss]),
            record(day: "2026-07-03", results: [.hit, .flat, .unresolved, .marketClosed])
        ])

        #expect(scorecard.scoredCount == 3)
        #expect(scorecard.hitCount == 2)
        #expect(scorecard.flatCount == 1)
        let hitRate = scorecard.hitRate
        #expect(hitRate != nil)
        if let hitRate {
            #expect(abs(hitRate - (2.0 / 3.0)) < 0.0001)
        }
    }

    @Test("Hit rate is nil under the minimum scored sample")
    func hitRateNilUnderMinimumSample() {
        let scorecard = PredictionScorecard.make(from: [
            record(day: "2026-07-01", results: [.hit]),
            record(day: "2026-07-02", results: [.hit])
        ])

        #expect(scorecard.scoredCount == 2)
        #expect(scorecard.hitRate == nil)
    }

    @Test("After-close records never enter accuracy stats")
    func afterCloseRecordsAreExcluded() {
        let scorecard = PredictionScorecard.make(from: [
            record(day: "2026-07-01", results: [.hit]),
            record(day: "2026-07-02", results: [.hit, .hit], afterClose: true),
            record(day: "2026-07-03", results: [.miss])
        ])

        #expect(scorecard.scoredCount == 2)
        #expect(scorecard.hitCount == 1)
    }

    @Test("Streak is positive consecutive hits from the newest scored claim")
    func positiveStreak() {
        let scorecard = PredictionScorecard.make(from: [
            record(day: "2026-07-01", results: [.miss]),
            record(day: "2026-07-02", results: [.hit]),
            record(day: "2026-07-03", results: [.hit])
        ])

        #expect(scorecard.currentStreak == 2)
    }

    @Test("Streak is negative for consecutive misses and ignores non-scored results")
    func negativeStreakIgnoresNonScored() {
        let scorecard = PredictionScorecard.make(from: [
            record(day: "2026-07-01", results: [.hit]),
            record(day: "2026-07-02", results: [.miss]),
            // Flat and marketClosed do not interrupt or extend the run.
            record(day: "2026-07-03", results: [.flat]),
            record(day: "2026-07-04", results: [.miss, .marketClosed])
        ])

        #expect(scorecard.currentStreak == -2)
    }

    @Test("Empty and unscored ledgers produce a zeroed scorecard")
    func emptyLedgerProducesZeroedScorecard() {
        let empty = PredictionScorecard.make(from: [])
        #expect(empty.scoredCount == 0)
        #expect(empty.hitRate == nil)
        #expect(empty.currentStreak == 0)
        #expect(empty.perDriverKind.isEmpty)
        #expect(!empty.provenance.isProviderBacked)

        let unscored = PredictionScorecard.make(from: [
            record(day: "2026-07-01", results: [.unresolved, .marketClosed])
        ])
        #expect(unscored.scoredCount == 0)
        #expect(unscored.currentStreak == 0)
    }

    @Test("Per-driver rollup splits hits by cosmic driver kind")
    func perDriverRollup() {
        let scorecard = PredictionScorecard.make(from: [
            record(day: "2026-07-01", results: [.hit], driverKind: .fullMoon),
            record(day: "2026-07-02", results: [.miss], driverKind: .fullMoon),
            record(day: "2026-07-03", results: [.hit], driverKind: .mercuryRetrograde)
        ])

        let fullMoon = scorecard.perDriverKind[AstroOverlayEventKind.fullMoon.rawValue]
        #expect(fullMoon == PredictionScorecard.DriverStats(hits: 1, scored: 2))
        let mercury = scorecard.perDriverKind[AstroOverlayEventKind.mercuryRetrograde.rawValue]
        #expect(mercury == PredictionScorecard.DriverStats(hits: 1, scored: 1))
        #expect(fullMoon?.hitRate == 0.5)
    }

    @Test("Aggregate provenance surfaces the least-fresh scored source")
    func aggregateProvenanceSurfacesLeastFresh() {
        let live = FinancialDataProvenance.live(
            provider: FinancialDataProvenance.yahooProvider,
            fetchedAt: date("2026-07-02")
        )
        let staleCached = FinancialDataProvenance.cached(
            provider: FinancialDataProvenance.yahooProvider,
            fetchedAt: date("2026-07-01"),
            age: 90_000
        )

        let scorecard = PredictionScorecard.make(from: [
            record(day: "2026-07-01", results: [.hit], provenance: live),
            record(day: "2026-07-02", results: [.hit], provenance: staleCached),
            record(day: "2026-07-03", results: [.hit], provenance: live)
        ])

        #expect(scorecard.provenance == staleCached)
    }

    // MARK: - Fixtures

    private func record(
        day: String,
        results: [PredictionResult],
        afterClose: Bool = false,
        driverKind: AstroOverlayEventKind = .fullMoon,
        provenance: FinancialDataProvenance? = nil
    ) -> PredictionRecord {
        let outcomeProvenance = provenance ?? .live(
            provider: FinancialDataProvenance.yahooProvider,
            fetchedAt: date(day)
        )
        let claims = results.map { result in
            PredictionClaim(
                subject: .market,
                direction: .bullish,
                cosmicDriver: "Fixture Event",
                driverKind: driverKind.rawValue,
                historicalWinRate: 0.6,
                historicalEdge: 0.4,
                confidence: .moderate,
                outcome: PredictionOutcome(
                    result: result,
                    actualReturnPercent: result == .hit || result == .miss ? 0.5 : nil,
                    resolvedAt: date(day),
                    provenance: outcomeProvenance
                )
            )
        }
        return PredictionRecord(
            tradingDay: day,
            recordedAt: date(day),
            recordedAfterClose: afterClose,
            claims: claims
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
