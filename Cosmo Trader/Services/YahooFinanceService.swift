import Foundation

// MARK: - YahooFinanceService
// ============================
// Fetches historical OHLC price data from Yahoo Finance's chart API.
// Used as the historical data provider (candles/line charts) while
// Finnhub handles real-time quotes.
//
// Yahoo Finance chart API is free with no API key required.
// Returns data compatible with FinnhubCandleResponse via adapter.

@MainActor
final class YahooFinanceService {

    static let shared = YahooFinanceService()

    private let session: URLSession
    private let baseURL = "https://query1.finance.yahoo.com/v8/finance/chart"

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        // Yahoo may block default user agents
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        ]
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Fetch historical candles and return as FinnhubCandleResponse for drop-in compatibility.
    ///
    /// - Parameters:
    ///   - symbol: Stock ticker (e.g., "AAPL", "SPY")
    ///   - resolution: Finnhub-style resolution string ("5", "60", "D", "W")
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: FinnhubCandleResponse with Yahoo data adapted to Finnhub format
    func fetchCandles(
        symbol: String,
        resolution: String,
        from: Date,
        to: Date
    ) async throws -> FinnhubCandleResponse {
        let interval = mapResolution(resolution)
        let range = mapRange(from: from, to: to, resolution: resolution)

        var components = URLComponents(string: "\(baseURL)/\(symbol.uppercased())")
        components?.queryItems = [
            URLQueryItem(name: "range", value: range),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "includePrePost", value: "false"),
            URLQueryItem(name: "events", value: ""),
        ]

        guard let url = components?.url else {
            throw NetworkError.invalidResponse
        }

        log("🌐 [Yahoo] Fetching candles for \(symbol) (range: \(range), interval: \(interval))...")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw NetworkError.unknown("Yahoo Finance access denied")
        case 429:
            throw NetworkError.rateLimited
        case 404:
            throw NetworkError.invalidSymbol(symbol)
        case 500...599:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw NetworkError.unknown("Yahoo Finance HTTP \(httpResponse.statusCode)")
        }

        let chartResponse = try JSONDecoder().decode(YahooChartResponse.self, from: data)

        guard let result = chartResponse.chart.result?.first else {
            log("⚠️ [Yahoo] No data for \(symbol)")
            return FinnhubCandleResponse(s: "no_data", t: nil, o: nil, h: nil, l: nil, c: nil, v: nil)
        }

        // Yahoo can answer a daily request with coarser candles at HTTP 200 and
        // no error field, so the only evidence of a downgrade is in `meta`.
        // Carry it forward instead of discarding it with the rest of the meta.
        let metadata = HistoricalCandleMetadata(
            reportedGranularity: result.meta?.dataGranularity,
            firstTradeDate: result.meta?.firstTradeDate.map { Date(timeIntervalSince1970: Double($0)) }
        )

        guard let timestamps = result.timestamp,
              let quote = result.indicators.quote.first else {
            log("⚠️ [Yahoo] No data for \(symbol)")
            return FinnhubCandleResponse(s: "no_data", t: nil, o: nil, h: nil, l: nil, c: nil, v: nil, metadata: metadata)
        }

        // Convert to FinnhubCandleResponse format
        let count = timestamps.count
        var opens: [Double] = []
        var highs: [Double] = []
        var lows: [Double] = []
        var closes: [Double] = []
        var volumes: [Int] = []
        var validTimestamps: [Int] = []

        for i in 0..<count {
            // Yahoo returns null for missing data points — skip them
            guard let o = quote.open?[safe: i] ?? nil,
                  let h = quote.high?[safe: i] ?? nil,
                  let l = quote.low?[safe: i] ?? nil,
                  let c = quote.close?[safe: i] ?? nil else {
                continue
            }

            validTimestamps.append(timestamps[i])
            opens.append(o)
            highs.append(h)
            lows.append(l)
            closes.append(c)
            volumes.append(quote.volume?[safe: i].flatMap { $0 } ?? 0)
        }

        log("✅ [Yahoo] Fetched \(validTimestamps.count) candles for \(symbol) (granularity: \(metadata.reportedGranularity ?? "unreported"))")

        return FinnhubCandleResponse(
            s: validTimestamps.isEmpty ? "no_data" : "ok",
            t: validTimestamps,
            o: opens,
            h: highs,
            l: lows,
            c: closes,
            v: volumes,
            metadata: metadata
        )
    }

    // MARK: - Resolution Mapping

    /// Yahoo's unbounded range token. Never sent at daily or finer resolution:
    /// `range=max&interval=1d` answers HTTP 200 with a well formed body of
    /// monthly candles and `meta.dataGranularity: "1mo"`, so the request does
    /// not fail, it just returns useless resolution.
    static let unboundedRange = "max"

    /// Deepest bounded range this service will request. Measured against the
    /// live endpoint: `range=20y&interval=1d` returns full trading day density.
    static let deepestDailyRange = "20y"

    /// Map Finnhub resolution strings to Yahoo Finance intervals
    private func mapResolution(_ resolution: String) -> String {
        HistoricalCandleResolution(token: resolution).providerGranularity
    }

    /// Map date range to Yahoo Finance range parameter
    func mapRange(from: Date, to: Date, resolution: String) -> String {
        let days = Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
        return Self.rangeEnforcingDailyResolution(
            unenforcedRange(days: days, resolution: resolution),
            resolution: resolution
        )
    }

    /// Standing invariant for `mapRange`: a daily or finer request must never
    /// carry the unbounded range. Written as a substitution rather than a
    /// comment on the ladder below so a later edit to that ladder cannot
    /// reintroduce the silent downgrade.
    nonisolated static func rangeEnforcingDailyResolution(_ range: String, resolution: String) -> String {
        guard range == unboundedRange,
              HistoricalCandleResolution(token: resolution).isDailyOrFiner else {
            return range
        }

        return deepestDailyRange
    }

    private func unenforcedRange(days: Int, resolution: String) -> String {
        // For intraday resolutions, use shorter ranges
        switch resolution {
        case "1", "5":
            return days <= 1 ? "1d" : "5d"
        case "15", "30":
            return days <= 7 ? "5d" : "1mo"
        case "60":
            return days <= 30 ? "1mo" : "3mo"
        default:
            // Daily/weekly resolution
            if days <= 30 { return "1mo" }
            if days <= 90 { return "3mo" }
            if days <= 180 { return "6mo" }
            if days <= 365 { return "1y" }
            if days <= 730 { return "2y" }
            if days <= 1_830 { return "5y" }
            return Self.deepestDailyRange
        }
    }

    // MARK: - Logging

    private func log(_ message: String) {
        #if DEBUG
        print("[YahooFinance] \(message)")
        #endif
    }
}

// MARK: - Yahoo Finance Response Models

/// Top-level response from Yahoo Finance chart API
struct YahooChartResponse: Decodable {
    let chart: YahooChartResult
}

struct YahooChartResult: Decodable {
    let result: [YahooChartData]?
    let error: YahooChartError?
}

struct YahooChartError: Decodable {
    let code: String?
    let description: String?
}

struct YahooChartData: Decodable {
    let meta: YahooChartMeta?
    let timestamp: [Int]?
    let indicators: YahooIndicators
}

struct YahooChartMeta: Decodable {
    let currency: String?
    let symbol: String?
    let regularMarketPrice: Double?
    let previousClose: Double?
    /// Bar size Yahoo actually served, which is not always the interval that
    /// was requested.
    let dataGranularity: String?
    /// Epoch seconds of the symbol's first ever trade.
    let firstTradeDate: Int?
}

struct YahooIndicators: Decodable {
    let quote: [YahooQuoteData]
}

struct YahooQuoteData: Decodable {
    let open: [Double?]?
    let high: [Double?]?
    let low: [Double?]?
    let close: [Double?]?
    let volume: [Int?]?
}

