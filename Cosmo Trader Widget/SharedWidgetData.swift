//
//  SharedWidgetData.swift
//  Cosmo Trader Widget
//
//  Shared data model between main app and widget extension.
//  Uses App Group for data sharing.
//

import Foundation

// MARK: - App Group Identifier

enum WidgetConstants {
    /// App Group identifier for sharing data between app and widget
    /// NOTE: Must be configured in both targets' entitlements
    static let appGroupIdentifier = "group.com.cosmotrader.app"

    /// UserDefaults keys for widget data
    static let widgetDataKey = "widgetLunarData"
    static let horoscopeDataKey = "widgetHoroscopeData"
    static let portfolioDataKey = "widgetPortfolioData"

    /// Last update timestamp key
    static let lastUpdateKey = "widgetLastUpdate"

    /// Signal framing level key (0=rational, 1=leanRational, 2=balanced, 3=leanMystical, 4=mystical)
    static let framingLevelKey = "widgetFramingLevel"
}

// MARK: - Widget Lunar Data

/// Lightweight lunar data model for widget display
/// This is a simplified version of LunarData that can be easily encoded/decoded
struct WidgetLunarData: Codable {
    let date: Date
    let phaseName: String
    let phaseEmoji: String
    let illumination: Double
    let isWaxing: Bool
    let daysUntilFullMoon: Int
    let daysUntilNewMoon: Int
    let moonSignName: String
    let moonSignElement: String
    let tradingSignalHeadline: String
    let tradingSignalType: String
    let tradingSignalSentiment: String

    // MARK: - Computed Properties

    var formattedIllumination: String {
        String(format: "%.0f%%", illumination * 100)
    }

    var shortTradingInsight: String {
        switch tradingSignalType {
        case "Accumulate":
            return "Good for new positions"
        case "Build Position":
            return "Momentum building"
        case "Hold":
            return "Evaluate positions"
        case "Caution":
            return "Expect volatility"
        case "Take Profit":
            return "Secure your gains"
        case "Reduce":
            return "Trim underperformers"
        case "Wait":
            return "Wait for new cycle"
        default:
            return "Monitor markets"
        }
    }

    var sentimentColor: WidgetColor {
        switch tradingSignalSentiment {
        case "Bullish":
            return .green
        case "Bearish":
            return .red
        case "Volatile":
            return .orange
        default:
            return .gray
        }
    }

    /// Placeholder data for widget previews
    static let placeholder = WidgetLunarData(
        date: Date(),
        phaseName: "Waxing Gibbous",
        phaseEmoji: "🌔",
        illumination: 0.78,
        isWaxing: true,
        daysUntilFullMoon: 3,
        daysUntilNewMoon: 18,
        moonSignName: "Scorpio",
        moonSignElement: "Water",
        tradingSignalHeadline: "Pre-Peak Energy",
        tradingSignalType: "Build Position",
        tradingSignalSentiment: "Bullish"
    )
}

// MARK: - Widget Color (Simplified for Widget)

enum WidgetColor: String, Codable {
    case green, red, orange, gray, gold, blue, purple

    var description: String { rawValue }
}

// MARK: - Widget Horoscope Data

/// Lightweight horoscope data model for widget display
struct WidgetHoroscopeData: Codable {
    let date: Date
    let signName: String
    let signSymbol: String
    let signElement: String
    let horoscopeText: String
    let luckyNumber: Int
    let compatibility: String

    /// Placeholder data for previews
    static let placeholder = WidgetHoroscopeData(
        date: Date(),
        signName: "Scorpio",
        signSymbol: "♏\u{FE0E}",
        signElement: "Water",
        horoscopeText: "Venus favors bold moves in your financial sector. Consider reviewing Fire sign stocks today.",
        luckyNumber: 7,
        compatibility: "Cancer, Pisces"
    )
}

// MARK: - Widget Portfolio Data

/// Lightweight portfolio data model for widget display
struct WidgetPortfolioData: Codable {
    let date: Date
    let totalValue: Double
    let dayChange: Double
    let dayChangePercent: Double
    let topHoldings: [WidgetHolding]
    let overallCompatibility: Int

    var isPositive: Bool { dayChangePercent >= 0 }

    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalValue)) ?? "$0"
    }

    var formattedChange: String {
        String(format: "%+.1f%%", dayChangePercent)
    }

    /// Placeholder data for previews
    static let placeholder = WidgetPortfolioData(
        date: Date(),
        totalValue: 12450.00,
        dayChange: 290.00,
        dayChangePercent: 2.4,
        topHoldings: [
            WidgetHolding(symbol: "AAPL", changePercent: 1.2),
            WidgetHolding(symbol: "TSLA", changePercent: 4.1),
            WidgetHolding(symbol: "NVDA", changePercent: -0.3)
        ],
        overallCompatibility: 78
    )
}

/// Individual holding for widget display
struct WidgetHolding: Codable {
    let symbol: String
    let changePercent: Double

    var isPositive: Bool { changePercent >= 0 }

    var formattedChange: String {
        String(format: "%+.1f%%", changePercent)
    }
}

// MARK: - Widget Data Provider

/// Provides access to shared widget data via App Group UserDefaults
enum WidgetDataProvider {

    /// Get shared UserDefaults for App Group
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: WidgetConstants.appGroupIdentifier)
    }

    // MARK: - Lunar Data

    /// Read lunar widget data from App Group
    static func readLunarData() -> WidgetLunarData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: WidgetConstants.widgetDataKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WidgetLunarData.self, from: data)
        } catch {
            #if DEBUG
            print("[Widget] Failed to decode lunar data: \(error)")
            #endif
            return nil
        }
    }

    /// Alias for backward compatibility
    static func readWidgetData() -> WidgetLunarData? {
        readLunarData()
    }

    /// Write lunar widget data to App Group (called from main app)
    static func writeWidgetData(_ data: WidgetLunarData) {
        guard let defaults = sharedDefaults else {
            #if DEBUG
            print("[Widget] Failed to access shared UserDefaults")
            #endif
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: WidgetConstants.widgetDataKey)
            defaults.set(Date(), forKey: WidgetConstants.lastUpdateKey)
            defaults.synchronize()
            #if DEBUG
            print("[Widget] Lunar data updated successfully")
            #endif
        } catch {
            #if DEBUG
            print("[Widget] Failed to encode lunar data: \(error)")
            #endif
        }
    }

    // MARK: - Horoscope Data

    /// Read horoscope widget data from App Group
    static func readHoroscopeData() -> WidgetHoroscopeData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: WidgetConstants.horoscopeDataKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WidgetHoroscopeData.self, from: data)
        } catch {
            #if DEBUG
            print("[Widget] Failed to decode horoscope data: \(error)")
            #endif
            return nil
        }
    }

    /// Write horoscope widget data to App Group (called from main app)
    static func writeHoroscopeData(_ data: WidgetHoroscopeData) {
        guard let defaults = sharedDefaults else {
            #if DEBUG
            print("[Widget] Failed to access shared UserDefaults")
            #endif
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: WidgetConstants.horoscopeDataKey)
            defaults.synchronize()
            #if DEBUG
            print("[Widget] Horoscope data updated successfully")
            #endif
        } catch {
            #if DEBUG
            print("[Widget] Failed to encode horoscope data: \(error)")
            #endif
        }
    }

    // MARK: - Portfolio Data

    /// Read portfolio widget data from App Group
    static func readPortfolioData() -> WidgetPortfolioData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: WidgetConstants.portfolioDataKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WidgetPortfolioData.self, from: data)
        } catch {
            #if DEBUG
            print("[Widget] Failed to decode portfolio data: \(error)")
            #endif
            return nil
        }
    }

    /// Write portfolio widget data to App Group (called from main app)
    static func writePortfolioData(_ data: WidgetPortfolioData) {
        guard let defaults = sharedDefaults else {
            #if DEBUG
            print("[Widget] Failed to access shared UserDefaults")
            #endif
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: WidgetConstants.portfolioDataKey)
            defaults.synchronize()
            #if DEBUG
            print("[Widget] Portfolio data updated successfully")
            #endif
        } catch {
            #if DEBUG
            print("[Widget] Failed to encode portfolio data: \(error)")
            #endif
        }
    }

    // MARK: - Utilities

    /// Get last update timestamp
    static func lastUpdateTime() -> Date? {
        sharedDefaults?.object(forKey: WidgetConstants.lastUpdateKey) as? Date
    }

    /// Check if data needs refresh (older than 1 hour)
    static func needsRefresh() -> Bool {
        guard let lastUpdate = lastUpdateTime() else { return true }
        return Date().timeIntervalSince(lastUpdate) > 3600 // 1 hour
    }

    // MARK: - Framing Level

    /// Read framing level from App Group (0=rational to 4=mystical)
    static func readFramingLevel() -> Int {
        sharedDefaults?.integer(forKey: WidgetConstants.framingLevelKey) ?? 2 // Default to balanced
    }

    /// Write framing level to App Group
    static func writeFramingLevel(_ level: Int) {
        sharedDefaults?.set(level, forKey: WidgetConstants.framingLevelKey)
        sharedDefaults?.synchronize()
    }

    /// Check if framing should use mystical language
    static func isMysticalFraming() -> Bool {
        readFramingLevel() >= 2 // balanced or higher
    }

    /// Check if framing should be fully rational (no astrology)
    static func isRationalFraming() -> Bool {
        readFramingLevel() <= 1 // rational or leanRational
    }
}
