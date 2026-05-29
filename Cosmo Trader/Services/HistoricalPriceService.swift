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

enum HistoricalPriceSource: Equatable {
    case provider
    case cache

    var displayName: String {
        switch self {
        case .provider:
            return "Provider data"
        case .cache:
            return "Cached provider data"
        }
    }
}

struct HistoricalPriceResult: Equatable {
    let data: [OHLCData]
    let source: HistoricalPriceSource
    let fetchedAt: Date

    var provenance: FinancialDataProvenance {
        switch source {
        case .provider:
            return .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        case .cache:
            return .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
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
        try await fetchHistoricalPriceResult(symbol: symbol, timeframe: timeframe).data
    }

    func fetchHistoricalPriceResult(
        symbol: String,
        timeframe: ChartTimeframe
    ) async throws -> HistoricalPriceResult {
        let request = requestParameters(for: timeframe)
        let key = "\(symbol.uppercased())-\(timeframe.rawValue)-\(request.resolution)"

        if let cached = cache[key],
           Date().timeIntervalSince(cached.fetchedAt) < cacheDuration {
            return HistoricalPriceResult(data: cached.data, source: .cache, fetchedAt: cached.fetchedAt)
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

        let fetchedAt = Date()
        cache[key] = (data, fetchedAt)
        return HistoricalPriceResult(data: data, source: .provider, fetchedAt: fetchedAt)
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
