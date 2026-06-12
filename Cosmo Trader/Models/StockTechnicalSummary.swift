import Foundation

enum StockTechnicalDisplayMode: Equatable {
    case providerBacked
    case staleDataset
    case partialDataset
    case insufficientDataset
    case unavailable
    case sampleOnly
}

struct StockTechnicalMetric: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
    let detail: String
}

struct StockTechnicalSummary: Equatable {
    let symbol: String
    let timeframeLabel: String
    let candleCount: Int
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness
    let displayMode: StockTechnicalDisplayMode
    let movingAverage20: Double?
    let movingAverage50: Double?
    let movingAverage200: Double?
    let rsi14: Double?
    let volumeTrendRatio: Double?
    let annualizedVolatility: Double?
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
    let disclaimer: String

    var canShowNumericMetrics: Bool {
        displayMode == .providerBacked && provenance.isProviderBacked
    }

    var sourceLine: String {
        switch displayMode {
        case .providerBacked:
            return "\(timeframeLabel) daily candles - \(candleCount) candles - \(completeness.label) history"
        case .staleDataset:
            return "Stale cached provider-backed history"
        case .partialDataset:
            return "Partial provider-backed history"
        case .insufficientDataset:
            return "Insufficient provider-backed history"
        case .unavailable:
            return "Provider-backed history unavailable"
        case .sampleOnly:
            return "Sample history is preview-only"
        }
    }

    var metrics: [StockTechnicalMetric] {
        guard canShowNumericMetrics else { return [] }

        return [
            StockTechnicalMetric(
                id: "trend",
                label: "Trend context",
                value: movingAverage50.map { "50D \(Self.currency($0))" } ?? "N/A",
                detail: trendContext
            ),
            StockTechnicalMetric(
                id: "momentum",
                label: "Momentum context",
                value: rsi14.map { "RSI \(Self.number($0))" } ?? "N/A",
                detail: momentumContext
            ),
            StockTechnicalMetric(
                id: "volume",
                label: "Volume context",
                value: volumeTrendRatio.map { "\(Self.number($0))x" } ?? "N/A",
                detail: volumeContext
            ),
            StockTechnicalMetric(
                id: "volatility",
                label: "Volatility context",
                value: annualizedVolatility.map { "\(Self.number($0))%" } ?? "N/A",
                detail: volatilityContext
            )
        ]
    }

    var rangeMetric: StockTechnicalMetric? {
        guard canShowNumericMetrics,
              let recentRangeLow,
              let recentRangeHigh else { return nil }

        return StockTechnicalMetric(
            id: "recent-range",
            label: "Recent range",
            value: "\(Self.currency(recentRangeLow)) - \(Self.currency(recentRangeHigh))",
            detail: rangeContext
        )
    }

    var supportResistanceMetric: StockTechnicalMetric? {
        guard canShowNumericMetrics,
              let supportCandidate,
              let resistanceCandidate else { return nil }

        return StockTechnicalMetric(
            id: "support-resistance",
            label: "Support / resistance candidates",
            value: "\(Self.currency(supportCandidate)) / \(Self.currency(resistanceCandidate))",
            detail: "Derived from recent provider-backed candle highs and lows. Treat as a chart reference, not an instruction."
        )
    }

    static func unavailable(
        symbol: String,
        reason: String,
        provenance: FinancialDataProvenance = .unavailable(reason: "Provider-backed historical candles unavailable"),
        displayMode: StockTechnicalDisplayMode = .unavailable
    ) -> StockTechnicalSummary {
        StockTechnicalSummary(
            symbol: symbol.uppercased(),
            timeframeLabel: "1Y",
            candleCount: 0,
            provenance: provenance,
            completeness: .insufficient(reason: reason),
            displayMode: displayMode,
            movingAverage20: nil,
            movingAverage50: nil,
            movingAverage200: nil,
            rsi14: nil,
            volumeTrendRatio: nil,
            annualizedVolatility: nil,
            recentRangeLow: nil,
            recentRangeHigh: nil,
            supportCandidate: nil,
            resistanceCandidate: nil,
            trendContext: "Trend context will appear when complete provider-backed daily candles are available.",
            momentumContext: "Momentum context will appear when enough provider-backed closes are available.",
            volumeContext: "Volume context will appear when enough provider-backed volume history is available.",
            volatilityContext: "Volatility context will appear when enough provider-backed closes are available.",
            rangeContext: "Recent range context will appear when provider-backed candle history is available.",
            explanation: reason,
            disclaimer: Self.standardDisclaimer
        )
    }

    static let standardDisclaimer = "Historical technical context only. Not predictive and not financial advice."

    static func currency(_ value: Double) -> String {
        guard value.isFinite else { return "N/A" }
        return String(format: "$%.2f", value)
    }

    static func number(_ value: Double) -> String {
        guard value.isFinite else { return "N/A" }
        return String(format: "%.1f", value)
    }
}
