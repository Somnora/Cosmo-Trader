import Foundation

final class StockTechnicalAnalysisService {
    static let shared = StockTechnicalAnalysisService()

    private let minimumCandlesForSummary = 50
    private let rsiPeriod = 14
    private let recentRangeWindow = 20
    private let supportResistanceWindow = 60
    private let volumeRecentWindow = 10
    private let volumeBaselineWindow = 30
    private let volatilityWindow = 20

    init() {}

    func summary(
        dataset: HistoricalPriceDataset,
        staleAfter: TimeInterval = HistoricalPriceDataset.defaultStaleInterval
    ) -> StockTechnicalSummary {
        guard dataset.provenance.isProviderBacked else {
            if case .sample = dataset.provenance {
                return StockTechnicalSummary.unavailable(
                    symbol: dataset.symbol,
                    reason: "Sample historical candles are preview-only. Technical metrics are hidden.",
                    provenance: dataset.provenance,
                    displayMode: .sampleOnly
                )
            }

            return StockTechnicalSummary.unavailable(
                symbol: dataset.symbol,
                reason: "Provider-backed historical candles are unavailable.",
                provenance: dataset.provenance,
                displayMode: .unavailable
            )
        }

        if !dataset.completeness.allowsNumericCorrelationClaims {
            switch dataset.completeness {
            case .complete:
                break
            case .partial(let reason):
                return StockTechnicalSummary.unavailable(
                    symbol: dataset.symbol,
                    reason: "Partial historical dataset. \(reason). Technical metrics are hidden.",
                    provenance: .mixed(reason: "Partial historical dataset. \(reason)"),
                    displayMode: .partialDataset
                )
            case .insufficient(let reason):
                return StockTechnicalSummary.unavailable(
                    symbol: dataset.symbol,
                    reason: "Insufficient historical dataset. \(reason). Technical metrics are hidden.",
                    provenance: .unavailable(reason: "Insufficient historical dataset. \(reason)"),
                    displayMode: .insufficientDataset
                )
            }
        }

        let candles = validCandles(from: dataset.ohlcData)
        guard candles.count >= minimumCandlesForSummary else {
            return StockTechnicalSummary.unavailable(
                symbol: dataset.symbol,
                reason: "At least \(minimumCandlesForSummary) provider-backed daily candles are needed for technical context.",
                provenance: .unavailable(reason: "Insufficient provider-backed daily candle history"),
                displayMode: .insufficientDataset
            )
        }

        let closes = candles.map(\.close)
        let ma20 = movingAverage(closes, period: 20)
        let ma50 = movingAverage(closes, period: 50)
        let ma200 = movingAverage(closes, period: 200)
        let rsi = relativeStrengthIndex(closes: closes, period: rsiPeriod)
        let volumeRatio = volumeTrendRatio(candles: candles)
        let volatility = annualizedVolatilityPercent(closes: closes)
        let recentRange = recentRange(candles: candles)
        let supportResistance = supportResistanceCandidates(candles: candles)
        let latestClose = closes.last ?? 0

        return StockTechnicalSummary(
            symbol: dataset.symbol.uppercased(),
            timeframeLabel: "1Y",
            candleCount: candles.count,
            provenance: dataset.provenance,
            completeness: dataset.completeness,
            displayMode: .providerBacked,
            movingAverage20: ma20,
            movingAverage50: ma50,
            movingAverage200: ma200,
            rsi14: rsi,
            volumeTrendRatio: volumeRatio,
            annualizedVolatility: volatility,
            recentRangeLow: recentRange?.low,
            recentRangeHigh: recentRange?.high,
            supportCandidate: supportResistance?.support,
            resistanceCandidate: supportResistance?.resistance,
            trendContext: trendContext(latestClose: latestClose, ma20: ma20, ma50: ma50, ma200: ma200),
            momentumContext: momentumContext(rsi: rsi),
            volumeContext: volumeContext(ratio: volumeRatio),
            volatilityContext: volatilityContext(annualizedVolatility: volatility),
            rangeContext: rangeContext(range: recentRange),
            explanation: "Computed from complete provider-backed daily candles. Cached data remains labeled with freshness.",
            disclaimer: StockTechnicalSummary.standardDisclaimer
        )
    }

    private func validCandles(from candles: [OHLCData]) -> [OHLCData] {
        candles
            .filter { candle in
                candle.open.isFinite
                    && candle.high.isFinite
                    && candle.low.isFinite
                    && candle.close.isFinite
                    && candle.open > 0
                    && candle.high > 0
                    && candle.low > 0
                    && candle.close > 0
            }
            .sorted { $0.date < $1.date }
    }

    private func movingAverage(_ values: [Double], period: Int) -> Double? {
        guard values.count >= period else { return nil }
        return average(Array(values.suffix(period)))
    }

    private func relativeStrengthIndex(closes: [Double], period: Int) -> Double? {
        guard closes.count > period else { return nil }

        let window = Array(closes.suffix(period + 1))
        var gains: [Double] = []
        var losses: [Double] = []

        for index in 1..<window.count {
            let change = window[index] - window[index - 1]
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }

        let averageGain = average(gains)
        let averageLoss = average(losses)
        guard averageLoss > 0 else { return 100 }

        let relativeStrength = averageGain / averageLoss
        return 100 - (100 / (1 + relativeStrength))
    }

    private func volumeTrendRatio(candles: [OHLCData]) -> Double? {
        let required = volumeRecentWindow + volumeBaselineWindow
        guard candles.count >= required else { return nil }

        let recentVolumes = candles.suffix(volumeRecentWindow).map { Double($0.volume) }.filter { $0 > 0 }
        let baselineVolumes = candles
            .dropLast(volumeRecentWindow)
            .suffix(volumeBaselineWindow)
            .map { Double($0.volume) }
            .filter { $0 > 0 }

        guard recentVolumes.count == volumeRecentWindow,
              baselineVolumes.count == volumeBaselineWindow else { return nil }

        let baseline = average(baselineVolumes)
        guard baseline > 0 else { return nil }
        return average(recentVolumes) / baseline
    }

    private func annualizedVolatilityPercent(closes: [Double]) -> Double? {
        guard closes.count > volatilityWindow else { return nil }

        let recent = Array(closes.suffix(volatilityWindow + 1))
        let returns = (1..<recent.count).compactMap { index -> Double? in
            let prior = recent[index - 1]
            guard prior > 0 else { return nil }
            return (recent[index] - prior) / prior
        }
        guard returns.count >= volatilityWindow else { return nil }

        let mean = average(returns)
        let variance = returns.reduce(0) { partial, value in
            let delta = value - mean
            return partial + delta * delta
        } / Double(max(returns.count - 1, 1))

        return sqrt(variance) * sqrt(252) * 100
    }

    private func recentRange(candles: [OHLCData]) -> (low: Double, high: Double)? {
        guard candles.count >= recentRangeWindow else { return nil }
        let recent = candles.suffix(recentRangeWindow)
        guard let low = recent.map(\.low).min(),
              let high = recent.map(\.high).max() else { return nil }
        return (low, high)
    }

    private func supportResistanceCandidates(candles: [OHLCData]) -> (support: Double, resistance: Double)? {
        guard candles.count >= supportResistanceWindow else { return nil }
        let recent = candles.suffix(supportResistanceWindow)
        guard let support = recent.map(\.low).min(),
              let resistance = recent.map(\.high).max(),
              support < resistance else { return nil }
        return (support, resistance)
    }

    private func trendContext(latestClose: Double, ma20: Double?, ma50: Double?, ma200: Double?) -> String {
        guard let ma20, let ma50 else {
            return "Moving-average context needs more provider-backed daily candles."
        }

        if latestClose >= ma20 && ma20 >= ma50 {
            if let ma200, latestClose >= ma200 {
                return "Price is above the 20D, 50D, and 200D averages. The technical lens shows firm recent trend context."
            }
            return "Price is above the 20D and 50D averages. The technical lens shows firm recent trend context."
        }

        if latestClose < ma20 && ma20 < ma50 {
            if let ma200, latestClose < ma200 {
                return "Price is below the 20D, 50D, and 200D averages. The technical lens shows soft recent trend context."
            }
            return "Price is below the 20D and 50D averages. The technical lens shows soft recent trend context."
        }

        return "Moving averages are mixed. The technical lens shows an uneven recent trend context."
    }

    private func momentumContext(rsi: Double?) -> String {
        guard let rsi else {
            return "RSI needs at least 14 provider-backed closes."
        }

        if rsi >= 70 {
            return "RSI is elevated. Read it as momentum context, not an instruction."
        }

        if rsi <= 30 {
            return "RSI is compressed. Read it as momentum context, not an instruction."
        }

        return "RSI sits in a middle zone. Momentum context is balanced over the recent window."
    }

    private func volumeContext(ratio: Double?) -> String {
        guard let ratio else {
            return "Volume context needs recent and baseline provider-backed volume history."
        }

        if ratio >= 1.25 {
            return "Recent volume is above its 30-session baseline. Participation context is elevated."
        }

        if ratio <= 0.75 {
            return "Recent volume is below its 30-session baseline. Participation context is quieter."
        }

        return "Recent volume is close to its 30-session baseline. Participation context is steady."
    }

    private func volatilityContext(annualizedVolatility: Double?) -> String {
        guard let annualizedVolatility else {
            return "Volatility context needs at least 20 provider-backed daily returns."
        }

        if annualizedVolatility >= 40 {
            return "Recent realized volatility is elevated relative to a calmer tape."
        }

        if annualizedVolatility <= 20 {
            return "Recent realized volatility is comparatively quiet."
        }

        return "Recent realized volatility is moderate."
    }

    private func rangeContext(range: (low: Double, high: Double)?) -> String {
        guard let range else {
            return "Recent range context needs at least 20 provider-backed candles."
        }

        return "Last 20 sessions traded between \(StockTechnicalSummary.currency(range.low)) and \(StockTechnicalSummary.currency(range.high))."
    }

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}
