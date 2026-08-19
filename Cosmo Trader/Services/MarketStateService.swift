import Foundation

// MARK: - MarketStateService
// ==========================
// Where the market IS, with historical context — not where it is going.
//
// Two independent sweeps over twenty years of daily data say the same thing:
// neither lunar phase nor any classic technical state predicts SPY's next week
// once overlapping windows are discounted and multiple comparisons corrected.
// So this service does not forecast. It measures the present against the
// record, states how unusual the present is, and reports how the sessions that
// looked like this one actually went afterwards — including, almost always,
// that the difference is too small to separate from an ordinary session.
//
// That last part is the product. Saying "no different from any other day" out
// loud is the thing nothing else in this category will do.

/// One measured fact about where the market stands right now.
nonisolated struct MarketStateReading: Identifiable, Equatable {
    let id: String
    let label: String
    let value: String
    /// How unusual this reading is against the whole record.
    let context: String
    /// Share of past sessions whose value sat below this one, 0...1. Carried
    /// as a number so the view can rank or tint without re-parsing `context`.
    let shareBelow: Double
}

/// How the sessions that looked like this one actually went afterwards.
///
/// Every field is a measurement over the symbol's own history. Nothing here
/// is an estimate of the future, and `isDistinguishableFromOrdinary` exists so
/// the copy can say plainly when the answer is "this looks like any other day".
nonisolated struct MarketStateHistory: Equatable {
    let conditionLabel: String
    let matchedSessions: Int
    let horizonSessions: Int
    let matchedAveragePercent: Double
    let ordinaryAveragePercent: Double
    let matchedUpRate: Double
    let ordinaryUpRate: Double
    /// 95% half-width on the difference of the two averages.
    let differenceHalfWidthPercent: Double

    var differencePercent: Double {
        matchedAveragePercent - ordinaryAveragePercent
    }

    /// True only when the gap is wider than its own uncertainty. Expect false
    /// most of the time; that is the measured reality, not a bug.
    var isDistinguishableFromOrdinary: Bool {
        abs(differencePercent) > differenceHalfWidthPercent
    }
}

nonisolated struct MarketStateSnapshot: Equatable {
    let symbol: String
    let asOfDate: Date
    let firstSessionDate: Date
    let sessionCount: Int
    let readings: [MarketStateReading]
    let history: MarketStateHistory?
    let provenance: FinancialDataProvenance
}

nonisolated enum MarketStateService {

    static let shortHighLookback = 20
    static let longHighLookback = 252
    static let meanLookback = 50
    static let shortVolatilityLookback = 20
    static let longVolatilityLookback = 252
    static let trailingReturnLookback = 5

    /// Forward horizon for the historical comparison, in sessions. One week.
    static let forwardHorizonSessions = 5

    /// Roughly a year of sessions. Below this the percentile context is a
    /// story about one market regime rather than about the record.
    static let minimumSessions = 260

    /// Below this many comparable sessions there is no comparison worth
    /// printing, and `history` is nil rather than a number built from scraps.
    static let minimumMatchedSessions = 40

    /// Drawdown bands for the historical comparison.
    ///
    /// The condition variable is FIXED to drawdown-from-the-20-day-high and
    /// the cut points are fixed here, deliberately. Choosing whichever reading
    /// looks most dramatic today, then reporting how special it is, is exactly
    /// the selection bias that manufactures findings out of noise. The app asks
    /// the same question every day and lives with whatever answer comes back.
    static let deepDrawdownPercent = -5.0
    static let nearHighPercent = -0.5

    static func snapshot(
        symbol: String,
        prices: [OHLCData],
        provenance: FinancialDataProvenance
    ) -> MarketStateSnapshot? {
        let candles = prices
            .filter { $0.close.isFinite && $0.close > 0 }
            .sorted { $0.date < $1.date }

        guard candles.count >= minimumSessions,
              let latest = candles.last,
              let earliest = candles.first else { return nil }

        let closes = candles.map(\.close)
        let series = seriesValues(closes: closes)

        let readings = series.compactMap { definition -> MarketStateReading? in
            guard let last = definition.values.last, let current = last else { return nil }
            return reading(
                id: definition.id,
                label: definition.label,
                current: current,
                values: definition.values.compactMap { $0 },
                format: definition.format,
                since: earliest.date
            )
        }

        return MarketStateSnapshot(
            symbol: symbol.uppercased(),
            asOfDate: latest.date,
            firstSessionDate: earliest.date,
            sessionCount: candles.count,
            readings: readings,
            history: history(closes: closes),
            provenance: provenance
        )
    }

    // MARK: - Readings

    private struct SeriesDefinition {
        let id: String
        let label: String
        let values: [Double?]
        let format: (Double) -> String
    }

    private static func seriesValues(closes: [Double]) -> [SeriesDefinition] {
        let percent: (Double) -> String = { String(format: "%+.1f%%", $0) }

        return [
            SeriesDefinition(
                id: "drawdown20",
                label: "FROM 20D HIGH",
                values: drawdown(closes: closes, lookback: shortHighLookback),
                format: percent
            ),
            SeriesDefinition(
                id: "drawdown252",
                label: "FROM 1Y HIGH",
                values: drawdown(closes: closes, lookback: longHighLookback),
                format: percent
            ),
            SeriesDefinition(
                id: "mean50",
                label: "VS 50D AVERAGE",
                values: distanceFromMean(closes: closes, lookback: meanLookback),
                format: percent
            ),
            SeriesDefinition(
                id: "trailing5",
                label: "PAST WEEK",
                values: trailingReturn(closes: closes, lookback: trailingReturnLookback),
                format: percent
            ),
            SeriesDefinition(
                id: "volatility",
                label: "VOLATILITY",
                values: volatilityRatio(closes: closes),
                format: { String(format: "%.2fx 1Y", $0) }
            )
        ]
    }

    private static func reading(
        id: String,
        label: String,
        current: Double,
        values: [Double],
        format: (Double) -> String,
        since: Date
    ) -> MarketStateReading {
        let below = values.filter { $0 < current }.count
        let share = values.isEmpty ? 0 : Double(below) / Double(values.count)
        let year = Calendar.current.component(.year, from: since)

        let context: String
        if share >= 0.5 {
            context = String(format: "Higher than %.0f%% of sessions since %d.", share * 100, year)
        } else {
            context = String(format: "Lower than %.0f%% of sessions since %d.", (1 - share) * 100, year)
        }

        return MarketStateReading(
            id: id,
            label: label,
            value: format(current),
            context: context,
            shareBelow: share
        )
    }

    // MARK: - Historical comparison

    private static func history(closes: [Double]) -> MarketStateHistory? {
        let drawdowns = drawdown(closes: closes, lookback: shortHighLookback)
        guard let last = drawdowns.last, let currentDrawdown = last else { return nil }

        let horizon = forwardHorizonSessions
        let currentBand = band(for: currentDrawdown)

        var matched: [Double] = []
        var ordinary: [Double] = []

        for index in 0..<(closes.count - horizon) {
            guard let value = drawdowns[index], closes[index] > 0 else { continue }
            let forward = (closes[index + horizon] / closes[index] - 1) * 100
            if band(for: value) == currentBand {
                matched.append(forward)
            } else {
                ordinary.append(forward)
            }
        }

        guard matched.count >= minimumMatchedSessions,
              ordinary.count >= minimumMatchedSessions else { return nil }

        return MarketStateHistory(
            conditionLabel: currentBand.label,
            matchedSessions: matched.count,
            horizonSessions: horizon,
            matchedAveragePercent: mean(matched),
            ordinaryAveragePercent: mean(ordinary),
            matchedUpRate: upRate(matched),
            ordinaryUpRate: upRate(ordinary),
            differenceHalfWidthPercent: halfWidth(matched: matched, ordinary: ordinary, horizon: horizon)
        )
    }

    private enum DrawdownBand: Equatable {
        case deep
        case middling
        case nearHigh

        var label: String {
            switch self {
            case .deep:
                return "more than 5% below its 20-day high"
            case .middling:
                return "modestly below its 20-day high"
            case .nearHigh:
                return "at or near its 20-day high"
            }
        }
    }

    private static func band(for drawdown: Double) -> DrawdownBand {
        if drawdown <= deepDrawdownPercent { return .deep }
        if drawdown >= nearHighPercent { return .nearHigh }
        return .middling
    }

    /// 95% half-width on the difference between the two averages.
    ///
    /// Forward windows sampled every session overlap by `horizon - 1` days, so
    /// the raw counts badly overstate how much independent evidence there is.
    /// Dividing by the horizon approximates the number of non-overlapping
    /// windows. Skipping this step roughly doubles every t-statistic and is
    /// how a run of ordinary weeks starts looking like a discovery.
    private static func halfWidth(matched: [Double], ordinary: [Double], horizon: Int) -> Double {
        let effectiveMatched = max(1, matched.count / horizon)
        let effectiveOrdinary = max(1, ordinary.count / horizon)
        let standardError = (
            pow(standardDeviation(matched), 2) / Double(effectiveMatched)
            + pow(standardDeviation(ordinary), 2) / Double(effectiveOrdinary)
        ).squareRoot()
        return 1.96 * standardError
    }

    // MARK: - Series builders

    private static func drawdown(closes: [Double], lookback: Int) -> [Double?] {
        rolling(closes: closes, lookback: lookback) { window, current in
            guard let peak = window.max(), peak > 0 else { return nil }
            return (current / peak - 1) * 100
        }
    }

    private static func distanceFromMean(closes: [Double], lookback: Int) -> [Double?] {
        rolling(closes: closes, lookback: lookback) { window, current in
            let average = mean(window)
            guard average > 0 else { return nil }
            return (current / average - 1) * 100
        }
    }

    private static func trailingReturn(closes: [Double], lookback: Int) -> [Double?] {
        closes.indices.map { index in
            guard index >= lookback, closes[index - lookback] > 0 else { return nil }
            return (closes[index] / closes[index - lookback] - 1) * 100
        }
    }

    private static func volatilityRatio(closes: [Double]) -> [Double?] {
        let daily = dailyReturns(closes: closes)
        return closes.indices.map { index in
            guard index >= longVolatilityLookback else { return nil }
            let short = Array(daily[(index - shortVolatilityLookback)..<index])
            let long = Array(daily[(index - longVolatilityLookback)..<index])
            let longDeviation = standardDeviation(long)
            guard longDeviation > 0 else { return nil }
            return standardDeviation(short) / longDeviation
        }
    }

    /// Day-over-day percentage returns, aligned so `daily[i]` is the move into
    /// candle `i`. The first entry is zero because there is nothing before it.
    private static func dailyReturns(closes: [Double]) -> [Double] {
        closes.indices.map { index in
            guard index > 0, closes[index - 1] > 0 else { return 0 }
            return (closes[index] / closes[index - 1] - 1) * 100
        }
    }

    private static func rolling(
        closes: [Double],
        lookback: Int,
        transform: (ArraySlice<Double>, Double) -> Double?
    ) -> [Double?] {
        closes.indices.map { index in
            guard index >= lookback - 1 else { return nil }
            return transform(closes[(index - lookback + 1)...index], closes[index])
        }
    }

    // MARK: - Statistics

    private static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func mean(_ values: ArraySlice<Double>) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let average = mean(values)
        let variance = values.reduce(0) { $0 + pow($1 - average, 2) } / Double(values.count - 1)
        return variance.squareRoot()
    }

    private static func upRate(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return Double(values.filter { $0 > 0 }.count) / Double(values.count)
    }
}
