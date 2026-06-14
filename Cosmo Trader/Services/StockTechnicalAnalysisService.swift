import Foundation

enum StockTechnicalDisplayMode: Equatable {
    case providerBacked
    case unavailable(reason: String)
    case sampleOnly(reason: String)
    case mixed(reason: String)
    case partial(reason: String)
    case insufficient(reason: String)
    case staleCached
}

struct StockTechnicalSummary: Equatable {
    let symbol: String
    let displayMode: StockTechnicalDisplayMode
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness
    let candleCount: Int
    let metrics: StockTechnicalMetrics?
    let headline: String
    let explanation: String

    var hasNumericClaims: Bool {
        metrics != nil
    }
}

struct StockTechnicalMetrics: Equatable {
    let latestClose: Double
    let movingAverage20: Double?
    let movingAverage50: Double?
    let movingAverage200: Double?
    let rsi14: Double?
    let volumeTrend: StockVolumeTrend?
    let volatility: StockVolatilityContext?
    let recentRange: StockRecentRange?
    let supportResistance: StockSupportResistance?
}

struct StockVolumeTrend: Equatable {
    let recentAverageVolume: Double
    let previousAverageVolume: Double
    let percentDifference: Double

    var label: String {
        if abs(percentDifference) < 3 {
            return "Similar to prior volume"
        }
        return percentDifference > 0 ? "Above prior volume" : "Below prior volume"
    }
}

struct StockVolatilityContext: Equatable {
    let annualizedPercent: Double
    let sampleDays: Int

    var label: String {
        switch annualizedPercent {
        case ..<25:
            return "Lower variance context"
        case 25..<55:
            return "Moderate variance context"
        default:
            return "High variance context"
        }
    }
}

struct StockRecentRange: Equatable {
    let low: Double
    let high: Double
    let sampleDays: Int
}

struct StockSupportResistance: Equatable {
    let supportCandidate: Double
    let resistanceCandidate: Double
    let sampleDays: Int
}

final class StockTechnicalAnalysisService {
    static let shared = StockTechnicalAnalysisService()

    private let minimumCandlesForAnyMetric = 20
    private let rsiPeriod = 14
    private let supportResistanceWindow = 60

    private init() {}

    func summary(for dataset: HistoricalPriceDataset) -> StockTechnicalSummary {
        let displayProvenance = displayProvenance(for: dataset)
        let symbol = dataset.symbol.uppercased()

        guard dataset.provenance.isProviderBacked else {
            return unavailableSummary(
                symbol: symbol,
                displayMode: displayMode(for: dataset.provenance),
                provenance: displayProvenance,
                completeness: dataset.completeness,
                candleCount: dataset.candles.count
            )
        }

        guard !dataset.provenance.isCachedStale() else {
            return unavailableSummary(
                symbol: symbol,
                displayMode: .staleCached,
                provenance: dataset.provenance,
                completeness: dataset.completeness,
                candleCount: dataset.candles.count
            )
        }

        guard case .complete = dataset.completeness else {
            return unavailableSummary(
                symbol: symbol,
                displayMode: completenessDisplayMode(dataset.completeness),
                provenance: displayProvenance,
                completeness: dataset.completeness,
                candleCount: dataset.candles.count
            )
        }

        let candles = validCandles(from: dataset.ohlcData)
        guard candles.count >= minimumCandlesForAnyMetric,
              let latestClose = candles.last?.close,
              latestClose.isFinite,
              latestClose > 0 else {
            return unavailableSummary(
                symbol: symbol,
                displayMode: .insufficient(reason: "Provider returned fewer than \(minimumCandlesForAnyMetric) usable candles"),
                provenance: dataset.provenance,
                completeness: .insufficient(reason: "Provider returned fewer than \(minimumCandlesForAnyMetric) usable candles"),
                candleCount: candles.count
            )
        }

        let closes = candles.map(\.close)
        let metrics = StockTechnicalMetrics(
            latestClose: latestClose,
            movingAverage20: movingAverage(closes, period: 20),
            movingAverage50: movingAverage(closes, period: 50),
            movingAverage200: movingAverage(closes, period: 200),
            rsi14: rsi(candles: candles, period: rsiPeriod),
            volumeTrend: volumeTrend(candles: candles),
            volatility: volatility(candles: candles),
            recentRange: recentRange(candles: candles),
            supportResistance: supportResistance(candles: candles)
        )

        return StockTechnicalSummary(
            symbol: symbol,
            displayMode: .providerBacked,
            provenance: dataset.provenance,
            completeness: .complete,
            candleCount: candles.count,
            metrics: metrics,
            headline: headline(for: metrics),
            explanation: "Technical lens uses provider-backed historical candles only. Read this as historical context, not financial advice."
        )
    }

    func unavailableSummary(symbol: String, reason: String) -> StockTechnicalSummary {
        StockTechnicalSummary(
            symbol: symbol.uppercased(),
            displayMode: .unavailable(reason: reason),
            provenance: .unavailable(reason: reason),
            completeness: .insufficient(reason: reason),
            candleCount: 0,
            metrics: nil,
            headline: "Technical lens unavailable",
            explanation: "Provider-backed complete candles are required before this technical context can show metrics."
        )
    }

    private func unavailableSummary(
        symbol: String,
        displayMode: StockTechnicalDisplayMode,
        provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness,
        candleCount: Int
    ) -> StockTechnicalSummary {
        StockTechnicalSummary(
            symbol: symbol.uppercased(),
            displayMode: displayMode,
            provenance: provenance,
            completeness: completeness,
            candleCount: candleCount,
            metrics: nil,
            headline: title(for: displayMode),
            explanation: explanation(for: displayMode)
        )
    }

    private func displayMode(for provenance: FinancialDataProvenance) -> StockTechnicalDisplayMode {
        switch provenance {
        case .live, .cached:
            return .unavailable(reason: "Provider-backed complete candles are required")
        case .sample(let reason):
            return .sampleOnly(reason: reason)
        case .mixed(let reason):
            return .mixed(reason: reason)
        case .unavailable(let reason):
            return .unavailable(reason: reason)
        }
    }

    private func completenessDisplayMode(_ completeness: HistoricalDatasetCompleteness) -> StockTechnicalDisplayMode {
        switch completeness {
        case .complete:
            return .unavailable(reason: "Provider-backed complete candles are required")
        case .partial(let reason):
            return .partial(reason: reason)
        case .insufficient(let reason):
            return .insufficient(reason: reason)
        }
    }

    private func displayProvenance(for dataset: HistoricalPriceDataset) -> FinancialDataProvenance {
        guard dataset.provenance.isProviderBacked else { return dataset.provenance }
        return dataset.correlationDisplayProvenance
    }

    private func title(for displayMode: StockTechnicalDisplayMode) -> String {
        switch displayMode {
        case .providerBacked:
            return "Technical lens ready"
        case .unavailable:
            return "Technical lens unavailable"
        case .sampleOnly:
            return "Sample data hidden"
        case .mixed:
            return "Mixed data hidden"
        case .partial:
            return "Partial history"
        case .insufficient:
            return "Insufficient history"
        case .staleCached:
            return "Stale cached history"
        }
    }

    private func explanation(for displayMode: StockTechnicalDisplayMode) -> String {
        switch displayMode {
        case .providerBacked:
            return "Technical lens uses provider-backed historical candles only. Read this as historical context, not financial advice."
        case .unavailable(let reason):
            return "\(reason). Load provider-backed history to unlock the technical lens."
        case .sampleOnly:
            return "Sample data is hidden from technical metrics. Provider-backed candles are required."
        case .mixed:
            return "Mixed provenance is not enough for technical metrics. Provider-backed complete candles are required."
        case .partial(let reason):
            return "Partial history is not enough for technical metrics. \(reason)"
        case .insufficient(let reason):
            return "Not enough historical candles for a reliable technical lens. \(reason)"
        case .staleCached:
            return "Cached candles are stale under the current policy. Refresh provider history to recheck."
        }
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
                    && candle.high >= max(candle.open, candle.close)
                    && candle.low <= min(candle.open, candle.close)
                    && candle.high > candle.low
            }
            .sorted { $0.date < $1.date }
    }

    private func movingAverage(_ values: [Double], period: Int) -> Double? {
        guard values.count >= period else { return nil }
        let values = values.suffix(period)
        return values.reduce(0, +) / Double(period)
    }

    private func rsi(candles: [OHLCData], period: Int) -> Double? {
        guard candles.count > period else { return nil }
        let recent = Array(candles.suffix(period + 1))
        var gains: [Double] = []
        var losses: [Double] = []

        for index in 1..<recent.count {
            let change = recent[index].close - recent[index - 1].close
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }

        let averageGain = gains.reduce(0, +) / Double(period)
        let averageLoss = losses.reduce(0, +) / Double(period)

        if averageLoss == 0 {
            return averageGain == 0 ? 50 : 100
        }

        let relativeStrength = averageGain / averageLoss
        return 100 - (100 / (1 + relativeStrength))
    }

    private func volumeTrend(candles: [OHLCData]) -> StockVolumeTrend? {
        guard candles.count >= 20 else { return nil }
        let recent = Array(candles.suffix(10))
        let previous = Array(candles.suffix(20).prefix(10))
        guard recent.allSatisfy({ $0.volume > 0 }),
              previous.allSatisfy({ $0.volume > 0 }) else { return nil }

        let recentAverage = recent.map { Double($0.volume) }.reduce(0, +) / Double(recent.count)
        let previousAverage = previous.map { Double($0.volume) }.reduce(0, +) / Double(previous.count)
        guard previousAverage > 0 else { return nil }

        return StockVolumeTrend(
            recentAverageVolume: recentAverage,
            previousAverageVolume: previousAverage,
            percentDifference: ((recentAverage - previousAverage) / previousAverage) * 100
        )
    }

    private func volatility(candles: [OHLCData]) -> StockVolatilityContext? {
        guard candles.count >= 21 else { return nil }
        let recent = Array(candles.suffix(21))
        var returns: [Double] = []

        for index in 1..<recent.count {
            let previousClose = recent[index - 1].close
            guard previousClose > 0 else { continue }
            returns.append((recent[index].close - previousClose) / previousClose)
        }

        guard returns.count >= 20 else { return nil }
        let average = returns.reduce(0, +) / Double(returns.count)
        let variance = returns
            .map { pow($0 - average, 2) }
            .reduce(0, +) / Double(returns.count)
        let dailyStandardDeviation = sqrt(variance)

        return StockVolatilityContext(
            annualizedPercent: dailyStandardDeviation * sqrt(252) * 100,
            sampleDays: returns.count
        )
    }

    private func recentRange(candles: [OHLCData]) -> StockRecentRange? {
        guard candles.count >= 20 else { return nil }
        let recent = Array(candles.suffix(20))
        guard let low = recent.map(\.low).min(),
              let high = recent.map(\.high).max(),
              low > 0,
              high >= low else { return nil }

        return StockRecentRange(low: low, high: high, sampleDays: recent.count)
    }

    private func supportResistance(candles: [OHLCData]) -> StockSupportResistance? {
        guard candles.count >= supportResistanceWindow else { return nil }
        let recent = Array(candles.suffix(supportResistanceWindow))
        guard let support = recent.map(\.low).min(),
              let resistance = recent.map(\.high).max(),
              support > 0,
              resistance >= support else { return nil }

        return StockSupportResistance(
            supportCandidate: support,
            resistanceCandidate: resistance,
            sampleDays: recent.count
        )
    }

    private func headline(for metrics: StockTechnicalMetrics) -> String {
        var parts: [String] = []

        if let average50 = metrics.movingAverage50 {
            parts.append(metrics.latestClose >= average50 ? "above 50D average" : "below 50D average")
        } else if let average20 = metrics.movingAverage20 {
            parts.append(metrics.latestClose >= average20 ? "above 20D average" : "below 20D average")
        }

        if let rsi = metrics.rsi14 {
            switch rsi {
            case 70...:
                parts.append("RSI elevated")
            case ..<30:
                parts.append("RSI low")
            default:
                parts.append("RSI balanced")
            }
        }

        if parts.isEmpty {
            return "Provider-backed technical context is available."
        }

        return "Technical lens: " + parts.joined(separator: ", ") + "."
    }
}
