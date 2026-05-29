import Foundation

// MARK: - OHLCData
// =================
// Open-High-Low-Close candlestick data for technical analysis.
// Used by ChartPatternService to detect chart patterns.

struct OHLCData: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int

    init(date: Date, open: Double, high: Double, low: Double, close: Double, volume: Int) {
        self.id = UUID()
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, date, open, high, low, close, volume
    }

    // MARK: - Computed Properties

    /// Whether this candle closed higher than it opened (bullish)
    var isBullish: Bool {
        close > open
    }

    /// Whether this candle closed lower than it opened (bearish)
    var isBearish: Bool {
        close < open
    }

    /// The body size (difference between open and close)
    var bodySize: Double {
        abs(close - open)
    }

    /// The total range (high - low)
    var totalRange: Double {
        high - low
    }

    /// Upper wick/shadow size
    var upperWick: Double {
        high - max(open, close)
    }

    /// Lower wick/shadow size
    var lowerWick: Double {
        min(open, close) - low
    }

    /// Body as percentage of total range
    var bodyRatio: Double {
        guard totalRange > 0 else { return 0 }
        return bodySize / totalRange
    }

    /// Percentage change from open to close
    var percentageChange: Double {
        guard open > 0 else { return 0 }
        return ((close - open) / open) * 100
    }

    // MARK: - Equatable

    static func == (lhs: OHLCData, rhs: OHLCData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Finnhub Response

/// Response structure from Finnhub candle API
struct FinnhubCandleResponse: Codable {
    let s: String       // Status: "ok" or "no_data"
    let t: [Int]?       // Timestamps
    let o: [Double]?    // Opens
    let h: [Double]?    // Highs
    let l: [Double]?    // Lows
    let c: [Double]?    // Closes
    let v: [Int]?       // Volumes

    /// Convert to array of OHLCData
    func toOHLCData() -> [OHLCData] {
        guard s == "ok",
              let timestamps = t,
              let opens = o,
              let highs = h,
              let lows = l,
              let closes = c,
              let volumes = v else {
            return []
        }

        var ohlcData: [OHLCData] = []
        let count = min(timestamps.count, opens.count, highs.count, lows.count, closes.count, volumes.count)

        for i in 0..<count {
            ohlcData.append(OHLCData(
                date: Date(timeIntervalSince1970: Double(timestamps[i])),
                open: opens[i],
                high: highs[i],
                low: lows[i],
                close: closes[i],
                volume: volumes[i]
            ))
        }

        return ohlcData.sorted { $0.date < $1.date }
    }
}

// MARK: - Mock OHLC Data Generator

#if DEBUG
/// Debug/test-only OHLC fixture generator. Production pattern analysis must use
/// provider-backed candles or return an insufficient-data state.
enum MockOHLCGenerator {

    /// Generate realistic OHLC data for a stock
    static func generate(
        for symbol: String,
        days: Int = 365,
        basePrice: Double = 100,
        volatility: Double = 0.02
    ) -> [OHLCData] {
        var data: [OHLCData] = []
        let calendar = Calendar.current
        let now = Date()
        var currentPrice = basePrice

        // Use symbol hash for consistent but different data per stock
        let seed = abs(symbol.hashValue)
        var generator = SeededRandomGenerator(seed: UInt64(seed))

        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }

            // Skip weekends
            let weekday = calendar.component(.weekday, from: date)
            if weekday == 1 || weekday == 7 { continue }

            // Generate daily movement
            let dailyChange = Double.random(in: -volatility...volatility, using: &generator)
            let intraDay = Double.random(in: 0.005...0.025, using: &generator)

            // Calculate OHLC
            let open = currentPrice
            let close = currentPrice * (1 + dailyChange)
            let high = max(open, close) * (1 + intraDay)
            let low = min(open, close) * (1 - intraDay)

            // Generate volume
            let baseVolume = 1_000_000 + seed % 5_000_000
            let volumeVariation = Double.random(in: 0.5...1.5, using: &generator)
            let volume = Int(Double(baseVolume) * volumeVariation)

            data.append(OHLCData(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))

            currentPrice = close
        }

        // Inject some patterns for demonstration
        data = injectPatterns(data, seed: seed, generator: &generator)

        return data
    }

    /// Inject recognizable patterns into the data
    private static func injectPatterns(_ data: [OHLCData], seed: Int, generator: inout SeededRandomGenerator) -> [OHLCData] {
        guard data.count > 10 else { return data }
        var modifiedData = data

        // Randomly inject a pattern in recent data
        let patternIndex = max(0, data.count - Int.random(in: 1...5, using: &generator))

        // Decide which pattern to inject based on seed
        let patternType = seed % 5

        switch patternType {
        case 0:
            // Inject Doji (small body, equal wicks)
            modifiedData = injectDoji(modifiedData, at: patternIndex)
        case 1:
            // Inject Hammer (small body at top, long lower wick)
            modifiedData = injectHammer(modifiedData, at: patternIndex)
        case 2:
            // Inject Shooting Star (small body at bottom, long upper wick)
            modifiedData = injectShootingStar(modifiedData, at: patternIndex)
        case 3:
            // Inject Bullish Engulfing
            modifiedData = injectBullishEngulfing(modifiedData, at: patternIndex)
        default:
            // Inject Bearish Engulfing
            modifiedData = injectBearishEngulfing(modifiedData, at: patternIndex)
        }

        return modifiedData
    }

    private static func injectDoji(_ data: [OHLCData], at index: Int) -> [OHLCData] {
        guard index < data.count else { return data }
        var modifiedData = data
        let original = data[index]
        let midPrice = (original.high + original.low) / 2
        let range = original.high - original.low

        modifiedData[index] = OHLCData(
            date: original.date,
            open: midPrice - range * 0.02,
            high: original.high,
            low: original.low,
            close: midPrice + range * 0.02,
            volume: original.volume
        )
        return modifiedData
    }

    private static func injectHammer(_ data: [OHLCData], at index: Int) -> [OHLCData] {
        guard index < data.count else { return data }
        var modifiedData = data
        let original = data[index]
        let range = original.high - original.low

        modifiedData[index] = OHLCData(
            date: original.date,
            open: original.high - range * 0.15,
            high: original.high,
            low: original.low,
            close: original.high - range * 0.1,
            volume: original.volume
        )
        return modifiedData
    }

    private static func injectShootingStar(_ data: [OHLCData], at index: Int) -> [OHLCData] {
        guard index < data.count else { return data }
        var modifiedData = data
        let original = data[index]
        let range = original.high - original.low

        modifiedData[index] = OHLCData(
            date: original.date,
            open: original.low + range * 0.15,
            high: original.high,
            low: original.low,
            close: original.low + range * 0.1,
            volume: original.volume
        )
        return modifiedData
    }

    private static func injectBullishEngulfing(_ data: [OHLCData], at index: Int) -> [OHLCData] {
        guard index >= 1, index < data.count else { return data }
        var modifiedData = data
        let prev = data[index - 1]
        let current = data[index]

        // Make previous candle bearish (red)
        modifiedData[index - 1] = OHLCData(
            date: prev.date,
            open: prev.high - (prev.high - prev.low) * 0.2,
            high: prev.high,
            low: prev.low,
            close: prev.low + (prev.high - prev.low) * 0.2,
            volume: prev.volume
        )

        // Make current candle bullish and engulfing
        modifiedData[index] = OHLCData(
            date: current.date,
            open: modifiedData[index - 1].close - (current.high - current.low) * 0.1,
            high: current.high,
            low: current.low,
            close: modifiedData[index - 1].open + (current.high - current.low) * 0.1,
            volume: current.volume
        )

        return modifiedData
    }

    private static func injectBearishEngulfing(_ data: [OHLCData], at index: Int) -> [OHLCData] {
        guard index >= 1, index < data.count else { return data }
        var modifiedData = data
        let prev = data[index - 1]
        let current = data[index]

        // Make previous candle bullish (green)
        modifiedData[index - 1] = OHLCData(
            date: prev.date,
            open: prev.low + (prev.high - prev.low) * 0.2,
            high: prev.high,
            low: prev.low,
            close: prev.high - (prev.high - prev.low) * 0.2,
            volume: prev.volume
        )

        // Make current candle bearish and engulfing
        modifiedData[index] = OHLCData(
            date: current.date,
            open: modifiedData[index - 1].close + (current.high - current.low) * 0.1,
            high: current.high,
            low: current.low,
            close: modifiedData[index - 1].open - (current.high - current.low) * 0.1,
            volume: current.volume
        )

        return modifiedData
    }
}
#endif
