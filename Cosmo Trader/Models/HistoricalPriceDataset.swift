import Foundation

nonisolated enum HistoricalDatasetCompleteness: Equatable, Codable {
    case complete
    case partial(reason: String)
    case insufficient(reason: String)

    var isUsableForCorrelation: Bool {
        if case .insufficient = self { return false }
        return true
    }

    var allowsNumericCorrelationClaims: Bool {
        if case .complete = self { return true }
        return false
    }

    var reason: String? {
        switch self {
        case .complete:
            return nil
        case .partial(let reason), .insufficient(let reason):
            return reason
        }
    }

    var label: String {
        switch self {
        case .complete:
            return "Complete"
        case .partial:
            return "Partial"
        case .insufficient:
            return "Insufficient"
        }
    }
}

nonisolated enum HistoricalDatasetFreshness: Equatable {
    case live
    case cachedFresh(age: TimeInterval)
    case cachedStale(age: TimeInterval)
    case unavailable

    var isProviderBacked: Bool {
        switch self {
        case .live, .cachedFresh, .cachedStale:
            return true
        case .unavailable:
            return false
        }
    }
}

nonisolated struct HistoricalPricePoint: Codable, Equatable {
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int

    init(date: Date, open: Double, high: Double, low: Double, close: Double, volume: Int) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }

    init(candle: OHLCData) {
        self.init(
            date: candle.date,
            open: candle.open,
            high: candle.high,
            low: candle.low,
            close: candle.close,
            volume: candle.volume
        )
    }

    var ohlcData: OHLCData {
        OHLCData(date: date, open: open, high: high, low: low, close: close, volume: volume)
    }
}

nonisolated struct HistoricalPriceDataset: Codable, Equatable {
    static let defaultStaleInterval: TimeInterval = FinancialDataProvenance.defaultCachedStaleInterval

    let symbol: String
    let candles: [HistoricalPricePoint]
    let provider: String
    let fetchedAt: Date
    let requestedRange: DateInterval
    let actualRange: DateInterval?
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness

    var ohlcData: [OHLCData] {
        candles.map(\.ohlcData)
    }

    var isUsableForCorrelation: Bool {
        provenance.isProviderBacked
            && completeness.allowsNumericCorrelationClaims
            && candles.count >= 2
    }

    func freshness(staleAfter staleInterval: TimeInterval = Self.defaultStaleInterval) -> HistoricalDatasetFreshness {
        switch provenance {
        case .live:
            return .live
        case .cached(_, _, let age):
            return age >= staleInterval ? .cachedStale(age: age) : .cachedFresh(age: age)
        case .mixed, .unavailable, .sample:
            return .unavailable
        }
    }

    var correlationDisplayProvenance: FinancialDataProvenance {
        guard provenance.isProviderBacked else { return provenance }

        switch completeness {
        case .complete:
            return provenance
        case .partial(let reason):
            return .mixed(reason: "Partial historical dataset. \(reason)")
        case .insufficient(let reason):
            return .unavailable(reason: "Insufficient historical dataset. \(reason)")
        }
    }

    static func providerBacked(
        symbol: String,
        candles: [OHLCData],
        provider: String,
        fetchedAt: Date,
        requestedRange: DateInterval,
        provenance: FinancialDataProvenance
    ) -> HistoricalPriceDataset {
        let normalized = candles
            .filter { candle in
                candle.open.isFinite
                    && candle.high.isFinite
                    && candle.low.isFinite
                    && candle.close.isFinite
                    && candle.close > 0
            }
            .sorted { $0.date < $1.date }

        let actualRange = Self.actualRange(for: normalized)

        return HistoricalPriceDataset(
            symbol: symbol.uppercased(),
            candles: normalized.map(HistoricalPricePoint.init(candle:)),
            provider: provider,
            fetchedAt: fetchedAt,
            requestedRange: requestedRange,
            actualRange: actualRange,
            provenance: provenance,
            completeness: Self.completeness(
                candleCount: normalized.count,
                requestedRange: requestedRange,
                actualRange: actualRange
            )
        )
    }

    func withProvenance(_ nextProvenance: FinancialDataProvenance) -> HistoricalPriceDataset {
        HistoricalPriceDataset(
            symbol: symbol,
            candles: candles,
            provider: provider,
            fetchedAt: fetchedAt,
            requestedRange: requestedRange,
            actualRange: actualRange,
            provenance: nextProvenance,
            completeness: completeness
        )
    }

    private static func actualRange(for candles: [OHLCData]) -> DateInterval? {
        guard let first = candles.first?.date, let last = candles.last?.date else { return nil }
        return DateInterval(start: min(first, last), end: max(first, last))
    }

    private static func completeness(
        candleCount: Int,
        requestedRange: DateInterval,
        actualRange: DateInterval?
    ) -> HistoricalDatasetCompleteness {
        guard candleCount >= 2 else {
            return .insufficient(reason: "Provider returned fewer than two historical candles")
        }

        guard requestedRange.duration > 0,
              let actualRange,
              actualRange.duration > 0 else {
            return .complete
        }

        let coverage = actualRange.duration / requestedRange.duration
        if coverage < 0.5 {
            return .partial(reason: "Provider returned a limited portion of the requested range")
        }

        return .complete
    }
}
