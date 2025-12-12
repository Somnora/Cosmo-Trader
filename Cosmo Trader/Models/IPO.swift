import Foundation
import SwiftUI

// MARK: - IPO Model
// ==================
// Represents an upcoming Initial Public Offering.
// The IPO date determines the company's zodiac sign - treat IPOs like births!

struct IPO: Identifiable, Equatable {

    let id: UUID
    let companyName: String
    let ticker: String?  // May not be assigned yet
    let expectedDate: Date
    let priceRangeLow: Double?
    let priceRangeHigh: Double?
    let sector: String
    let industry: String
    let description: String
    let headquarters: String
    let foundedYear: Int?
    let employeeCount: Int?
    let estimatedValuation: Double?

    // MARK: - Computed Properties

    /// The zodiac sign based on IPO date - the company's "birth sign"
    var zodiacSign: ZodiacSign {
        ZodiacSign.from(date: expectedDate)
    }

    /// Days until IPO
    var daysUntilIPO: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let ipoDate = calendar.startOfDay(for: expectedDate)
        return calendar.dateComponents([.day], from: today, to: ipoDate).day ?? 0
    }

    /// Whether IPO is in the past
    var hasLaunched: Bool {
        daysUntilIPO < 0
    }

    /// Whether IPO is today
    var isToday: Bool {
        daysUntilIPO == 0
    }

    /// Whether IPO is this week (next 7 days)
    var isThisWeek: Bool {
        daysUntilIPO >= 0 && daysUntilIPO <= 7
    }

    /// Whether IPO is this month
    var isThisMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(expectedDate, equalTo: Date(), toGranularity: .month)
    }

    /// Formatted expected date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: expectedDate)
    }

    /// Short formatted date
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: expectedDate)
    }

    /// Weekday of IPO
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: expectedDate)
    }

    /// Relative date description
    var relativeDateDescription: String {
        if isToday {
            return "Today"
        } else if daysUntilIPO == 1 {
            return "Tomorrow"
        } else if daysUntilIPO < 0 {
            return "Launched"
        } else if daysUntilIPO <= 7 {
            return "This \(weekdayName)"
        } else {
            return shortFormattedDate
        }
    }

    /// Formatted price range
    var formattedPriceRange: String? {
        guard let low = priceRangeLow, let high = priceRangeHigh else {
            return nil
        }
        return "$\(Int(low)) - $\(Int(high))"
    }

    /// Mid-point of price range
    var midPrice: Double? {
        guard let low = priceRangeLow, let high = priceRangeHigh else {
            return nil
        }
        return (low + high) / 2
    }

    /// Formatted estimated valuation
    var formattedValuation: String? {
        guard let valuation = estimatedValuation else { return nil }
        if valuation >= 1_000_000_000 {
            return String(format: "$%.1fB", valuation / 1_000_000_000)
        } else if valuation >= 1_000_000 {
            return String(format: "$%.0fM", valuation / 1_000_000)
        } else {
            return String(format: "$%.0f", valuation)
        }
    }

    /// Display ticker or placeholder
    var displayTicker: String {
        ticker ?? "TBA"
    }

    // MARK: - Compatibility

    /// Calculate compatibility with a user
    func compatibility(with user: UserProfile) -> IPOCompatibilityResult {
        let userSign = user.sunSign
        let ipoSign = zodiacSign

        // Base score from sign compatibility
        var score = calculateBaseScore(userSign: userSign, ipoSign: ipoSign)

        // Element harmony bonus
        let elementBonus = calculateElementBonus(userElement: userSign.element, ipoElement: ipoSign.element)
        score += elementBonus

        // Modality synergy
        let modalityBonus = calculateModalityBonus(userModality: userSign.modality, ipoModality: ipoSign.modality)
        score += modalityBonus

        // Clamp to 0-100
        score = max(0, min(100, score))

        return IPOCompatibilityResult(
            score: score,
            userSign: userSign,
            ipoSign: ipoSign,
            description: generateDescription(score: score, userSign: userSign, ipoSign: ipoSign),
            advice: generateAdvice(score: score, ipoSign: ipoSign),
            elementSynergy: describeElementSynergy(userElement: userSign.element, ipoElement: ipoSign.element)
        )
    }

    private func calculateBaseScore(userSign: ZodiacSign, ipoSign: ZodiacSign) -> Int {
        if userSign == ipoSign {
            return 95  // Same sign - cosmic twins
        } else if userSign.isCompatible(with: ipoSign) {
            return 85  // Traditional compatibility
        } else if userSign.element == ipoSign.element {
            return 80  // Same element
        } else {
            // Check for challenging combinations
            let challenging = [
                (ZodiacSign.aries, ZodiacSign.cancer),
                (ZodiacSign.taurus, ZodiacSign.aquarius),
                (ZodiacSign.gemini, ZodiacSign.virgo),
                (ZodiacSign.leo, ZodiacSign.scorpio),
                (ZodiacSign.sagittarius, ZodiacSign.pisces),
                (ZodiacSign.capricorn, ZodiacSign.libra)
            ]
            for (a, b) in challenging {
                if (userSign == a && ipoSign == b) || (userSign == b && ipoSign == a) {
                    return 45
                }
            }
            return 60  // Neutral
        }
    }

    private func calculateElementBonus(userElement: ZodiacSign.Element, ipoElement: ZodiacSign.Element) -> Int {
        if userElement == ipoElement {
            return 10
        }
        // Complementary elements
        let complements: [(ZodiacSign.Element, ZodiacSign.Element)] = [
            (.fire, .air),
            (.earth, .water)
        ]
        for (a, b) in complements {
            if (userElement == a && ipoElement == b) || (userElement == b && ipoElement == a) {
                return 5
            }
        }
        return 0
    }

    private func calculateModalityBonus(userModality: ZodiacSign.Modality, ipoModality: ZodiacSign.Modality) -> Int {
        if userModality == ipoModality {
            return 3
        }
        return 0
    }

    private func generateDescription(score: Int, userSign: ZodiacSign, ipoSign: ZodiacSign) -> String {
        if score >= 90 {
            return "This \(ipoSign.displayName) birth aligns perfectly with your \(userSign.displayName) energy. A cosmic match made for early investors."
        } else if score >= 75 {
            return "This \(ipoSign.displayName) IPO harmonizes well with your \(userSign.displayName) nature. Strong potential for mutual growth."
        } else if score >= 60 {
            return "This \(ipoSign.displayName) company offers balanced energy for your \(userSign.displayName) portfolio."
        } else {
            return "This \(ipoSign.displayName) energy may challenge your \(userSign.displayName) approach, but challenges breed growth."
        }
    }

    private func generateAdvice(score: Int, ipoSign: ZodiacSign) -> String {
        if score >= 85 {
            return "Consider being an original holder from birth. The stars favor this cosmic connection."
        } else if score >= 70 {
            return "A solid opportunity. Watch the market open and trust your intuition on timing."
        } else if score >= 55 {
            return "Proceed mindfully. This company's energy may require patience to harmonize with yours."
        } else {
            return "If drawn to this IPO despite cosmic friction, start small and observe how your energies interact."
        }
    }

    private func describeElementSynergy(userElement: ZodiacSign.Element, ipoElement: ZodiacSign.Element) -> String {
        if userElement == ipoElement {
            return "Same element — natural understanding and shared approach to growth."
        }

        switch (userElement, ipoElement) {
        case (.fire, .air), (.air, .fire):
            return "Fire and Air fuel each other — your enthusiasm ignites their innovation."
        case (.earth, .water), (.water, .earth):
            return "Earth and Water nourish growth — your stability grounds their flow."
        case (.fire, .earth), (.earth, .fire):
            return "Fire and Earth require balance — ambition meets practicality."
        case (.fire, .water), (.water, .fire):
            return "Fire and Water create steam — transformation through tension."
        case (.air, .earth), (.earth, .air):
            return "Air and Earth differ in approach — ideas meet execution."
        case (.air, .water), (.water, .air):
            return "Air and Water flow differently — logic meets intuition."
        default:
            return "Your elements interact in unique ways."
        }
    }

    // MARK: - Birth Narrative

    /// Generate a "birth announcement" style narrative
    var birthNarrative: String {
        let signTraits = zodiacSign.keyTraits.prefix(2).joined(separator: " and ")
        return "This company will be born a \(zodiacSign.displayName) — expect \(signTraits.lowercased()) in their market approach."
    }

    /// What kind of company personality based on sign
    var predictedPersonality: String {
        switch zodiacSign {
        case .aries:
            return "Bold first-mover energy. Expect aggressive growth strategies and market disruption."
        case .taurus:
            return "Built for longevity. This company will prioritize steady, reliable returns over flash."
        case .gemini:
            return "Adaptable and communicative. Watch for pivots and diversification."
        case .cancer:
            return "Customer-centric at heart. Strong brand loyalty potential."
        case .leo:
            return "A natural spotlight-seeker. Expect bold marketing and premium positioning."
        case .virgo:
            return "Detail-oriented execution. Operational excellence over hype."
        case .libra:
            return "Partnership-focused. Watch for strategic alliances and M&A activity."
        case .scorpio:
            return "Deep resources and transformation. They'll emerge stronger from challenges."
        case .sagittarius:
            return "Global expansion mindset. Optimistic growth trajectory."
        case .capricorn:
            return "Disciplined and ambitious. Long-term institutional investor appeal."
        case .aquarius:
            return "Innovation-driven disruptor. May challenge industry norms."
        case .pisces:
            return "Intuitive market sensing. Strong in creative and wellness sectors."
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        companyName: String,
        ticker: String? = nil,
        expectedDate: Date,
        priceRangeLow: Double? = nil,
        priceRangeHigh: Double? = nil,
        sector: String,
        industry: String = "",
        description: String,
        headquarters: String = "",
        foundedYear: Int? = nil,
        employeeCount: Int? = nil,
        estimatedValuation: Double? = nil
    ) {
        self.id = id
        self.companyName = companyName
        self.ticker = ticker
        self.expectedDate = expectedDate
        self.priceRangeLow = priceRangeLow
        self.priceRangeHigh = priceRangeHigh
        self.sector = sector
        self.industry = industry.isEmpty ? sector : industry
        self.description = description
        self.headquarters = headquarters
        self.foundedYear = foundedYear
        self.employeeCount = employeeCount
        self.estimatedValuation = estimatedValuation
    }
}

// MARK: - IPO Compatibility Result

struct IPOCompatibilityResult {
    let score: Int
    let userSign: ZodiacSign
    let ipoSign: ZodiacSign
    let description: String
    let advice: String
    let elementSynergy: String

    var rating: CompatibilityRating {
        switch score {
        case 85...100: return .cosmicSoulmates
        case 70..<85:  return .highCompatibility
        case 55..<70:  return .neutral
        case 40..<55:  return .challenging
        default:       return .cosmicClash
        }
    }

    var isHighlyCompatible: Bool {
        score >= 80
    }
}

// MARK: - IPO Status

enum IPOStatus: String, CaseIterable {
    case upcoming = "Upcoming"
    case thisWeek = "This Week"
    case today = "Today"
    case launched = "Launched"
    case withdrawn = "Withdrawn"

    var color: Color {
        switch self {
        case .upcoming: return CosmicTheme.textSecondary
        case .thisWeek: return CosmicTheme.gold
        case .today: return CosmicTheme.positive
        case .launched: return CosmicTheme.nebulaBlue
        case .withdrawn: return CosmicTheme.negative
        }
    }
}

// MARK: - IPO Sort Option

enum IPOSortOption: String, CaseIterable {
    case date = "Date"
    case compatibility = "Compatibility"
    case sector = "Sector"
    case valuation = "Valuation"

    var icon: String {
        switch self {
        case .date: return "calendar"
        case .compatibility: return "sparkles"
        case .sector: return "building.2"
        case .valuation: return "dollarsign.circle"
        }
    }
}
