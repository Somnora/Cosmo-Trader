import Foundation

enum HistoricalPriceError: LocalizedError, Equatable {
    case noHistoricalData
    case invalidDateRange

    var errorDescription: String? {
        switch self {
        case .noHistoricalData:
            return "Historical data unavailable. Try again later."
        case .invalidDateRange:
            return "Historical date range unavailable."
        }
    }
}

@MainActor
@Observable
final class HistoricalPriceService {
    static let shared = HistoricalPriceService()

    private var cache: [String: (data: [OHLCData], fetchedAt: Date)] = [:]
    private let cacheDuration: TimeInterval = 3600

    private init() {}

    func fetchHistoricalPrices(
        symbol: String,
        timeframe: ChartTimeframe
    ) async throws -> [OHLCData] {
        let request = requestParameters(for: timeframe)
        let key = "\(symbol.uppercased())-\(timeframe.rawValue)-\(request.resolution)"

        if let cached = cache[key],
           Date().timeIntervalSince(cached.fetchedAt) < cacheDuration {
            return cached.data
        }

        let response = try await StockAPIService.shared.fetchCandles(
            symbol: symbol,
            resolution: request.resolution,
            from: request.from,
            to: request.to
        )

        let data = response.toOHLCData()
            .filter { candle in
                candle.close.isFinite && candle.close > 0
            }
            .sorted { $0.date < $1.date }

        guard !data.isEmpty else {
            throw HistoricalPriceError.noHistoricalData
        }

        cache[key] = (data, Date())
        return data
    }

    func requestParameters(for timeframe: ChartTimeframe) -> (resolution: String, from: Date, to: Date) {
        let calendar = Calendar.current
        let to = Date()

        switch timeframe {
        case .day:
            return ("5", calendar.date(byAdding: .day, value: -1, to: to) ?? to, to)
        case .week:
            return ("60", calendar.date(byAdding: .day, value: -7, to: to) ?? to, to)
        case .month:
            return ("D", calendar.date(byAdding: .day, value: -30, to: to) ?? to, to)
        case .threeMonth:
            return ("D", calendar.date(byAdding: .day, value: -90, to: to) ?? to, to)
        case .sixMonth:
            return ("D", calendar.date(byAdding: .day, value: -180, to: to) ?? to, to)
        case .year:
            return ("D", calendar.date(byAdding: .day, value: -365, to: to) ?? to, to)
        case .all:
            return ("W", calendar.date(byAdding: .year, value: -5, to: to) ?? to, to)
        }
    }
}
