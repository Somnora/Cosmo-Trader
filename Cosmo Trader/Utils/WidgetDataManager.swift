//
//  WidgetDataManager.swift
//  Cosmo Trader
//
//  Manages widget data sharing between main app and widget extension.
//  Writes lunar data to App Group UserDefaults for widget access.
//

import Foundation
import WidgetKit

// MARK: - Widget Data Manager

/// Manages data sharing with the home screen widget
final class WidgetDataManager {

    // MARK: - Singleton

    static let shared = WidgetDataManager()

    // MARK: - Constants

    private let appGroupIdentifier = "group.com.cosmotrader.app"
    private let widgetDataKey = "widgetLunarData"
    private let lastUpdateKey = "widgetLastUpdate"

    // MARK: - Properties

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Update widget with current lunar data
    /// Call this on app launch and when lunar data changes
    func updateWidgetData() {
        let moonService = MoonPhaseService.shared
        let lunarData = moonService.getCurrentLunarData()

        let widgetData = WidgetLunarData(
            date: lunarData.date,
            phaseName: lunarData.phase.rawValue,
            phaseEmoji: lunarData.phase.emoji,
            illumination: lunarData.illumination,
            isWaxing: lunarData.isWaxing,
            daysUntilFullMoon: lunarData.daysUntilFullMoon,
            daysUntilNewMoon: lunarData.daysUntilNewMoon,
            moonSignName: lunarData.moonSign.displayName,
            moonSignElement: lunarData.moonSign.element.displayName,
            tradingSignalHeadline: lunarData.phase.tradingSignal.headline,
            tradingSignalType: lunarData.phase.tradingSignal.type.rawValue,
            tradingSignalSentiment: lunarData.phase.tradingSignal.sentiment.rawValue
        )

        writeWidgetData(widgetData)
        reloadWidgetTimelines()
    }

    /// Force reload all widget timelines
    /// Call this after any data change that should be reflected immediately
    func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
        print("[WidgetDataManager] Widget timelines reloaded")
    }

    /// Check if widget data needs refresh
    func needsRefresh() -> Bool {
        guard let defaults = sharedDefaults,
              let lastUpdate = defaults.object(forKey: lastUpdateKey) as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastUpdate) > 3600 // 1 hour
    }

    // MARK: - Private Methods

    private func writeWidgetData(_ data: WidgetLunarData) {
        guard let defaults = sharedDefaults else {
            print("[WidgetDataManager] Failed to access shared UserDefaults - App Group not configured")
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: widgetDataKey)
            defaults.set(Date(), forKey: lastUpdateKey)
            defaults.synchronize()
            print("[WidgetDataManager] Widget data updated: \(data.phaseName)")
        } catch {
            print("[WidgetDataManager] Failed to encode widget data: \(error)")
        }
    }
}

// MARK: - Widget Lunar Data Model

/// Lightweight lunar data model shared between app and widget
/// This file must be included in BOTH the main app target AND the widget extension target
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

    /// Placeholder data for previews
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

// MARK: - App Group Setup Instructions

/*
 APP GROUP SETUP INSTRUCTIONS:
 =============================

 Both the main app and widget extension need the App Group capability configured.

 1. In Xcode, select the main app target
 2. Go to Signing & Capabilities
 3. Click "+ Capability"
 4. Add "App Groups"
 5. Add group: "group.com.cosmotrader.app"

 6. Repeat steps 1-5 for the Widget Extension target

 7. Ensure the App Group identifier matches in:
    - Main app entitlements
    - Widget extension entitlements
    - WidgetDataManager.swift (appGroupIdentifier constant)
    - SharedWidgetData.swift (WidgetConstants.appGroupIdentifier)

 WIDGET EXTENSION TARGET SETUP:
 ==============================

 1. File > New > Target
 2. Select "Widget Extension"
 3. Name: "Cosmo Trader Widget"
 4. UNCHECK "Include Configuration App Intent"
 5. UNCHECK "Include Live Activity"
 6. Click Finish

 7. Add the widget files to the new target:
    - CosmoWidgetBundle.swift
    - MoonPhaseWidget.swift
    - WidgetViews.swift
    - SharedWidgetData.swift

 8. Add App Group capability to widget target (same as main app)

 9. Build and run - the widget should appear in the widget gallery
 */
