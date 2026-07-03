import AppIntents
import Foundation

// MARK: - Cosmo Trader Siri Shortcuts
// =====================================
// Four App Intents that expose Cosmo Trader's core features to Siri,
// Spotlight, and the Shortcuts app. All data is computed locally —
// no network calls required.
//
// INTENTS:
// 1. GetMyHoroscopeIntent     → "What's my Cosmo Trader horoscope?"
// 2. CheckMoonPhaseIntent     → "What's the moon phase on Cosmo Trader?"
// 3. GetPortfolioSummaryIntent → "How's my Cosmo Trader portfolio?"
// 4. OpenTabIntent             → "Open Portfolio in Cosmo Trader"

// MARK: - 1. Get My Horoscope

/// Returns today's personalized cosmic portfolio reading via Siri.
struct GetMyHoroscopeIntent: AppIntent {

    static var title: LocalizedStringResource = "Get My Horoscope"
    static var description = IntentDescription(
        "Get your personalized daily cosmic portfolio reading.",
        categoryName: "Readings"
    )

    /// Show result inline without opening the app
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let user = loadUserProfile() else {
            return .result(
                dialog: "Set up your profile in Cosmo Trader to get personalized readings."
            )
        }

        let horoscope = HoroscopeGenerator.generate(for: user)
        let sign = user.sunSign

        return .result(
            dialog: "\(sign.textSymbol) \(sign.displayName) — \(horoscope.reading)"
        )
    }
}

// MARK: - 2. Check Moon Phase

/// Returns current lunar phase, illumination, and cosmic context.
struct CheckMoonPhaseIntent: AppIntent {

    static var title: LocalizedStringResource = "Check Moon Phase"
    static var description = IntentDescription(
        "Check the current moon phase and its cosmic market context.",
        categoryName: "Cosmos"
    )

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let lunarData = MoonPhaseService.shared.getCurrentLunarData()
        let signal = lunarData.phase.tradingSignal

        let response = """
        \(lunarData.phase.rawValue) · \(lunarData.formattedIllumination) illuminated. \
        Moon in \(lunarData.moonSign.displayName). \
        \(signal.headline): \(signal.summary). \
        \(lunarData.daysUntilFullMoon) days until full moon.
        """

        return .result(dialog: "\(response)")
    }
}

// MARK: - 3. Get Portfolio Summary

/// Returns a quick snapshot of the user's portfolio performance.
struct GetPortfolioSummaryIntent: AppIntent {

    static var title: LocalizedStringResource = "Get Portfolio Summary"
    static var description = IntentDescription(
        "Get a quick snapshot of your cosmic portfolio performance.",
        categoryName: "Portfolio"
    )

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let user = loadUserProfile() else {
            return .result(
                dialog: "Add holdings in Cosmo Trader to see your portfolio summary."
            )
        }

        let holdings = user.portfolio.filter { $0.sharesOwned > 0 }

        guard !holdings.isEmpty else {
            return .result(
                dialog: "Your portfolio is empty. Add some stocks in Cosmo Trader to track them."
            )
        }

        let changePercent = user.totalDailyChangePercent
        let direction = changePercent >= 0 ? "up" : "down"
        let emoji = changePercent >= 0 ? "📈" : "📉"
        let formattedChange = String(format: "%.1f%%", abs(changePercent))

        let topGainer = holdings.max(by: { $0.percentageChange < $1.percentageChange })
        let topLoser = holdings.min(by: { $0.percentageChange < $1.percentageChange })

        var response = "\(emoji) \(holdings.count) holdings, \(direction) \(formattedChange) today."

        if let gainer = topGainer, gainer.percentageChange > 0 {
            response += " Top gainer: \(gainer.symbol) at +\(String(format: "%.1f%%", gainer.percentageChange))."
        }

        if let loser = topLoser, loser.percentageChange < 0 {
            response += " Biggest dip: \(loser.symbol) at \(String(format: "%.1f%%", loser.percentageChange))."
        }

        // Add dominant element flavor
        let dominantElement = findDominantElement(in: user)
        if let element = dominantElement {
            response += " Your portfolio leans \(element.displayName)."
        }

        return .result(dialog: "\(response)")
    }

    /// Find the dominant element in the user's portfolio by market value.
    private func findDominantElement(in user: UserProfile) -> ZodiacSign.Element? {
        let holdings = user.portfolio.filter { $0.isOwned && $0.foundedElement != nil }
        guard !holdings.isEmpty else { return nil }

        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in holdings {
            guard let element = stock.foundedElement else { continue }
            let marketValue = stock.marketValue
            guard marketValue > 0 else { continue }
            elementValues[element, default: 0] += marketValue
        }

        return elementValues.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - 4. Open Tab

/// Opens Cosmo Trader to a specific tab.
struct OpenTabIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Tab"
    static var description = IntentDescription(
        "Open Cosmo Trader to a specific tab.",
        categoryName: "Navigation"
    )

    /// Must open the app to show a tab
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Tab")
    var tab: TabAppEnum

    @MainActor
    func perform() async throws -> some IntentResult {
        // Post the appropriate notification to switch tabs
        switch tab {
        case .today:
            NotificationCenter.default.post(name: .openToday, object: nil)
        case .portfolio:
            NotificationCenter.default.post(name: .openPortfolio, object: nil)
        case .discover:
            NotificationCenter.default.post(name: .openDiscover, object: nil)
        case .cosmos:
            NotificationCenter.default.post(name: .openCosmos, object: nil)
        case .profile:
            NotificationCenter.default.post(name: .openProfile, object: nil)
        }

        return .result()
    }
}

// MARK: - Tab App Enum

/// Enum that Siri uses to resolve which tab to open.
enum TabAppEnum: String, AppEnum {
    case today
    case portfolio
    case discover
    case cosmos
    case profile

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tab"

    static var caseDisplayRepresentations: [TabAppEnum: DisplayRepresentation] = [
        .today:     "Today",
        .portfolio: "Portfolio",
        .discover:  "Discover",
        .cosmos:    "Cosmos",
        .profile:   "Profile"
    ]
}

// MARK: - App Shortcuts Provider

/// Registers all shortcuts with Siri so they appear automatically
/// in the Shortcuts app and Siri suggestions.
struct CosmoTraderShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetMyHoroscopeIntent(),
            phrases: [
                "What's my \(.applicationName) horoscope?",
                "Get my \(.applicationName) reading",
                "My horoscope on \(.applicationName)"
            ],
            shortTitle: "Get My Horoscope",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: CheckMoonPhaseIntent(),
            phrases: [
                "What's the moon phase on \(.applicationName)?",
                "Moon phase \(.applicationName)",
                "Check the moon on \(.applicationName)"
            ],
            shortTitle: "Check Moon Phase",
            systemImageName: "moon.stars"
        )

        AppShortcut(
            intent: GetPortfolioSummaryIntent(),
            phrases: [
                "How's my \(.applicationName) portfolio?",
                "My portfolio on \(.applicationName)",
                "Portfolio summary \(.applicationName)"
            ],
            shortTitle: "Portfolio Summary",
            systemImageName: "chart.pie"
        )

        AppShortcut(
            intent: OpenTabIntent(),
            phrases: [
                "Open \(\.$tab) in \(.applicationName)",
                "Show \(\.$tab) on \(.applicationName)",
                "Go to \(\.$tab) in \(.applicationName)"
            ],
            shortTitle: "Open Tab",
            systemImageName: "rectangle.stack"
        )
    }
}

// MARK: - Shared Helpers

/// Load the saved UserProfile from UserDefaults.
/// Used by intents that need user data but run outside the main app context.
private func loadUserProfile() -> UserProfile? {
    guard let data = UserDefaults.standard.data(forKey: "com.cosmotrader.userProfile") else {
        return nil
    }

    return try? JSONDecoder().decode(UserProfile.self, from: data)
}
