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

    /// UserDefaults key for widget data
    static let widgetDataKey = "widgetLunarData"

    /// Last update timestamp key
    static let lastUpdateKey = "widgetLastUpdate"
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

// MARK: - Widget Data Provider

/// Provides access to shared widget data via App Group UserDefaults
enum WidgetDataProvider {

    /// Get shared UserDefaults for App Group
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: WidgetConstants.appGroupIdentifier)
    }

    /// Read widget data from App Group
    static func readWidgetData() -> WidgetLunarData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: WidgetConstants.widgetDataKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WidgetLunarData.self, from: data)
        } catch {
            print("[Widget] Failed to decode widget data: \(error)")
            return nil
        }
    }

    /// Write widget data to App Group (called from main app)
    static func writeWidgetData(_ data: WidgetLunarData) {
        guard let defaults = sharedDefaults else {
            print("[Widget] Failed to access shared UserDefaults")
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: WidgetConstants.widgetDataKey)
            defaults.set(Date(), forKey: WidgetConstants.lastUpdateKey)
            defaults.synchronize()
            print("[Widget] Widget data updated successfully")
        } catch {
            print("[Widget] Failed to encode widget data: \(error)")
        }
    }

    /// Get last update timestamp
    static func lastUpdateTime() -> Date? {
        sharedDefaults?.object(forKey: WidgetConstants.lastUpdateKey) as? Date
    }

    /// Check if data needs refresh (older than 1 hour)
    static func needsRefresh() -> Bool {
        guard let lastUpdate = lastUpdateTime() else { return true }
        return Date().timeIntervalSince(lastUpdate) > 3600 // 1 hour
    }
}
