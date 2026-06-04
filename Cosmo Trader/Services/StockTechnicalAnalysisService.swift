import Foundation

nonisolated enum StockTechnicalDisplayMode: Equatable {
    case providerBacked
    case staleProviderBacked
    case partialDataset
    case insufficientDataset
    case unavailable
    case sampleOnly

    var allowsNumericMetrics: Bool {
        switch self {
        case .providerBacked, .staleProviderBacked:
            return true
        case .partialDataset, .insufficientDataset, .unavailable, .sampleOnly:
            return false
        }
    }
}

nonisolated struct StockTechnicalSummary: Equatable {
    static let unavailableTitle = "Technical context unavailable"
    static let disclaimer = "Historical technical context only. Not financial advice."

    let symbol: String
    let asOf: Date?
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness
    let displayMode: StockTechnicalDisplayMode
    let latestClose: Double?
    let movingAverage20: Double?
    let movingAverage50: Double?
    let rsi14: Double?
    let latestVolume: Int?
    let averageVolume20: Double?
    let volumeRatio20: Double?
    let averageAbsoluteMove20: Double?
    let recentRangeLow: Double?
    let recentRangeHigh: Double?
    let supportCandidate: Double?
    let resistanceCandidate: Double?
    let trendContext: String
    let momentumContext: String
    let volumeContext: String
    let volatilityContext: String
    let rangeContext: String
    let explanation: String

    var canShowNumericMetrics: Bool {
        displayMode.allowsNumericMetrics
    }

    var unavailableDetail: String {
        switch displayMode {
        case .providerBacked, .staleProviderBacked:
            return "Some technical fields need more provider-backed candles before they appear."
        case .partialDataset:
            return "Provider-backed history is partial. Technical metrics stay hidden until the historical dataset is complete."
        case .insufficientDataset:
            return "Provider-backed history is insufficient. Technical context will appear when more candles are available."
        case .sampleOnly:
            return "Sample history is not used for technical analysis."
        case .unavailable:
            return "Provider-backed historical candles are unavailable. Technical context will appear when enough history is available."
        }
    }

    var freshnessLabel: String {
        switch provenance {
        case .live(let provider, _):
            return "\(provider) live history"
        case .cached(let provider, _, _):
            return provenance.isCachedStale() ? "\(provider) stale cached history" : "\(provider) cached history"
        case .mixed:
            return "Mixed historical data"
        case .unavailable:
            return "Historical data unavailable"
        case .sample:
            return "Sample history"
        }
    }

    static func unavailable(
        symbol: String,
        reason: String = "Provider-backed historical candles unavailable",
        provenance: FinancialDataProvenance? = nil,
        completeness: HistoricalDatasetCompleteness = .insufficient(reason: "Provider-backed historical candles unavailable")
    ) -> StockTechnicalSummary {
        StockTechnicalSummary(
            symbol: symbol.uppercased(),
            asOf: nil,
            provenance: provenance ?? .unavailable(reason: reason),
            completeness: completeness,
            displayMode: .unavailable,
            latestClose: nil,
            movingAverage20: nil,
            movingAverage50: nil,
            rsi14: nil,
            latestVolume: nil,
            averageVolume20: nil,
            volumeRatio20: nil,
            averageAbsoluteMove20: nil,
            recentRangeLow: nil,
            recentRangeHigh: nil,
            supportCandidate: nil,
            resistanceCandidate: nil,
            trendContext: "Trend context needs provider-backed candles.",
            momentumContext: "Momentum context needs provider-backed candles.",
            volumeContext: "Volume context needs provider-backed candles.",
            volatilityContext: "Volatility context needs provider-backed candles.",
            rangeContext: "Recent range context needs provider-backed candles.",
            explanation: "Provider-backed history is required before technical metrics are shown."
        )
    }
}

final class StockTechnicalAnalysisService {
    static let shared = StockTechnicalAnalysisService()

    private let rsiPeriod = 14
    private let shortMovingAveragePeriod = 20
    private let longMovingAveragePeriod = 50
    private let recentRangePeriod = 20
    private let supportResistancePeriod = 60

    init() {}

    func summary(symbol: String, dataset: HistoricalPriceDataset) -> StockTechnicalSummary {
        let normalizedSymbol = symbol.uppercased()
        let displayMode = displayMode(for: dataset)

        guard displayMode.allowsNumericMetrics else {
            return unavailableSummary(
                symbol: normalizedSymbol,
                dataset: dataset,
                displayMode: displayMode
            )
        }

        let candles = normalizedCandles(dataset.ohlcData)
        let closes = candles.map(\.close)
        let latestClose = closes.last
        let movingAverage20 = movingAverage(closes, period: shortMovingAveragePeriod)
        let movingAverage50 = movingAverage(closes, period: longMovingAveragePeriod)
        let rsi14 = rsi(closes, period: rsiPeriod)
        let latestVolume = candles.last?.volume
        let averageVolume20 = averageVolume(candles, period: shortMovingAveragePeriod)
        let volumeRatio20 = ratio(numerator: latestVolume.map(Double.init), denominator: averageVolume20)
        let averageAbsoluteMove20 = averageAbsoluteReturn(candles, period: recentRangePeriod)
        let recentRange = priceRange(candles, period: recentRangePeriod)
        let levels = supportResistance(candles, period: supportResistancePeriod)

        return StockTechnicalSummary(
            symbol: normalizedSymbol,
            asOf: candles.last?.date,
            provenance: dataset.provenance,
            completeness: dataset.completeness,
            displayMode: displayMode,
            latestClose: latestClose,
            movingAverage20: movingAverage20,
            movingAverage50: movingAverage50,
            rsi14: rsi14,
            latestVolume: latestVolume,
            averageVolume20: averageVolume20,
            volumeRatio20: volumeRatio20,
            averageAbsoluteMove20: averageAbsoluteMove20,
            recentRangeLow: recentRange?.low,
            recentRangeHigh: recentRange?.high,
            supportCandidate: levels?.support,
            resistanceCandidate: levels?.resistance,
            trendContext: trendContext(latestClose: latestClose, ma20: movingAverage20, ma50: movingAverage50),
            momentumContext: momentumContext(rsi: rsi14),
            volumeContext: volumeContext(volumeRatio: volumeRatio20),
            volatilityContext: volatilityContext(averageAbsoluteMove: averageAbsoluteMove20),
            rangeContext: rangeContext(range: recentRange, levels: levels),
            explanation: "Provider-backed candles power this technical lens. Values are historical context, not instructions."
        )
    }

    private func displayMode(for dataset: HistoricalPriceDataset) -> StockTechnicalDisplayMode {
        guard dataset.provenance.isProviderBacked else {
            if case .sample = dataset.provenance {
                return .sampleOnly
            }
            return .unavailable
        }

        guard dataset.completeness.allowsNumericCorrelationClaims else {
            switch dataset.completeness {
            case .complete:
                return .unavailable
            case .partial:
                return .partialDataset
            case .insufficient:
                return .insufficientDataset
            }
        }

        if dataset.provenance.isCachedStale() {
            return .staleProviderBacked
        }

        return .providerBacked
    }

    private func unavailableSummary(
        symbol: String,
        dataset: HistoricalPriceDataset,
        displayMode: StockTechnicalDisplayMode
    ) -> StockTechnicalSummary {
        let reason: String
        switch displayMode {
        case .partialDataset:
            reason = dataset.completeness.reason ?? "Partial historical dataset"
        case .insufficientDataset:
            reason = dataset.completeness.reason ?? "Insufficient historical dataset"
        case .sampleOnly:
            reason = "Sample history is not used for technical metrics"
        case .unavailable:
            reason = "Provider-backed historical candles unavailable"
        case .providerBacked, .staleProviderBacked:
            reason = "Technical metrics unavailable"
        }

        return StockTechnicalSummary(
            symbol: symbol,
            asOf: nil,
            provenance: dataset.correlationDisplayProvenance,
            completeness: dataset.completeness,
            displayMode: displayMode,
            latestClose: nil,
            movingAverage20: nil,
            movingAverage50: nil,
            rsi14: nil,
            latestVolume: nil,
            averageVolume20: nil,
            volumeRatio20: nil,
            averageAbsoluteMove20: nil,
            recentRangeLow: nil,
            recentRangeHigh: nil,
            supportCandidate: nil,
            resistanceCandidate: nil,
            trendContext: "Trend context needs complete provider-backed candles.",
            momentumContext: "Momentum context needs complete provider-backed candles.",
            volumeContext: "Volume context needs complete provider-backed candles.",
            volatilityContext: "Volatility context needs complete provider-backed candles.",
            rangeContext: "Recent range context needs complete provider-backed candles.",
            explanation: "\(reason). No numeric technical claim is shown."
        )
    }

    private func normalizedCandles(_ candles: [OHLCData]) -> [OHLCData] {
        candles
            .filter { candle in
                candle.open.isFinite
                    && candle.high.isFinite
                    && candle.low.isFinite
                    && candle.close.isFinite
                    && candle.close > 0
            }
            .sorted { $0.date < $1.date }
    }

    private func movingAverage(_ closes: [Double], period: Int) -> Double? {
        guard closes.count >= period else { return nil }
        let values = closes.suffix(period)
        return values.reduce(0, +) / Double(period)
    }

    private func rsi(_ closes: [Double], period: Int) -> Double? {
        guard closes.count >= period + 1 else { return nil }
        let recent = closes.suffix(period + 1)
        let changes = zip(recent, recent.dropFirst()).map { current, next in next - current }
        let gains = changes.map { max($0, 0) }
        let losses = changes.map { abs(min($0, 0)) }
        let averageGain = gains.reduce(0, +) / Double(period)
        let averageLoss = losses.reduce(0, +) / Double(period)

        if averageLoss == 0 {
            return averageGain == 0 ? 50 : 100
        }

        let relativeStrength = averageGain / averageLoss
        return 100 - (100 / (1 + relativeStrength))
    }

    private func averageVolume(_ candles: [OHLCData], period: Int) -> Double? {
        guard candles.count >= period else { return nil }
        let volumes = candles.suffix(period).map(\.volume).filter { $0 > 0 }
        guard volumes.count == period else { return nil }
        return Double(volumes.reduce(0, +)) / Double(period)
    }

    private func averageAbsoluteReturn(_ candles: [OHLCData], period: Int) -> Double? {
        guard candles.count >= period + 1 else { return nil }
        let recent = candles.suffix(period + 1)
        let returns = zip(recent, recent.dropFirst()).compactMap { previous, current -> Double? in
            guard previous.close > 0 else { return nil }
            return abs((current.close - previous.close) / previous.close) * 100
        }
        guard returns.count == period else { return nil }
        return returns.reduce(0, +) / Double(period)
    }

    private func priceRange(_ candles: [OHLCData], period: Int) -> (low: Double, high: Double)? {
        guard candles.count >= 2 else { return nil }
        let recent = candles.suffix(min(period, candles.count))
        guard let low = recent.map(\.low).min(),
              let high = recent.map(\.high).max() else {
            return nil
        }
        return (low, high)
    }

    private func supportResistance(_ candles: [OHLCData], period: Int) -> (support: Double, resistance: Double)? {
        guard candles.count >= period else { return nil }
        let recent = candles.suffix(period)
        guard let support = recent.map(\.low).min(),
              let resistance = recent.map(\.high).max(),
              support > 0,
              resistance > support else {
            return nil
        }
        return (support, resistance)
    }

    private func ratio(numerator: Double?, denominator: Double?) -> Double? {
        guard let numerator,
              let denominator,
              denominator > 0 else {
            return nil
        }
        return numerator / denominator
    }

    private func trendContext(latestClose: Double?, ma20: Double?, ma50: Double?) -> String {
        guard let latestClose, let ma20, let ma50 else {
            return "Moving-average context needs more provider-backed candles."
        }

        if latestClose >= ma20 && ma20 >= ma50 {
            return "Price is above its 20-session and 50-session averages, a constructive historical trend context."
        }

        if latestClose <= ma20 && ma20 <= ma50 {
            return "Price is below its 20-session and 50-session averages, a cooler historical trend context."
        }

        return "Price is between key moving averages, a mixed historical trend context."
    }

    private func momentumContext(rsi: Double?) -> String {
        guard let rsi else {
            return "RSI context needs at least 15 provider-backed candles."
        }

        switch rsi {
        case 70...:
            return "RSI is elevated. Treat momentum as stretched historical context."
        case ...30:
            return "RSI is cooled. Treat momentum as compressed historical context."
        default:
            return "RSI sits in a middle band, suggesting balanced historical momentum context."
        }
    }

    private func volumeContext(volumeRatio: Double?) -> String {
        guard let volumeRatio else {
            return "Volume context needs at least 20 provider-backed candles with valid volume."
        }

        if volumeRatio >= 1.25 {
            return "Latest volume is above its 20-session average, so participation is elevated."
        }

        if volumeRatio <= 0.75 {
            return "Latest volume is below its 20-session average, so participation is quieter."
        }

        return "Latest volume is near its 20-session average."
    }

    private func volatilityContext(averageAbsoluteMove: Double?) -> String {
        guard let averageAbsoluteMove else {
            return "Volatility context needs at least 21 provider-backed candles."
        }

        if averageAbsoluteMove >= 3 {
            return "Recent candles show a wider average daily move than usual for a calm tape."
        }

        if averageAbsoluteMove <= 1 {
            return "Recent candles show a tighter average daily move."
        }

        return "Recent candles show moderate average daily movement."
    }

    private func rangeContext(
        range: (low: Double, high: Double)?,
        levels: (support: Double, resistance: Double)?
    ) -> String {
        guard let range else {
            return "Recent range context needs provider-backed high and low candles."
        }

        if levels != nil {
            return "Recent range and candidate support/resistance levels come from observed provider candles."
        }

        return "Recent range spans \(Self.formatPrice(range.low)) to \(Self.formatPrice(range.high)); more candles improve level context."
    }

    nonisolated static func formatPrice(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}
