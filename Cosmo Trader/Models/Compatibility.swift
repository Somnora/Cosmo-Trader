import Foundation

// MARK: - Compatibility System
// ============================
// A rich compatibility analysis system inspired by Co-Star's voice:
// witty, slightly fatalistic, cosmically knowing.
//
// The system calculates compatibility between a user's sun sign and
// a stock's zodiac sign (based on founding date), producing:
// - A numerical score (0-100)
// - A rating category
// - A personalized description
// - Actionable (or amusingly unhelpful) advice

// MARK: - CompatibilityRating Enum

/// The five levels of cosmic compatibility
/// From destined partnership to karmic disaster
enum CompatibilityRating: String, CaseIterable, Codable {
    case cosmicSoulmates    // 85-100: Written in the stars
    case highCompatibility  // 65-84: The universe approves
    case neutral            // 40-64: The cosmos shrugs
    case challenging        // 20-39: Growth through suffering
    case cosmicClash        // 0-19: The universe is testing you

    /// Display name for UI
    var displayName: String {
        switch self {
        case .cosmicSoulmates:   return "Cosmic Soulmates"
        case .highCompatibility: return "High Compatibility"
        case .neutral:           return "Neutral"
        case .challenging:       return "Challenging"
        case .cosmicClash:       return "Cosmic Clash"
        }
    }

    /// Short tagline for the rating
    var tagline: String {
        switch self {
        case .cosmicSoulmates:   return "Rare cosmic match"
        case .highCompatibility: return "Strong alignment"
        case .neutral:           return "Neutral match"
        case .challenging:       return "Growth opportunity"
        case .cosmicClash:       return "High-friction match"
        }
    }

    /// SF Symbol representation
    var sfSymbol: String {
        switch self {
        case .cosmicSoulmates:   return "star.circle.fill"
        case .highCompatibility: return "scope"
        case .neutral:           return "moon.fill"
        case .challenging:       return "bolt.fill"
        case .cosmicClash:       return "exclamationmark.triangle.fill"
        }
    }

    /// Color name for UI theming
    var colorName: String {
        switch self {
        case .cosmicSoulmates:   return "gold"
        case .highCompatibility: return "purple"
        case .neutral:           return "gray"
        case .challenging:       return "orange"
        case .cosmicClash:       return "red"
        }
    }

    /// Get rating from a numerical score
    static func from(score: Int) -> CompatibilityRating {
        switch score {
        case 85...100: return .cosmicSoulmates
        case 65...84:  return .highCompatibility
        case 40...64:  return .neutral
        case 20...39:  return .challenging
        default:       return .cosmicClash
        }
    }
}

// MARK: - CompatibilityResult Struct

/// The complete result of a compatibility analysis
struct CompatibilityResult: Identifiable, Codable {
    let id: UUID
    let userSign: ZodiacSign
    let stockSign: ZodiacSign
    let score: Int                    // 0-100
    let rating: CompatibilityRating
    let description: String           // Co-Star style description
    let advice: String                // What to do about it
    let elementDynamic: String        // How the elements interact

    init(
        id: UUID = UUID(),
        userSign: ZodiacSign,
        stockSign: ZodiacSign,
        score: Int,
        description: String,
        advice: String,
        elementDynamic: String
    ) {
        self.id = id
        self.userSign = userSign
        self.stockSign = stockSign
        self.score = min(100, max(0, score)) // Clamp to 0-100
        self.rating = CompatibilityRating.from(score: score)
        self.description = description
        self.advice = advice
        self.elementDynamic = elementDynamic
    }

    /// Formatted score for display
    var formattedScore: String {
        "\(score)%"
    }

    /// Whether this is generally a positive pairing
    var isPositive: Bool {
        score >= 50
    }
}

// MARK: - Compatibility Calculator

/// The engine that calculates cosmic compatibility
/// Uses astrological principles with Co-Star's sardonic wisdom
enum CompatibilityCalculator {

    /// Calculate full compatibility between a user and a stock
    static func calculate(userSign: ZodiacSign, stockSign: ZodiacSign) -> CompatibilityResult {
        let score = calculateScore(userSign: userSign, stockSign: stockSign)
        let rating = CompatibilityRating.from(score: score)
        let elementDynamic = getElementDynamic(
            userElement: userSign.element,
            stockElement: stockSign.element
        )
        let description = getDescription(
            rating: rating,
            userSign: userSign,
            stockSign: stockSign
        )
        let advice = getAdvice(
            rating: rating,
            userSign: userSign,
            stockSign: stockSign
        )

        return CompatibilityResult(
            userSign: userSign,
            stockSign: stockSign,
            score: score,
            description: description,
            advice: advice,
            elementDynamic: elementDynamic
        )
    }

    /// Calculate compatibility for a user profile and stock
    static func calculate(user: UserProfile, stock: Stock) -> CompatibilityResult {
        calculate(userSign: user.sunSign, stockSign: stock.zodiacSign)
    }

    // MARK: - Score Calculation

    /// Calculate the numerical compatibility score
    /// Based on traditional astrological compatibility factors
    private static func calculateScore(userSign: ZodiacSign, stockSign: ZodiacSign) -> Int {
        var score = 50 // Base neutral score

        // Same sign: You understand each other too well
        if userSign == stockSign {
            score += 25
        }

        // Traditional compatibility (from compatibleSigns)
        if userSign.compatibleSigns.contains(stockSign) {
            score += 30
        }

        // Same element: Elemental harmony
        if userSign.element == stockSign.element {
            score += 15
        }

        // Complementary elements
        if areElementsComplementary(userSign.element, stockSign.element) {
            score += 10
        }

        // Challenging elements
        if areElementsChallenging(userSign.element, stockSign.element) {
            score -= 25
        }

        // Opposite signs (6 signs apart): Tension but attraction
        if areOppositeSigns(userSign, stockSign) {
            score -= 10 // Tension
            score += 5  // But also fascination
        }

        // Square aspect (3 signs apart): Friction
        if areSquareSigns(userSign, stockSign) {
            score -= 15
        }

        return min(100, max(0, score))
    }

    /// Check if elements are complementary (support each other)
    private static func areElementsComplementary(_ e1: ZodiacSign.Element, _ e2: ZodiacSign.Element) -> Bool {
        switch (e1, e2) {
        case (.fire, .air), (.air, .fire):   return true // Air feeds fire
        case (.earth, .water), (.water, .earth): return true // Water nourishes earth
        default: return false
        }
    }

    /// Check if elements are challenging (clash)
    private static func areElementsChallenging(_ e1: ZodiacSign.Element, _ e2: ZodiacSign.Element) -> Bool {
        switch (e1, e2) {
        case (.fire, .water), (.water, .fire): return true // Fire and water = steam/destruction
        case (.earth, .air), (.air, .earth):   return true // Earth smothers air / air erodes earth
        default: return false
        }
    }

    /// Check if signs are opposite (180 degrees apart)
    private static func areOppositeSigns(_ s1: ZodiacSign, _ s2: ZodiacSign) -> Bool {
        let opposites: [(ZodiacSign, ZodiacSign)] = [
            (.aries, .libra), (.taurus, .scorpio), (.gemini, .sagittarius),
            (.cancer, .capricorn), (.leo, .aquarius), (.virgo, .pisces)
        ]
        return opposites.contains { ($0 == s1 && $1 == s2) || ($0 == s2 && $1 == s1) }
    }

    /// Check if signs are square (90 degrees apart - friction)
    private static func areSquareSigns(_ s1: ZodiacSign, _ s2: ZodiacSign) -> Bool {
        let allSigns = ZodiacSign.allCases
        guard let i1 = allSigns.firstIndex(of: s1),
              let i2 = allSigns.firstIndex(of: s2) else { return false }
        let distance = abs(i1 - i2)
        return distance == 3 || distance == 9
    }

    // MARK: - Element Dynamics

    /// Get a description of how the two elements interact
    private static func getElementDynamic(
        userElement: ZodiacSign.Element,
        stockElement: ZodiacSign.Element
    ) -> String {
        if userElement == stockElement {
            return sameElementDynamics[userElement]?.randomElement()
                ?? "Same element. You get each other. Maybe too well."
        }

        let key = ElementPair(userElement, stockElement)
        return elementPairDynamics[key]?.randomElement()
            ?? "The elements acknowledge each other's existence."
    }

    /// Same-element dynamics
    private static let sameElementDynamics: [ZodiacSign.Element: [String]] = [
        .fire: [
            "Two fires burning. The heat is intense. So are the egos.",
            "Fire meets fire. Either a bonfire or a burnout. No in-between.",
            "Double fire energy. You'll either conquer together or reduce everything to ash."
        ],
        .earth: [
            "Earth grounds earth. Stable, predictable, maybe a little boring. You'll profit anyway.",
            "Two earth signs building something solid. Slow. Inevitable. Reliable.",
            "Grounded meets grounded. Nothing exciting will happen. Your portfolio won't mind."
        ],
        .air: [
            "Air amplifies air. Ideas everywhere. Execution optional.",
            "Two air signs intellectualizing everything. Analysis paralysis has entered the chat.",
            "Double air energy. Great at theory. The spreadsheet has seventeen tabs."
        ],
        .water: [
            "Water merges with water. Emotional depth. Also emotional flooding.",
            "Two water signs feeling their way through. Intuition is strong; logic needs a seat at the table.",
            "Deep meets deep. You'll feel the shift before you can explain it. Verify it anyway."
        ]
    ]

    /// Cross-element dynamics
    private static let elementPairDynamics: [ElementPair: [String]] = [
        // Fire + Earth
        ElementPair(.fire, .earth): [
            "Fire wants to leap. Earth wants a business plan. Compromise is available but not preferred.",
            "Your fire energy meets their grounded nature. You'll be frustrated. You'll also be rich.",
            "Fire burns hot, earth moves slow. One of you will learn patience. It won't be you."
        ],
        // Fire + Air
        ElementPair(.fire, .air): [
            "Air feeds your fire. Ideas become action. Neither of you will remember whose idea it was.",
            "Fire and air: a natural alliance. You ignite, they fan the flames. Try not to burn the house down.",
            "Your fire, their air. Together you're unstoppable. Apart you're just hot air and sparks."
        ],
        // Fire + Water
        ElementPair(.fire, .water): [
            "Fire meets water. Someone's getting extinguished. Statistically, it's you.",
            "Your fire, their water. Steam, tears, or transformation. Possibly all three.",
            "Fire and water don't mix. The universe knows this. The universe doesn't care."
        ],
        // Earth + Air
        ElementPair(.earth, .air): [
            "Earth wants roots. Air wants options. Neither of you is wrong. Both of you are frustrated.",
            "Grounded meets scattered. You'll provide stability. They'll provide chaos. Balance, theoretically.",
            "Your earth energy finds their air energy exhausting. Their returns find your skepticism offensive."
        ],
        // Earth + Water
        ElementPair(.earth, .water): [
            "Earth and water grow things. Patience plus intuition equals quiet, steady gains.",
            "Water nourishes earth. This is the slow-burn success story. Bring snacks.",
            "Your practicality, their intuition. A solid foundation for growth. Nothing flashy. Everything functional."
        ],
        // Air + Water
        ElementPair(.air, .water): [
            "Air analyzes what water feels. Neither fully understands the other. Both are correct.",
            "Logic meets intuition. Your spreadsheet should account for sentiment risk.",
            "Air and water: miscommunication as a love language. You'll figure it out eventually."
        ]
    ]

    // MARK: - Descriptions (Co-Star Voice)

    /// Get a rating-appropriate description
    private static func getDescription(
        rating: CompatibilityRating,
        userSign: ZodiacSign,
        stockSign: ZodiacSign
    ) -> String {
        let descriptions = ratingDescriptions[rating] ?? []
        var description = descriptions.randomElement() ?? "The reading is unclear. Use your own framework."

        // Replace placeholders
        description = description
            .replacingOccurrences(of: "{USER}", with: userSign.displayName)
            .replacingOccurrences(of: "{STOCK}", with: stockSign.displayName)
            .replacingOccurrences(of: "{USER_ELEMENT}", with: userSign.element.displayName)
            .replacingOccurrences(of: "{STOCK_ELEMENT}", with: stockSign.element.displayName)

        return description
    }

    /// Descriptions by rating level - at least 3 per level
    private static let ratingDescriptions: [CompatibilityRating: [String]] = [
        .cosmicSoulmates: [
            "This is rare reading fit. Your {USER} profile and this {STOCK} name line up across the astrology layer, but your own thesis still matters.",
            "A {USER} and a {STOCK} pairing reads unusually clean. Treat the alignment as context, not permission to skip research.",
            "This {STOCK} company was founded under a signature that mirrors your own. Good fit, still only one lens.",
            "The alignment is strong enough to notice. A {USER} and a {STOCK} can read clean if your own framework agrees.",
            "Your {USER_ELEMENT} exposure recognizes a clean match in their {STOCK_ELEMENT} foundation."
        ],
        .highCompatibility: [
            "A {USER} reading a {STOCK} company has solid fit. The reading is constructive, not conclusive.",
            "Your {USER_ELEMENT} nature harmonizes with their {STOCK_ELEMENT} energy. It's not soulmates, but it is a coherent lens.",
            "This pairing is not perfect, but it is coherent. Compatibility supports the thesis if the numbers also work.",
            "As a {USER}, you'll find this {STOCK} investment surprisingly intuitive. Use that as a prompt to research, not chase.",
            "High compatibility doesn't mean no conflict. It means the conflict will be productive. Your {USER} energy can work with their {STOCK} vibration."
        ],
        .neutral: [
            "The astrology layer has no strong opinion about a {USER} investing in a {STOCK} company. Let fundamentals lead.",
            "This pairing is neutral. It will not carry the reading by itself.",
            "Neutral does not mean bad. It means the decision needs a market thesis, not a sign thesis.",
            "A {USER} and a {STOCK} together reads as ordinary. Do your own research.",
            "This one is written in pencil: adjustable, unremarkable, and potentially profitable anyway."
        ],
        .challenging: [
            "This {STOCK} reading will teach you things about yourself you didn't ask to learn. Your {USER} nature will be tested. Growth is available.",
            "{USER} and {STOCK} create friction. Consider this a higher-effort read with open questions.",
            "Challenging doesn't mean impossible. It means your {USER_ELEMENT} energy and their {STOCK_ELEMENT} nature will need constant negotiation. Exhausting but educational.",
            "A {USER} investing in a {STOCK} company is the astrological equivalent of a gym membership. Uncomfortable. Character-building. Results not guaranteed.",
            "This pairing requires effort. Your {USER} instincts will clash with their {STOCK} energy. The friction can spark growth or just spark. Choose wisely."
        ],
        .cosmicClash: [
            "This is a high-friction pairing. If a {USER} studies a {STOCK} name here, the thesis has to do real work.",
            "Your {USER} nature and their {STOCK} energy are poorly matched. Defer to a strong thesis and your own risk rules.",
            "A cosmic clash does not mean failure. It means the reading needs extra context before conviction.",
            "This {STOCK} pairing reads as a warning, not a ban. Bold can work; unmanaged risk cannot.",
            "This is not a plot twist to romanticize. If you keep exploring, make the thesis measurable."
        ]
    ]

    // MARK: - Advice Generation

    /// Get rating-appropriate advice
    private static func getAdvice(
        rating: CompatibilityRating,
        userSign: ZodiacSign,
        stockSign: ZodiacSign
    ) -> String {
        let adviceList = ratingAdvice[rating] ?? []
        var advice = adviceList.randomElement() ?? "Consult your chart. Then ignore it."

        advice = advice
            .replacingOccurrences(of: "{USER}", with: userSign.displayName)
            .replacingOccurrences(of: "{STOCK}", with: stockSign.displayName)
            .replacingOccurrences(of: "{USER_ELEMENT}", with: userSign.element.displayName)
            .replacingOccurrences(of: "{STOCK_ELEMENT}", with: stockSign.element.displayName)

        return advice
    }

    /// Advice by rating level
    private static let ratingAdvice: [CompatibilityRating: [String]] = [
        .cosmicSoulmates: [
            "High fit is useful context. Still read the quarterly reports.",
            "Treat the reading as one lens. Your own framework still decides.",
            "Let your {USER} intuition guide attention, not the whole decision.",
            "This is a rare case where intuition and reading agree. Keep it inside your plan.",
            "A strong fit is better suited to patient research than impulse."
        ],
        .highCompatibility: [
            "A solid read for your portfolio lens. Check on it occasionally, like a low-maintenance plant.",
            "Your {USER} instincts are noticeable here. Verify them.",
            "Keep this compatibility in view only where the thesis remains intact.",
            "This can read as foundational in a watchlist. Not flashy, but coherent.",
            "The reading is steady. Use your {USER_ELEMENT} balance as a reflection prompt, not a timing tool."
        ],
        .neutral: [
            "Make your decision based on fundamentals. The astrology layer is neutral.",
            "The reading neither leans in nor pulls away. This is the Switzerland of investments.",
            "Due diligence matters more here. The signal is not doing the work for you.",
            "Notice the assumptions carefully. The reading is not co-signing the risk.",
            "Treat this like any other investment: with appropriate research and mild suspicion."
        ],
        .challenging: [
            "If you keep exploring, do so with eyes open. Growth requires surviving first.",
            "Treat this as a learning read. Budget attention, not certainty.",
            "Your {USER} nature may want to force this. Let your thesis prove itself.",
            "Keep skepticism close. The reading is not saying no, but it is not enthusiastic.",
            "Use this friction productively. Smaller assumptions. Larger lessons. Eventual wisdom."
        ],
        .cosmicClash: [
            "If you keep it on the list, keep the drama in perspective.",
            "A low-fit reading. Notice it, then defer to your own thesis.",
            "Define your risk rules elsewhere. The reading has warned you.",
            "Only keep exploring if you're comfortable telling this story later, regardless of outcome.",
            "Consider this a chaos read. Small assumptions. Maximum entertainment value."
        ]
    ]
}

// MARK: - Helper Types

/// A hashable pair of elements for dictionary lookup
private struct ElementPair: Hashable {
    let element1: ZodiacSign.Element
    let element2: ZodiacSign.Element

    init(_ e1: ZodiacSign.Element, _ e2: ZodiacSign.Element) {
        // Normalize order for consistent lookup
        if e1.rawValue < e2.rawValue {
            self.element1 = e1
            self.element2 = e2
        } else {
            self.element1 = e2
            self.element2 = e1
        }
    }
}

// MARK: - Extensions for Easy Access

extension UserProfile {

    /// Get full compatibility analysis with a stock
    func compatibility(with stock: Stock) -> CompatibilityResult {
        CompatibilityCalculator.calculate(user: self, stock: stock)
    }

    /// Get compatibility results for entire portfolio, sorted by score
    var portfolioCompatibility: [CompatibilityResult] {
        portfolio.map { compatibility(with: $0) }
            .sorted { $0.score > $1.score }
    }

    /// Average compatibility score across portfolio
    var averagePortfolioCompatibility: Int {
        guard !portfolio.isEmpty else { return 0 }
        let total = portfolio.reduce(0) { sum, stock in
            sum + CompatibilityCalculator.calculate(user: self, stock: stock).score
        }
        return total / portfolio.count
    }

    /// Get stocks grouped by compatibility rating
    var portfolioByCompatibility: [CompatibilityRating: [Stock]] {
        Dictionary(grouping: portfolio) { stock in
            compatibility(with: stock).rating
        }
    }
}

extension Stock {

    /// Get compatibility with a specific zodiac sign
    func compatibility(with userSign: ZodiacSign) -> CompatibilityResult {
        CompatibilityCalculator.calculate(userSign: userSign, stockSign: zodiacSign)
    }
}

extension ZodiacSign {

    /// Get compatibility with another sign
    func compatibility(with other: ZodiacSign) -> CompatibilityResult {
        CompatibilityCalculator.calculate(userSign: self, stockSign: other)
    }
}

// MARK: - Usage Examples
/*
 EXAMPLE 1: Get compatibility between user and stock
 ---------------------------------------------------
 let user = UserProfile.sample // Leo
 let stock = Stock.sample      // Apple (Aries)
 let result = user.compatibility(with: stock)

 print(result.score)           // 95
 print(result.rating)          // .cosmicSoulmates
 print(result.description)     // "When a Leo finds an Aries..."
 print(result.advice)          // "Trust this cosmic connection..."
 print(result.elementDynamic)  // "Two fires burning..."

 EXAMPLE 2: Analyze entire portfolio
 -----------------------------------
 let results = user.portfolioCompatibility
 for result in results {
     print("\(result.stockSign): \(result.score)% - \(result.rating.displayName)")
 }

 EXAMPLE 3: Direct sign-to-sign compatibility
 --------------------------------------------
 let result = ZodiacSign.leo.compatibility(with: .aquarius)
 print(result.description)  // Something about opposites...
*/
