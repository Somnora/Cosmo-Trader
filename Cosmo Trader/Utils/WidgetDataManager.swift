//
//  WidgetDataManager.swift
//  Cosmo Trader
//
//  Future-scope widget data sharing for a deferred widget extension.
//  This file is intentionally excluded from v1 app target membership.
//

import Foundation

// MARK: - Widget Data Manager

/// Manages data sharing with the home screen widgets
final class WidgetDataManager {

    // MARK: - Singleton

    static let shared = WidgetDataManager()

    // MARK: - Constants

    private let appGroupIdentifier = "group.com.cosmotrader.app"
    private let lunarDataKey = "widgetLunarData"
    private let horoscopeDataKey = "widgetHoroscopeData"
    private let portfolioDataKey = "widgetPortfolioData"
    private let lastUpdateKey = "widgetLastUpdate"
    private let framingLevelKey = "widgetFramingLevel"

    // MARK: - Properties

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Update all widget data
    /// Call this on app launch and when any relevant data changes
    func updateWidgetData() {
        updateLunarData()
        reloadWidgetTimelines()
    }

    /// Update lunar data for Moon Phase widget
    func updateLunarData() {
        let moonService = MoonPhaseService.shared
        let lunarData = moonService.getCurrentLunarData()

        let widgetData = WidgetLunarData(
            date: lunarData.date,
            phaseName: lunarData.phase.rawValue,
            phaseEmoji: lunarData.phase.sfSymbol,
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

        writeLunarData(widgetData)
    }

    /// Update horoscope data for Horoscope widget
    /// - Parameters:
    ///   - user: The current user profile
    ///   - horoscopeText: The generated horoscope text
    func updateHoroscopeData(user: UserProfile, horoscopeText: String) {
        let sign = user.sunSign

        let widgetData = WidgetHoroscopeData(
            date: Date(),
            signName: sign.displayName,
            signSymbol: sign.textSymbol,
            signElement: sign.element.displayName,
            horoscopeText: horoscopeText,
            luckyNumber: Int.random(in: 1...9),
            compatibility: sign.compatibleSigns.prefix(2).map { $0.displayName }.joined(separator: ", ")
        )

        writeHoroscopeData(widgetData)
        reloadWidgetTimelines()
    }

    /// Update portfolio data for Portfolio widget
    /// - Parameters:
    ///   - totalValue: Total portfolio value
    ///   - dayChange: Dollar change today
    ///   - dayChangePercent: Percentage change today
    ///   - holdings: Array of holdings with their changes
    ///   - compatibility: Overall portfolio compatibility score
    func updatePortfolioData(
        totalValue: Double,
        dayChange: Double,
        dayChangePercent: Double,
        holdings: [(symbol: String, changePercent: Double)],
        compatibility: Int
    ) {
        let widgetHoldings = holdings.prefix(3).map { holding in
            WidgetHolding(symbol: holding.symbol, changePercent: holding.changePercent)
        }

        let widgetData = WidgetPortfolioData(
            date: Date(),
            totalValue: totalValue,
            dayChange: dayChange,
            dayChangePercent: dayChangePercent,
            topHoldings: Array(widgetHoldings),
            overallCompatibility: compatibility
        )

        writePortfolioData(widgetData)
        reloadWidgetTimelines()
    }

    /// Future hook for widget timeline reloads.
    /// v1 ships without a widget extension, app group, or widget capability.
    func reloadWidgetTimelines() {
        #if DEBUG
        print("[WidgetDataManager] Widget reload skipped; widgets are deferred for v1")
        #endif
    }

    /// Update the signal framing level for widgets
    /// - Parameter level: The SignalFramingLevel from user preferences
    func updateFramingLevel(_ level: SignalFramingLevel) {
        guard let defaults = sharedDefaults else { return }

        let levelValue: Int
        switch level {
        case .rational: levelValue = 0
        case .leanRational: levelValue = 1
        case .balanced: levelValue = 2
        case .leanMystical: levelValue = 3
        case .mystical: levelValue = 4
        }

        defaults.set(levelValue, forKey: framingLevelKey)
        defaults.synchronize()
        #if DEBUG
        print("[WidgetDataManager] Framing level updated to: \(level.displayName)")
        #endif

        // Reload widgets to reflect new framing
        reloadWidgetTimelines()
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

    private func writeLunarData(_ data: WidgetLunarData) {
        guard let defaults = sharedDefaults else {
            #if DEBUG
            print("[WidgetDataManager] Failed to access shared UserDefaults - App Group not configured")
            #endif
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: lunarDataKey)
            defaults.set(Date(), forKey: lastUpdateKey)
            defaults.synchronize()
            #if DEBUG
            print("[WidgetDataManager] Lunar data updated: \(data.phaseName)")
            #endif
        } catch {
            #if DEBUG
            print("[WidgetDataManager] Failed to encode lunar data: \(error)")
            #endif
        }
    }

    private func writeHoroscopeData(_ data: WidgetHoroscopeData) {
        guard let defaults = sharedDefaults else {
            #if DEBUG
            print("[WidgetDataManager] Failed to access shared UserDefaults - App Group not configured")
            #endif
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: horoscopeDataKey)
            defaults.synchronize()
            #if DEBUG
            print("[WidgetDataManager] Horoscope data updated for: \(data.signName)")
            #endif
        } catch {
            #if DEBUG
            print("[WidgetDataManager] Failed to encode horoscope data: \(error)")
            #endif
        }
    }

    private func writePortfolioData(_ data: WidgetPortfolioData) {
        guard let defaults = sharedDefaults else {
            #if DEBUG
            print("[WidgetDataManager] Failed to access shared UserDefaults - App Group not configured")
            #endif
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: portfolioDataKey)
            defaults.synchronize()
            #if DEBUG
            print("[WidgetDataManager] Portfolio data updated: \(data.formattedValue)")
            #endif
        } catch {
            #if DEBUG
            print("[WidgetDataManager] Failed to encode portfolio data: \(error)")
            #endif
        }
    }
}

// MARK: - Widget Horoscope Data Model

/// Lightweight horoscope data model shared between app and widget
struct WidgetHoroscopeData: Codable {
    let date: Date
    let signName: String
    let signSymbol: String
    let signElement: String
    let horoscopeText: String
    let luckyNumber: Int
    let compatibility: String

    static let placeholder = WidgetHoroscopeData(
        date: Date(),
        signName: "Scorpio",
        signSymbol: "♏",
        signElement: "Water",
        horoscopeText: "Venus favors bold moves in your financial sector.",
        luckyNumber: 7,
        compatibility: "Cancer, Pisces"
    )
}

// MARK: - Widget Portfolio Data Model

/// Lightweight portfolio data model shared between app and widget
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
