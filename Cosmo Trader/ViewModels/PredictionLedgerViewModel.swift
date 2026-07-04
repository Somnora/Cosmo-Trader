import Foundation

/// Owns loading and resolution for the cosmic scorecard surfaces
/// (specs/prediction-ledger-mvp.md, phase C).
///
/// Responsibility split: `TodayMarketHoroscopeViewModel` records the day's
/// calls after composing Today; this view model resolves earlier days and
/// reads the ledger for display. Both operations are idempotent (the store
/// keeps one record per day; outcomes are write-once), so load order can
/// never corrupt the ledger.
@MainActor
@Observable
final class PredictionLedgerViewModel {
    private(set) var todayRecord: PredictionRecord?
    /// Newest record before today with at least one resolved claim — the
    /// "last scored close" block on the Today card.
    private(set) var lastScoredRecord: PredictionRecord?
    private(set) var scorecard = PredictionScorecard.make(from: [])
    /// All records, newest first, for the scorecard history list.
    private(set) var history: [PredictionRecord] = []
    private(set) var isLoading = false

    /// Scored-call count below which the scorecard shows the early-days
    /// caveat instead of treating the hit rate as meaningful.
    static let earlyDaysThreshold = 20

    private let store: PredictionLedgerStore
    private let scoringService: PredictionScoringService
    private let nowProvider: () -> Date

    init(
        store: PredictionLedgerStore? = nil,
        scoringService: PredictionScoringService? = nil,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.store = store ?? PredictionLedgerStore.shared
        self.scoringService = scoringService ?? PredictionScoringService.shared
        self.nowProvider = nowProvider
    }

    /// Reads the ledger, resolves any scoreable earlier days, and re-reads.
    /// Called after the Today context loads (so today's record exists) and
    /// safe to call repeatedly.
    func load() async {
        isLoading = history.isEmpty
        refreshFromStore()
        await scoringService.resolvePending()
        refreshFromStore()
        isLoading = false
    }

    var hasAnyLedgerContent: Bool {
        todayRecord != nil || !history.isEmpty
    }

    var isEarlyDays: Bool {
        scorecard.scoredCount < Self.earlyDaysThreshold
    }

    private func refreshFromStore() {
        let records = store.allRecords()
        let today = PredictionExtractor.tradingDay(for: nowProvider())
        history = records
        todayRecord = records.first { $0.tradingDay == today }
        lastScoredRecord = records.first { record in
            record.tradingDay < today && record.claims.contains { $0.outcome != nil }
        }
        scorecard = PredictionScorecard.make(from: records)
    }
}

// MARK: - Display mapping
//
// Copy on these surfaces is compliance-gated: never instructional, never the
// word the scanner bans for forecasts. Direction reads as where the cosmos
// "leans" — a scored entertainment claim, not advice. Every string below is
// enumerated in ComplianceCopyGuardTests.

extension PredictionDirection {
    var displayLabel: String {
        switch self {
        case .bullish: return "LEANS BULLISH"
        case .bearish: return "LEANS BEARISH"
        case .neutral: return "READS NEUTRAL"
        }
    }
}

extension PredictionResult {
    var displayLabel: String {
        switch self {
        case .hit: return "HIT"
        case .miss: return "MISS"
        case .flat: return "PUSH"
        case .unresolved: return "UNSCORED"
        case .marketClosed: return "MKT CLOSED"
        }
    }

    /// Results that count toward the accuracy stats.
    var isScored: Bool {
        self == .hit || self == .miss
    }
}

extension PredictionSubject {
    var displayLabel: String {
        switch self {
        case .market: return "MARKET (SPY)"
        case .portfolio: return "PORTFOLIO"
        case .stock(let symbol): return symbol.uppercased()
        }
    }
}

extension PredictionClaim {
    /// Historical framing for the call, e.g.
    /// "Full Moon · 62% of past windows up · edge +0.40%".
    var historicalContextLine: String {
        let upRate = Int((historicalWinRate * 100).rounded())
        let edge = String(format: "%+.2f%%", historicalEdge)
        return "\(cosmicDriver) · \(upRate)% of past windows up · edge \(edge)"
    }
}

extension PredictionRecord {
    /// "JUL 6" style label for history rows, derived from the ET trading day.
    var tradingDayDisplayLabel: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = PredictionExtractor.easternTimeZone
        guard let date = parser.date(from: tradingDay) else { return tradingDay }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PredictionExtractor.easternTimeZone
        return formatter.string(from: date).uppercased()
    }
}
