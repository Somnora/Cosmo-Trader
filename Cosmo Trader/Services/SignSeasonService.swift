import Foundation
import SwiftUI

// MARK: - Sign Season Service
// ============================
// Tracks zodiac seasons and provides spotlight features for stocks.
//
// FEATURE: Sign Season Spotlights
// When the sun enters a new zodiac sign (~21st of each month), spotlight
// stocks born under that sign.
//
// "Aries Season begins March 21. Your Fire Sector stocks are activated."
//
// WHY IT WORKS: Monthly recurring engagement hook. Reason to open the app.
//
// ZODIAC SEASON DATES:
// - Aries:       Mar 21 - Apr 19
// - Taurus:      Apr 20 - May 20
// - Gemini:      May 21 - Jun 20
// - Cancer:      Jun 21 - Jul 22
// - Leo:         Jul 23 - Aug 22
// - Virgo:       Aug 23 - Sep 22
// - Libra:       Sep 23 - Oct 22
// - Scorpio:     Oct 23 - Nov 21
// - Sagittarius: Nov 22 - Dec 21
// - Capricorn:   Dec 22 - Jan 19
// - Aquarius:    Jan 20 - Feb 18
// - Pisces:      Feb 19 - Mar 20

@MainActor
@Observable
final class SignSeasonService {

    // MARK: - Singleton

    static let shared = SignSeasonService()

    // MARK: - Storage Keys

    private enum StorageKeys {
        static let lastSeenSeasonSign = "signSeason_lastSeenSign"
        static let signSeasonAlertsEnabled = "signSeason_alertsEnabled"
    }

    // MARK: - State

    /// Whether sign season alerts are enabled
    var signSeasonAlertsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(signSeasonAlertsEnabled, forKey: StorageKeys.signSeasonAlertsEnabled)
        }
    }

    /// The last season the user has seen (to show "new season" banner)
    private var lastSeenSeasonSign: ZodiacSign?

    /// Current zodiac season
    private(set) var currentSeason: SignSeason

    /// Days until next season
    var daysUntilNextSeason: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: currentSeason.endDate).day ?? 0
    }

    // MARK: - Initialization

    private init() {
        // Load preferences
        signSeasonAlertsEnabled = UserDefaults.standard.object(forKey: StorageKeys.signSeasonAlertsEnabled) as? Bool ?? true

        if let lastSeenRaw = UserDefaults.standard.string(forKey: StorageKeys.lastSeenSeasonSign),
           let sign = ZodiacSign(rawValue: lastSeenRaw) {
            lastSeenSeasonSign = sign
        }

        // Calculate current season
        currentSeason = Self.calculateCurrentSeason(for: Date())
    }

    // MARK: - Public Methods

    /// Get the current zodiac sign season
    func getCurrentSign() -> ZodiacSign {
        currentSeason.sign
    }

    /// Check if today is a season transition (first day of new sign)
    var isSeasonTransitionDay: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(currentSeason.startDate)
    }

    /// Check if user hasn't seen this season yet
    var isNewSeasonForUser: Bool {
        lastSeenSeasonSign != currentSeason.sign
    }

    /// Mark the current season as seen by the user
    func markSeasonAsSeen() {
        lastSeenSeasonSign = currentSeason.sign
        UserDefaults.standard.set(currentSeason.sign.rawValue, forKey: StorageKeys.lastSeenSeasonSign)
    }

    /// Get the next zodiac season
    func getNextSeason() -> SignSeason {
        let nextSign = Self.getNextSign(after: currentSeason.sign)
        let year = Calendar.current.component(.year, from: Date())
        return Self.createSeason(for: nextSign, year: year)
    }

    /// Get spotlight stocks from a portfolio for the current season
    func getSpotlightStocks(from stocks: [Stock]) -> [Stock] {
        stocks.filter { $0.zodiacSign == currentSeason.sign }
    }

    /// Get element-aligned stocks (same element as current season)
    func getElementAlignedStocks(from stocks: [Stock]) -> [Stock] {
        let currentElement = currentSeason.sign.element
        return stocks.filter { $0.foundedElement == currentElement }
    }

    /// Check if user has holdings in the current season's sign
    func hasHoldingsInCurrentSeason(holdings: [Stock]) -> Bool {
        !getSpotlightStocks(from: holdings).isEmpty
    }

    /// Generate a season horoscope for user's holdings
    func generateSeasonHoroscope(userSign: ZodiacSign, holdings: [Stock]) -> SeasonHoroscope {
        let spotlightStocks = getSpotlightStocks(from: holdings)
        let elementStocks = getElementAlignedStocks(from: holdings)
        let currentSign = currentSeason.sign

        // Generate personalized message
        let personalMessage = generatePersonalMessage(
            userSign: userSign,
            seasonSign: currentSign,
            spotlightStocks: spotlightStocks
        )

        // Generate element insight
        let elementInsight = generateElementInsight(
            element: currentSign.element,
            elementStocks: elementStocks
        )

        // Generate trading outlook
        let tradingOutlook = generateTradingOutlook(
            seasonSign: currentSign,
            hasSpotlightStocks: !spotlightStocks.isEmpty
        )

        return SeasonHoroscope(
            season: currentSeason,
            userSign: userSign,
            personalMessage: personalMessage,
            elementInsight: elementInsight,
            tradingOutlook: tradingOutlook,
            spotlightStocks: spotlightStocks,
            elementStocks: elementStocks
        )
    }

    /// Refresh service (recalculate current season)
    func refresh() {
        currentSeason = Self.calculateCurrentSeason(for: Date())
    }

    // MARK: - Static Season Calculation

    /// Calculate the current zodiac season for a given date
    static func calculateCurrentSeason(for date: Date) -> SignSeason {
        let sign = ZodiacSign.from(date: date)
        let year = Calendar.current.component(.year, from: date)
        return createSeason(for: sign, year: year)
    }

    /// Create a full SignSeason for a given sign and year
    static func createSeason(for sign: ZodiacSign, year: Int) -> SignSeason {
        let calendar = Calendar.current
        let startDate = sign.startDate

        // Determine the year for start and end dates
        var startYear = year
        var endYear = year

        // Handle year boundaries (Capricorn spans Dec-Jan, Aquarius/Pisces are in early year)
        if sign == .capricorn {
            // If we're in January, the season started last year
            let currentMonth = calendar.component(.month, from: Date())
            if currentMonth == 1 {
                startYear = year - 1
            } else {
                endYear = year + 1
            }
        }

        var startComponents = DateComponents()
        startComponents.year = startYear
        startComponents.month = startDate.month
        startComponents.day = startDate.day
        startComponents.hour = 0
        startComponents.minute = 0

        let seasonStartDate = calendar.date(from: startComponents) ?? Date()

        // Get end date (start of next sign)
        let nextSign = getNextSign(after: sign)
        let endDateComponents = nextSign.startDate

        var endComponents = DateComponents()
        endComponents.year = endYear
        endComponents.month = endDateComponents.month
        endComponents.day = endDateComponents.day
        endComponents.hour = 0
        endComponents.minute = 0

        // Adjust year if next sign is in new year
        if nextSign.startDate.month < sign.startDate.month || sign == .capricorn {
            endComponents.year = startYear + 1
        }

        let seasonEndDate = calendar.date(from: endComponents) ?? Date()

        return SignSeason(
            sign: sign,
            startDate: seasonStartDate,
            endDate: seasonEndDate,
            year: year
        )
    }

    /// Get the next zodiac sign in sequence
    private static func getNextSign(after sign: ZodiacSign) -> ZodiacSign {
        let allSigns = ZodiacSign.allCases
        guard let currentIndex = allSigns.firstIndex(of: sign) else { return .aries }
        let nextIndex = (currentIndex + 1) % allSigns.count
        return allSigns[nextIndex]
    }

    // MARK: - Message Generation

    private func generatePersonalMessage(userSign: ZodiacSign, seasonSign: ZodiacSign, spotlightStocks: [Stock]) -> String {
        let userElement = userSign.element
        let seasonElement = seasonSign.element

        if userSign == seasonSign {
            return "Happy \(seasonSign.displayName) Season! This is YOUR time to shine. The cosmic spotlight is on you and your holdings align with maximum solar energy."
        } else if userElement == seasonElement {
            return "\(seasonSign.displayName) Season activates your fellow \(seasonElement.displayName) energy. As a \(userSign.displayName), you're naturally in tune with this month's cosmic currents."
        } else if areElementsCompatible(userElement, seasonElement) {
            return "\(seasonSign.displayName) Season brings harmonious energy to your \(userSign.displayName) nature. The \(seasonElement.displayName) and \(userElement.displayName) elements work well together this month."
        } else {
            return "\(seasonSign.displayName) Season may feel like unfamiliar territory for your \(userSign.displayName) sensibilities. Use this time to explore outside your comfort zone."
        }
    }

    private func generateElementInsight(element: ZodiacSign.Element, elementStocks: [Stock]) -> String {
        let stockCount = elementStocks.count

        switch element {
        case .fire:
            if stockCount > 0 {
                return "Your \(stockCount) Fire sector holding\(stockCount > 1 ? "s are" : " is") activated. Fire signs favor bold moves, aggressive growth, and leadership. Expect increased momentum in these positions."
            } else {
                return "The Fire sector is activated this month. Consider exploring Aries, Leo, or Sagittarius companies for their bold growth energy."
            }

        case .earth:
            if stockCount > 0 {
                return "Your \(stockCount) Earth sector holding\(stockCount > 1 ? "s are" : " is") in focus. Earth signs favor stability, value, and steady accumulation. A good time to reinforce your foundation."
            } else {
                return "The Earth sector is grounded this month. Taurus, Virgo, and Capricorn companies offer practical, value-oriented opportunities."
            }

        case .air:
            if stockCount > 0 {
                return "Your \(stockCount) Air sector holding\(stockCount > 1 ? "s are" : " is") energized. Air signs thrive on communication, innovation, and intellectual pursuits. Ideas become action."
            } else {
                return "The Air sector is buzzing with ideas. Gemini, Libra, and Aquarius companies may lead in innovation and communication this month."
            }

        case .water:
            if stockCount > 0 {
                return "Your \(stockCount) Water sector holding\(stockCount > 1 ? "s are" : " is") flowing. Water signs connect to intuition, emotion, and deep currents. Trust your gut on these positions."
            } else {
                return "The Water sector runs deep this month. Cancer, Scorpio, and Pisces companies may reveal hidden value through intuitive assessment."
            }
        }
    }

    private func generateTradingOutlook(seasonSign: ZodiacSign, hasSpotlightStocks: Bool) -> String {
        let modality = seasonSign.modality

        var outlook = ""

        switch modality {
        case .cardinal:
            outlook = "\(seasonSign.displayName) is a Cardinal sign — this month favors initiating new positions and taking decisive action. "
        case .fixed:
            outlook = "\(seasonSign.displayName) is a Fixed sign — this month favors holding steady and building on existing positions. "
        case .mutable:
            outlook = "\(seasonSign.displayName) is a Mutable sign — this month favors flexibility and adapting to changing conditions. "
        }

        if hasSpotlightStocks {
            outlook += "Your \(seasonSign.displayName) holdings are in the cosmic spotlight."
        } else {
            outlook += "Consider how \(seasonSign.displayName) energy might complement your portfolio."
        }

        return outlook
    }

    private func areElementsCompatible(_ e1: ZodiacSign.Element, _ e2: ZodiacSign.Element) -> Bool {
        switch (e1, e2) {
        case (.fire, .air), (.air, .fire): return true
        case (.earth, .water), (.water, .earth): return true
        case (.fire, .fire), (.earth, .earth), (.air, .air), (.water, .water): return true
        default: return false
        }
    }
}

// MARK: - Supporting Types

/// Represents a zodiac season period
struct SignSeason: Identifiable {
    let id = UUID()
    let sign: ZodiacSign
    let startDate: Date
    let endDate: Date
    let year: Int

    /// Duration of this season in days
    var durationDays: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 30
    }

    /// Progress through the current season (0.0 - 1.0)
    var progress: Double {
        let now = Date()
        guard now >= startDate else { return 0 }
        guard now <= endDate else { return 1 }

        let total = endDate.timeIntervalSince(startDate)
        let elapsed = now.timeIntervalSince(startDate)
        return elapsed / total
    }

    /// Days remaining in this season
    var daysRemaining: Int {
        let calendar = Calendar.current
        return max(0, calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }

    /// Formatted start date
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: startDate)
    }

    /// Formatted date range
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        return "\(start) - \(end)"
    }

    /// Season announcement text
    var announcementText: String {
        "\(sign.displayName) Season begins \(formattedStartDate). Your \(sign.element.displayName) Sector stocks are activated."
    }

    /// Notification text for local notifications
    var notificationText: String {
        "Sun enters \(sign.displayName). Your \(sign.element.displayName) Sector is in focus."
    }
}

/// Personalized horoscope for the current season
struct SeasonHoroscope: Identifiable {
    let id = UUID()
    let season: SignSeason
    let userSign: ZodiacSign
    let personalMessage: String
    let elementInsight: String
    let tradingOutlook: String
    let spotlightStocks: [Stock]
    let elementStocks: [Stock]

    /// Whether user has holdings in the spotlight
    var hasSpotlightHoldings: Bool {
        !spotlightStocks.isEmpty
    }

    /// Total value of spotlight stocks
    var spotlightValue: Double {
        spotlightStocks.reduce(0) { $0 + $1.totalValue }
    }

    /// Total value of element-aligned stocks
    var elementValue: Double {
        elementStocks.reduce(0) { $0 + $1.totalValue }
    }
}
