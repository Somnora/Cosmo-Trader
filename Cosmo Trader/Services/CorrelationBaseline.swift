import Foundation

// MARK: - CorrelationBaseline
// ===========================
// What an ordinary stretch of this market did — measured the same way the
// event windows were measured, over candles no event window touched.
//
// Three services used to carry their own private copy of the baseline, and all
// three copies were wrong the same two ways:
//
//   1. Contamination. The baseline averaged daily returns across the ENTIRE
//      series, so every event sat inside its own control group. The more the
//      events mattered, the more they dragged the thing they were supposed to
//      be compared against, and the smaller the measured edge looked.
//   2. Estimator mismatch. The baseline was `mean daily return x window size`,
//      while the event statistic is a point-to-point return over the window.
//      Those are different quantities with different variance, so the two
//      numbers were never comparable even before the contamination.
//
// This type fixes both: same estimator, event windows removed, and `nil`
// rather than a manufactured zero when there is not enough clean history to
// compare against.

nonisolated struct CorrelationBaseline: Equatable {
    /// Mean point-to-point return across every clean window, in percent.
    let averageReturnPercent: Double
    /// Share of clean windows that closed higher than they opened, 0...1.
    /// This is the base rate the event win rate has to beat to mean anything.
    ///
    /// Optional because callers that aggregate across several series can
    /// compute a comparable average return but not a comparable up-rate — a
    /// win rate is not linear in the weights. Those callers pass nil rather
    /// than a blended number that answers a different question.
    let winRate: Double?
    /// Standard deviation of daily returns across clean candles, in percent.
    let volatilityPercent: Double
    /// How many clean windows the estimate is built from.
    let windowCount: Int
    /// Candles per window — the same length as the event windows it answers.
    let windowLength: Int
}

nonisolated enum CorrelationBaselineCalculator {

    /// Below this many clean windows there is no baseline worth printing, so
    /// the calculator returns nil and the summary reports the comparison as
    /// unavailable. Callers must treat nil as "no comparison" and never
    /// substitute zero — a zero baseline silently turns every event return
    /// into an apparent edge.
    static let minimumWindowCount = 20

    /// A 95% half-width at or under this many percentage points is precise
    /// enough to call the sample strong, given enough observations.
    static let strongPrecisionPercent = 0.75

    /// The same test, relaxed, for a useful-but-not-strong sample.
    static let moderatePrecisionPercent = 1.5

    /// The baseline for one event kind.
    ///
    /// `excludedIntervals` should be the price windows of the kind being
    /// measured, and only that kind: the control is "market without these
    /// events", not "market without anything the app draws". Excluding every
    /// kind at once compounds the exclusions until the baseline is built from
    /// whatever calendar scraps are left.
    static func baseline(
        prices: [OHLCData],
        excluding excludedIntervals: [DateInterval],
        windowLength: Int
    ) -> CorrelationBaseline? {
        let candles = prices
            .filter { $0.close.isFinite && $0.close > 0 }
            .sorted { $0.date < $1.date }

        // Two candles is the floor for a return, and it matches the guard
        // `eventReactions` applies before it will report an event at all.
        let length = max(2, windowLength)
        guard candles.count >= length else { return nil }

        let excluded = exclusionFlags(for: candles, intervals: merge(excludedIntervals))
        let windowReturns = cleanWindowReturns(candles: candles, excluded: excluded, length: length)

        guard windowReturns.count >= minimumWindowCount else { return nil }

        let wins = windowReturns.filter { $0 > 0 }.count

        return CorrelationBaseline(
            averageReturnPercent: mean(windowReturns),
            winRate: Double(wins) / Double(windowReturns.count),
            volatilityPercent: populationStandardDeviation(
                cleanDailyReturns(candles: candles, excluded: excluded)
            ),
            windowCount: windowReturns.count,
            windowLength: length
        )
    }

    /// How well the sample pins down its own average, not merely how many
    /// observations it has.
    ///
    /// Counting alone called twelve wild observations a strong sample. It is
    /// not: an average is only as good as the spread around it, so the grade
    /// pairs a minimum count with the 95% half-width of the mean. A large,
    /// precise sample that finds nothing still reads as strong — that is the
    /// honest outcome, and the one worth showing.
    static func confidence(returns: [Double]) -> CorrelationConfidence {
        let count = returns.count
        guard count >= 3 else { return .insufficient }

        let halfWidth = 1.96 * sampleStandardDeviation(returns) / Double(count).squareRoot()

        if count >= 30, halfWidth <= strongPrecisionPercent { return .strong }
        if count >= 12, halfWidth <= moderatePrecisionPercent { return .moderate }
        return .thin
    }

    // MARK: - Window construction

    /// Point-to-point returns for every window of `length` candles that no
    /// event touched. Walks the clean runs and slides inside them, so a window
    /// straddling an excluded candle is never counted.
    ///
    /// Windows overlap at stride 1 on purpose: the mean and the win rate stay
    /// unbiased, and using every available window makes them as precise as the
    /// history allows. `windowCount` therefore counts windows, not independent
    /// observations, and no interval estimate is derived from it.
    private static func cleanWindowReturns(
        candles: [OHLCData],
        excluded: [Bool],
        length: Int
    ) -> [Double] {
        var returns: [Double] = []
        var runStart = 0

        while runStart < candles.count {
            guard !excluded[runStart] else {
                runStart += 1
                continue
            }

            var runEnd = runStart
            while runEnd + 1 < candles.count, !excluded[runEnd + 1] {
                runEnd += 1
            }

            if runEnd - runStart + 1 >= length {
                for start in runStart...(runEnd - length + 1) {
                    let first = candles[start]
                    let last = candles[start + length - 1]
                    guard first.close > 0 else { continue }
                    returns.append(((last.close - first.close) / first.close) * 100)
                }
            }

            runStart = runEnd + 1
        }

        return returns
    }

    /// Day-over-day returns between adjacent candles that are both clean. An
    /// excluded candle breaks the chain rather than bridging across the event.
    private static func cleanDailyReturns(candles: [OHLCData], excluded: [Bool]) -> [Double] {
        var returns: [Double] = []

        for index in 1..<max(1, candles.count) {
            guard !excluded[index], !excluded[index - 1] else { continue }
            let previous = candles[index - 1]
            guard previous.close > 0 else { continue }
            returns.append(((candles[index].close - previous.close) / previous.close) * 100)
        }

        return returns
    }

    // MARK: - Interval bookkeeping

    private static func merge(_ intervals: [DateInterval]) -> [DateInterval] {
        var merged: [DateInterval] = []

        for interval in intervals.sorted(by: { $0.start < $1.start }) {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1] = DateInterval(
                    start: last.start,
                    end: max(last.end, interval.end)
                )
            } else {
                merged.append(interval)
            }
        }

        return merged
    }

    /// Both sequences are sorted, so one forward pass marks every candle that
    /// falls inside an event window.
    private static func exclusionFlags(for candles: [OHLCData], intervals: [DateInterval]) -> [Bool] {
        var flags = [Bool](repeating: false, count: candles.count)
        guard !intervals.isEmpty else { return flags }

        var cursor = 0
        for (index, candle) in candles.enumerated() {
            while cursor < intervals.count, intervals[cursor].end < candle.date {
                cursor += 1
            }
            guard cursor < intervals.count else { break }
            if intervals[cursor].contains(candle.date) {
                flags[index] = true
            }
        }

        return flags
    }

    // MARK: - Statistics

    private static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Divides by n. Matches how the app reports realized volatility.
    private static func populationStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let average = mean(values)
        let variance = values.reduce(0) { $0 + pow($1 - average, 2) } / Double(values.count)
        return sqrt(variance)
    }

    /// Divides by n - 1. Correct for the standard error of a sample mean,
    /// which is what the confidence grade is built on.
    private static func sampleStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let average = mean(values)
        let variance = values.reduce(0) { $0 + pow($1 - average, 2) } / Double(values.count - 1)
        return sqrt(variance)
    }
}
