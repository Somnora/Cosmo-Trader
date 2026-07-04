import Foundation

/// Resolves pending prediction-ledger records against actual market closes
/// (specs/prediction-ledger-mvp.md, phase B).
///
/// Outcomes come exclusively from provider-backed daily candles via
/// `HistoricalPriceService` — never quotes. Candles are canonical,
/// retroactively fetchable, and provenance-labeled, so every outcome carries
/// the provenance of the data that resolved it.
///
/// Resolution rules:
/// - A claim resolves `hit`/`miss`/`flat` from the subject's close-over-
///   previous-close return on the prediction's trading day. Moves inside the
///   ±0.10% deadband count as flat days.
/// - No SPY candle on the trading day, with later candles present, means the
///   market never traded — the whole record resolves `marketClosed`.
/// - Provider data that is genuinely absent (the market traded but a symbol
///   has no candle, or frozen portfolio weights fall under 70% coverage)
///   resolves `unresolved` — the ledger never guesses.
/// - Transient fetch failures leave the record pending for retry; after
///   `unresolvedTimeoutDays` the record resolves `unresolved`.
@MainActor
final class PredictionScoringService {
    static let shared = PredictionScoringService()

    typealias DatasetFetcher = (String, ChartTimeframe) async throws -> HistoricalPriceDataset

    /// Moves with |return| below this (percent) count as flat days.
    static let flatDeadbandPercent = 0.10
    /// Pending records older than this resolve `unresolved` instead of
    /// retrying forever.
    static let unresolvedTimeoutDays = 7
    /// Frozen portfolio weight that must have candles before a portfolio
    /// claim resolves numerically (mirrors the composer's 70% rule).
    static let minimumPortfolioWeightCoverage = 0.70
    /// SPY is the market proxy and the market-open authority.
    static let marketProxySymbol = "SPY"

    private let store: PredictionLedgerStore
    private let fetchDataset: DatasetFetcher
    private let nowProvider: () -> Date
    /// Daily candles for the last month cover both fresh resolutions and the
    /// 7-day unresolved timeout window.
    private let timeframe: ChartTimeframe = .month

    init(
        store: PredictionLedgerStore? = nil,
        nowProvider: @escaping () -> Date = Date.init,
        fetchDataset: DatasetFetcher? = nil
    ) {
        self.store = store ?? PredictionLedgerStore.shared
        self.nowProvider = nowProvider
        self.fetchDataset = fetchDataset ?? { symbol, timeframe in
            try await HistoricalPriceService.shared.fetchHistoricalDataset(
                symbol: symbol,
                timeframe: timeframe
            )
        }
    }

    /// Resolves every pending record from trading days before today (ET).
    /// Safe to call on every Today load: records that cannot be resolved yet
    /// stay pending, and outcomes are write-once in the store.
    /// Returns the number of claims that received an outcome.
    @discardableResult
    func resolvePending() async -> Int {
        let now = nowProvider()
        let today = PredictionExtractor.tradingDay(for: now)
        let pending = store.pendingRecords(before: today)
        guard !pending.isEmpty else { return 0 }

        // Fetch each needed symbol once per run; claims share the datasets.
        var symbols: Set<String> = [Self.marketProxySymbol]
        for record in pending {
            for claim in record.claims where claim.outcome == nil {
                switch claim.subject {
                case .market:
                    break
                case .stock(let symbol):
                    symbols.insert(symbol.uppercased())
                case .portfolio:
                    for symbol in (claim.portfolioWeights ?? [:]).keys {
                        symbols.insert(symbol.uppercased())
                    }
                }
            }
        }

        var datasets: [String: HistoricalPriceDataset] = [:]
        var failedSymbols: Set<String> = []
        for symbol in symbols.sorted() {
            do {
                let dataset = try await fetchDataset(symbol, timeframe)
                if dataset.provenance.isProviderBacked {
                    datasets[symbol] = dataset
                } else {
                    failedSymbols.insert(symbol)
                }
            } catch {
                failedSymbols.insert(symbol)
            }
        }

        var applied = 0
        for record in pending {
            applied += resolve(
                record: record,
                datasets: datasets,
                failedSymbols: failedSymbols,
                now: now,
                today: today
            )
        }
        return applied
    }

    // MARK: - Per-record resolution

    private func resolve(
        record: PredictionRecord,
        datasets: [String: HistoricalPriceDataset],
        failedSymbols: Set<String>,
        now: Date,
        today: String
    ) -> Int {
        let timedOut = isPastTimeout(tradingDay: record.tradingDay, today: today)
        let spyDataset = datasets[Self.marketProxySymbol]

        // The market-open authority: was there a SPY candle on the trading day?
        let marketDayStatus = spyDataset.map {
            dayStatus(for: record.tradingDay, in: $0)
        }

        // Whole-record market-closed: SPY has later candles but none for the
        // recorded day, so no trading occurred.
        if let spyDataset, marketDayStatus == .closedDay {
            var applied = 0
            for claim in record.claims where claim.outcome == nil {
                let outcome = PredictionOutcome(
                    result: .marketClosed,
                    actualReturnPercent: nil,
                    resolvedAt: now,
                    provenance: spyDataset.provenance,
                    detail: "No trading on \(record.tradingDay)."
                )
                if store.applyOutcome(outcome, claimID: claim.id, tradingDay: record.tradingDay) {
                    applied += 1
                }
            }
            return applied
        }

        var applied = 0
        for claim in record.claims where claim.outcome == nil {
            let resolution = resolveClaim(
                claim,
                tradingDay: record.tradingDay,
                datasets: datasets,
                failedSymbols: failedSymbols,
                marketDayStatus: marketDayStatus
            )

            let outcome: PredictionOutcome?
            switch resolution {
            case .resolved(let resolvedOutcome):
                outcome = resolvedOutcome
            case .retryLater(let reason):
                outcome = timedOut
                    ? PredictionOutcome(
                        result: .unresolved,
                        actualReturnPercent: nil,
                        resolvedAt: now,
                        provenance: .unavailable(reason: reason),
                        detail: "Provider-backed candles never became available. \(reason)"
                    )
                    : nil
            }

            if let outcome,
               store.applyOutcome(outcome, claimID: claim.id, tradingDay: record.tradingDay) {
                applied += 1
            }
        }
        return applied
    }

    private enum ClaimResolution {
        case resolved(PredictionOutcome)
        case retryLater(reason: String)
    }

    private func resolveClaim(
        _ claim: PredictionClaim,
        tradingDay: String,
        datasets: [String: HistoricalPriceDataset],
        failedSymbols: Set<String>,
        marketDayStatus: DayStatus?
    ) -> ClaimResolution {
        switch claim.subject {
        case .market:
            return singleSymbolResolution(
                symbol: Self.marketProxySymbol,
                direction: claim.direction,
                tradingDay: tradingDay,
                datasets: datasets,
                marketDayStatus: marketDayStatus
            )
        case .stock(let symbol):
            return singleSymbolResolution(
                symbol: symbol.uppercased(),
                direction: claim.direction,
                tradingDay: tradingDay,
                datasets: datasets,
                marketDayStatus: marketDayStatus
            )
        case .portfolio:
            return portfolioResolution(
                claim: claim,
                tradingDay: tradingDay,
                datasets: datasets,
                failedSymbols: failedSymbols,
                marketDayStatus: marketDayStatus
            )
        }
    }

    private func singleSymbolResolution(
        symbol: String,
        direction: PredictionDirection,
        tradingDay: String,
        datasets: [String: HistoricalPriceDataset],
        marketDayStatus: DayStatus?
    ) -> ClaimResolution {
        guard let dataset = datasets[symbol] else {
            return .retryLater(reason: "Provider-backed history unavailable for \(symbol)")
        }

        switch dailyReturnPercent(for: tradingDay, in: dataset) {
        case .value(let returnPercent):
            return .resolved(outcome(
                direction: direction,
                actualReturnPercent: returnPercent,
                provenance: dataset.provenance
            ))
        case .missingDay:
            // The market traded (SPY has this day) but this symbol has no
            // candle — data is genuinely absent, not late. Never guess.
            if marketDayStatus == .tradedDay {
                return .resolved(PredictionOutcome(
                    result: .unresolved,
                    actualReturnPercent: nil,
                    resolvedAt: nowProvider(),
                    provenance: .unavailable(reason: "No \(symbol) candle for \(tradingDay)"),
                    detail: "The market traded on \(tradingDay) but no \(symbol) candle exists."
                ))
            }
            return .retryLater(reason: "No \(symbol) candle for \(tradingDay) yet")
        case .dataNotYetAvailable:
            return .retryLater(reason: "Candles for \(tradingDay) not yet published for \(symbol)")
        }
    }

    private func portfolioResolution(
        claim: PredictionClaim,
        tradingDay: String,
        datasets: [String: HistoricalPriceDataset],
        failedSymbols: Set<String>,
        marketDayStatus: DayStatus?
    ) -> ClaimResolution {
        // Scoring uses the weights frozen at recording time, never the
        // live portfolio.
        let weights = claim.portfolioWeights ?? [:]
        guard !weights.isEmpty else {
            return .resolved(PredictionOutcome(
                result: .unresolved,
                actualReturnPercent: nil,
                resolvedAt: nowProvider(),
                provenance: .unavailable(reason: "No recorded portfolio weights"),
                detail: "The claim carries no frozen portfolio weights to score against."
            ))
        }

        var coveredWeight = 0.0
        var weightedReturn = 0.0
        var anyTransientFailure = false
        var usedDatasets: [HistoricalPriceDataset] = []

        for (symbol, weight) in weights {
            let upper = symbol.uppercased()
            guard let dataset = datasets[upper] else {
                if failedSymbols.contains(upper) { anyTransientFailure = true }
                continue
            }
            if case .value(let returnPercent) = dailyReturnPercent(for: tradingDay, in: dataset) {
                coveredWeight += weight
                weightedReturn += weight * returnPercent
                usedDatasets.append(dataset)
            }
        }

        if coveredWeight >= Self.minimumPortfolioWeightCoverage {
            return .resolved(outcome(
                direction: claim.direction,
                actualReturnPercent: weightedReturn / coveredWeight,
                provenance: aggregateProvenance(of: usedDatasets)
            ))
        }

        // Under-coverage from a transient fetch failure is retryable; the
        // record's timeout converts persistent failure into `unresolved`.
        if anyTransientFailure {
            return .retryLater(reason: "Provider-backed history unavailable for portfolio holdings")
        }

        // All fetches succeeded and coverage still falls short: the data is
        // genuinely absent. Resolve honestly rather than guess.
        return .resolved(PredictionOutcome(
            result: .unresolved,
            actualReturnPercent: nil,
            resolvedAt: nowProvider(),
            provenance: .unavailable(
                reason: "Candles cover \(Int((coveredWeight * 100).rounded()))% of recorded portfolio weight; 70% is required"
            ),
            detail: "Provider-backed candles cover too little of the recorded portfolio weight to score this claim."
        ))
    }

    // MARK: - Return math

    private enum DayStatus: Equatable {
        /// A candle exists for the day.
        case tradedDay
        /// No candle for the day, but later candles exist — no trading occurred.
        case closedDay
        /// The dataset ends before the day — data simply isn't published yet.
        case notYetCovered
    }

    private enum DailyReturn {
        case value(Double)
        /// The day is missing from an otherwise-covering dataset.
        case missingDay
        /// The dataset does not reach the day yet.
        case dataNotYetAvailable
    }

    private func dayStatus(for tradingDay: String, in dataset: HistoricalPriceDataset) -> DayStatus {
        let candles = sortedCandles(of: dataset)
        if candles.contains(where: { PredictionExtractor.tradingDay(for: $0.date) == tradingDay }) {
            return .tradedDay
        }
        if candles.contains(where: { PredictionExtractor.tradingDay(for: $0.date) > tradingDay }) {
            return .closedDay
        }
        return .notYetCovered
    }

    /// Close-over-previous-close return (percent) for the trading day.
    private func dailyReturnPercent(for tradingDay: String, in dataset: HistoricalPriceDataset) -> DailyReturn {
        let candles = sortedCandles(of: dataset)
        guard let index = candles.firstIndex(where: {
            PredictionExtractor.tradingDay(for: $0.date) == tradingDay
        }) else {
            switch dayStatus(for: tradingDay, in: dataset) {
            case .closedDay:
                return .missingDay
            case .notYetCovered, .tradedDay:
                return .dataNotYetAvailable
            }
        }

        guard index > 0 else {
            // No previous close inside the fetched window to compute against.
            return .dataNotYetAvailable
        }
        let previousClose = candles[index - 1].close
        guard previousClose > 0 else { return .dataNotYetAvailable }
        return .value(((candles[index].close - previousClose) / previousClose) * 100)
    }

    private func sortedCandles(of dataset: HistoricalPriceDataset) -> [OHLCData] {
        dataset.ohlcData.sorted { $0.date < $1.date }
    }

    private func outcome(
        direction: PredictionDirection,
        actualReturnPercent: Double,
        provenance: FinancialDataProvenance
    ) -> PredictionOutcome {
        PredictionOutcome(
            result: result(direction: direction, actualReturnPercent: actualReturnPercent),
            actualReturnPercent: actualReturnPercent,
            resolvedAt: nowProvider(),
            provenance: provenance
        )
    }

    private func result(direction: PredictionDirection, actualReturnPercent: Double) -> PredictionResult {
        let isFlatDay = abs(actualReturnPercent) < Self.flatDeadbandPercent
        switch direction {
        case .neutral:
            return isFlatDay ? .hit : .miss
        case .bullish:
            if isFlatDay { return .flat }
            return actualReturnPercent > 0 ? .hit : .miss
        case .bearish:
            if isFlatDay { return .flat }
            return actualReturnPercent < 0 ? .hit : .miss
        }
    }

    /// The honest label for a return computed from several datasets: the
    /// least-fresh source wins, so a stale input can never hide behind a
    /// live one.
    private func aggregateProvenance(of datasets: [HistoricalPriceDataset]) -> FinancialDataProvenance {
        var worst: FinancialDataProvenance?
        for dataset in datasets {
            switch (worst, dataset.provenance) {
            case (nil, let provenance):
                worst = provenance
            case (.live, .cached):
                worst = dataset.provenance
            case (.cached(_, _, let currentAge), .cached(_, _, let age)) where age > currentAge:
                worst = dataset.provenance
            default:
                break
            }
        }
        return worst ?? .unavailable(reason: "No provider-backed datasets")
    }

    private func isPastTimeout(tradingDay: String, today: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PredictionExtractor.easternTimeZone
        guard let recordDay = formatter.date(from: tradingDay),
              let todayDate = formatter.date(from: today) else {
            return false
        }
        let days = Calendar.current.dateComponents([.day], from: recordDay, to: todayDate).day ?? 0
        return days > Self.unresolvedTimeoutDays
    }
}
