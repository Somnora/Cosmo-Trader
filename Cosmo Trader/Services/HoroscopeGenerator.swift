import Foundation

// MARK: - HoroscopeGenerator
// ===========================
// A service that generates personalized daily portfolio horoscopes
// in a Co-Star style voice: witty, direct, slightly nihilistic.
//
// The generator analyzes:
// - User's sun sign
// - Portfolio performance (up/down/flat)
// - Dominant element in portfolio
// - Current planetary events
// - Specific stock movements
//
// Output is a 2-4 sentence reading that feels personal and insightful.

struct HoroscopeGenerator {

    // MARK: - Generation

    /// Generate a personalized horoscope for the user
    static func generate(
        for user: UserProfile,
        planetaryEvents: [PlanetaryEvent] = PlanetaryEvent.currentEvents
    ) -> DailyHoroscope {

        let performance = analyzePerformance(user: user)
        let dominantElement = findDominantElement(in: user)
        let relevantEvent = findRelevantEvent(for: user.sunSign, events: planetaryEvents)

        // Build the horoscope from templates
        let opening = selectOpening(performance: performance, sign: user.sunSign)
        let middle = selectMiddle(
            performance: performance,
            element: dominantElement,
            topStock: performance.topGainer,
            bottomStock: performance.topLoser,
            sign: user.sunSign
        )
        let closing = selectClosing(
            performance: performance,
            event: relevantEvent,
            sign: user.sunSign
        )

        return DailyHoroscope(
            date: Date(),
            sign: user.sunSign,
            reading: "\(opening) \(middle) \(closing)",
            performance: performance,
            relevantEvent: relevantEvent,
            dominantElement: dominantElement
        )
    }

    // MARK: - Performance Analysis

    private static func analyzePerformance(user: UserProfile) -> PortfolioPerformance {
        let holdings = user.portfolio.filter { $0.sharesOwned > 0 }

        guard !holdings.isEmpty else {
            return PortfolioPerformance(
                overallChange: 0,
                sentiment: .flat,
                topGainer: nil,
                topLoser: nil,
                gainersCount: 0,
                losersCount: 0
            )
        }

        let gainers = holdings.filter { $0.priceChange > 0 }
        let losers = holdings.filter { $0.priceChange < 0 }

        let topGainer = holdings.max(by: { $0.percentageChange < $1.percentageChange })
        let topLoser = holdings.min(by: { $0.percentageChange < $1.percentageChange })

        let overallChange = user.totalDailyChangePercent

        let sentiment: PortfolioSentiment
        if overallChange > 1.5 {
            sentiment = .veryPositive
        } else if overallChange > 0.3 {
            sentiment = .positive
        } else if overallChange < -1.5 {
            sentiment = .veryNegative
        } else if overallChange < -0.3 {
            sentiment = .negative
        } else {
            sentiment = .flat
        }

        return PortfolioPerformance(
            overallChange: overallChange,
            sentiment: sentiment,
            topGainer: topGainer,
            topLoser: topLoser,
            gainersCount: gainers.count,
            losersCount: losers.count
        )
    }

    private static func findDominantElement(in user: UserProfile) -> ZodiacSign.Element? {
        let holdings = user.portfolio.filter { $0.sharesOwned > 0 }
        guard !holdings.isEmpty else { return nil }

        var elementValues: [ZodiacSign.Element: Double] = [:]
        for stock in holdings {
            let element = stock.zodiacSign.element
            elementValues[element, default: 0] += stock.totalValue
        }

        return elementValues.max(by: { $0.value < $1.value })?.key
    }

    private static func findRelevantEvent(
        for sign: ZodiacSign,
        events: [PlanetaryEvent]
    ) -> PlanetaryEvent? {
        // Find an event affecting the user's sign or element
        return events.first { event in
            event.affectedSigns.contains(sign) || event.affectedElements.contains(sign.element)
        } ?? events.first
    }

    // MARK: - Template Selection

    private static func selectOpening(
        performance: PortfolioPerformance,
        sign: ZodiacSign
    ) -> String {
        let templates: [String]

        switch performance.sentiment {
        case .veryPositive:
            templates = OpeningTemplates.veryPositive
        case .positive:
            templates = OpeningTemplates.positive
        case .flat:
            templates = OpeningTemplates.flat
        case .negative:
            templates = OpeningTemplates.negative
        case .veryNegative:
            templates = OpeningTemplates.veryNegative
        }

        let template = templates.randomElement() ?? templates[0]
        return template
            .replacingOccurrences(of: "{sign}", with: sign.displayName)
            .replacingOccurrences(of: "{change}", with: String(format: "%.1f%%", abs(performance.overallChange)))
    }

    private static func selectMiddle(
        performance: PortfolioPerformance,
        element: ZodiacSign.Element?,
        topStock: Stock?,
        bottomStock: Stock?,
        sign: ZodiacSign
    ) -> String {
        var templates: [String] = []

        // Add element-based templates if we have a dominant element
        if let element = element {
            templates += MiddleTemplates.byElement[element] ?? []
        }

        // Add stock-specific templates if we have notable movers
        if let gainer = topStock, gainer.percentageChange > 1.0 {
            templates += MiddleTemplates.topGainer.map { template in
                template
                    .replacingOccurrences(of: "{stock}", with: gainer.name)
                    .replacingOccurrences(of: "{symbol}", with: gainer.symbol)
                    .replacingOccurrences(of: "{change}", with: gainer.formattedPercentageChange)
                    .replacingOccurrences(of: "{stockSign}", with: gainer.zodiacSign.displayName)
            }
        }

        if let loser = bottomStock, loser.percentageChange < -1.0 {
            templates += MiddleTemplates.topLoser.map { template in
                template
                    .replacingOccurrences(of: "{stock}", with: loser.name)
                    .replacingOccurrences(of: "{symbol}", with: loser.symbol)
                    .replacingOccurrences(of: "{change}", with: loser.formattedPercentageChange)
                    .replacingOccurrences(of: "{stockSign}", with: loser.zodiacSign.displayName)
            }
        }

        // Fallback templates
        if templates.isEmpty {
            templates = MiddleTemplates.generic
        }

        let template = templates.randomElement() ?? "The stars are silent on specifics today."
        return template
            .replacingOccurrences(of: "{sign}", with: sign.displayName)
            .replacingOccurrences(of: "{element}", with: element?.displayName ?? "elemental")
    }

    private static func selectClosing(
        performance: PortfolioPerformance,
        event: PlanetaryEvent?,
        sign: ZodiacSign
    ) -> String {
        var templates: [String] = []

        // Add event-based closings if relevant
        if let event = event {
            templates += ClosingTemplates.byEventType[event.type] ?? []
        }

        // Add sentiment-based closings
        switch performance.sentiment {
        case .veryPositive, .positive:
            templates += ClosingTemplates.positive
        case .flat:
            templates += ClosingTemplates.neutral
        case .negative, .veryNegative:
            templates += ClosingTemplates.negative
        }

        let template = templates.randomElement() ?? "The cosmos offers no further comment."
        return template
            .replacingOccurrences(of: "{sign}", with: sign.displayName)
            .replacingOccurrences(of: "{planet}", with: event?.planet ?? "Mercury")
    }
}

// MARK: - Supporting Types

/// Performance summary of the portfolio
struct PortfolioPerformance {
    let overallChange: Double
    let sentiment: PortfolioSentiment
    let topGainer: Stock?
    let topLoser: Stock?
    let gainersCount: Int
    let losersCount: Int
}

/// Overall portfolio sentiment
enum PortfolioSentiment {
    case veryPositive   // > 1.5%
    case positive       // > 0.3%
    case flat           // -0.3% to 0.3%
    case negative       // < -0.3%
    case veryNegative   // < -1.5%
}

/// A generated daily horoscope
struct DailyHoroscope: Identifiable {
    let id = UUID()
    let date: Date
    let sign: ZodiacSign
    let reading: String
    let performance: PortfolioPerformance
    let relevantEvent: PlanetaryEvent?
    let dominantElement: ZodiacSign.Element?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Template Collections

/// Opening lines based on market performance
private enum OpeningTemplates {

    static let veryPositive = [
        "The universe is showing off today, {sign}.",
        "Even the cosmos couldn't ignore your portfolio's {change} surge.",
        "Jupiter sends its regards through your green numbers.",
        "Today the stars aligned—literally. Your portfolio thanks them.",
        "The celestial odds were in your favor, {sign}. Don't get used to it."
    ]

    static let positive = [
        "A gentle cosmic breeze lifts your holdings today, {sign}.",
        "Venus smiles on your portfolio, if only slightly.",
        "The stars didn't promise much, but they delivered something.",
        "A {change} gain. Small victories are still victories, {sign}.",
        "The universe offers you a modest green today. Accept it gracefully."
    ]

    static let flat = [
        "The moon is void-of-course and so is your portfolio's direction.",
        "Today the cosmos shrugged at your holdings, {sign}.",
        "Neither blessing nor curse—the stars are indifferent today.",
        "Your portfolio exists in a state of cosmic pause.",
        "The universe has no opinion on your stocks today. Rare neutrality."
    ]

    static let negative = [
        "The stars are testing your resolve today, {sign}.",
        "Saturn's lessons arrive in the form of red numbers.",
        "Not every day is a manifestation success. Today proves it.",
        "The cosmos asks: did you really need that {change} anyway?",
        "A minor cosmic correction. The universe is editing your expectations."
    ]

    static let veryNegative = [
        "Mercury retrograde is not why your portfolio is down. But blame it anyway.",
        "The void stared back today, {sign}. And it brought receipts.",
        "Some days the cosmos tests you. Today it's a pop quiz.",
        "Your {change} loss is just the universe's way of keeping you humble.",
        "Pluto demands transformation. Starting with your account balance."
    ]
}

/// Middle content referencing elements and specific stocks
private enum MiddleTemplates {

    static let byElement: [ZodiacSign.Element: [String]] = [
        .fire: [
            "Your Fire holdings burn bright—perhaps too bright.",
            "Fire energy dominates your portfolio. Bold, but watch for burns.",
            "The flames of your Fire stocks flicker with potential.",
            "Aries, Leo, Sagittarius energy courses through your positions. Stay sharp."
        ],
        .earth: [
            "Your Earth holdings remain grounded. Boring? Maybe. Stable? Absolutely.",
            "Taurus energy keeps your portfolio stubborn in the face of volatility.",
            "The Earth signs in your portfolio are doing what Earth signs do: enduring.",
            "Your practical Earth holdings won't make headlines. That's the point."
        ],
        .air: [
            "Your Air holdings drift with intellectual promise.",
            "Gemini, Libra, Aquarius energy swirls through your positions. Overthinking incoming.",
            "Air dominates your portfolio—ideas over execution, as always.",
            "Your Air stocks think they're smarter than the market. Sometimes they are."
        ],
        .water: [
            "Your Water holdings flow with emotional intelligence today.",
            "Cancer, Scorpio, Pisces energy runs deep in your portfolio.",
            "Trust your gut on these Water holdings. Or don't. The moon doesn't care.",
            "Water signs rule your portfolio. Intuition is your only strategy now."
        ]
    ]

    static let topGainer = [
        "That {change} gain in {stock}? You didn't manifest it, but you can pretend you did.",
        "{symbol}'s rise feels personal. It isn't, but let yourself have this.",
        "{stock} ({stockSign} energy) is having a moment. Bask in reflected glory.",
        "Your {symbol} position proves even broken clocks are right sometimes."
    ]

    static let topLoser = [
        "{stock}'s {change} drop isn't personal. The universe doesn't know your brokerage password.",
        "Blaming Mercury for {symbol}'s decline feels better than blaming yourself.",
        "{stock} is in its flop era. {stockSign} energy needs a nap.",
        "Your {symbol} position is teaching you about non-attachment. How Buddhist."
    ]

    static let generic = [
        "Your positions hold steady in the cosmic current.",
        "The stars see your portfolio but choose not to comment.",
        "Your holdings exist. The universe acknowledges this and nothing more.",
        "No individual stock demands cosmic attention today. Peaceful? Or ominous?"
    ]
}

/// Closing advice and reflections
private enum ClosingTemplates {

    static let byEventType: [PlanetaryEventType: [String]] = [
        .retrograde: [
            "With {planet} retrograde, review before you trade. Or don't. Free will exists.",
            "The retrograde asks you to reconsider. Will you? Probably not.",
            "Retrograde energy suggests patience. The market suggests otherwise."
        ],
        .conjunction: [
            "This cosmic conjunction amplifies everything. Including your anxiety.",
            "Two planets align. Your portfolio may or may not notice.",
            "Celestial convergence promises intensity. Define 'promise' loosely."
        ],
        .moonPhase: [
            "This lunar phase favors introspection over action.",
            "The moon's current state suggests holding. Emotionally and financially.",
            "Let the moon handle the tides. You handle your sell limits."
        ],
        .transit: [
            "This transit brings change. Whether you want it or not is irrelevant.",
            "Planetary movement suggests movement in your portfolio. Correlation isn't causation.",
            "The cosmic transit continues. So does the market. Both are indifferent to you."
        ]
    ]

    static let positive = [
        "Enjoy the green while it lasts, {sign}. Nothing is permanent.",
        "Today's gains are tomorrow's baseline. Manage expectations accordingly.",
        "The universe gave. Don't ask when it will take back.",
        "Celebrate quietly. The cosmos doesn't like bragging."
    ]

    static let neutral = [
        "Sometimes doing nothing is the move. Today might be one of those times.",
        "The cosmos offers no clear direction. Neither does your portfolio. Poetic.",
        "In stillness, find peace. Or at least find something on Netflix.",
        "When the stars are quiet, listen anyway. Or check your phone. Either works."
    ]

    static let negative = [
        "Remember: time in the market beats timing the market. Even when it hurts.",
        "The cosmos tests those it believes in. Or it's random. Both can be true.",
        "Tomorrow is a new trading day. The stars will still be there, indifferent as ever.",
        "This too shall pass. Your portfolio agrees, eventually."
    ]
}
