import Foundation

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
}
