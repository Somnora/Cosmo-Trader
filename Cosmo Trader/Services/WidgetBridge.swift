//
//  WidgetBridge.swift
//  Cosmo Trader
//
//  Bridges the main app to WidgetKit.
//  Syncs lunar, horoscope, and portfolio data to App Group UserDefaults
//  and triggers widget timeline reloads so home screen widgets stay fresh.
//

import Foundation
import WidgetKit

// MARK: - Widget Bridge

/// Lightweight service that pushes data to the widget extension
/// via App Group shared UserDefaults and signals WidgetKit to reload.
///
/// Call sites:
/// - `ContentView.onAppear` → `syncAllWidgetData()`
/// - `AppState.saveUserToStorage()` → `syncPortfolioSnapshot()`
/// - `HoroscopeViewModel.regenerateHoroscope()` → `syncHoroscopeSnapshot()`
/// - `PortfolioView.fetchLivePrices()` → `syncPortfolioSnapshot()`
final class WidgetBridge {

    // MARK: - Singleton

    static let shared = WidgetBridge()

    // MARK: - Constants

    private let appGroupID = "group.com.cosmotrader.app"

    private enum Keys {
        static let lunarData = "widgetLunarData"
        static let horoscopeData = "widgetHoroscopeData"
        static let portfolioData = "widgetPortfolioData"
        static let lastUpdate = "widgetLastUpdate"
        static let framingLevel = "widgetFramingLevel"
    }

    // MARK: - Shared Defaults

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Init

    private init() {}

    // MARK: - Public API

    /// Sync all widget data and reload timelines.
    /// Call on app launch and when returning from background.
    func syncAllWidgetData() {
        syncLunarData()
        reloadTimelines()
    }

    /// Sync the current horoscope reading to the widget.
    /// Call after generating or regenerating a horoscope.
    func syncHoroscopeSnapshot(signName: String,
                                signSymbol: String,
                                signElement: String,
                                horoscopeText: String) {
        guard let defaults = sharedDefaults else { return }

        let data = WidgetHoroscopePayload(
            date: Date(),
            signName: signName,
            signSymbol: signSymbol,
            signElement: signElement,
            horoscopeText: horoscopeText,
            compatibility: ""
        )

        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: Keys.horoscopeData)
            defaults.synchronize()
        }

        reloadTimelines()
    }

    /// Sync portfolio summary to the widget.
    /// Call after price fetches or portfolio mutations.
    func syncPortfolioSnapshot(totalValue: Double,
                                dayChange: Double,
                                dayChangePercent: Double,
                                topHoldings: [(symbol: String, changePercent: Double)],
                                compatibility: Int) {
        guard let defaults = sharedDefaults else { return }

        let holdings = topHoldings.prefix(3).map { holding in
            WidgetHoldingPayload(symbol: holding.symbol, changePercent: holding.changePercent)
        }

        let data = WidgetPortfolioPayload(
            date: Date(),
            totalValue: totalValue,
            dayChange: dayChange,
            dayChangePercent: dayChangePercent,
            topHoldings: Array(holdings),
            overallCompatibility: compatibility
        )

        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: Keys.portfolioData)
            defaults.synchronize()
        }

        reloadTimelines()
    }

    /// Sync the framing level preference so widgets respect
    /// the user's rational↔mystical slider position.
    func syncFramingLevel(_ levelRawValue: Int) {
        sharedDefaults?.set(levelRawValue, forKey: Keys.framingLevel)
        sharedDefaults?.synchronize()
        reloadTimelines()
    }

    // MARK: - Private

    /// Push current moon phase data to widget storage.
    private func syncLunarData() {
        guard let defaults = sharedDefaults else { return }

        let moon = MoonPhaseService.shared.getCurrentLunarData()
        let data = WidgetLunarPayload(
            date: moon.date,
            phaseName: moon.phase.rawValue,
            phaseEmoji: moon.phase.sfSymbol,
            illumination: moon.illumination,
            isWaxing: moon.isWaxing,
            daysUntilFullMoon: moon.daysUntilFullMoon,
            daysUntilNewMoon: moon.daysUntilNewMoon,
            moonSignName: moon.moonSign.displayName,
            moonSignElement: moon.moonSign.element.displayName,
            tradingSignalHeadline: moon.phase.tradingSignal.headline,
            tradingSignalType: moon.phase.tradingSignal.type.rawValue,
            tradingSignalSentiment: moon.phase.tradingSignal.sentiment.rawValue
        )

        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: Keys.lunarData)
            defaults.set(Date(), forKey: Keys.lastUpdate)
            defaults.synchronize()
        }
    }

    /// Tell WidgetKit to refresh all widget timelines.
    private func reloadTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
        #if DEBUG
        print("[WidgetBridge] Reloaded all widget timelines")
        #endif
    }
}

// MARK: - Wire-Format Payloads
// These match the Codable models in SharedWidgetData.swift
// used by the widget extension to decode.

private struct WidgetLunarPayload: Codable {
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
}

private struct WidgetHoroscopePayload: Codable {
    let date: Date
    let signName: String
    let signSymbol: String
    let signElement: String
    let horoscopeText: String
    let compatibility: String
}

private struct WidgetPortfolioPayload: Codable {
    let date: Date
    let totalValue: Double
    let dayChange: Double
    let dayChangePercent: Double
    let topHoldings: [WidgetHoldingPayload]
    let overallCompatibility: Int
}

private struct WidgetHoldingPayload: Codable {
    let symbol: String
    let changePercent: Double
}
