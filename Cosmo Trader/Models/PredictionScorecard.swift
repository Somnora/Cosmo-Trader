import Foundation

/// Computed accuracy rollup over the prediction ledger — never stored, always
/// derived from records (specs/prediction-ledger-mvp.md).
///
/// Scoring integrity: only `hit`/`miss` outcomes from records made before the
/// close enter the accuracy stats. `flat` (a push), `unresolved`,
/// `marketClosed`, and every claim on an after-close record are excluded —
/// the ledger never pads its accuracy with pushes or hindsight.
nonisolated struct PredictionScorecard: Equatable {
    struct DriverStats: Equatable {
        let hits: Int
        let scored: Int

        var hitRate: Double? {
            scored > 0 ? Double(hits) / Double(scored) : nil
        }
    }

    /// Minimum scored claims before a hit rate is shown at all (matches the
    /// correlation services' minimumSampleSize). UI adds an "early days"
    /// caveat below ~20 in phase C.
    static let minimumScoredClaims = 3

    /// Claims that produced a scoreable outcome (hit or miss).
    let scoredCount: Int
    let hitCount: Int
    /// Directional pushes (flat days on directional calls) — shown, not scored.
    let flatCount: Int
    /// Nil until `minimumScoredClaims` outcomes exist. Baseline: coin flip, 50%.
    let hitRate: Double?
    /// Signed streak over scored claims, newest backwards: positive counts
    /// consecutive hits, negative counts consecutive misses, zero when
    /// nothing is scored.
    let currentStreak: Int
    /// `AstroOverlayEventKind` raw value → per-driver accuracy.
    let perDriverKind: [String: DriverStats]
    /// Aggregate provenance of the candle data behind the scored outcomes;
    /// the least-fresh source wins.
    let provenance: FinancialDataProvenance

    static func make(from records: [PredictionRecord]) -> PredictionScorecard {
        // Chronological, so the streak walks newest-last; after-close records
        // are display-only and never enter stats.
        let scoreableRecords = records
            .filter { !$0.recordedAfterClose }
            .sorted { $0.tradingDay < $1.tradingDay }

        var scored = 0
        var hits = 0
        var flats = 0
        var perDriver: [String: (hits: Int, scored: Int)] = [:]
        var orderedResults: [PredictionResult] = []
        var provenance: FinancialDataProvenance?

        for record in scoreableRecords {
            for claim in record.claims {
                guard let outcome = claim.outcome else { continue }
                switch outcome.result {
                case .hit, .miss:
                    scored += 1
                    orderedResults.append(outcome.result)
                    var stats = perDriver[claim.driverKind] ?? (hits: 0, scored: 0)
                    stats.scored += 1
                    if outcome.result == .hit {
                        hits += 1
                        stats.hits += 1
                    }
                    perDriver[claim.driverKind] = stats
                    provenance = worst(of: provenance, and: outcome.provenance)
                case .flat:
                    flats += 1
                case .unresolved, .marketClosed:
                    break
                }
            }
        }

        return PredictionScorecard(
            scoredCount: scored,
            hitCount: hits,
            flatCount: flats,
            hitRate: scored >= minimumScoredClaims ? Double(hits) / Double(scored) : nil,
            currentStreak: streak(of: orderedResults),
            perDriverKind: perDriver.mapValues { DriverStats(hits: $0.hits, scored: $0.scored) },
            provenance: provenance ?? .unavailable(reason: "No scored predictions yet")
        )
    }

    /// Consecutive run of the most recent result: +n for hits, -n for misses.
    private static func streak(of orderedResults: [PredictionResult]) -> Int {
        guard let latest = orderedResults.last else { return 0 }
        var run = 0
        for result in orderedResults.reversed() {
            guard result == latest else { break }
            run += 1
        }
        return latest == .hit ? run : -run
    }

    /// Least-fresh provenance wins so stale inputs are never hidden.
    private static func worst(
        of current: FinancialDataProvenance?,
        and candidate: FinancialDataProvenance
    ) -> FinancialDataProvenance {
        guard let current else { return candidate }
        switch (current, candidate) {
        case (.live, .cached):
            return candidate
        case (.cached(_, _, let currentAge), .cached(_, _, let age)) where age > currentAge:
            return candidate
        default:
            return current
        }
    }
}
