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

enum CorrelationConfidence: String, Equatable {
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
    let volatilityRatio: Double?
    let maxDrawdown: Double?
    let provenance: FinancialDataProvenance
    let confidence: CorrelationConfidence
    let displayMode: CorrelationDisplayMode
    let disclaimer: String
}

struct AstroCorrelationSummary: Identifiable, Equatable {
    let id: String
    let kind: AstroOverlayEventKind
    let occurrenceCount: Int
    let averageReturn: Double
    let medianReturn: Double
    let winRate: Double
    let averageVolatility: Double
    let baselineAverageReturn: Double
    let baselineVolatility: Double
    let strongestEvent: AstroEventPriceReaction?
    let weakestEvent: AstroEventPriceReaction?

    var returnDeltaVsBaseline: Double {
        averageReturn - baselineAverageReturn
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
            let baseline = baselineReturnPercent(prices: prices, averageWindowSize: averageCandleCount(for: kindReactions))

            return AstroCorrelationSummary(
                id: kind.rawValue,
                kind: kind,
                occurrenceCount: kindReactions.count,
                averageReturn: average(returns),
                medianReturn: median(returns),
                winRate: winRate(returns),
                averageVolatility: average(volatilities),
                baselineAverageReturn: baseline,
                baselineVolatility: volatilityPercent(for: prices),
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
        minimumSampleSize: Int = 10
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
                    confidence: .unavailable,
                    displayMode: .unavailable,
                    disclaimer: "Historical price data unavailable. Correlation context will appear when provider-backed history is available."
                )
            }
        }

        let reactions = eventReactions(prices: sortedPrices, events: events, filterState: filterState)
        let groupedReactions = Dictionary(grouping: reactions) { $0.event.kind }
        let baselineVolatility = volatilityPercent(for: sortedPrices)

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
                    disclaimer: "Awaiting more historical data. (10 observations required; currently has \(kindReactions.count))."
                )
            }

            let returns = kindReactions.map(\.returnPercent)
            let volatilities = kindReactions.map(\.volatilityPercent)
            let baselineReturn = baselineReturnPercent(
                prices: sortedPrices,
                averageWindowSize: averageCandleCount(for: kindReactions)
            )
            let averageVolatility = average(volatilities)
            let volatilityRatio = baselineVolatility > 0
                ? averageVolatility / baselineVolatility
                : nil

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
                baselineReturn: baselineReturn,
                volatilityRatio: volatilityRatio,
                maxDrawdown: kindReactions.map(\.maxDrawdownPercent).max(),
                provenance: provenance,
                confidence: confidence(for: kindReactions.count),
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
            let window = priceWindow(for: event, filterState: filterState)
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
                volumeRatio: volumeRatio
            )
        }
    }

    private func priceWindow(
        for event: AstroOverlayEvent,
        filterState: AstroOverlayFilterState
    ) -> DateInterval {
        if event.isRange, let endDate = event.endDate {
            return DateInterval(start: event.startDate, end: endDate)
        }

        let start = calendar.date(byAdding: .day, value: -1, to: event.markerDate) ?? event.markerDate
        let end = calendar.date(byAdding: .day, value: max(1, filterState.eventWindowDays), to: event.markerDate) ?? event.markerDate
        return DateInterval(start: start, end: end)
    }

    private func baselineReturnPercent(prices: [OHLCData], averageWindowSize: Int) -> Double {
        let sorted = prices.sorted { $0.date < $1.date }
        guard sorted.count > 1,
              let first = sorted.first,
              first.close > 0 else { return 0 }

        let dailyReturns = zip(sorted, sorted.dropFirst()).compactMap { previous, current -> Double? in
            guard previous.close > 0 else { return nil }
            return ((current.close - previous.close) / previous.close) * 100
        }

        return average(dailyReturns) * Double(max(1, averageWindowSize))
    }

    private func averageCandleCount(for reactions: [AstroEventPriceReaction]) -> Int {
        let counts = reactions.map { reaction in
            let days = calendar.dateComponents([.day], from: reaction.windowStart, to: reaction.windowEnd).day ?? 1
            return max(1, days)
        }
        return Int(round(average(counts.map(Double.init))))
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
            confidence: confidence,
            displayMode: displayMode,
            disclaimer: disclaimer
        )
    }

    private func confidence(for sampleSize: Int) -> CorrelationConfidence {
        switch sampleSize {
        case 12...:
            return .strong
        case 6...:
            return .moderate
        case 3...:
            return .thin
        default:
            return .insufficient
        }
    }
}
