import Foundation

// MARK: - OptionCompatibilityService
// ===================================
// Calculates cosmic compatibility for option expiration dates.
// Which expiry dates align with the user's zodiac energy?
//
// Factors considered:
// - Zodiac sign of the expiration date
// - Moon phase on that date
// - Day of week energy
// - Mercury retrograde periods (extra caution)

// MARK: - Expiry Compatibility Model

struct ExpiryCompatibility: Identifiable {
    let id = UUID()
    let date: Date
    let zodiacSign: ZodiacSign
    let moonPhase: MoonPhase
    let score: Int
    let insight: String
    let warnings: [ExpiryWarning]

    /// Whether this is a recommended expiry
    var isRecommended: Bool {
        score >= 80
    }

    /// Whether this expiry has warnings
    var hasWarnings: Bool {
        !warnings.isEmpty
    }

    /// Formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// Full formatted date
    var fullFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Days until expiration
    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    /// Rating text based on score
    var rating: String {
        switch score {
        case 90...: return "EXCELLENT"
        case 80..<90: return "GOOD"
        case 65..<80: return "NEUTRAL"
        case 50..<65: return "CAUTION"
        default: return "AVOID"
        }
    }
}

// MARK: - Expiry Warning

struct ExpiryWarning: Identifiable {
    let id = UUID()
    let type: WarningType
    let message: String

    enum WarningType: String {
        case fullMoon = "Full Moon"
        case mercuryRetrograde = "Mercury Retrograde"
        case fridayExpiry = "Friday Expiry"
        case volatileSign = "Volatile Energy"
        case newMoon = "New Moon"
    }

    var icon: String {
        switch type {
        case .fullMoon: return "moon.circle.fill"
        case .mercuryRetrograde: return "arrow.uturn.backward.circle"
        case .fridayExpiry: return "calendar.badge.exclamationmark"
        case .volatileSign: return "bolt.fill"
        case .newMoon: return "moon"
        }
    }
}

// MARK: - Service

enum OptionCompatibilityService {

    // MARK: - Main Calculation

    /// Get compatible expirations for user's sign
    /// - Parameters:
    ///   - userSign: User's zodiac sign
    ///   - expiryCount: Number of expiries to generate (default 6)
    /// - Returns: Array of expiry compatibility sorted by score
    static func getCompatibleExpirations(
        userSign: ZodiacSign,
        expiryCount: Int = 6
    ) -> [ExpiryCompatibility] {
        let expiries = generateUpcomingExpiries(count: expiryCount)
        return getCompatibleExpirations(userSign: userSign, availableExpiries: expiries)
    }

    /// Get compatible expirations from specific dates
    static func getCompatibleExpirations(
        userSign: ZodiacSign,
        availableExpiries: [Date]
    ) -> [ExpiryCompatibility] {
        return availableExpiries.map { date in
            let dateSign = ZodiacSign.from(date: date)
            let moonPhase = MoonPhase.from(date: date)

            // Base compatibility score
            let baseScore = userSign.compatibilityScore(with: dateSign)

            // Moon phase bonus/penalty
            let moonBonus = moonPhaseBonus(moonPhase)

            // Day of week bonus
            let dayBonus = dayOfWeekBonus(date)

            // Mercury retrograde penalty
            let retrogradeBonus = mercuryRetrogradeBonus(date)

            // Calculate final score (capped at 0-100)
            let finalScore = min(100, max(0, baseScore + moonBonus + dayBonus + retrogradeBonus))

            // Generate warnings
            let warnings = generateWarnings(date: date, moonPhase: moonPhase)

            // Generate insight
            let insight = generateExpiryInsight(
                date: date,
                sign: dateSign,
                moon: moonPhase,
                userSign: userSign
            )

            return ExpiryCompatibility(
                date: date,
                zodiacSign: dateSign,
                moonPhase: moonPhase,
                score: finalScore,
                insight: insight,
                warnings: warnings
            )
        }.sorted { $0.score > $1.score }
    }

    // MARK: - Generate Expiries

    /// Generate upcoming monthly option expiration dates
    /// Options typically expire on the 3rd Friday of each month
    static func generateUpcomingExpiries(count: Int = 6) -> [Date] {
        var expiries: [Date] = []
        let calendar = Calendar.current
        var currentDate = Date()

        for _ in 0..<count {
            if let nextExpiry = nextThirdFriday(after: currentDate) {
                expiries.append(nextExpiry)
                // Move to next month
                currentDate = calendar.date(byAdding: .month, value: 1, to: nextExpiry) ?? nextExpiry
            }
        }

        return expiries
    }

    /// Find the 3rd Friday of the month containing or after the given date
    private static func nextThirdFriday(after date: Date) -> Date? {
        let calendar = Calendar.current

        // Start with the first day of the current month
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = 1

        guard let firstOfMonth = calendar.date(from: components) else { return nil }

        // Find the first Friday
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let daysUntilFriday = (6 - weekday + 7) % 7  // Friday is weekday 6
        guard let firstFriday = calendar.date(byAdding: .day, value: daysUntilFriday, to: firstOfMonth) else { return nil }

        // Get the 3rd Friday (add 2 weeks)
        guard let thirdFriday = calendar.date(byAdding: .day, value: 14, to: firstFriday) else { return nil }

        // If the 3rd Friday has passed, get next month's
        if thirdFriday < date {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth) else { return nil }
            return nextThirdFriday(after: nextMonth)
        }

        return thirdFriday
    }

    // MARK: - Bonus Calculations

    private static func moonPhaseBonus(_ phase: MoonPhase) -> Int {
        switch phase {
        case .fullMoon:
            return -10  // Volatility spike risk
        case .newMoon:
            return -5   // Low energy, uncertainty
        case .waxingGibbous:
            return 10   // Building momentum
        case .firstQuarter:
            return 8    // Good for action
        case .waningGibbous:
            return 5    // Harvest energy
        case .waxingCrescent:
            return 3    // New beginnings
        case .lastQuarter, .waningCrescent:
            return 0    // Neutral
        }
    }

    private static func dayOfWeekBonus(_ date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)

        switch weekday {
        case 6:  // Friday
            return -5  // OpEx Friday can be volatile
        case 2:  // Monday
            return 3   // Fresh week energy
        case 4:  // Wednesday
            return 5   // Mid-week stability
        default:
            return 0
        }
    }

    private static func mercuryRetrogradeBonus(_ date: Date) -> Int {
        // 2025 Mercury Retrograde periods (approximate)
        let retrogrades: [(start: DateComponents, end: DateComponents)] = [
            (DateComponents(year: 2025, month: 3, day: 15), DateComponents(year: 2025, month: 4, day: 7)),
            (DateComponents(year: 2025, month: 7, day: 18), DateComponents(year: 2025, month: 8, day: 11)),
            (DateComponents(year: 2025, month: 11, day: 9), DateComponents(year: 2025, month: 11, day: 29)),
            (DateComponents(year: 2026, month: 3, day: 1), DateComponents(year: 2026, month: 3, day: 25)),
        ]

        let calendar = Calendar.current

        for retrograde in retrogrades {
            guard let start = calendar.date(from: retrograde.start),
                  let end = calendar.date(from: retrograde.end) else { continue }

            if date >= start && date <= end {
                return -15  // Significant penalty during retrograde
            }
        }

        return 0
    }

    // MARK: - Warnings

    private static func generateWarnings(date: Date, moonPhase: MoonPhase) -> [ExpiryWarning] {
        var warnings: [ExpiryWarning] = []

        // Full moon warning
        if moonPhase == .fullMoon {
            warnings.append(ExpiryWarning(
                type: .fullMoon,
                message: "Full Moon - volatility may spike"
            ))
        }

        // New moon warning
        if moonPhase == .newMoon {
            warnings.append(ExpiryWarning(
                type: .newMoon,
                message: "New Moon - uncertainty in direction"
            ))
        }

        // Friday expiry warning
        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 6 {
            warnings.append(ExpiryWarning(
                type: .fridayExpiry,
                message: "OpEx Friday - expect pin risk"
            ))
        }

        // Mercury retrograde warning
        if mercuryRetrogradeBonus(date) < 0 {
            warnings.append(ExpiryWarning(
                type: .mercuryRetrograde,
                message: "Mercury Retrograde - review positions carefully"
            ))
        }

        return warnings
    }

    // MARK: - Insight Generation

    private static func generateExpiryInsight(
        date: Date,
        sign: ZodiacSign,
        moon: MoonPhase,
        userSign: ZodiacSign
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        let dateString = formatter.string(from: date)

        // Check for same element
        let sameElement = sign.element == userSign.element

        // Check for compatible signs
        let isCompatible = userSign.compatibleSigns.contains(sign)

        // Check for challenging signs (low compatibility score)
        let compatScore = userSign.compatibilityScore(with: sign)
        let isChallenging = compatScore < 50

        // Generate insight based on factors
        if mercuryRetrogradeBonus(date) < 0 {
            return "\(dateString) falls during Mercury Retrograde. Double-check all positions and avoid rushed decisions."
        }

        if moon == .fullMoon {
            return "\(sign.displayName) Full Moon on \(dateString). Expect heightened volatility - risky for short-dated options."
        }

        if isCompatible {
            return "\(dateString) under \(sign.displayName) harmonizes with your \(userSign.displayName) energy. Favorable for calculated moves."
        }

        if sameElement {
            return "\(sign.displayName) energy (\(sign.element.displayName)) on \(dateString) resonates with your \(userSign.element.displayName) nature."
        }

        if isChallenging {
            return "\(dateString) under \(sign.displayName) challenges your \(userSign.displayName). Caution with aggressive positions."
        }

        // Default insights based on sign
        switch sign.element {
        case .fire:
            return "\(dateString) carries \(sign.displayName)'s fire energy. Bold moves may pay off, but manage risk."
        case .earth:
            return "\(sign.displayName)'s disciplined energy on \(dateString) favors longer-duration plays."
        case .air:
            return "\(sign.displayName)'s airy energy on \(dateString). Good for analytical plays, watch for indecision."
        case .water:
            return "\(dateString) under \(sign.displayName). Trust intuition but set stop losses."
        }
    }

    // MARK: - Best Expiry

    /// Get the single best expiry for the user
    static func getBestExpiry(userSign: ZodiacSign, count: Int = 6) -> ExpiryCompatibility? {
        getCompatibleExpirations(userSign: userSign, expiryCount: count).first
    }

    /// Get expiries grouped by rating
    static func getExpiriesByRating(
        userSign: ZodiacSign,
        count: Int = 6
    ) -> (excellent: [ExpiryCompatibility], good: [ExpiryCompatibility], avoid: [ExpiryCompatibility]) {
        let expiries = getCompatibleExpirations(userSign: userSign, expiryCount: count)

        let excellent = expiries.filter { $0.score >= 80 }
        let good = expiries.filter { $0.score >= 65 && $0.score < 80 }
        let avoid = expiries.filter { $0.score < 65 }

        return (excellent, good, avoid)
    }
}
