import Foundation

// MARK: - HoroscopeGenerator
// ===========================
// A service that generates personalized daily portfolio horoscopes
// with a sharp, Bloomberg-meets-Co-Star voice: witty, specific, actually insightful.
//
// The generator analyzes:
// - User's sun sign (and uses sign-specific personality traits)
// - Portfolio performance with real numbers
// - Dominant element and balance
// - Current planetary events
// - Specific stock movements by name
// - Time of day / market status
//
// Output is a 2-4 sentence reading that feels personal, specific, and useful.

struct HoroscopeGenerator {

    // MARK: - Generation

    /// Generate a personalized horoscope for the user
    static func generate(
        for user: UserProfile,
        planetaryEvents: [PlanetaryEvent] = PlanetaryEvent.currentEvents
    ) -> DailyHoroscope {

        let context = buildContext(for: user, events: planetaryEvents)

        // Build the horoscope from specialized templates
        var reading = buildReading(context: context)

        // Clean up any double spaces
        reading = reading.replacingOccurrences(of: "  ", with: " ")

        return DailyHoroscope(
            date: Date(),
            sign: user.sunSign,
            reading: reading,
            performance: context.performance,
            relevantEvent: context.relevantEvent,
            dominantElement: context.dominantElement
        )
    }

    // MARK: - Context Building

    private static func buildContext(
        for user: UserProfile,
        events: [PlanetaryEvent]
    ) -> HoroscopeContext {

        let performance = analyzePerformance(user: user)
        let dominantElement = findDominantElement(in: user)
        let relevantEvent = findRelevantEvent(for: user.sunSign, events: events)
        let portfolioAnalysis = analyzePortfolioComposition(user: user)
        let timeContext = analyzeTimeContext()

        return HoroscopeContext(
            user: user,
            performance: performance,
            dominantElement: dominantElement,
            relevantEvent: relevantEvent,
            portfolioAnalysis: portfolioAnalysis,
            timeContext: timeContext
        )
    }

    // MARK: - Reading Construction

    private static func buildReading(context: HoroscopeContext) -> String {
        var parts: [String] = []

        // 1. Time-aware opener (if market timing is relevant)
        if let timeOpener = selectTimeAwareOpener(context: context) {
            parts.append(timeOpener)
        }

        // 2. Main observation (performance + specifics)
        parts.append(selectMainObservation(context: context))

        // 3. Sign-specific insight (personality-aware)
        if Bool.random() || parts.count < 2 {
            parts.append(selectSignSpecificInsight(context: context))
        }

        // 4. Closing wisdom or question
        parts.append(selectClosing(context: context))

        return parts.joined(separator: " ")
    }

    // MARK: - Time-Aware Opener

    private static func selectTimeAwareOpener(context: HoroscopeContext) -> String? {
        let timeContext = context.timeContext

        // Only include time-aware opener ~40% of the time to vary readings
        guard Bool.random() || timeContext.isWeekend || timeContext.isAfterHours else {
            return nil
        }

        switch timeContext.period {
        case .preMarket:
            return [
                "Markets open in \(timeContext.minutesToOpen ?? 0 > 60 ? "a few hours" : "\(timeContext.minutesToOpen ?? 60) minutes"). Your anxiety opened earlier.",
                "Pre-market futures are moving. Your blood pressure is keeping pace.",
                "The opening bell hasn't rung, but your portfolio thoughts are already loud.",
            ].randomElement()

        case .marketOpen:
            return [
                "Markets just opened. The chaos is fresh.",
                "First hour volatility is doing its thing.",
                "Opening bell energy: chaotic neutral.",
            ].randomElement()

        case .midDay:
            return nil // Don't always need a time opener

        case .powerHour:
            return [
                "Power hour approaches. Amateur hour ends.",
                "The last hour of trading. Where paper hands fold and diamond hands pretend they're not nervous.",
            ].randomElement()

        case .afterHours:
            return [
                "Markets are closed. Your portfolio can't hurt you until tomorrow.",
                "After-hours trading exists. Your ulcer doesn't care about market hours.",
                "The closing bell rang. Your positions are locked in their cells until 9:30 AM.",
            ].randomElement()

        case .weekend:
            return [
                "No trading today. The cosmos suggest touching grass.",
                "Markets are closed. Your portfolio is taking a much-needed break from your scrutiny.",
                "It's the weekend. The only green you should be watching is in your backyard.",
                "Two days without price movements. However will you cope.",
            ].randomElement()
        }
    }

    // MARK: - Main Observation

    private static func selectMainObservation(context: HoroscopeContext) -> String {
        let perf = context.performance
        let user = context.user

        // Build observation with real specifics
        var observation: String

        switch perf.sentiment {
        case .veryPositive:
            observation = selectVeryPositiveObservation(context: context)
        case .positive:
            observation = selectPositiveObservation(context: context)
        case .flat:
            observation = selectFlatObservation(context: context)
        case .negative:
            observation = selectNegativeObservation(context: context)
        case .veryNegative:
            observation = selectVeryNegativeObservation(context: context)
        }

        return observation
            .replacingOccurrences(of: "{change}", with: String(format: "%.1f%%", abs(perf.overallChange)))
            .replacingOccurrences(of: "{sign}", with: user.sunSign.displayName)
            .replacingOccurrences(of: "{element}", with: context.dominantElement?.displayName ?? "cosmic")
    }

    private static func selectVeryPositiveObservation(context: HoroscopeContext) -> String {
        let templates: [String]

        if let gainer = context.performance.topGainer {
            let gainerSign = gainer.zodiacSign?.displayName ?? "unknown"
            templates = [
                "\(gainer.name)'s \(gainer.formattedPercentageChange) surge is carrying your portfolio today. \(gainerSign) energy said 'you're welcome.'",
                "Your portfolio is up {change}. \(gainer.symbol) is doing the heavy lifting while the rest of your picks watch.",
                "\(gainer.symbol)'s \(gainerSign) confidence is radiating through your account. {change} up and counting.",
                "The {change} gain is real. \(gainer.name) remembered it has shareholders to impress.",
            ]
        } else {
            templates = [
                "Your portfolio is up {change}. Even you seem surprised.",
                "{change} gain. The cosmos aligned, or the market did. Take the win, {sign}.",
                "Everything's green. Enjoy it. Screenshot it. This feeling is temporary.",
            ]
        }

        return templates.randomElement() ?? templates[0]
    }

    private static func selectPositiveObservation(context: HoroscopeContext) -> String {
        let analysis = context.portfolioAnalysis

        var templates = [
            "Your portfolio is up {change}. Not life-changing, but enough to feel smug at dinner.",
            "A modest {change} gain. The universe gave what it could spare today.",
            "{change} up. Your {element} holdings are pulling their weight, barely.",
        ]

        // Add element-specific observation
        if let element = context.dominantElement {
            switch element {
            case .earth:
                templates.append("Your Earth holdings are doing what Earth holdings do: not much. That's the point.")
            case .fire:
                templates.append("Fire signs in your portfolio are warming up. Not burning yet, but the heat is building.")
            case .air:
                templates.append("Your Air holdings are thinking about gains. Whether they'll act on those thoughts is another matter.")
            case .water:
                templates.append("Water energy flows through your portfolio. Slow, steady, occasionally drowning your impatience.")
            }
        }

        // Add concentration insight
        if analysis.techPercentage > 60 {
            templates.append("You're \(Int(analysis.techPercentage))% tech. That's a bet on growth over stability. Own it or rebalance.")
        }

        return templates.randomElement() ?? templates[0]
    }

    private static func selectFlatObservation(context: HoroscopeContext) -> String {
        let analysis = context.portfolioAnalysis

        var templates = [
            "Your portfolio moved {change}. The market equivalent of a shrug emoji.",
            "Nothing happened today. Your positions are in a holding pattern, and so is your blood pressure.",
            "Flat. The cosmos has no opinion on your stocks today. Neither does anyone else, apparently.",
            "Zero percent change energy. The universe is edging you.",
        ]

        // Add balance insight
        if analysis.isWellBalanced {
            templates.append("Your portfolio's elemental balance is showing: gains and losses cancel out. Diversification working as intended, for better or worse.")
        }

        if let loser = context.performance.topLoser,
           let gainer = context.performance.topGainer,
           abs(loser.percentageChange) > 1 && gainer.percentageChange > 1 {
            templates.append("\(gainer.symbol) is up, \(loser.symbol) is down. The net effect? You're standing still while running in place.")
        }

        return templates.randomElement() ?? templates[0]
    }

    private static func selectNegativeObservation(context: HoroscopeContext) -> String {
        var templates: [String]

        if let loser = context.performance.topLoser {
            let loserSign = loser.zodiacSign?.displayName ?? "unknown"
            templates = [
                "Your portfolio's {change} dip is Saturn saying 'I told you so.' \(loser.symbol) took the hint personally.",
                "\(loser.name)'s \(loser.formattedPercentageChange) slide is testing your conviction. \(loserSign) mood swings are real.",
                "\(loser.symbol) is having an existential crisis. Your portfolio is having one too, down {change}.",
                "The {change} loss has a face: \(loser.symbol). Don't take it personally. Or do. The stock doesn't care.",
            ]
        } else {
            templates = [
                "Down {change}. Not devastating, but enough to ruin the vibes.",
                "Your portfolio is {change} lighter. The cosmos calls it a 'learning opportunity.' You call it Tuesday.",
                "A {change} dip. The universe is editing your net worth downward today.",
            ]
        }

        return templates.randomElement() ?? templates[0]
    }

    private static func selectVeryNegativeObservation(context: HoroscopeContext) -> String {
        var templates: [String]

        if let loser = context.performance.topLoser {
            let loserSign = loser.zodiacSign?.displayName ?? "unknown"
            templates = [
                "Mercury retrograde isn't why \(loser.symbol) dropped \(loser.formattedPercentageChange). But it's a convenient excuse.",
                "\(loser.name) said 'not today' and took your portfolio down {change} with it. \(loserSign) chaos.",
                "Your portfolio is down {change}. \(loser.symbol) is the main character in this tragedy.",
                "The void stared back today, and \(loser.symbol)'s \(loser.formattedPercentageChange) drop was its hello.",
            ]
        } else {
            templates = [
                "Down {change}. The cosmos didn't do this. The market did. But blame Pluto anyway.",
                "Your portfolio lost {change}. Some days the universe tests you. Today it's a final exam.",
                "{change} loss. Time in the market beats timing the market. Doesn't make today feel better, though.",
            ]
        }

        // Add holdings count context
        if context.portfolioAnalysis.holdingsCount > 8 {
            templates.append("With \(context.portfolioAnalysis.holdingsCount) positions, this {change} loss is a team effort. No single stock to blame.")
        }

        return templates.randomElement() ?? templates[0]
    }

    // MARK: - Sign-Specific Insight

    private static func selectSignSpecificInsight(context: HoroscopeContext) -> String {
        let sign = context.user.sunSign

        // Sign-specific observations that use actual personality traits
        switch sign {
        case .aries:
            return [
                "As an Aries, your instinct is to double down. Your wallet asks that you don't.",
                "Aries impatience says sell. Saturn says wait. You'll do whatever you want anyway.",
                "Your Aries energy wants action. Sometimes the action is doing nothing.",
            ].randomElement()!

        case .taurus:
            return [
                "Taurus stubbornness is an asset in investing. Unless you're stubborn about the wrong pick.",
                "As a Taurus, you hate change. Your portfolio is testing that.",
                "Bull energy in a bull market is redundant. In a bear market, it's resilience.",
            ].randomElement()!

        case .gemini:
            return [
                "Your Gemini brain has already considered three contradictory strategies. Pick one.",
                "Both sides of your Gemini nature have opinions on this portfolio. Neither is wrong. Neither is right.",
                "As a Gemini, you've already rationalized both selling and buying more. Impressive.",
            ].randomElement()!

        case .cancer:
            return [
                "Your Cancer intuition says something. Whether it's market wisdom or anxiety is unclear.",
                "As a Cancer, you're emotionally attached to at least one of these positions. That's fine until it isn't.",
                "Cancer loyalty to your picks is admirable. Sometimes it's also expensive.",
            ].randomElement()!

        case .leo:
            return [
                "Leo confidence in your portfolio is unshaken. Whether it's warranted is another matter.",
                "As a Leo, you expect your stocks to perform. They're aware of your expectations. They don't care.",
                "Your Leo energy demands attention. Your portfolio's performance is... quieter.",
            ].randomElement()!

        case .virgo:
            return [
                "As a Virgo, you've already noticed the 0.01% discrepancy in the math. Relax.",
                "Virgo analysis paralysis is real. You've run the numbers. Run them again if you must.",
                "Your Virgo precision wants perfect entries. Markets don't offer perfect, only available.",
            ].randomElement()!

        case .libra:
            return [
                "Libra indecision is showing. Your portfolio balance is showing too. Maybe that's enough.",
                "As a Libra, you've weighed every option twice. The market moved while you deliberated.",
                "Your Libra need for harmony conflicts with volatility. Volatility doesn't negotiate.",
            ].randomElement()!

        case .scorpio:
            return [
                "Scorpio intensity is overkill for portfolio management. But you'll be intense anyway.",
                "As a Scorpio, you're already planning revenge on the stock that betrayed you. It's a company, not a person.",
                "Your Scorpio instincts sense something. Market wisdom or paranoia? Time will tell.",
            ].randomElement()!

        case .sagittarius:
            return [
                "Sagittarius optimism says everything will be fine. Math says review your positions.",
                "As a Sagittarius, you're already looking at the next shiny opportunity. Focus.",
                "Your Sagittarius wanderlust wants exotic investments. Your risk tolerance should weigh in.",
            ].randomElement()!

        case .capricorn:
            return [
                "Capricorn discipline is your edge. Unless you're disciplined about the wrong strategy.",
                "As a Capricorn, you've already planned through seven market scenarios. Number eight will surprise you.",
                "Your Capricorn work ethic applies to your portfolio. Unfortunately, stocks don't care how hard you research.",
            ].randomElement()!

        case .aquarius:
            return [
                "Aquarius contrarianism is interesting. Buying what everyone else sells works until it doesn't.",
                "As an Aquarius, your portfolio is probably 'different.' Whether different means better is the question.",
                "Your Aquarius vision sees future value. The market sees today's price. Patience.",
            ].randomElement()!

        case .pisces:
            return [
                "Pisces intuition is valuable. Just don't let it override the spreadsheet entirely.",
                "As a Pisces, you feel your portfolio more than analyze it. Both have value.",
                "Your Pisces sensitivity to market vibes is real. So is the need for stop losses.",
            ].randomElement()!
        }
    }

    // MARK: - Closing

    private static func selectClosing(context: HoroscopeContext) -> String {
        var templates: [String] = []

        // Event-based closings
        if let event = context.relevantEvent {
            switch event.type {
            case .retrograde:
                templates += [
                    "With \(event.planet) retrograde, review your positions. Or don't. Free will is yours.",
                    "The retrograde asks you to reconsider. Your confirmation bias says you're right. Someone's wrong.",
                ]
            case .conjunction:
                templates += [
                    "This cosmic conjunction amplifies everything. Including your tendency to overthink.",
                ]
            case .moonPhase:
                templates += [
                    "The current lunar phase favors patience. Your refresh button disagrees.",
                ]
            case .transit:
                templates += [
                    "Planetary movement suggests movement. Whether your portfolio cooperates is its choice.",
                ]
            }
        }

        // Performance-based closings
        switch context.performance.sentiment {
        case .veryPositive, .positive:
            templates += [
                "Did you check your portfolio or just your horoscope? Both confirm you're fine.",
                "Enjoy the green. Resist the urge to tell everyone about it.",
                "Gains today. Try not to calculate what you'd have if you'd bought more.",
            ]
        case .flat:
            templates += [
                "Sometimes doing nothing is the move. Today confirmed that.",
                "The universe offers no clear direction. Make peace with ambiguity.",
                "Flat markets build character. Or boredom. Similar outcomes.",
            ]
        case .negative, .veryNegative:
            templates += [
                "Tomorrow is a new trading day. The stars will still be there, indifferent as always.",
                "This too shall pass. Your position doesn't have to, but it could.",
                "The cosmos tests those it... actually, it tests everyone. You're not special. Neither are your losses.",
            ]
        }

        // Add occasional question
        if Bool.random() {
            templates += [
                "Did you check your watchlist or just your ex's Instagram?",
                "What would you do if you weren't staring at a chart?",
                "Have you considered that some questions don't have answers?",
            ]
        }

        return templates.randomElement() ?? "The cosmos offers no further comment."
    }

    // MARK: - Analysis Helpers

    private static func analyzePerformance(user: UserProfile) -> PortfolioPerformance {
        let holdings = user.portfolio.filter(\.isOwned)

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

    private static func findRelevantEvent(
        for sign: ZodiacSign,
        events: [PlanetaryEvent]
    ) -> PlanetaryEvent? {
        return events.first { event in
            event.affectedSigns.contains(sign) || event.affectedElements.contains(sign.element)
        } ?? events.first
    }

    private static func analyzePortfolioComposition(user: UserProfile) -> PortfolioAnalysis {
        let holdings = user.portfolio.filter(\.isOwned)
        let verifiedHoldings = holdings.filter { $0.foundedElement != nil }
        let totalValue = verifiedHoldings.reduce(0.0) { $0 + $1.marketValue }

        guard totalValue > 0 else {
            return PortfolioAnalysis(
                holdingsCount: 0,
                techPercentage: 0,
                isWellBalanced: false,
                largestPosition: nil,
                smallestPosition: nil
            )
        }

        // Calculate tech percentage (Fire + Air signs are typically tech/growth)
        let techValue = verifiedHoldings
            .filter { $0.foundedElement == .fire || $0.foundedElement == .air }
            .reduce(0.0) { $0 + $1.marketValue }
        let techPercentage = (techValue / totalValue) * 100

        // Check balance across elements
        var elementPercentages: [ZodiacSign.Element: Double] = [:]
        for element in ZodiacSign.Element.allCases {
            let elementValue = holdings
                .filter { $0.foundedElement == element }
                .reduce(0.0) { $0 + $1.marketValue }
            elementPercentages[element] = (elementValue / totalValue) * 100
        }
        let maxElementPct = elementPercentages.values.max() ?? 0
        let isWellBalanced = maxElementPct < 40

        let largestPosition = holdings.max(by: { $0.marketValue < $1.marketValue })
        let smallestPosition = holdings.min(by: { $0.marketValue < $1.marketValue })

        return PortfolioAnalysis(
            holdingsCount: holdings.count,
            techPercentage: techPercentage,
            isWellBalanced: isWellBalanced,
            largestPosition: largestPosition,
            smallestPosition: smallestPosition
        )
    }

    private static func analyzeTimeContext() -> TimeContext {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let weekday = calendar.component(.weekday, from: now)

        // Weekend check (Saturday = 7, Sunday = 1)
        let isWeekend = weekday == 1 || weekday == 7

        if isWeekend {
            return TimeContext(
                period: .weekend,
                isWeekend: true,
                isAfterHours: true,
                minutesToOpen: nil,
                minutesToClose: nil
            )
        }

        // Market hours: 9:30 AM - 4:00 PM ET
        let totalMinutes = hour * 60 + minute
        let marketOpen = 9 * 60 + 30   // 9:30 AM
        let marketClose = 16 * 60       // 4:00 PM
        let powerHourStart = 15 * 60   // 3:00 PM

        let period: MarketPeriod
        let isAfterHours: Bool
        var minutesToOpen: Int? = nil
        var minutesToClose: Int? = nil

        if totalMinutes < marketOpen {
            period = .preMarket
            isAfterHours = true
            minutesToOpen = marketOpen - totalMinutes
        } else if totalMinutes < marketOpen + 30 {
            period = .marketOpen
            isAfterHours = false
            minutesToClose = marketClose - totalMinutes
        } else if totalMinutes < powerHourStart {
            period = .midDay
            isAfterHours = false
            minutesToClose = marketClose - totalMinutes
        } else if totalMinutes < marketClose {
            period = .powerHour
            isAfterHours = false
            minutesToClose = marketClose - totalMinutes
        } else {
            period = .afterHours
            isAfterHours = true
        }

        return TimeContext(
            period: period,
            isWeekend: false,
            isAfterHours: isAfterHours,
            minutesToOpen: minutesToOpen,
            minutesToClose: minutesToClose
        )
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

// MARK: - Context Types

/// Full context for horoscope generation
struct HoroscopeContext {
    let user: UserProfile
    let performance: PortfolioPerformance
    let dominantElement: ZodiacSign.Element?
    let relevantEvent: PlanetaryEvent?
    let portfolioAnalysis: PortfolioAnalysis
    let timeContext: TimeContext
}

/// Analysis of portfolio composition
struct PortfolioAnalysis {
    let holdingsCount: Int
    let techPercentage: Double
    let isWellBalanced: Bool
    let largestPosition: Stock?
    let smallestPosition: Stock?
}

/// Time-related context for the reading
struct TimeContext {
    let period: MarketPeriod
    let isWeekend: Bool
    let isAfterHours: Bool
    let minutesToOpen: Int?
    let minutesToClose: Int?
}

/// Current market period
enum MarketPeriod {
    case preMarket
    case marketOpen
    case midDay
    case powerHour
    case afterHours
    case weekend
}
