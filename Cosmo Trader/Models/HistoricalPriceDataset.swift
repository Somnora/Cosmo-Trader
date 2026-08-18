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

nonisolated enum HistoricalCandleResolution: String, CaseIterable, Codable {
    case oneMinute = "1"
    case fiveMinute = "5"
    case fifteenMinute = "15"
    case thirtyMinute = "30"
    case hour = "60"
    case day = "D"
    case week = "W"
    case month = "M"

    /// Provider granularity label that corresponds to this resolution. Yahoo
    /// echoes the granularity it actually served in `meta.dataGranularity`, so
    /// an exact mismatch against this value is a silent downgrade.
    var providerGranularity: String {
        switch self {
        case .oneMinute: return "1m"
        case .fiveMinute: return "5m"
        case .fifteenMinute: return "15m"
        case .thirtyMinute: return "30m"
        case .hour: return "1h"
        case .day: return "1d"
        case .week: return "1wk"
        case .month: return "1mo"
        }
    }

    /// Roughly how many candles a full year at this resolution contains, using
    /// 252 US trading days and a 6.5 hour session.
    var expectedCandlesPerYear: Double {
        switch self {
        case .oneMinute: return 252 * 390
        case .fiveMinute: return 252 * 78
        case .fifteenMinute: return 252 * 26
        case .thirtyMinute: return 252 * 13
        case .hour: return 252 * 7
        case .day: return 252
        case .week: return 52
        case .month: return 12
        }
    }

    /// Daily or finer bars. Yahoo answers an unbounded range with monthly
    /// candles regardless of the interval it was asked for, so these are the
    /// resolutions that must never be paired with that range.
    var isDailyOrFiner: Bool {
        switch self {
        case .oneMinute, .fiveMinute, .fifteenMinute, .thirtyMinute, .hour, .day:
            return true
        case .week, .month:
            return false
        }
    }

    /// Unknown tokens fall back to daily, matching the historical provider
    /// adapter's default interval.
    init(token: String) {
        self = HistoricalCandleResolution(rawValue: token) ?? .day
    }

    /// Minutes per bar for a provider granularity token such as `1d` or `60m`.
    /// Granularities are compared by duration rather than by spelling because
    /// providers use more than one label for the same bar size, and reading
    /// `60m` as a downgrade of `1h` would silence honest data.
    static func barMinutes(forGranularity granularity: String) -> Int? {
        let normalized = granularity.lowercased().trimmingCharacters(in: .whitespaces)
        let digits = normalized.prefix(while: \.isNumber)
        guard let count = Int(digits), count > 0 else { return nil }

        switch normalized.dropFirst(digits.count) {
        case "m":        return count
        case "h":        return count * 60
        case "d":        return count * 24 * 60
        case "w", "wk":  return count * 7 * 24 * 60
        case "mo":       return count * 30 * 24 * 60
        case "y":        return count * 365 * 24 * 60
        default:         return nil
        }
    }
}

/// What the provider said about the payload it returned, as opposed to what the
/// candles themselves show. Yahoo reports both fields in `chart.result[].meta`.
nonisolated struct HistoricalCandleMetadata: Codable, Equatable {
    /// The bar size the provider says it served (Yahoo `meta.dataGranularity`).
    let reportedGranularity: String?
    /// The first day the symbol ever traded (Yahoo `meta.firstTradeDate`).
    let firstTradeDate: Date?

    static let unknown = HistoricalCandleMetadata()

    init(reportedGranularity: String? = nil, firstTradeDate: Date? = nil) {
        self.reportedGranularity = reportedGranularity
        self.firstTradeDate = firstTradeDate
    }
}

/// The resolution the app asked for paired with what the provider reported
/// back. Completeness otherwise only sees span coverage, which cannot tell a
/// twenty year daily series from the twenty year monthly series a provider
/// substitutes when it quietly downgrades a request.
nonisolated struct HistoricalDatasetExpectation: Equatable {
    let resolution: HistoricalCandleResolution
    let metadata: HistoricalCandleMetadata

    init(resolution: HistoricalCandleResolution, metadata: HistoricalCandleMetadata = .unknown) {
        self.resolution = resolution
        self.metadata = metadata
    }

    /// A reported granularity that disagrees with the requested resolution is a
    /// downgrade: the payload is well formed and the transport succeeded, only
    /// the bar size is wrong. A provider that reports nothing is not evidence
    /// either way, so it is left to the density backstop.
    var hasResolutionDowngrade: Bool {
        guard let reportedGranularity = metadata.reportedGranularity else { return false }

        let requestedGranularity = resolution.providerGranularity
        guard let reportedMinutes = HistoricalCandleResolution.barMinutes(forGranularity: reportedGranularity),
              let requestedMinutes = HistoricalCandleResolution.barMinutes(forGranularity: requestedGranularity) else {
            return reportedGranularity.caseInsensitiveCompare(requestedGranularity) != .orderedSame
        }

        return reportedMinutes != requestedMinutes
    }
}

nonisolated struct HistoricalChartDataQuality: Equatable {
    let canRenderChart: Bool
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness
    let unavailableTitle: String
    let unavailableMessage: String

    static func evaluate(
        dataset: HistoricalPriceDataset,
        minimumCandles: Int = 2,
        staleAfter staleInterval: TimeInterval = HistoricalPriceDataset.defaultStaleInterval
    ) -> HistoricalChartDataQuality {
        let provenance = dataset.correlationDisplayProvenance

        guard dataset.provenance.isProviderBacked else {
            return HistoricalChartDataQuality(
                canRenderChart: false,
                provenance: provenance,
                completeness: dataset.completeness,
                unavailableTitle: "Historical price data unavailable",
                unavailableMessage: "Chart will appear when provider-backed history is available."
            )
        }

        if dataset.provenance.isCachedStale(staleAfter: staleInterval) {
            return HistoricalChartDataQuality(
                canRenderChart: false,
                provenance: dataset.provenance,
                completeness: dataset.completeness,
                unavailableTitle: "Cached history is stale",
                unavailableMessage: "Refresh provider history before viewing chart context."
            )
        }

        switch dataset.completeness {
        case .complete:
            break
        case .partial(let reason):
            return HistoricalChartDataQuality(
                canRenderChart: false,
                provenance: provenance,
                completeness: dataset.completeness,
                unavailableTitle: "Partial historical dataset",
                unavailableMessage: "\(reason). Chart context will appear when the provider returns a complete range."
            )
        case .insufficient(let reason):
            return HistoricalChartDataQuality(
                canRenderChart: false,
                provenance: provenance,
                completeness: dataset.completeness,
                unavailableTitle: "Insufficient historical data",
                unavailableMessage: "\(reason). Chart context will appear when enough provider-backed candles are available."
            )
        }

        guard dataset.candles.count >= minimumCandles else {
            return HistoricalChartDataQuality(
                canRenderChart: false,
                provenance: .unavailable(reason: "Provider returned fewer than two historical candles"),
                completeness: .insufficient(reason: "Provider returned fewer than two historical candles"),
                unavailableTitle: "Insufficient historical data",
                unavailableMessage: "Chart context will appear when enough provider-backed candles are available."
            )
        }

        return HistoricalChartDataQuality(
            canRenderChart: true,
            provenance: dataset.provenance,
            completeness: dataset.completeness,
            unavailableTitle: "",
            unavailableMessage: ""
        )
    }

    static var unavailable: HistoricalChartDataQuality {
        HistoricalChartDataQuality(
            canRenderChart: false,
            provenance: .unavailable(reason: "Historical price data unavailable"),
            completeness: .insufficient(reason: "Historical price data unavailable"),
            unavailableTitle: "Historical price data unavailable",
            unavailableMessage: "Chart will appear when provider-backed history is available."
        )
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

    private static let secondsPerYear: TimeInterval = 365.25 * 24 * 60 * 60
    /// Candle density only becomes a reliable signal once a request spans
    /// several years, so shorter windows are left to coverage scoring.
    private static let minimumDensityMeasurementDuration: TimeInterval = 3 * secondsPerYear
    /// Real daily history lands near 1.0 of the expected density, a weekly
    /// substitution near 0.2, and a monthly one near 0.05.
    private static let minimumResolutionDensityRatio: Double = 0.4

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
        provenance: FinancialDataProvenance,
        expectation: HistoricalDatasetExpectation? = nil
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
        let scoredRange = Self.rangeClampedToFirstTrade(requestedRange, expectation: expectation)

        return HistoricalPriceDataset(
            symbol: symbol.uppercased(),
            candles: normalized.map(HistoricalPricePoint.init(candle:)),
            provider: provider,
            fetchedAt: fetchedAt,
            requestedRange: scoredRange,
            actualRange: actualRange,
            provenance: provenance,
            completeness: Self.completeness(
                candleCount: normalized.count,
                requestedRange: scoredRange,
                actualRange: actualRange,
                expectation: expectation
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

    /// Coverage is measured against the window the symbol could actually have
    /// traded in. A listing that opened partway through the requested range
    /// otherwise scores as a fraction of a range that never existed for it, and
    /// a perfect daily series gets silenced for being young rather than thin.
    private static func rangeClampedToFirstTrade(
        _ requestedRange: DateInterval,
        expectation: HistoricalDatasetExpectation?
    ) -> DateInterval {
        guard let firstTradeDate = expectation?.metadata.firstTradeDate,
              firstTradeDate > requestedRange.start,
              firstTradeDate < requestedRange.end else {
            return requestedRange
        }

        return DateInterval(start: firstTradeDate, end: requestedRange.end)
    }

    /// Backstop for the granularity check: a provider that downgrades without
    /// saying so still betrays itself in candle density, because a daily
    /// request covering a year returns roughly 252 candles while the monthly
    /// substitution returns about 12. Limited to deep daily requests, which is
    /// where the silent downgrade actually happens. Shorter windows and
    /// intraday resolutions are legitimately sparse, so measuring them here
    /// would suppress honest data.
    private static func resolutionDensityFailureReason(
        candleCount: Int,
        requestedRange: DateInterval,
        resolution: HistoricalCandleResolution
    ) -> String? {
        guard resolution == .day,
              requestedRange.duration >= minimumDensityMeasurementDuration else {
            return nil
        }

        let years = requestedRange.duration / secondsPerYear
        guard years > 0 else { return nil }

        let observedCandlesPerYear = Double(candleCount) / years
        guard observedCandlesPerYear / resolution.expectedCandlesPerYear < minimumResolutionDensityRatio else {
            return nil
        }

        return "Provider returned fewer candles than the requested resolution allows"
    }

    private static func completeness(
        candleCount: Int,
        requestedRange: DateInterval,
        actualRange: DateInterval?,
        expectation: HistoricalDatasetExpectation?
    ) -> HistoricalDatasetCompleteness {
        guard candleCount >= 2 else {
            return .insufficient(reason: "Provider returned fewer than two historical candles")
        }

        if let expectation {
            if expectation.hasResolutionDowngrade {
                let reported = expectation.metadata.reportedGranularity ?? "unknown"
                return .insufficient(
                    reason: "Provider returned \(reported) candles instead of the requested \(expectation.resolution.providerGranularity)"
                )
            }

            if let reason = resolutionDensityFailureReason(
                candleCount: candleCount,
                requestedRange: requestedRange,
                resolution: expectation.resolution
            ) {
                return .insufficient(reason: reason)
            }
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
