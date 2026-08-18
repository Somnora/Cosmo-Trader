import Foundation

/// Derives the day's falsifiable `PredictionRecord` from the same correlation
/// summaries the Today horoscope displays (specs/prediction-ledger-mvp.md).
///
/// Pure and stateless: the same inputs always produce the same claims, so the
/// full behavior is unit-testable without any network or clock.
///
/// Data honesty: only summaries with `displayMode == .marketBackedResult` may
/// create scored claims. Sample, partial, stale, and insufficient data never
/// become predictions — the same rule the UI follows for showing numbers.
///
/// Second, independent gate: the summaries cover a full year of history, so a
/// market-backed Full Moon summary exists on every trading day. A claim may
/// only cite a driver whose window actually contains today
/// (`ActiveCosmicDriverSnapshot`); otherwise the ledger would score "is the
/// market up today" under a cosmic label. When nothing is active the record
/// is an honest no-call.
///
/// Main-actor like the composer: its inputs are the main-actor correlation
/// summary types. The records it produces are `nonisolated` models.
struct PredictionExtractor {

    struct Thresholds {
        /// Minimum historical win rate (0...1) for a positive edge to read bullish.
        let bullishMinimumWinRate: Double
        /// Maximum historical win rate (0...1) for a negative edge to read bearish.
        let bearishMaximumWinRate: Double

        static let standard = Thresholds(
            bullishMinimumWinRate: 0.55,
            bearishMaximumWinRate: 0.45
        )
    }

    static let easternTimeZone = TimeZone(identifier: "America/New_York")!
    /// US equity markets close at 4:00 p.m. ET.
    static let marketCloseHour = 16

    private let thresholds: Thresholds
    private let calendar: Calendar

    init(thresholds: Thresholds = .standard) {
        self.thresholds = thresholds
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.easternTimeZone
        self.calendar = calendar
    }

    /// Builds the prediction record for `date` (an ET trading day).
    /// `activeDriverKinds` is the set of cosmic drivers whose window contains
    /// `date`; an empty set means nothing is happening, and every builder
    /// declines. Returns a no-call record (empty claims) when nothing
    /// market-backed is active — silence is recorded honestly, never invented.
    func makeRecord(
        date: Date,
        activeDriverKinds: Set<AstroOverlayEventKind>,
        marketWeather: MarketWeatherSummary?,
        portfolioSummaries: [PortfolioCosmicCorrelationSummary],
        portfolioHoldings: [Stock],
        stockCandidate: TodayStockCandidate?
    ) -> PredictionRecord {
        var claims: [PredictionClaim] = []
        if let market = marketClaim(from: marketWeather, activeDriverKinds: activeDriverKinds) {
            claims.append(market)
        }
        if let portfolio = portfolioClaim(
            from: portfolioSummaries,
            holdings: portfolioHoldings,
            activeDriverKinds: activeDriverKinds
        ) {
            claims.append(portfolio)
        }
        if let stock = stockClaim(from: stockCandidate, activeDriverKinds: activeDriverKinds) {
            claims.append(stock)
        }

        return PredictionRecord(
            tradingDay: Self.tradingDay(for: date),
            recordedAt: date,
            recordedAfterClose: isAfterClose(date),
            claims: claims
        )
    }

    /// ET calendar day key, "yyyy-MM-dd".
    static func tradingDay(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = easternTimeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    // MARK: - Claims

    private func marketClaim(
        from summary: MarketWeatherSummary?,
        activeDriverKinds: Set<AstroOverlayEventKind>
    ) -> PredictionClaim? {
        guard let summary else { return nil }

        let candidates = summary.eventSummaries.compactMap { event -> ScoredEvent? in
            guard event.displayMode == .marketBackedResult,
                  let average = event.averageMarketReturn,
                  let baseline = event.baselineMarketReturn,
                  let winRate = event.winRate else {
                return nil
            }
            // Kept separate from the market-backed gate: a summary can be
            // fully market-backed and still describe an event that is not
            // occurring today.
            guard activeDriverKinds.contains(event.eventType) else { return nil }
            return ScoredEvent(
                eventName: event.eventName,
                eventKind: event.eventType,
                edge: average - baseline,
                winRate: winRate,
                confidence: event.confidence
            )
        }

        return bestEvent(among: candidates).map { claim(subject: .market, event: $0) }
    }

    private func portfolioClaim(
        from summaries: [PortfolioCosmicCorrelationSummary],
        holdings: [Stock],
        activeDriverKinds: Set<AstroOverlayEventKind>
    ) -> PredictionClaim? {
        // Weights are frozen at recording time so later portfolio edits can
        // never rewrite what a prediction was about.
        let owned = holdings.filter(\.isOwned).filter { $0.marketValue > 0 }
        let totalValue = owned.reduce(0) { $0 + $1.marketValue }
        guard totalValue > 0 else { return nil }
        let weights = Dictionary(
            owned.map { ($0.symbol.uppercased(), $0.marketValue / totalValue) },
            uniquingKeysWith: +
        )

        let candidates = summaries.compactMap { summary -> ScoredEvent? in
            guard summary.displayMode == .marketBackedResult,
                  let average = summary.averagePortfolioReturn,
                  let baseline = summary.baselinePortfolioReturn,
                  let winRate = summary.winRate else {
                return nil
            }
            guard activeDriverKinds.contains(summary.eventType) else { return nil }
            return ScoredEvent(
                eventName: summary.eventName,
                eventKind: summary.eventType,
                edge: average - baseline,
                winRate: winRate,
                confidence: summary.confidence
            )
        }

        return bestEvent(among: candidates).map {
            claim(subject: .portfolio, event: $0, portfolioWeights: weights)
        }
    }

    private func stockClaim(
        from candidate: TodayStockCandidate?,
        activeDriverKinds: Set<AstroOverlayEventKind>
    ) -> PredictionClaim? {
        guard let candidate else { return nil }
        let symbol = candidate.stock.symbol.uppercased()

        let candidates = candidate.summaries.compactMap { summary -> ScoredEvent? in
            guard summary.displayMode == .marketBackedResult,
                  let average = summary.averageReturn,
                  let baseline = summary.baselineReturn,
                  let winRate = summary.winRate else {
                return nil
            }
            guard activeDriverKinds.contains(summary.eventType) else { return nil }
            return ScoredEvent(
                eventName: summary.eventName,
                eventKind: summary.eventType,
                edge: average - baseline,
                winRate: winRate,
                confidence: summary.confidence
            )
        }

        return bestEvent(among: candidates).map { claim(subject: .stock(symbol: symbol), event: $0) }
    }

    // MARK: - Selection and direction

    private struct ScoredEvent {
        let eventName: String
        let eventKind: AstroOverlayEventKind
        let edge: Double
        let winRate: Double
        let confidence: CorrelationConfidence
    }

    /// Highest confidence wins; |edge| breaks ties.
    private func bestEvent(among candidates: [ScoredEvent]) -> ScoredEvent? {
        candidates.max { lhs, rhs in
            if confidenceRank(lhs.confidence) != confidenceRank(rhs.confidence) {
                return confidenceRank(lhs.confidence) < confidenceRank(rhs.confidence)
            }
            return abs(lhs.edge) < abs(rhs.edge)
        }
    }

    private func confidenceRank(_ confidence: CorrelationConfidence) -> Int {
        switch confidence {
        case .strong: return 4
        case .moderate: return 3
        case .thin: return 2
        case .insufficient: return 1
        case .unavailable: return 0
        }
    }

    private func claim(
        subject: PredictionSubject,
        event: ScoredEvent,
        portfolioWeights: [String: Double]? = nil
    ) -> PredictionClaim {
        PredictionClaim(
            subject: subject,
            direction: direction(edge: event.edge, winRate: event.winRate),
            cosmicDriver: event.eventName,
            driverKind: event.eventKind.rawValue,
            historicalWinRate: event.winRate,
            historicalEdge: event.edge,
            confidence: event.confidence,
            portfolioWeights: portfolioWeights
        )
    }

    private func direction(edge: Double, winRate: Double) -> PredictionDirection {
        if edge > 0, winRate >= thresholds.bullishMinimumWinRate {
            return .bullish
        }
        if edge < 0, winRate <= thresholds.bearishMaximumWinRate {
            return .bearish
        }
        return .neutral
    }

    private func isAfterClose(_ date: Date) -> Bool {
        calendar.component(.hour, from: date) >= Self.marketCloseHour
    }
}
