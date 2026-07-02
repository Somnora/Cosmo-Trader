import Foundation
import Combine

// MARK: - StockQuote

/// Real-time stock price data from the Finnhub API.
///
/// `StockQuote` represents the current trading data for a stock, including price,
/// daily change, and high/low values. The property names match Finnhub's JSON response
/// format (single-letter keys), with computed properties providing friendly access.
///
/// ## Example
/// ```swift
/// let quote = try await StockAPIService.shared.getQuote(symbol: "AAPL")
/// print("\(quote.formattedPrice) \(quote.formattedPercentage)")
/// // Output: "$185.92 +1.25%"
/// ```
///
/// ## API Response Mapping
/// | Property | Finnhub Key | Description |
/// |----------|-------------|-------------|
/// | `c` | `c` | Current price |
/// | `d` | `d` | Dollar change |
/// | `dp` | `dp` | Percent change |
/// | `h` | `h` | Day high |
/// | `l` | `l` | Day low |
/// | `o` | `o` | Open price |
/// | `pc` | `pc` | Previous close |
struct StockQuote: Codable {
    /// Current trading price (Finnhub key: `c`).
    let c: Double

    /// Dollar change from previous close (Finnhub key: `d`).
    /// - Note: May be nil for some symbols; computed from `c - pc` as fallback.
    let d: Double?

    /// Percent change from previous close (Finnhub key: `dp`).
    /// - Note: May be nil for some symbols; computed as fallback.
    let dp: Double?

    /// Highest price of the current trading day (Finnhub key: `h`).
    let h: Double

    /// Lowest price of the current trading day (Finnhub key: `l`).
    let l: Double

    /// Opening price of the current trading day (Finnhub key: `o`).
    let o: Double

    /// Previous trading day's closing price (Finnhub key: `pc`).
    let pc: Double

    /// Unix timestamp of the quote (Finnhub key: `t`).
    let t: Int?

    /// Current trading price.
    /// - Returns: The current price as a `Double`.
    var currentPrice: Double { c }

    /// Dollar change from previous close.
    /// - Returns: Price change, calculated from API value or computed from `c - pc`.
    var priceChange: Double { d ?? (c - pc) }

    /// Percentage change from previous close.
    /// - Returns: Percent change, calculated from API value or computed.
    var percentageChange: Double {
        if let dp, dp.isFinite {
            return dp
        }
        guard pc.isFinite, pc != 0 else { return 0 }
        let computed = (c - pc) / pc * 100
        return computed.isFinite ? computed : 0
    }

    /// Whether the stock is up or unchanged from previous close.
    var isPositive: Bool { priceChange >= 0 }

    /// Price formatted as currency (e.g., "$185.92").
    var formattedPrice: String {
        String(format: "$%.2f", currentPrice)
    }

    /// Dollar change with sign (e.g., "+$2.50" or "-$1.25").
    var formattedChange: String {
        let sign = priceChange >= 0 ? "+" : ""
        return String(format: "%@$%.2f", sign, priceChange)
    }

    /// Percentage change with sign (e.g., "+1.25%" or "-0.50%").
    var formattedPercentage: String {
        let sign = percentageChange >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, percentageChange)
    }
}

// MARK: - CachedQuote

/// A time-stamped wrapper for cached stock quotes.
///
/// `CachedQuote` tracks when a quote was fetched, enabling cache expiration
/// and "data as of" display in offline mode.
///
/// ## Cache Behavior
/// - Fresh cache (< 60s): Returned immediately, no API call
/// - Expired cache: API call attempted; stale data used as fallback
/// - Offline mode: Stale cache returned with timestamp indicator
struct CachedQuote {
    /// The cached quote data.
    let quote: StockQuote

    /// When this quote was fetched from the API.
    let timestamp: Date

    /// The stock symbol this quote belongs to.
    let symbol: String

    /// Time elapsed since this quote was fetched, in seconds.
    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }

    /// Whether this cache entry has exceeded the expiration threshold.
    /// - Returns: `true` if older than ``StockAPIService/cacheExpirationSeconds``.
    var isExpired: Bool {
        age > StockAPIService.cacheExpirationSeconds
    }

    /// Human-readable age string for display (e.g., "5 mins ago", "2h ago").
    var formattedAge: String {
        let minutes = Int(age / 60)
        if minutes < 1 {
            return "Just now"
        } else if minutes == 1 {
            return "1 min ago"
        } else if minutes < 60 {
            return "\(minutes) mins ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h ago"
        }
    }
}

struct StockQuoteResult {
    let quote: StockQuote?
    let provenance: FinancialDataProvenance
    let error: NetworkError?

    var isCached: Bool {
        provenance.isCached
    }
}

struct BasicFinancialsResult {
    let metrics: [String: Double]
    let provenance: FinancialDataProvenance
}

private struct CachedBasicFinancials {
    let metrics: [String: Double]
    let timestamp: Date

    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}

// MARK: - StockAPIService

/// A service that manages real-time stock data fetching from the Finnhub API.
///
/// `StockAPIService` is the primary interface for fetching live stock quotes and
/// searching for stock symbols. It handles API communication, rate limiting,
/// caching, and error handling automatically.
///
/// ## Usage
///
/// ```swift
/// // Fetch a single quote
/// let quote = try await StockAPIService.shared.getQuote(symbol: "AAPL")
/// print(quote.formattedPrice) // "$185.92"
///
/// // Fetch multiple quotes
/// let quotes = await StockAPIService.shared.getMultipleQuotes(symbols: ["AAPL", "GOOGL", "MSFT"])
///
/// // Search for symbols
/// let results = try await StockAPIService.shared.searchSymbols(query: "Apple")
/// ```
///
/// ## Rate Limiting
///
/// The service enforces Finnhub's free tier limit of 60 requests per minute:
/// - Requests are tracked with timestamps
/// - A minimum 1-second delay is enforced between requests
/// - ``NetworkError/rateLimited`` is thrown if limit is exceeded
///
/// ## Caching
///
/// Quotes are cached in memory for 60 seconds to reduce API calls:
/// - Fresh cache: Returned immediately without API call
/// - Expired cache: New API call made; stale data used as fallback on failure
/// - Offline mode: Stale cache returned with age indicator
///
/// ## Thread Safety
///
/// This service is `@MainActor` isolated and uses locks for thread-safe cache access.
/// All published properties update on the main thread.
///
/// ## Error Handling
///
/// All methods throw ``NetworkError`` on failure. Common errors:
/// - ``NetworkError/noConnection``: Device is offline
/// - ``NetworkError/rateLimited``: API rate limit exceeded
/// - ``NetworkError/invalidSymbol(_:)``: Symbol not found
/// - ``NetworkError/apiKeyMissing``: API key not configured
///
/// - Note: This service requires a valid Finnhub API key configured in ``APIConfig``.
@MainActor
final class StockAPIService: ObservableObject {

    // MARK: - Singleton

    /// Shared singleton instance for app-wide use.
    static let shared = StockAPIService()

    // MARK: - Configuration

    /// Cache expiration in seconds
    static let cacheExpirationSeconds: TimeInterval = 60

    /// Maximum requests per minute (Finnhub free tier)
    static let maxRequestsPerMinute = 60

    /// Minimum delay between requests (in seconds)
    static let minRequestDelay: TimeInterval = 1.0

    // MARK: - Published State

    @Published var isLoading: Bool = false
    @Published var lastError: NetworkError?
    @Published var lastUpdateTime: Date?
    @Published var isOfflineMode: Bool = false

    // MARK: - Private State

    /// In-memory cache for quotes
    private var quoteCache: [String: CachedQuote] = [:]

    /// In-memory cache for provider-backed basic financial metrics.
    private var basicFinancialsCache: [String: CachedBasicFinancials] = [:]

    /// Basic financials change slowly; keep provider snapshots for one day.
    private let basicFinancialsCacheDuration: TimeInterval = 86_400

    /// Timestamps of recent requests for throttling
    private var requestTimestamps: [Date] = []

    /// URLSession for API calls
    private let session: URLSession

    /// Lock for thread-safe cache access
    private let cacheLock = NSLock()

    // MARK: - Init

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Fetch a single stock quote
    /// - Parameter symbol: Stock ticker symbol (e.g., "AAPL")
    /// - Returns: StockQuote with current price data
    func getQuote(symbol: String) async throws -> StockQuote {
        let upperSymbol = symbol.uppercased()

        // Check cache first (fresh cache always preferred)
        if let cached = getCachedQuote(for: upperSymbol), !cached.isExpired {
            log("📦 Cache hit for \(upperSymbol) (age: \(cached.formattedAge))")
            return cached.quote
        }

        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            // Offline - try to return stale cache if available
            if let staleCache = getCachedQuote(for: upperSymbol) {
                log("📦 Offline - returning stale cache for \(upperSymbol) (age: \(staleCache.formattedAge))")
                isOfflineMode = true
                return staleCache.quote
            }
            // No cache available
            isOfflineMode = true
            throw NetworkError.noConnection
        }

        // Ensure API key is configured
        try requireFinnhubConfiguration()

        // Throttle requests
        try await throttleIfNeeded()

        // Build URL
        guard let url = APIConfig.finnhubURL(endpoint: "quote", params: ["symbol": upperSymbol]) else {
            throw NetworkError.invalidResponse
        }

        log("🌐 Fetching quote for \(upperSymbol)...")

        do {
            // Make request
            let (data, response) = try await session.data(from: url)

            // Check HTTP status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Record request timestamp for throttling
            recordRequest()

            // Handle HTTP errors
            switch httpResponse.statusCode {
            case 200:
                break // Success
            case 401:
                throw NetworkError.apiKeyMissing
            case 429:
                throw NetworkError.rateLimited
            case 400...499:
                throw NetworkError.invalidSymbol(upperSymbol)
            case 500...599:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw NetworkError.unknown("HTTP \(httpResponse.statusCode)")
            }

            // Decode response
            let quote = try JSONDecoder().decode(StockQuote.self, from: data)

            // Validate quote (Finnhub returns zeros for invalid symbols)
            if quote.c == 0 && quote.pc == 0 {
                throw NetworkError.invalidSymbol(upperSymbol)
            }

            // Cache the result
            cacheQuote(quote, for: upperSymbol)

            log("✅ Got quote for \(upperSymbol): \(quote.formattedPrice) (\(quote.formattedPercentage))")

            lastUpdateTime = Date()
            lastError = nil
            isOfflineMode = false

            return quote

        } catch let error as NetworkError {
            lastError = error
            logNetworkErrorIfNeeded(error, context: "API Error for \(upperSymbol)")
            throw error
        } catch {
            let networkError = mapError(error)
            lastError = networkError
            logNetworkErrorIfNeeded(networkError, context: "Network Error for \(upperSymbol)")
            throw networkError
        }
    }

    /// Fetch multiple stock quotes
    /// - Parameter symbols: Array of ticker symbols
    /// - Returns: Dictionary mapping symbols to quotes
    func getMultipleQuotes(symbols: [String]) async -> [String: StockQuote] {
        guard APIConfig.isFinnhubConfigured else {
            ConfigWarnings.warnOnce(
                key: "FINNHUB_API_KEY_MISSING",
                message: "Finnhub API key missing. Stock requests will use cached or placeholder data."
            )
            lastError = .apiKeyMissing
            let cachedQuotes = getCachedQuotes(for: symbols)
            if !cachedQuotes.isEmpty {
                isOfflineMode = true
            }
            return cachedQuotes
        }

        var results: [String: StockQuote] = [:]

        isLoading = true
        defer { isLoading = false }

        // Use TaskGroup for parallel fetching with concurrency limit
        await withTaskGroup(of: (String, StockQuote?).self) { group in
            // Limit concurrency to avoid hitting rate limits too fast
            let maxConcurrent = 5
            var activeTasks = 0

            for symbol in symbols {
                if activeTasks >= maxConcurrent {
                    if let result = await group.next() {
                        activeTasks -= 1
                        if let quote = result.1 {
                            results[result.0] = quote
                        }
                    }
                }

                activeTasks += 1
                group.addTask {
                    // Slight random jitter to prevent thundering herd on API
                    // Reduced for better responsiveness (5-20ms)
                    try? await Task.sleep(nanoseconds: UInt64.random(in: 5_000_000...20_000_000))

                    do {
                        let quote = try await self.getQuote(symbol: symbol)
                        return (symbol.uppercased(), quote)
                    } catch {
                        await self.log("⚠️ Failed to fetch \(symbol): \(error.localizedDescription)")
                        return (symbol.uppercased(), nil)
                    }
                }
            }

            // Collect remaining results
            for await result in group {
                if let quote = result.1 {
                    results[result.0] = quote
                }
            }
        }

        return results
    }

    /// Get cached quote if available (even if expired)
    func getCachedQuote(for symbol: String) -> CachedQuote? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return quoteCache[symbol.uppercased()]
    }

    /// Get quote with explicit field-level provenance.
    func getQuoteWithProvenance(symbol: String) async -> StockQuoteResult {
        let upperSymbol = symbol.uppercased()

        if let cached = getCachedQuote(for: upperSymbol), !cached.isExpired {
            return StockQuoteResult(
                quote: cached.quote,
                provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: cached.timestamp),
                error: nil
            )
        }

        guard NetworkMonitor.shared.isConnected else {
            if let cached = getCachedQuote(for: upperSymbol) {
                return StockQuoteResult(
                    quote: cached.quote,
                    provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: cached.timestamp),
                    error: .noConnection
                )
            }

            return StockQuoteResult(
                quote: nil,
                provenance: .unavailable(reason: NetworkError.noConnection.cosmicMessage),
                error: .noConnection
            )
        }

        guard APIConfig.isFinnhubConfigured else {
            let error = NetworkError.apiKeyMissing
            lastError = error
            ConfigWarnings.warnOnce(
                key: "FINNHUB_API_KEY_MISSING",
                message: "Finnhub API key missing. Stock requests will use cached or unavailable states."
            )

            if let cached = getCachedQuote(for: upperSymbol) {
                return StockQuoteResult(
                    quote: cached.quote,
                    provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: cached.timestamp),
                    error: error
                )
            }

            return StockQuoteResult(
                quote: nil,
                provenance: .unavailable(reason: error.cosmicMessage),
                error: error
            )
        }

        do {
            let quote = try await getQuote(symbol: upperSymbol)
            let fetchedAt = getCachedQuote(for: upperSymbol)?.timestamp ?? Date()
            return StockQuoteResult(
                quote: quote,
                provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt),
                error: nil
            )
        } catch let error as NetworkError {
            if let cached = getCachedQuote(for: upperSymbol) {
                return StockQuoteResult(
                    quote: cached.quote,
                    provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: cached.timestamp),
                    error: error
                )
            }

            return StockQuoteResult(
                quote: nil,
                provenance: .unavailable(reason: error.cosmicMessage),
                error: error
            )
        } catch {
            let networkError = mapError(error)
            if let cached = getCachedQuote(for: upperSymbol) {
                return StockQuoteResult(
                    quote: cached.quote,
                    provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: cached.timestamp),
                    error: networkError
                )
            }

            return StockQuoteResult(
                quote: nil,
                provenance: .unavailable(reason: networkError.cosmicMessage),
                error: networkError
            )
        }
    }

    /// Fetch quote results sequentially so each returned field carries provenance.
    func getMultipleQuoteResults(symbols: [String]) async -> [String: StockQuoteResult] {
        var results: [String: StockQuoteResult] = [:]

        for symbol in symbols {
            let upperSymbol = symbol.uppercased()
            results[upperSymbol] = await getQuoteWithProvenance(symbol: upperSymbol)
        }

        return results
    }

    /// Get quote with fallback to cache/provider data
    func getQuoteWithFallback(symbol: String) async -> (quote: StockQuote?, isCached: Bool, error: NetworkError?) {
        let result = await getQuoteWithProvenance(symbol: symbol)
        return (result.quote, result.isCached, result.error)
    }

    /// Get all cached quotes (for offline mode)
    /// Returns quotes even if expired, for offline viewing
    func getAllCachedQuotes() -> [String: CachedQuote] {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return quoteCache
    }

    /// Get cached quotes for specific symbols (for offline portfolio)
    func getCachedQuotes(for symbols: [String]) -> [String: StockQuote] {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        var results: [String: StockQuote] = [:]
        for symbol in symbols {
            if let cached = quoteCache[symbol.uppercased()] {
                results[symbol.uppercased()] = cached.quote
            }
        }
        return results
    }

    /// Check if we have cached data for a symbol
    func hasCachedData(for symbol: String) -> Bool {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return quoteCache[symbol.uppercased()] != nil
    }

    /// Get the oldest cache timestamp (for "data as of" display)
    func oldestCacheTimestamp(for symbols: [String]) -> Date? {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        var oldest: Date?
        for symbol in symbols {
            if let cached = quoteCache[symbol.uppercased()] {
                if oldest == nil || cached.timestamp < oldest! {
                    oldest = cached.timestamp
                }
            }
        }
        return oldest
    }

    /// Clear all cached quotes
    func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        quoteCache.removeAll()
        log("🗑️ Cache cleared")
    }

    /// Test the API connection
    func testConnection() async -> Bool {
        do {
            _ = try await getQuote(symbol: "AAPL")
            return true
        } catch {
            return false
        }
    }

    // MARK: - Cache Management

    private func cacheQuote(_ quote: StockQuote, for symbol: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        quoteCache[symbol] = CachedQuote(
            quote: quote,
            timestamp: Date(),
            symbol: symbol
        )
    }

    // MARK: - Throttling

    private func throttleIfNeeded() async throws {
        // Remove old timestamps (older than 1 minute)
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        requestTimestamps.removeAll { $0 < oneMinuteAgo }

        // Check if we're at the rate limit
        if requestTimestamps.count >= Self.maxRequestsPerMinute {
            log("⏳ Rate limit approaching, waiting...")
            throw NetworkError.rateLimited
        }

        // Ensure minimum delay between requests
        if let lastRequest = requestTimestamps.last {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < Self.minRequestDelay {
                let waitTime = Self.minRequestDelay - timeSinceLastRequest
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
    }

    private func recordRequest() {
        requestTimestamps.append(Date())
    }

    private func requireFinnhubConfiguration() throws {
        guard APIConfig.isFinnhubConfigured else {
            lastError = .apiKeyMissing
            ConfigWarnings.warnOnce(
                key: "FINNHUB_API_KEY_MISSING",
                message: "Finnhub API key missing. Stock requests will use cached or placeholder data."
            )
            throw NetworkError.apiKeyMissing
        }
    }

    private func logNetworkErrorIfNeeded(_ error: NetworkError, context: String) {
        guard error != .apiKeyMissing else { return }
        log("❌ \(context): \(error.cosmicMessage)")
    }

    // MARK: - Error Mapping

    private func mapError(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }

        let nsError = error as NSError

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .noConnection
        case NSURLErrorTimedOut:
            return .timeout
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return .serverError(statusCode: 503)
        default:
            return .unknown(error.localizedDescription)
        }
    }

    // MARK: - Logging

    private func log(_ message: String) {
        #if DEBUG
        print("[StockAPI] \(message)")
        #endif
    }
}

// MARK: - Stock Extension
// =======================
// Convenience methods to update Stock models with live quotes

extension Stock {
    /// Create a copy with updated price data from a quote
    func withQuote(_ quote: StockQuote) -> Stock {
        var updated = self
        updated.currentPrice = quote.currentPrice.isFinite ? quote.currentPrice : currentPrice
        updated.priceChange = quote.priceChange.isFinite ? quote.priceChange : priceChange
        updated.percentageChange = quote.percentageChange.isFinite ? quote.percentageChange : percentageChange
        return updated
    }

    /// Update this stock's prices in place
    mutating func updateWithQuote(_ quote: StockQuote) {
        currentPrice = quote.currentPrice.isFinite ? quote.currentPrice : currentPrice
        priceChange = quote.priceChange.isFinite ? quote.priceChange : priceChange
        percentageChange = quote.percentageChange.isFinite ? quote.percentageChange : percentageChange
    }
}

// MARK: - Search Result Model
// ============================
// Response model for Finnhub symbol search endpoint

struct SymbolSearchResult: Codable {
    let count: Int
    let result: [SymbolMatch]
}

struct SymbolMatch: Codable, Identifiable, Hashable {
    let description: String    // Company name
    let displaySymbol: String  // Ticker symbol for display
    let symbol: String         // Actual symbol to use for quotes
    let type: String           // Security type (e.g., "Common Stock")

    var id: String { symbol }

    /// Whether this is a common stock (filter out ADRs, ETFs, etc.)
    var isCommonStock: Bool {
        type == "Common Stock" || type == "EQS"
    }
}

// MARK: - Finnhub Basic Financials Models
// =======================================

struct FinnhubBasicFinancialsResponse: Decodable {
    let metric: [String: Double]

    private enum CodingKeys: String, CodingKey {
        case metric
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let metricContainer = try? container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .metric) else {
            metric = [:]
            return
        }

        var parsed: [String: Double] = [:]
        for key in metricContainer.allKeys {
            if let value = try? metricContainer.decode(Double.self, forKey: key), value.isFinite {
                parsed[key.stringValue] = value
            } else if let intValue = try? metricContainer.decode(Int.self, forKey: key) {
                parsed[key.stringValue] = Double(intValue)
            } else if let stringValue = try? metricContainer.decode(String.self, forKey: key),
                      let value = Double(stringValue),
                      value.isFinite {
                parsed[key.stringValue] = value
            }
        }

        metric = parsed
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

// MARK: - Search Methods
// ======================
// Symbol search functionality

extension StockAPIService {

    /// Search for stock symbols matching a query
    /// - Parameter query: Search term (company name or ticker)
    /// - Returns: Array of matching symbols
    func searchSymbols(query: String) async throws -> [SymbolMatch] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        // Ensure API key is configured
        try requireFinnhubConfiguration()

        // Build URL for symbol search
        guard let url = APIConfig.finnhubURL(endpoint: "search", params: ["q": trimmedQuery]) else {
            throw NetworkError.invalidResponse
        }

        log("🔍 Searching for: \(trimmedQuery)...")

        do {
            // Make request
            let (data, response) = try await session.data(from: url)

            // Check HTTP status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Record request timestamp for throttling
            recordRequest()

            // Handle HTTP errors
            switch httpResponse.statusCode {
            case 200:
                break // Success
            case 401:
                throw NetworkError.apiKeyMissing
            case 429:
                throw NetworkError.rateLimited
            default:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }

            // Decode response
            let searchResult = try JSONDecoder().decode(SymbolSearchResult.self, from: data)

            // Filter to common stocks only and limit results
            let filtered = searchResult.result
                .filter { $0.isCommonStock }
                .prefix(15)

            log("✅ Found \(filtered.count) results for '\(trimmedQuery)'")

            return Array(filtered)

        } catch let error as NetworkError {
            logNetworkErrorIfNeeded(error, context: "Search Error")
            throw error
        } catch {
            let networkError = mapError(error)
            logNetworkErrorIfNeeded(networkError, context: "Search Error")
            throw networkError
        }
    }
}

// MARK: - Basic Financials Methods
// ================================

extension StockAPIService {

    func fetchBasicFinancialsResult(symbol: String) async throws -> BasicFinancialsResult {
        let upperSymbol = symbol.uppercased()

        if let cached = basicFinancialsCache[upperSymbol],
           cached.age < basicFinancialsCacheDuration {
            return BasicFinancialsResult(
                metrics: cached.metrics,
                provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: cached.timestamp)
            )
        }

        guard NetworkMonitor.shared.isConnected else {
            if let cached = basicFinancialsCache[upperSymbol] {
                return BasicFinancialsResult(
                    metrics: cached.metrics,
                    provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: cached.timestamp)
                )
            }
            throw NetworkError.noConnection
        }

        try requireFinnhubConfiguration()
        try await throttleIfNeeded()

        guard let url = APIConfig.finnhubURL(
            endpoint: "stock/metric",
            params: [
                "symbol": upperSymbol,
                "metric": "all"
            ]
        ) else {
            throw NetworkError.invalidResponse
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            recordRequest()

            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                throw NetworkError.apiKeyMissing
            case 429:
                throw NetworkError.rateLimited
            case 400...499:
                throw NetworkError.invalidSymbol(upperSymbol)
            case 500...599:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw NetworkError.unknown("HTTP \(httpResponse.statusCode)")
            }

            let decoded = try JSONDecoder().decode(FinnhubBasicFinancialsResponse.self, from: data)
            guard !decoded.metric.isEmpty else {
                throw NetworkError.invalidResponse
            }

            let fetchedAt = Date()
            basicFinancialsCache[upperSymbol] = CachedBasicFinancials(
                metrics: decoded.metric,
                timestamp: fetchedAt
            )

            lastUpdateTime = fetchedAt
            lastError = nil
            isOfflineMode = false

            return BasicFinancialsResult(
                metrics: decoded.metric,
                provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
            )
        } catch let error as NetworkError {
            lastError = error
            if let cached = basicFinancialsCache[upperSymbol] {
                return BasicFinancialsResult(
                    metrics: cached.metrics,
                    provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: cached.timestamp)
                )
            }
            throw error
        } catch let error as DecodingError {
            log("❌ Basic Financials Decoding Error: \(error)")
            if let cached = basicFinancialsCache[upperSymbol] {
                return BasicFinancialsResult(
                    metrics: cached.metrics,
                    provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: cached.timestamp)
                )
            }
            throw NetworkError.decodingError
        } catch {
            let networkError = mapError(error)
            lastError = networkError
            if let cached = basicFinancialsCache[upperSymbol] {
                return BasicFinancialsResult(
                    metrics: cached.metrics,
                    provenance: .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: cached.timestamp)
                )
            }
            throw networkError
        }
    }

    func fetchKeyStatsResult(symbol: String) async -> ProvenancedValue<StockKeyStats> {
        let quoteResult = await getQuoteWithProvenance(symbol: symbol)

        var fieldProvenance: [StockKeyStats.Field: FinancialDataProvenance] = [
            .open: quoteResult.provenance,
            .dayRange: quoteResult.provenance
        ]

        var open: Double?
        var dayHigh: Double?
        var dayLow: Double?
        if let quote = quoteResult.quote {
            open = quote.o > 0 ? quote.o : nil
            dayHigh = quote.h > 0 ? quote.h : nil
            dayLow = quote.l > 0 ? quote.l : nil
        }

        var marketCap: Double?
        var peRatio: Double?
        var weekHigh52: Double?
        var weekLow52: Double?
        var dividendYield: Double?
        let metricUnavailable = FinancialDataProvenance.unavailable(reason: "Provider fundamentals unavailable")

        do {
            let basic = try await fetchBasicFinancialsResult(symbol: symbol)
            let metrics = basic.metrics
            fieldProvenance[.marketCap] = basic.provenance
            fieldProvenance[.peRatio] = basic.provenance
            fieldProvenance[.week52Range] = basic.provenance
            fieldProvenance[.dividendYield] = basic.provenance

            if let rawMarketCap = metrics["marketCapitalization"], rawMarketCap > 0 {
                // Finnhub reports marketCapitalization in millions for this endpoint.
                marketCap = rawMarketCap < 100_000_000 ? rawMarketCap * 1_000_000 : rawMarketCap
            }
            peRatio = metrics["peBasicExclExtraTTM"] ?? metrics["peNormalizedAnnual"]
            weekHigh52 = metrics["52WeekHigh"]
            weekLow52 = metrics["52WeekLow"]
            dividendYield = metrics["dividendYieldIndicatedAnnual"] ?? metrics["dividendYield5Y"]
        } catch {
            fieldProvenance[.marketCap] = metricUnavailable
            fieldProvenance[.peRatio] = metricUnavailable
            fieldProvenance[.week52Range] = metricUnavailable
            fieldProvenance[.dividendYield] = metricUnavailable
        }

        var volume: Int?
        var avgVolume: Int?
        let volumeUnavailable = FinancialDataProvenance.unavailable(reason: "Provider volume history unavailable")

        do {
            let history = try await HistoricalPriceService.shared.fetchHistoricalPriceResult(
                symbol: symbol,
                timeframe: .month
            )
            let volumes = history.data.map(\.volume).filter { $0 > 0 }
            volume = volumes.last
            if !volumes.isEmpty {
                avgVolume = Int(Double(volumes.reduce(0, +)) / Double(volumes.count))
            }
            fieldProvenance[.volume] = history.provenance
            fieldProvenance[.avgVolume] = history.provenance
        } catch {
            fieldProvenance[.volume] = volumeUnavailable
            fieldProvenance[.avgVolume] = volumeUnavailable
        }

        let stats = StockKeyStats(
            open: open,
            dayHigh: dayHigh,
            dayLow: dayLow,
            volume: volume,
            avgVolume: avgVolume,
            marketCap: marketCap,
            peRatio: peRatio,
            weekHigh52: weekHigh52,
            weekLow52: weekLow52,
            dividendYield: dividendYield,
            fieldProvenance: fieldProvenance
        )

        let providerProvenances = fieldProvenance.values.filter(\.isProviderBacked)
        let overall: FinancialDataProvenance
        if providerProvenances.contains(where: { if case .live = $0 { return true }; return false }) {
            overall = providerProvenances.first { if case .live = $0 { return true }; return false }
                ?? .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: Date())
        } else if let cached = providerProvenances.first {
            overall = cached
        } else {
            overall = .unavailable(reason: "Provider fundamentals unavailable")
        }

        return ProvenancedValue(
            value: stats.hasAnyAvailableField ? stats : nil,
            provenance: overall
        )
    }
}

// MARK: - Finnhub IPO Response Models
// ====================================

/// Response model for Finnhub IPO calendar endpoint
struct FinnhubIPOResponse: Codable {
    let ipoCalendar: [FinnhubIPO]
}

/// Individual IPO data from Finnhub
struct FinnhubIPO: Codable {
    let symbol: String
    let date: String
    let exchange: String?
    let name: String
    let price: String?  // Can be range like "15-17" or single price
    let shares: Int?
    let status: String?
}

// MARK: - IPO Calendar Methods
// ============================

extension StockAPIService {

    /// Fetch IPO calendar for a date range
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Array of FinnhubIPO objects
    func fetchIPOCalendar(from: Date, to: Date) async throws -> [FinnhubIPO] {
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noConnection
        }

        // Ensure API key is configured
        try requireFinnhubConfiguration()

        // Throttle requests
        try await throttleIfNeeded()

        // Format dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fromStr = dateFormatter.string(from: from)
        let toStr = dateFormatter.string(from: to)

        // Build URL
        guard let url = APIConfig.finnhubURL(
            endpoint: "calendar/ipo",
            params: ["from": fromStr, "to": toStr]
        ) else {
            throw NetworkError.invalidResponse
        }

        log("🌐 Fetching IPO calendar from \(fromStr) to \(toStr)...")

        do {
            // Make request
            let (data, response) = try await session.data(from: url)

            // Check HTTP status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Record request timestamp for throttling
            recordRequest()

            // Handle HTTP errors
            switch httpResponse.statusCode {
            case 200:
                break // Success
            case 401:
                throw NetworkError.apiKeyMissing
            case 429:
                throw NetworkError.rateLimited
            case 500...599:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw NetworkError.unknown("HTTP \(httpResponse.statusCode)")
            }

            // Decode response
            let ipoResponse = try JSONDecoder().decode(FinnhubIPOResponse.self, from: data)

            log("✅ Fetched \(ipoResponse.ipoCalendar.count) IPOs")

            lastUpdateTime = Date()
            lastError = nil
            isOfflineMode = false

            return ipoResponse.ipoCalendar

        } catch let error as NetworkError {
            lastError = error
            logNetworkErrorIfNeeded(error, context: "IPO Calendar Error")
            throw error
        } catch let error as DecodingError {
            log("❌ IPO Calendar Decoding Error: \(error)")
            throw NetworkError.unknown("Failed to decode IPO data")
        } catch {
            let networkError = mapError(error)
            lastError = networkError
            log("❌ IPO Calendar Network Error: \(networkError.cosmicMessage)")
            throw networkError
        }
    }
}

// MARK: - Finnhub Earnings Response Models
// ========================================

/// Response model for Finnhub earnings calendar endpoint
struct FinnhubEarningsResponse: Codable {
    let earningsCalendar: [FinnhubEarnings]
}

/// Individual earnings data from Finnhub
struct FinnhubEarnings: Codable {
    let date: String
    let epsActual: Double?
    let epsEstimate: Double?
    let hour: String?  // "bmo" (before market open), "amc" (after market close), "dmh" (during market hours)
    let quarter: Int?
    let revenueActual: Double?
    let revenueEstimate: Double?
    let symbol: String
    let year: Int?
}

// MARK: - Earnings Calendar Methods
// =================================

extension StockAPIService {

    /// Fetch earnings calendar for a date range
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Array of FinnhubEarnings objects
    func fetchEarningsCalendar(from: Date, to: Date) async throws -> [FinnhubEarnings] {
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noConnection
        }

        // Ensure API key is configured
        try requireFinnhubConfiguration()

        // Throttle requests
        try await throttleIfNeeded()

        // Format dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fromStr = dateFormatter.string(from: from)
        let toStr = dateFormatter.string(from: to)

        // Build URL
        guard let url = APIConfig.finnhubURL(
            endpoint: "calendar/earnings",
            params: ["from": fromStr, "to": toStr]
        ) else {
            throw NetworkError.invalidResponse
        }

        log("🌐 Fetching earnings calendar from \(fromStr) to \(toStr)...")

        do {
            // Make request
            let (data, response) = try await session.data(from: url)

            // Check HTTP status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Record request timestamp for throttling
            recordRequest()

            // Handle HTTP errors
            switch httpResponse.statusCode {
            case 200:
                break // Success
            case 401:
                throw NetworkError.apiKeyMissing
            case 429:
                throw NetworkError.rateLimited
            case 500...599:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw NetworkError.unknown("HTTP \(httpResponse.statusCode)")
            }

            // Decode response
            let earningsResponse = try JSONDecoder().decode(FinnhubEarningsResponse.self, from: data)

            log("✅ Fetched \(earningsResponse.earningsCalendar.count) earnings events")

            lastUpdateTime = Date()
            lastError = nil
            isOfflineMode = false

            return earningsResponse.earningsCalendar

        } catch let error as NetworkError {
            lastError = error
            logNetworkErrorIfNeeded(error, context: "Earnings Calendar Error")
            throw error
        } catch let error as DecodingError {
            log("❌ Earnings Calendar Decoding Error: \(error)")
            throw NetworkError.unknown("Failed to decode earnings data")
        } catch {
            let networkError = mapError(error)
            lastError = networkError
            log("❌ Earnings Calendar Network Error: \(networkError.cosmicMessage)")
            throw networkError
        }
    }
}

// MARK: - FinnhubCandleResponse Volume Extensions
// ================================================

extension FinnhubCandleResponse {
    /// Check if the response has valid volume data
    var hasValidVolumeData: Bool {
        s == "ok" && (v?.isEmpty == false)
    }

    /// Latest volume from the candles
    var latestVolume: Int? {
        v?.last
    }

    /// Average volume across all candles
    var averageVolume: Double? {
        guard let volumes = v, !volumes.isEmpty else { return nil }
        let sum = volumes.reduce(0, +)
        return Double(sum) / Double(volumes.count)
    }
}

// MARK: - Candles Methods
// =======================

extension StockAPIService {

    /// Fetch stock candles (OHLCV data) for a date range
    /// - Parameters:
    ///   - symbol: Stock ticker symbol
    ///   - resolution: Candle resolution (1, 5, 15, 30, 60, D, W, M)
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: FinnhubCandleResponse with OHLCV data
    func fetchCandles(symbol: String, resolution: String, from: Date, to: Date) async throws -> FinnhubCandleResponse {
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noConnection
        }

        // Ensure API key is configured
        try requireFinnhubConfiguration()

        // Throttle requests
        try await throttleIfNeeded()

        // Convert dates to timestamps
        let fromTimestamp = Int(from.timeIntervalSince1970)
        let toTimestamp = Int(to.timeIntervalSince1970)

        // Build URL
        guard let url = APIConfig.finnhubURL(
            endpoint: "stock/candle",
            params: [
                "symbol": symbol.uppercased(),
                "resolution": resolution,
                "from": String(fromTimestamp),
                "to": String(toTimestamp)
            ]
        ) else {
            throw NetworkError.invalidResponse
        }

        log("🌐 Fetching candles for \(symbol) (\(resolution))...")

        do {
            // Make request
            let (data, response) = try await session.data(from: url)

            // Check HTTP status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Record request timestamp for throttling
            recordRequest()

            // Handle HTTP errors
            switch httpResponse.statusCode {
            case 200:
                break // Success
            case 401:
                throw NetworkError.apiKeyMissing
            case 429:
                throw NetworkError.rateLimited
            case 500...599:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw NetworkError.unknown("HTTP \(httpResponse.statusCode)")
            }

            // Decode response
            let candleResponse = try JSONDecoder().decode(FinnhubCandleResponse.self, from: data)

            if candleResponse.s == "no_data" {
                log("⚠️ No candle data available for \(symbol)")
            } else {
                log("✅ Fetched \(candleResponse.v?.count ?? 0) candles for \(symbol)")
            }

            lastUpdateTime = Date()
            lastError = nil
            isOfflineMode = false

            return candleResponse

        } catch let error as NetworkError {
            lastError = error
            logNetworkErrorIfNeeded(error, context: "Candles Error for \(symbol)")
            throw error
        } catch let error as DecodingError {
            log("❌ Candles Decoding Error: \(error)")
            throw NetworkError.unknown("Failed to decode candle data")
        } catch {
            let networkError = mapError(error)
            lastError = networkError
            log("❌ Candles Network Error: \(networkError.cosmicMessage)")
            throw networkError
        }
    }

    /// Fetch recent candles for volume calculation (last 30 days)
    /// - Parameter symbol: Stock ticker symbol
    /// - Returns: FinnhubCandleResponse with daily OHLCV data
    func fetchRecentCandles(symbol: String) async throws -> FinnhubCandleResponse {
        let calendar = Calendar.current
        let to = Date()
        guard let from = calendar.date(byAdding: .day, value: -30, to: to) else {
            throw NetworkError.unknown("Failed to calculate date range")
        }
        // Use Yahoo Finance for historical candles (Finnhub free tier blocks /stock/candle)
        return try await YahooFinanceService.shared.fetchCandles(symbol: symbol, resolution: "D", from: from, to: to)
    }
}

// MARK: - Test Functions
// ======================
// Debug functions to test API connectivity

extension StockAPIService {

    /// Run a comprehensive API test
    func runDiagnosticTest() async {
        #if DEBUG
        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔬 FINNHUB API DIAGNOSTIC TEST")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        // Check configuration
        APIConfig.printStatus()
        print("")

        // Test valid symbols
        let testSymbols = ["AAPL", "GOOGL", "MSFT", "TSLA", "NVDA"]
        print("📊 Testing \(testSymbols.count) stock quotes...")
        print("")

        for symbol in testSymbols {
            do {
                let quote = try await getQuote(symbol: symbol)
                print("  ✅ \(symbol): \(quote.formattedPrice) (\(quote.formattedPercentage))")
            } catch {
                print("  ❌ \(symbol): \(error.localizedDescription)")
            }
        }

        print("")

        // Test invalid symbol
        print("🧪 Testing error handling with invalid symbol...")
        do {
            _ = try await getQuote(symbol: "FAKESYMBOL123")
            print("  ⚠️ Expected error but got success")
        } catch let error as NetworkError {
            print("  ✅ Correctly handled: \(error.cosmicMessage)")
        } catch {
            print("  ✅ Error caught: \(error.localizedDescription)")
        }

        print("")

        // Cache status
        print("📦 Cache Status:")
        print("  Cached symbols: \(quoteCache.keys.sorted().joined(separator: ", "))")

        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✨ DIAGNOSTIC TEST COMPLETE")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        #endif
    }

    /// Quick test for a single symbol
    func quickTest(symbol: String = "AAPL") async {
        #if DEBUG
        print("[StockAPI] Quick test for \(symbol)...")
        do {
            let quote = try await getQuote(symbol: symbol)
            print("[StockAPI] ✅ \(symbol): \(quote.formattedPrice) (\(quote.formattedPercentage))")
        } catch {
            print("[StockAPI] ❌ Error: \(error.localizedDescription)")
        }
        #endif
    }
}
