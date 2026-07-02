import Foundation
import SwiftUI

// MARK: - ChartPatternService
// ============================
// Detects technical chart patterns from OHLC candlestick data.
// Combines traditional technical analysis with cosmic interpretation.
//
// Patterns detected:
// - Candlestick patterns (Doji, Hammer, Shooting Star, Engulfing)
// - Moving average crossovers (Golden Cross, Death Cross)
// - RSI extremes (Overbought, Oversold)
// - Breakouts and support/resistance tests

// MARK: - Chart Pattern Enum

enum ChartPattern: String, CaseIterable, Identifiable {
    // Candlestick Patterns
    case doji = "Doji"
    case hammer = "Hammer"
    case shootingStar = "Shooting Star"
    case engulfingBullish = "Bullish Engulfing"
    case engulfingBearish = "Bearish Engulfing"
    case morningstar = "Morning Star"
    case eveningstar = "Evening Star"

    // Moving Average Patterns
    case goldenCross = "Golden Cross"      // 50 MA crosses above 200 MA
    case deathCross = "Death Cross"        // 50 MA crosses below 200 MA

    // Trend Patterns
    case breakoutUp = "Bullish Breakout"
    case breakoutDown = "Bearish Breakdown"
    case supportTest = "Testing Support"
    case resistanceTest = "Testing Resistance"

    // Momentum
    case overbought = "Overbought (RSI)"
    case oversold = "Oversold (RSI)"

    var id: String { rawValue }

    var sentiment: PatternSentiment {
        switch self {
        case .hammer, .engulfingBullish, .goldenCross, .breakoutUp, .oversold, .morningstar:
            return .bullish
        case .shootingStar, .engulfingBearish, .deathCross, .breakoutDown, .overbought, .eveningstar:
            return .bearish
        case .doji, .supportTest, .resistanceTest:
            return .neutral
        }
    }

    var icon: String {
        switch self {
        case .doji: return "equal.circle"
        case .hammer: return "hammer.fill"
        case .shootingStar: return "star.fill"
        case .engulfingBullish, .morningstar: return "sunrise.fill"
        case .engulfingBearish, .eveningstar: return "sunset.fill"
        case .goldenCross: return "sparkles"
        case .deathCross: return "xmark.circle.fill"
        case .breakoutUp: return "arrow.up.right.circle.fill"
        case .breakoutDown: return "arrow.down.right.circle.fill"
        case .supportTest: return "arrow.down.to.line"
        case .resistanceTest: return "arrow.up.to.line"
        case .overbought: return "flame.fill"
        case .oversold: return "snowflake"
        }
    }

    var description: String {
        switch self {
        case .doji:
            return "Indecision candle where open and close are nearly equal"
        case .hammer:
            return "Potential bullish reversal with long lower shadow"
        case .shootingStar:
            return "Potential bearish reversal with long upper shadow"
        case .engulfingBullish:
            return "Large green candle fully engulfs previous red candle"
        case .engulfingBearish:
            return "Large red candle fully engulfs previous green candle"
        case .morningstar:
            return "Three-candle bullish reversal pattern"
        case .eveningstar:
            return "Three-candle bearish reversal pattern"
        case .goldenCross:
            return "50-day MA crosses above 200-day MA - major bullish signal"
        case .deathCross:
            return "50-day MA crosses below 200-day MA - major bearish signal"
        case .breakoutUp:
            return "Price breaks above resistance level"
        case .breakoutDown:
            return "Price breaks below support level"
        case .supportTest:
            return "Price testing a key support level"
        case .resistanceTest:
            return "Price testing a key resistance level"
        case .overbought:
            return "RSI above 70 indicates potential pullback"
        case .oversold:
            return "RSI below 30 indicates potential bounce"
        }
    }

    var riskLevel: String {
        switch sentiment {
        case .bullish: return "Lower Risk"
        case .bearish: return "Higher Risk"
        case .neutral: return "Wait for Confirmation"
        }
    }
}

// MARK: - Pattern Sentiment

enum PatternSentiment: String {
    case bullish = "Bullish"
    case bearish = "Bearish"
    case neutral = "Neutral"

    var color: Color {
        switch self {
        case .bullish: return CosmicTheme.positive
        case .bearish: return CosmicTheme.negative
        case .neutral: return CosmicTheme.textSecondary
        }
    }

    var icon: String {
        switch self {
        case .bullish: return "arrow.up.right"
        case .bearish: return "arrow.down.right"
        case .neutral: return "arrow.left.arrow.right"
        }
    }
}

// MARK: - Detected Pattern

struct DetectedPattern: Identifiable {
    let id = UUID()
    let pattern: ChartPattern
    let confidence: Double  // 0-100
    let detectedAt: Date
    let priceAtDetection: Double
    let details: String?

    init(pattern: ChartPattern, confidence: Double, detectedAt: Date, priceAtDetection: Double, details: String? = nil) {
        self.pattern = pattern
        self.confidence = min(100, max(0, confidence))
        self.detectedAt = detectedAt
        self.priceAtDetection = priceAtDetection
        self.details = details
    }

    var formattedConfidence: String {
        String(format: "%.0f%%", confidence)
    }

    var formattedPrice: String {
        String(format: "$%.2f", priceAtDetection)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: detectedAt)
    }

    var isPremiumPattern: Bool {
        switch pattern {
        case .goldenCross, .deathCross, .morningstar, .eveningstar:
            return true
        default:
            return false
        }
    }
}

// MARK: - Chart Pattern Service

@MainActor
class ChartPatternService {

    // MARK: - Singleton

    static let shared = ChartPatternService()

    // MARK: - State

    private(set) var isAnalyzing: Bool = false
    private(set) var lastError: Error?

    // MARK: - Caching

    /// Cache for OHLC data: key = "symbol-days", value = (data, fetchedAt)
    private var ohlcCache: [String: (data: [OHLCData], fetchedAt: Date)] = [:]

    /// Cache duration (1 hour - pattern analysis doesn't need real-time data)
    private let cacheDuration: TimeInterval = 3600

    private init() {}

    // MARK: - Main Detection

    /// Detect all patterns from OHLC data
    func detectPatterns(ohlc: [OHLCData]) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []

        guard ohlc.count >= 3 else { return patterns }

        // Check for candlestick patterns (last 3 candles)
        if let candlePattern = detectCandlestickPattern(recent: Array(ohlc.suffix(3))) {
            patterns.append(candlePattern)
        }

        // Check for MA crossovers (need 200+ days)
        if ohlc.count >= 200 {
            if let crossover = detectMACrossover(ohlc: ohlc) {
                patterns.append(crossover)
            }
        }

        // Check RSI
        if let rsiPattern = detectRSIExtreme(ohlc: ohlc) {
            patterns.append(rsiPattern)
        }

        // Check breakouts
        if let breakout = detectBreakout(ohlc: ohlc) {
            patterns.append(breakout)
        }

        // Check support/resistance
        if let srTest = detectSupportResistanceTest(ohlc: ohlc) {
            patterns.append(srTest)
        }

        // Sort by confidence
        return patterns.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Candlestick Pattern Detection

    private func detectCandlestickPattern(recent: [OHLCData]) -> DetectedPattern? {
        guard let latest = recent.last else { return nil }

        let bodySize = latest.bodySize
        let totalRange = latest.totalRange
        let upperWick = latest.upperWick
        let lowerWick = latest.lowerWick

        // Doji: Body is < 10% of total range
        if totalRange > 0 && bodySize < totalRange * 0.1 {
            return DetectedPattern(
                pattern: .doji,
                confidence: 80,
                detectedAt: latest.date,
                priceAtDetection: latest.close,
                details: "Body size: \(String(format: "%.1f%%", (bodySize / totalRange) * 100)) of range"
            )
        }

        // Hammer: Small body at top, long lower wick (at least 2x body)
        if bodySize > 0 && lowerWick > bodySize * 2 && upperWick < bodySize * 0.5 {
            return DetectedPattern(
                pattern: .hammer,
                confidence: 75,
                detectedAt: latest.date,
                priceAtDetection: latest.close,
                details: "Lower wick is \(String(format: "%.1fx", lowerWick / bodySize)) the body size"
            )
        }

        // Shooting Star: Small body at bottom, long upper wick
        if bodySize > 0 && upperWick > bodySize * 2 && lowerWick < bodySize * 0.5 {
            return DetectedPattern(
                pattern: .shootingStar,
                confidence: 75,
                detectedAt: latest.date,
                priceAtDetection: latest.close,
                details: "Upper wick is \(String(format: "%.1fx", upperWick / bodySize)) the body size"
            )
        }

        // Engulfing patterns (need 2 candles)
        if recent.count >= 2 {
            let prev = recent[recent.count - 2]

            // Bullish Engulfing: red candle followed by larger green
            if prev.isBearish &&
               latest.isBullish &&
               latest.open < prev.close &&
               latest.close > prev.open {
                return DetectedPattern(
                    pattern: .engulfingBullish,
                    confidence: 85,
                    detectedAt: latest.date,
                    priceAtDetection: latest.close,
                    details: "Green candle engulfed \(String(format: "%.1f%%", ((latest.close - latest.open) / (prev.open - prev.close)) * 100)) of prior candle"
                )
            }

            // Bearish Engulfing: green candle followed by larger red
            if prev.isBullish &&
               latest.isBearish &&
               latest.open > prev.close &&
               latest.close < prev.open {
                return DetectedPattern(
                    pattern: .engulfingBearish,
                    confidence: 85,
                    detectedAt: latest.date,
                    priceAtDetection: latest.close,
                    details: "Red candle engulfed the prior green candle"
                )
            }
        }

        // Morning/Evening Star (need 3 candles)
        if recent.count >= 3 {
            let first = recent[recent.count - 3]
            let middle = recent[recent.count - 2]

            // Morning Star: Bearish, small body (star), Bullish
            if first.isBearish &&
               middle.bodyRatio < 0.3 &&
               latest.isBullish &&
               latest.close > (first.open + first.close) / 2 {
                return DetectedPattern(
                    pattern: .morningstar,
                    confidence: 88,
                    detectedAt: latest.date,
                    priceAtDetection: latest.close,
                    details: "Classic three-candle reversal pattern"
                )
            }

            // Evening Star: Bullish, small body (star), Bearish
            if first.isBullish &&
               middle.bodyRatio < 0.3 &&
               latest.isBearish &&
               latest.close < (first.open + first.close) / 2 {
                return DetectedPattern(
                    pattern: .eveningstar,
                    confidence: 88,
                    detectedAt: latest.date,
                    priceAtDetection: latest.close,
                    details: "Classic three-candle reversal pattern"
                )
            }
        }

        return nil
    }

    // MARK: - Moving Average Crossover

    private func detectMACrossover(ohlc: [OHLCData]) -> DetectedPattern? {
        let closes = ohlc.map { $0.close }

        let ma50 = movingAverage(closes, period: 50)
        let ma200 = movingAverage(closes, period: 200)

        guard ma50.count >= 2,
              ma200.count >= 2,
              let lastOHLC = ohlc.last,
              let currentMA50 = ma50.last,
              let currentMA200 = ma200.last else { return nil }

        let prevMA50 = ma50[ma50.count - 2]
        let prevMA200 = ma200[ma200.count - 2]

        // Golden Cross: 50 MA crosses ABOVE 200 MA
        if prevMA50 < prevMA200 && currentMA50 > currentMA200 {
            return DetectedPattern(
                pattern: .goldenCross,
                confidence: 92,
                detectedAt: lastOHLC.date,
                priceAtDetection: lastOHLC.close,
                details: "50-day MA ($\(String(format: "%.2f", currentMA50))) crossed above 200-day MA ($\(String(format: "%.2f", currentMA200)))"
            )
        }

        // Death Cross: 50 MA crosses BELOW 200 MA
        if prevMA50 > prevMA200 && currentMA50 < currentMA200 {
            return DetectedPattern(
                pattern: .deathCross,
                confidence: 92,
                detectedAt: lastOHLC.date,
                priceAtDetection: lastOHLC.close,
                details: "50-day MA ($\(String(format: "%.2f", currentMA50))) crossed below 200-day MA ($\(String(format: "%.2f", currentMA200)))"
            )
        }

        return nil
    }

    private func movingAverage(_ values: [Double], period: Int) -> [Double] {
        guard values.count >= period else { return [] }

        var result: [Double] = []
        for i in (period - 1)..<values.count {
            let slice = values[(i - period + 1)...i]
            let avg = slice.reduce(0, +) / Double(period)
            result.append(avg)
        }
        return result
    }

    // MARK: - RSI Detection

    private func detectRSIExtreme(ohlc: [OHLCData]) -> DetectedPattern? {
        guard let currentRSI = calculateRSI(ohlc: ohlc, period: 14),
              let lastOHLC = ohlc.last else { return nil }

        if currentRSI > 70 {
            return DetectedPattern(
                pattern: .overbought,
                confidence: currentRSI,
                detectedAt: lastOHLC.date,
                priceAtDetection: lastOHLC.close,
                details: "RSI at \(String(format: "%.1f", currentRSI)) - above 70 threshold"
            )
        }

        if currentRSI < 30 {
            return DetectedPattern(
                pattern: .oversold,
                confidence: 100 - currentRSI,
                detectedAt: lastOHLC.date,
                priceAtDetection: lastOHLC.close,
                details: "RSI at \(String(format: "%.1f", currentRSI)) - below 30 threshold"
            )
        }

        return nil
    }

    private func calculateRSI(ohlc: [OHLCData], period: Int) -> Double? {
        guard ohlc.count > period else { return nil }

        var gains: [Double] = []
        var losses: [Double] = []

        for i in 1..<ohlc.count {
            let change = ohlc[i].close - ohlc[i-1].close
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(abs(change))
            }
        }

        let avgGain = gains.suffix(period).reduce(0, +) / Double(period)
        let avgLoss = losses.suffix(period).reduce(0, +) / Double(period)

        if avgLoss == 0 { return 100 }

        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }

    // MARK: - Breakout Detection

    private func detectBreakout(ohlc: [OHLCData]) -> DetectedPattern? {
        guard ohlc.count >= 20 else { return nil }

        // Get the last 20 days (excluding today)
        let recentData = Array(ohlc.suffix(21).dropLast())
        guard let latest = ohlc.last else { return nil }

        // Find the high and low of the recent period
        let recentHigh = recentData.map { $0.high }.max() ?? latest.high
        let recentLow = recentData.map { $0.low }.min() ?? latest.low

        // Breakout above resistance
        if latest.close > recentHigh && latest.close > latest.open {
            let breakoutPercent = ((latest.close - recentHigh) / recentHigh) * 100
            return DetectedPattern(
                pattern: .breakoutUp,
                confidence: min(90, 70 + breakoutPercent * 5),
                detectedAt: latest.date,
                priceAtDetection: latest.close,
                details: "Broke above 20-day high of $\(String(format: "%.2f", recentHigh))"
            )
        }

        // Breakdown below support
        if latest.close < recentLow && latest.close < latest.open {
            let breakdownPercent = ((recentLow - latest.close) / recentLow) * 100
            return DetectedPattern(
                pattern: .breakoutDown,
                confidence: min(90, 70 + breakdownPercent * 5),
                detectedAt: latest.date,
                priceAtDetection: latest.close,
                details: "Broke below 20-day low of $\(String(format: "%.2f", recentLow))"
            )
        }

        return nil
    }

    // MARK: - Support/Resistance Test

    private func detectSupportResistanceTest(ohlc: [OHLCData]) -> DetectedPattern? {
        guard ohlc.count >= 20 else { return nil }

        let recentData = Array(ohlc.suffix(21).dropLast())
        guard let latest = ohlc.last else { return nil }

        let recentHigh = recentData.map { $0.high }.max() ?? latest.high
        let recentLow = recentData.map { $0.low }.min() ?? latest.low

        // Testing resistance (within 1% of high)
        let resistanceThreshold = recentHigh * 0.99
        if latest.high >= resistanceThreshold && latest.close < recentHigh {
            return DetectedPattern(
                pattern: .resistanceTest,
                confidence: 70,
                detectedAt: latest.date,
                priceAtDetection: latest.close,
                details: "Testing resistance at $\(String(format: "%.2f", recentHigh))"
            )
        }

        // Testing support (within 1% of low)
        let supportThreshold = recentLow * 1.01
        if latest.low <= supportThreshold && latest.close > recentLow {
            return DetectedPattern(
                pattern: .supportTest,
                confidence: 70,
                detectedAt: latest.date,
                priceAtDetection: latest.close,
                details: "Testing support at $\(String(format: "%.2f", recentLow))"
            )
        }

        return nil
    }

    // MARK: - Get OHLC Data for Stock

    /// Fetch OHLC data for a stock from API (async)
    func fetchOHLCData(for symbol: String, days: Int = 365) async -> [OHLCData] {
        isAnalyzing = true
        lastError = nil

        // Check cache first
        let cacheKey = "\(symbol)-\(days)"
        if let cached = ohlcCache[cacheKey],
           Date().timeIntervalSince(cached.fetchedAt) < cacheDuration {
            log("📦 Cache hit for \(symbol) OHLC data")
            isAnalyzing = false
            return cached.data
        }

        // Fetch from API
        do {
            let to = Date()
            guard let from = Calendar.current.date(byAdding: .day, value: -days, to: to) else {
                log("⚠️ Failed to calculate date range for \(symbol)")
                isAnalyzing = false
                return getCachedOrFallback(for: symbol, days: days)
            }

            let candles = try await YahooFinanceService.shared.fetchCandles(
                symbol: symbol,
                resolution: "D",
                from: from,
                to: to
            )

            // Convert to OHLCData array
            let ohlcData = candles.toOHLCData()

            if ohlcData.isEmpty {
                log("⚠️ No OHLC data returned for \(symbol)")
                isAnalyzing = false
                return getCachedOrFallback(for: symbol, days: days)
            }

            // Cache the data
            ohlcCache[cacheKey] = (ohlcData, Date())
            log("✅ Fetched \(ohlcData.count) OHLC candles for \(symbol)")

            isAnalyzing = false
            return ohlcData

        } catch {
            log("❌ OHLC fetch error for \(symbol): \(error)")
            lastError = error
            isAnalyzing = false
            return getCachedOrFallback(for: symbol, days: days)
        }
    }

    /// Analyze patterns for a stock (fetches real data)
    func analyzePatterns(for symbol: String, days: Int = 30) async -> [DetectedPattern] {
        let ohlcData = await fetchOHLCData(for: symbol, days: days)
        return detectPatterns(ohlc: ohlcData)
    }

    /// Analyze patterns for a stock object (convenience method)
    func analyzePatterns(for stock: Stock, days: Int = 30) async -> [DetectedPattern] {
        return await analyzePatterns(for: stock.symbol, days: days)
    }

    /// Get OHLC data from cache only (synchronous, for non-async contexts)
    func getCachedOHLCData(for symbol: String, days: Int = 365) -> [OHLCData]? {
        let cacheKey = "\(symbol)-\(days)"
        return ohlcCache[cacheKey]?.data
    }

    /// Get cached OHLC data for a stock.
    ///
    /// This synchronous compatibility path must never synthesize candles. If no
    /// provider-backed cache exists, callers get an empty array and should render
    /// an insufficient-data state.
    /// This method is for backwards compatibility with synchronous code paths.
    /// For new code, prefer using fetchOHLCData(for:days:) async method.
    func getOHLCData(for stock: Stock, days: Int = 365) -> [OHLCData] {
        if let cached = getCachedOHLCData(for: stock.symbol, days: days) {
            return cached
        }

        log("📦 No cached OHLC data for \(stock.symbol); pattern analysis unavailable")
        return []
    }

    /// Get cached data or an empty unavailable state.
    private func getCachedOrFallback(for symbol: String, days: Int) -> [OHLCData] {
        let cacheKey = "\(symbol)-\(days)"

        // Return stale cache if available
        if let cached = ohlcCache[cacheKey] {
            log("📦 Using stale cache for \(symbol)")
            return cached.data
        }

        // No cache - return empty (don't use mock data in production)
        log("📦 No cached OHLC data for \(symbol)")
        return []
    }

    // MARK: - Cache Management

    func clearCache() {
        ohlcCache.removeAll()
        log("🗑️ OHLC cache cleared")
    }

    func clearCache(for symbol: String) {
        ohlcCache = ohlcCache.filter { !$0.key.hasPrefix(symbol) }
        log("🗑️ Cache cleared for \(symbol)")
    }

    // MARK: - Logging

    private func log(_ message: String) {
        #if DEBUG
        print("[ChartPatternService] \(message)")
        #endif
    }
}
