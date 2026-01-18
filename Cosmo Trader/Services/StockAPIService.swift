import Foundation
import Combine

// MARK: - StockQuote
// ==================
// Response model for Finnhub quote endpoint

struct StockQuote: Codable {
    /// Current price
    let c: Double
    /// Change
    let d: Double?
    /// Percent change
    let dp: Double?
    /// High price of the day
    let h: Double
    /// Low price of the day
    let l: Double
    /// Open price of the day
    let o: Double
    /// Previous close price
    let pc: Double
    /// Timestamp
    let t: Int?

    /// Current price (alias)
    var currentPrice: Double { c }

    /// Price change from previous close
    var priceChange: Double { d ?? (c - pc) }

    /// Percentage change from previous close
    var percentageChange: Double { dp ?? ((c - pc) / pc * 100) }

    /// Is the price up from previous close?
    var isPositive: Bool { priceChange >= 0 }

    /// Formatted current price
    var formattedPrice: String {
        String(format: "$%.2f", currentPrice)
    }

    /// Formatted change with sign
    var formattedChange: String {
        let sign = priceChange >= 0 ? "+" : ""
        return String(format: "%@$%.2f", sign, priceChange)
    }

    /// Formatted percentage change
    var formattedPercentage: String {
        let sign = percentageChange >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, percentageChange)
    }
}

// MARK: - CachedQuote
// ===================
// Wrapper for cached quotes with timestamp

struct CachedQuote {
    let quote: StockQuote
    let timestamp: Date
    let symbol: String

    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }

    var isExpired: Bool {
        age > StockAPIService.cacheExpirationSeconds
    }

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

// MARK: - StockAPIService
// =======================
// Service for fetching real-time stock data from Finnhub.
// Features:
// - Async/await API
// - Request throttling (60 calls/min)
// - In-memory caching (60 second expiration)
// - Graceful error handling

@MainActor
final class StockAPIService: ObservableObject {

    // MARK: - Singleton

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

        // Check cache first
        if let cached = getCachedQuote(for: upperSymbol), !cached.isExpired {
            log("📦 Cache hit for \(upperSymbol) (age: \(cached.formattedAge))")
            return cached.quote
        }

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
            log("❌ API Error for \(upperSymbol): \(error.cosmicMessage)")
            throw error
        } catch {
            let networkError = mapError(error)
            lastError = networkError
            log("❌ Network Error for \(upperSymbol): \(networkError.cosmicMessage)")
            throw networkError
        }
    }

    /// Fetch multiple stock quotes
    /// - Parameter symbols: Array of ticker symbols
    /// - Returns: Dictionary mapping symbols to quotes
    func getMultipleQuotes(symbols: [String]) async -> [String: StockQuote] {
        var results: [String: StockQuote] = [:]

        isLoading = true
        defer { isLoading = false }

        for symbol in symbols {
            do {
                let quote = try await getQuote(symbol: symbol)
                results[symbol.uppercased()] = quote
            } catch {
                log("⚠️ Failed to fetch \(symbol): \(error.localizedDescription)")
                // Continue with other symbols
            }

            // Small delay between requests to avoid rate limiting
            if symbol != symbols.last {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
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

    /// Get quote with fallback to cache/mock data
    func getQuoteWithFallback(symbol: String) async -> (quote: StockQuote?, isCached: Bool, error: NetworkError?) {
        do {
            let quote = try await getQuote(symbol: symbol)
            return (quote, false, nil)
        } catch let error as NetworkError {
            // Try to return cached data even if expired
            if let cached = getCachedQuote(for: symbol) {
                log("📦 Using stale cache for \(symbol) (age: \(cached.formattedAge))")
                isOfflineMode = true
                return (cached.quote, true, error)
            }
            return (nil, false, error)
        } catch {
            if let cached = getCachedQuote(for: symbol) {
                isOfflineMode = true
                return (cached.quote, true, mapError(error))
            }
            return (nil, false, mapError(error))
        }
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
        updated.currentPrice = quote.currentPrice
        updated.priceChange = quote.priceChange
        updated.percentageChange = quote.percentageChange
        return updated
    }

    /// Update this stock's prices in place
    mutating func updateWithQuote(_ quote: StockQuote) {
        currentPrice = quote.currentPrice
        priceChange = quote.priceChange
        percentageChange = quote.percentageChange
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
            log("❌ Search Error: \(error.cosmicMessage)")
            throw error
        } catch {
            let networkError = mapError(error)
            log("❌ Search Error: \(networkError.cosmicMessage)")
            throw networkError
        }
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
