import Foundation

struct CorrelationWindow: Equatable {
    let daysBefore: Int
    let daysAfter: Int

    var displayName: String {
        switch (daysBefore, daysAfter) {
        case (0, 0):
            return "Same day"
        case (0, let after):
            return "Event day to +\(after)D"
        case (let before, let after) where before == after:
            return "+/-\(before)D"
        default:
            return "-\(daysBefore)D to +\(daysAfter)D"
        }
    }
}

nonisolated enum CorrelationConfidence: String, Equatable {
    case strong
    case moderate
    case thin
    case insufficient
    case unavailable

    var displayName: String {
        switch self {
        case .strong:
            return "Strong sample"
        case .moderate:
            return "Useful sample"
        case .thin:
            return "Thin sample"
        case .insufficient:
            return "Insufficient sample"
        case .unavailable:
            return "Unavailable"
        }
    }
}

enum CorrelationDisplayMode: Equatable {
    case marketBackedResult
    case partialCoverage
    case partialDataset
    case insufficientDataset
    case insufficientSample
    case unavailable
    case sampleOnly
}

struct StockCosmicCorrelationSummary: Identifiable, Equatable {
    let id: String
    let symbol: String
    let eventName: String
    let eventType: AstroOverlayEventKind
    let eventCount: Int
    let sampleSize: Int
    let window: CorrelationWindow
    let averageReturn: Double?
    let medianReturn: Double?
    let winRate: Double?
    let baselineReturn: Double?
    /// Share of comparable event-free windows that closed up. The base rate the
    /// event win rate has to beat; nil when there is not enough clean history.
    let baselineWinRate: Double?
    let volatilityRatio: Double?
    let maxDrawdown: Double?
    let bestHistoricalReturn: Double?
    let weakestHistoricalReturn: Double?
    let provenance: FinancialDataProvenance
    let dataCompleteness: HistoricalDatasetCompleteness
    let confidence: CorrelationConfidence
    let displayMode: CorrelationDisplayMode
    let disclaimer: String

    init(
        id: String,
        symbol: String,
        eventName: String,
        eventType: AstroOverlayEventKind,
        eventCount: Int,
        sampleSize: Int,
        window: CorrelationWindow,
        averageReturn: Double?,
        medianReturn: Double?,
        winRate: Double?,
        baselineReturn: Double?,
        baselineWinRate: Double? = nil,
        volatilityRatio: Double?,
        maxDrawdown: Double?,
        bestHistoricalReturn: Double? = nil,
        weakestHistoricalReturn: Double? = nil,
        provenance: FinancialDataProvenance,
        dataCompleteness: HistoricalDatasetCompleteness = .complete,
        confidence: CorrelationConfidence,
        displayMode: CorrelationDisplayMode,
        disclaimer: String
    ) {
        self.id = id
        self.symbol = symbol
        self.eventName = eventName
        self.eventType = eventType
        self.eventCount = eventCount
        self.sampleSize = sampleSize
        self.window = window
        self.averageReturn = averageReturn
        self.medianReturn = medianReturn
        self.winRate = winRate
        self.baselineReturn = baselineReturn
        self.baselineWinRate = baselineWinRate
        self.volatilityRatio = volatilityRatio
        self.maxDrawdown = maxDrawdown
        self.bestHistoricalReturn = bestHistoricalReturn
        self.weakestHistoricalReturn = weakestHistoricalReturn
        self.provenance = provenance
        self.dataCompleteness = dataCompleteness
        self.confidence = confidence
        self.displayMode = displayMode
        self.disclaimer = disclaimer
    }
}

struct AstroCorrelationSummary: Identifiable, Equatable {
    let id: String
    let kind: AstroOverlayEventKind
    let occurrenceCount: Int
    let averageReturn: Double
    let medianReturn: Double
    let winRate: Double
    let averageVolatility: Double
    /// Nil when the clean history is too thin to compare against. Never zero
    /// as a stand-in — that would read as "no edge" instead of "no baseline".
    let baselineAverageReturn: Double?
    let baselineWinRate: Double?
    let baselineVolatility: Double?
    let strongestEvent: AstroEventPriceReaction?
    let weakestEvent: AstroEventPriceReaction?

    var returnDeltaVsBaseline: Double? {
        baselineAverageReturn.map { averageReturn - $0 }
    }
}

struct AstroEventPriceReaction: Identifiable, Equatable {
    let id: String
    let event: AstroOverlayEvent
    let windowStart: Date
    let windowEnd: Date
    let startPrice: Double
    let endPrice: Double
    let returnPercent: Double
    let maxDrawdownPercent: Double
    let volatilityPercent: Double
    let volumeRatio: Double?
    /// Candles actually inside the window. The baseline has to be measured
    /// over stretches of the same length, and calendar days are not trading
    /// days — a "-1D to +3D" window is about four calendar days but only
    /// three candles, so counting calendar days stretched every baseline.
    let candleCount: Int
}

final class AstroCorrelationService {
    static let shared = AstroCorrelationService()

    private let calendar = Calendar.current

    private init() {}

    func summaries(
        prices: [OHLCData],
        events: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState
    ) -> [AstroCorrelationSummary] {
        let reactions = eventReactions(prices: prices, events: events, filterState: filterState)
        let grouped = Dictionary(grouping: reactions) { $0.event.kind }

        return grouped.keys.sorted { $0.displayName < $1.displayName }.compactMap { kind in
            guard let kindReactions = grouped[kind], !kindReactions.isEmpty else { return nil }

            let returns = kindReactions.map(\.returnPercent)
            let volatilities = kindReactions.map(\.volatilityPercent)
            let baseline = eventExcludedBaseline(
                prices: prices,
                events: events.filter { $0.kind == kind },
                reactions: kindReactions,
                filterState: filterState
            )

            return AstroCorrelationSummary(
                id: kind.rawValue,
                kind: kind,
                occurrenceCount: kindReactions.count,
                averageReturn: average(returns),
                medianReturn: median(returns),
                winRate: winRate(returns),
                averageVolatility: average(volatilities),
                baselineAverageReturn: baseline?.averageReturnPercent,
                baselineWinRate: baseline?.winRate,
                baselineVolatility: baseline?.volatilityPercent,
                strongestEvent: kindReactions.max { $0.returnPercent < $1.returnPercent },
                weakestEvent: kindReactions.min { $0.returnPercent < $1.returnPercent }
            )
        }
    }

    func stockSummaries(
        symbol: String,
        prices: [OHLCData],
        events: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState,
        provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness = .complete,
        minimumSampleSize: Int = 3
    ) -> [StockCosmicCorrelationSummary] {
        let groupedEvents = Dictionary(grouping: events) { $0.kind }
        let sortedKinds = groupedEvents.keys.sorted { $0.displayName < $1.displayName }
        let window = CorrelationWindow(daysBefore: 1, daysAfter: max(1, filterState.eventWindowDays))

        guard completeness.allowsNumericCorrelationClaims else {
            let mode: CorrelationDisplayMode
            let qualityProvenance: FinancialDataProvenance
            let disclaimer: String

            switch completeness {
            case .complete:
                mode = .unavailable
                qualityProvenance = provenance
                disclaimer = "Historical price data unavailable. Correlation context will appear when provider-backed history is available."
            case .partial(let reason):
                mode = .partialDataset
                qualityProvenance = .mixed(reason: "Partial historical dataset. \(reason)")
                disclaimer = "Partial historical dataset. \(reason). No return claim is shown."
            case .insufficient(let reason):
                mode = .insufficientDataset
                qualityProvenance = .unavailable(reason: "Insufficient historical dataset. \(reason)")
                disclaimer = "Insufficient historical dataset. \(reason). No return claim is shown."
            }

            return sortedKinds.map { kind in
                unavailableStockSummary(
                    symbol: symbol,
                    kind: kind,
                    eventCount: groupedEvents[kind]?.count ?? 0,
                    window: window,
                    provenance: qualityProvenance,
                    completeness: completeness,
                    confidence: .insufficient,
                    displayMode: mode,
                    disclaimer: disclaimer
                )
            }
        }

        guard provenance.isProviderBacked else {
            let mode: CorrelationDisplayMode
            let confidence: CorrelationConfidence
            let disclaimer: String

            if case .sample = provenance {
                mode = .sampleOnly
                confidence = .unavailable
                disclaimer = "Sample chart data is labeled for preview only. No historical correlation claim is shown."
            } else {
                mode = .unavailable
                confidence = .unavailable
                disclaimer = "Historical price data unavailable. Correlation context will appear when provider-backed history is available."
            }

            return sortedKinds.map { kind in
                unavailableStockSummary(
                    symbol: symbol,
                    kind: kind,
                    eventCount: groupedEvents[kind]?.count ?? 0,
                    window: window,
                    provenance: provenance,
                    completeness: completeness,
                    confidence: confidence,
                    displayMode: mode,
                    disclaimer: disclaimer
                )
            }
        }

        let sortedPrices = prices
            .filter { $0.close.isFinite && $0.close > 0 }
            .sorted { $0.date < $1.date }

        guard sortedPrices.count >= 2 else {
            return sortedKinds.map { kind in
                unavailableStockSummary(
                    symbol: symbol,
                    kind: kind,
                    eventCount: groupedEvents[kind]?.count ?? 0,
                    window: window,
                    provenance: .unavailable(reason: "Provider-backed historical prices unavailable"),
                    completeness: .insufficient(reason: "Provider returned fewer than two historical candles"),
                    confidence: .unavailable,
                    displayMode: .unavailable,
                    disclaimer: "Historical price data unavailable. Correlation context will appear when provider-backed history is available."
                )
            }
        }

        let reactions = eventReactions(prices: sortedPrices, events: events, filterState: filterState)
        let groupedReactions = Dictionary(grouping: reactions) { $0.event.kind }

        return sortedKinds.map { kind in
            let kindEvents = groupedEvents[kind] ?? []
            let kindReactions = groupedReactions[kind] ?? []

            guard kindReactions.count >= minimumSampleSize else {
                return StockCosmicCorrelationSummary(
                    id: "\(symbol.uppercased())-\(kind.rawValue)",
                    symbol: symbol.uppercased(),
                    eventName: kind.displayName,
                    eventType: kind,
                    eventCount: kindEvents.count,
                    sampleSize: kindReactions.count,
                    window: window,
                    averageReturn: nil,
                    medianReturn: nil,
                    winRate: nil,
                    baselineReturn: nil,
                    volatilityRatio: nil,
                    maxDrawdown: nil,
                    provenance: provenance,
                    confidence: .insufficient,
                    displayMode: .insufficientSample,
                    disclaimer: "Not enough historical observations for this event. No return claim is shown."
                )
            }

            let returns = kindReactions.map(\.returnPercent)
            let volatilities = kindReactions.map(\.volatilityPercent)
            let baseline = eventExcludedBaseline(
                prices: sortedPrices,
                events: kindEvents,
                reactions: kindReactions,
                filterState: filterState
            )
            let averageVolatility = average(volatilities)
            let volatilityRatio = (baseline?.volatilityPercent).flatMap { baselineVolatility in
                baselineVolatility > 0 ? averageVolatility / baselineVolatility : nil
            }

            return StockCosmicCorrelationSummary(
                id: "\(symbol.uppercased())-\(kind.rawValue)",
                symbol: symbol.uppercased(),
                eventName: kind.displayName,
                eventType: kind,
                eventCount: kindEvents.count,
                sampleSize: kindReactions.count,
                window: window,
                averageReturn: average(returns),
                medianReturn: median(returns),
                winRate: winRate(returns),
                baselineReturn: baseline?.averageReturnPercent,
                baselineWinRate: baseline?.winRate,
                volatilityRatio: volatilityRatio,
                maxDrawdown: kindReactions.map(\.maxDrawdownPercent).max(),
                bestHistoricalReturn: returns.max(),
                weakestHistoricalReturn: returns.min(),
                provenance: provenance,
                dataCompleteness: completeness,
                confidence: CorrelationBaselineCalculator.confidence(returns: returns),
                displayMode: .marketBackedResult,
                disclaimer: "Historical context only. Correlation does not imply causation and this is not financial advice."
            )
        }
    }

    func eventReactions(
        prices: [OHLCData],
        events: [AstroOverlayEvent],
        filterState: AstroOverlayFilterState
    ) -> [AstroEventPriceReaction] {
        let sortedPrices = prices
            .filter { $0.close.isFinite && $0.close > 0 }
            .sorted { $0.date < $1.date }

        guard !sortedPrices.isEmpty else { return [] }

        let fullAverageVolume = averageVolume(sortedPrices)

        return events.compactMap { event in
            let window = Self.priceWindow(for: event, filterState: filterState, calendar: calendar)
            let candles = sortedPrices.filter { candle in
                candle.date >= window.start && candle.date <= window.end
            }

            guard let first = candles.first,
                  let last = candles.last,
                  first.close > 0,
                  candles.count >= 2 else {
                return nil
            }

            let returnPercent = ((last.close - first.close) / first.close) * 100
            let volumeRatio: Double?
            if let fullAverageVolume, fullAverageVolume > 0, let eventAverageVolume = averageVolume(candles) {
                volumeRatio = eventAverageVolume / fullAverageVolume
            } else {
                volumeRatio = nil
            }

            return AstroEventPriceReaction(
                id: "\(event.id)-reaction",
                event: event,
                windowStart: first.date,
                windowEnd: last.date,
                startPrice: first.close,
                endPrice: last.close,
                returnPercent: returnPercent,
                maxDrawdownPercent: maxDrawdownPercent(for: candles),
                volatilityPercent: volatilityPercent(for: candles),
                volumeRatio: volumeRatio,
                candleCount: candles.count
            )
        }
    }

    /// The interval an event contributes to the historical statistics:
    /// range events (Mercury retrograde) span their own dates, point events
    /// (moon phases) span the day before the marker through the configured
    /// event window after it.
    ///
    /// Shared rather than private because "is this driver active today?" has
    /// to be the same question as "which candles did this driver's sample
    /// come from?" — if the two definitions drift, the ledger scores claims
    /// against a window the statistics were never computed over.
    static func priceWindow(
        for event: AstroOverlayEvent,
        filterState: AstroOverlayFilterState,
        calendar: Calendar = .current
    ) -> DateInterval {
        if event.isRange, let endDate = event.endDate {
            return DateInterval(start: event.startDate, end: endDate)
        }

        let start = calendar.date(byAdding: .day, value: -1, to: event.markerDate) ?? event.markerDate
        let end = calendar.date(byAdding: .day, value: max(1, filterState.eventWindowDays), to: event.markerDate) ?? event.markerDate
        return DateInterval(start: start, end: end)
    }

    /// What this market did over comparable stretches the event never touched.
    ///
    /// Shared with the portfolio and market-weather services so all three ask
    /// the question the same way; see `CorrelationBaseline` for why the old
    /// whole-series average was wrong.
    func eventExcludedBaseline(
        prices: [OHLCData],
        events: [AstroOverlayEvent],
        reactions: [AstroEventPriceReaction],
        filterState: AstroOverlayFilterState
    ) -> CorrelationBaseline? {
        CorrelationBaselineCalculator.baseline(
            prices: prices,
            excluding: events.map {
                Self.priceWindow(for: $0, filterState: filterState, calendar: calendar)
            },
            windowLength: averageCandleCount(for: reactions)
        )
    }

    private func averageCandleCount(for reactions: [AstroEventPriceReaction]) -> Int {
        guard !reactions.isEmpty else { return 2 }
        return Int(round(average(reactions.map { Double($0.candleCount) })))
    }

    private func maxDrawdownPercent(for candles: [OHLCData]) -> Double {
        var peak = candles.first?.close ?? 0
        var maxDrawdown = 0.0

        for candle in candles {
            peak = max(peak, candle.close)
            guard peak > 0 else { continue }
            let drawdown = ((candle.close - peak) / peak) * 100
            maxDrawdown = min(maxDrawdown, drawdown)
        }

        return abs(maxDrawdown)
    }

    private func volatilityPercent(for candles: [OHLCData]) -> Double {
        let returns = zip(candles, candles.dropFirst()).compactMap { previous, current -> Double? in
            guard previous.close > 0 else { return nil }
            return ((current.close - previous.close) / previous.close) * 100
        }

        guard returns.count > 1 else { return 0 }
        let mean = average(returns)
        let variance = returns.reduce(0) { partial, value in
            partial + pow(value - mean, 2)
        } / Double(returns.count)
        return sqrt(variance)
    }

    private func averageVolume(_ candles: [OHLCData]) -> Double? {
        let volumes = candles.map(\.volume).filter { $0 > 0 }
        guard !volumes.isEmpty else { return nil }
        return Double(volumes.reduce(0, +)) / Double(volumes.count)
    }

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }

    private func winRate(_ returns: [Double]) -> Double {
        guard !returns.isEmpty else { return 0 }
        let wins = returns.filter { $0 > 0 }.count
        return Double(wins) / Double(returns.count)
    }

    private func unavailableStockSummary(
        symbol: String,
        kind: AstroOverlayEventKind,
        eventCount: Int,
        window: CorrelationWindow,
        provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness = .complete,
        confidence: CorrelationConfidence,
        displayMode: CorrelationDisplayMode,
        disclaimer: String
    ) -> StockCosmicCorrelationSummary {
        StockCosmicCorrelationSummary(
            id: "\(symbol.uppercased())-\(kind.rawValue)",
            symbol: symbol.uppercased(),
            eventName: kind.displayName,
            eventType: kind,
            eventCount: eventCount,
            sampleSize: 0,
            window: window,
            averageReturn: nil,
            medianReturn: nil,
            winRate: nil,
            baselineReturn: nil,
            volatilityRatio: nil,
            maxDrawdown: nil,
            provenance: provenance,
            dataCompleteness: completeness,
            confidence: confidence,
            displayMode: displayMode,
            disclaimer: disclaimer
        )
    }
}
