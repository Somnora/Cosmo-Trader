import Foundation
import SwiftUI

// MARK: - SignalFramingService
// ============================
// Controls how signals are framed throughout the app.
// Allows users to dial between rational (technical) and mystical (astrological) language.
//
// Examples:
// - Rational: "Technical indicators suggest consolidation. Volume declining 15%."
// - Balanced: "Mercury retrograde aligns with declining volume. Review positions."
// - Mystical: "Mercury stations retrograde in your 2nd house. The cosmos whispers patience."

// MARK: - Signal Framing Level

enum SignalFramingLevel: Double, CaseIterable, Codable {
    case rational = 0.0
    case leanRational = 0.25
    case balanced = 0.5
    case leanMystical = 0.75
    case mystical = 1.0

    var displayName: String {
        switch self {
        case .rational: return "Rational"
        case .leanRational: return "Lean Rational"
        case .balanced: return "Balanced"
        case .leanMystical: return "Lean Mystical"
        case .mystical: return "Mystical"
        }
    }

    var shortName: String {
        switch self {
        case .rational: return "DATA"
        case .leanRational: return "TECH"
        case .balanced: return "BLEND"
        case .leanMystical: return "COSMIC"
        case .mystical: return "STARS"
        }
    }

    var description: String {
        switch self {
        case .rational:
            return "Pure technical analysis. No astrology references."
        case .leanRational:
            return "Primarily data-driven with subtle cosmic context."
        case .balanced:
            return "Astrology as metaphor for market patterns."
        case .leanMystical:
            return "Cosmic guidance with data support."
        case .mystical:
            return "More astrological language, still tied to market relevance."
        }
    }

    var sfSymbol: String {
        switch self {
        case .rational: return "chart.bar.fill"
        case .leanRational: return "chart.line.uptrend.xyaxis"
        case .balanced: return "scale.3d"
        case .leanMystical: return "scope"
        case .mystical: return "moon.stars.fill"
        }
    }

    var color: Color {
        switch self {
        case .rational: return CosmicTheme.positive
        case .leanRational: return CosmicTheme.nebulaBlue
        case .balanced: return CosmicTheme.gold
        case .leanMystical: return CosmicTheme.accentBlue
        case .mystical: return CosmicTheme.gold.opacity(0.9)
        }
    }

    /// Find nearest level from a raw value
    static func nearest(to value: Double) -> SignalFramingLevel {
        let clamped = min(1.0, max(0.0, value))
        return allCases.min(by: { abs($0.rawValue - clamped) < abs($1.rawValue - clamped) }) ?? .balanced
    }
}

// MARK: - Signal Framing Service

final class SignalFramingService {

    // MARK: - Singleton

    static let shared = SignalFramingService()

    private init() {}

    // MARK: - Headline Framing

    /// Frame a headline by interpolating between rational and mystical variants
    func frameHeadline(
        rational: String,
        mystical: String,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return rational
        case .leanRational:
            // Mostly rational with slight softening
            return rational
        case .balanced:
            // Could alternate or use a blended style
            return Bool.random() ? rational : mystical
        case .leanMystical:
            return mystical
        case .mystical:
            return mystical
        }
    }

    // MARK: - Conditions Framing

    /// Frame cosmic conditions description based on level
    func frameConditions(
        energy: CosmicEnergyLevel,
        mercury: MercuryStatus,
        moon: MoonPhase,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return rationalConditions(energy: energy, mercury: mercury, moon: moon)
        case .leanRational:
            return leanRationalConditions(energy: energy, mercury: mercury, moon: moon)
        case .balanced:
            return balancedConditions(energy: energy, mercury: mercury, moon: moon)
        case .leanMystical:
            return leanMysticalConditions(energy: energy, mercury: mercury, moon: moon)
        case .mystical:
            return mysticalConditions(energy: energy, mercury: mercury, moon: moon)
        }
    }

    private func rationalConditions(energy: CosmicEnergyLevel, mercury: MercuryStatus, moon: MoonPhase) -> String {
        var parts: [String] = []

        switch energy {
        case .high:
            parts.append("Market momentum indicators elevated")
        case .moderate:
            parts.append("Neutral technical conditions")
        case .low:
            parts.append("Low volatility environment")
        case .cautious:
            parts.append("Mixed signals across indicators")
        }

        if mercury == .retrograde {
            parts.append("Communication sector historically volatile this period")
        }

        if moon == .fullMoon {
            parts.append("Historically higher volume expected")
        } else if moon == .newMoon {
            parts.append("Lower activity period typical")
        }

        return parts.joined(separator: ". ") + "."
    }

    private func leanRationalConditions(energy: CosmicEnergyLevel, mercury: MercuryStatus, moon: MoonPhase) -> String {
        var parts: [String] = []

        switch energy {
        case .high:
            parts.append("Technical context is constructive today")
        case .moderate:
            parts.append("Balanced market conditions")
        case .low:
            parts.append("Consolidation pattern emerging")
        case .cautious:
            parts.append("Conflicting signals suggest patience")
        }

        if mercury == .retrograde {
            parts.append("Cyclical communication disruption period")
        }

        return parts.joined(separator: ". ") + "."
    }

    private func balancedConditions(energy: CosmicEnergyLevel, mercury: MercuryStatus, moon: MoonPhase) -> String {
        var parts: [String] = []

        switch energy {
        case .high:
            parts.append("Cosmic momentum aligns with bullish indicators")
        case .moderate:
            parts.append("Planetary balance suggests steady approach")
        case .low:
            parts.append("Lunar cycle supports consolidation")
        case .cautious:
            parts.append("Celestial crosscurrents warrant caution")
        }

        if mercury == .retrograde {
            parts.append("Mercury retrograde: review before committing")
        }

        parts.append("\(moon.rawValue) phase influences sentiment")

        return parts.joined(separator: ". ") + "."
    }

    private func leanMysticalConditions(energy: CosmicEnergyLevel, mercury: MercuryStatus, moon: MoonPhase) -> String {
        var parts: [String] = []

        switch energy {
        case .high:
            parts.append("Cosmic context leans constructive; treat as flavor, not setup")
        case .moderate:
            parts.append("Cosmic conditions hold steady")
        case .low:
            parts.append("Low-conviction conditions favor patience")
        case .cautious:
            parts.append("Planetary aspects favor review over impulse")
        }

        if mercury == .retrograde {
            parts.append("Mercury retrograde raises execution risk")
        }

        parts.append("The \(moon.rawValue) can shape sentiment")

        return parts.joined(separator: ". ") + "."
    }

    private func mysticalConditions(energy: CosmicEnergyLevel, mercury: MercuryStatus, moon: MoonPhase) -> String {
        switch energy {
        case .high:
            if mercury == .retrograde {
                return "Cosmic momentum is elevated, but Mercury retrograde raises execution risk. The \(moon.rawValue) can amplify conviction, so confirm before acting."
            }
            return "Cosmic context is constructive. The \(moon.rawValue) is a flavor note; let your own framework decide anything else."
        case .moderate:
            return "Cosmic conditions are balanced. Neither chase nor retreat; use the \(moon.rawValue) as sentiment context."
        case .low:
            return "Cosmic energy is low. This \(moon.rawValue) phase favors review, watchlists, and restraint over new risk."
        case .cautious:
            let mercuryNote = mercury == .retrograde ? "Mercury's retrograde deepens this call for patience." : ""
            return "Mixed planetary aspects make the signal noisy. \(mercuryNote) The \(moon.rawValue) favors risk control over impulse."
        }
    }

    // MARK: - Posture Note Framing

    /// Frame a posture note based on level
    func frameSuggestedAction(
        action: SuggestedAction,
        level: SignalFramingLevel
    ) -> (title: String, description: String) {
        switch level {
        case .rational:
            return rationalAction(action)
        case .leanRational:
            return leanRationalAction(action)
        case .balanced:
            return balancedAction(action)
        case .leanMystical:
            return leanMysticalAction(action)
        case .mystical:
            return mysticalAction(action)
        }
    }

    private func rationalAction(_ action: SuggestedAction) -> (title: String, description: String) {
        switch action {
        case .watch:
            return ("Monitor", "Track the tape. The reading is context, not a setup.")
        case .review:
            return ("Portfolio Review", "Look at your positions against your own targets.")
        case .rest:
            return ("Stand Aside", "Nothing in the reading asks for a move.")
        case .journal:
            return ("Document", "Note observations for your own reference.")
        case .rebalance:
            return ("Review Allocation", "Look at your weights against your own targets. The reading is not a trade signal.")
        }
    }

    private func leanRationalAction(_ action: SuggestedAction) -> (title: String, description: String) {
        switch action {
        case .watch:
            return ("Watch & Wait", "Monitor developments. Patience can be a useful posture.")
        case .review:
            return ("Review Positions", "Look at your holdings against current conditions.")
        case .rest:
            return ("Rest Day", "A quieter reading can be useful context.")
        case .journal:
            return ("Record Insights", "Document your thought process for future reference.")
        case .rebalance:
            return ("Review Weights", "A moment to look at your allocation. Decide for yourself.")
        }
    }

    private func balancedAction(_ action: SuggestedAction) -> (title: String, description: String) {
        switch action {
        case .watch:
            return ("Watch & Wait", "Observe market movements without acting. Let patterns emerge naturally.")
        case .review:
            return ("Review Portfolio", "Examine your positions. Assess alignment with your cosmic blueprint.")
        case .rest:
            return ("Rest Day", "Step back from the markets. The reading does not ask for urgency.")
        case .journal:
            return ("Journal Insights", "Document your observations and emotional state today.")
        case .rebalance:
            return ("Review Balance", "Notice how your allocation sits against your own goals.")
        }
    }

    private func leanMysticalAction(_ action: SuggestedAction) -> (title: String, description: String) {
        switch action {
        case .watch:
            return ("Watch the Tape", "Observe cosmic and market context without forcing a move.")
        case .review:
            return ("Review Holdings", "Check positions against today's cosmic market posture.")
        case .rest:
            return ("Step Back", "A quiet reading. Patience reads as the useful posture.")
        case .journal:
            return ("Log the Reading", "Record the reading, portfolio exposure, and what would change your mind.")
        case .rebalance:
            return ("Review Exposure", "Look at your allocation against the conditions you set for yourself.")
        }
    }

    private func mysticalAction(_ action: SuggestedAction) -> (title: String, description: String) {
        switch action {
        case .watch:
            return ("Watch the Reading", "Let the cosmic pattern sit beside your own framework.")
        case .review:
            return ("Review the Portfolio", "Each holding carries exposure. Confirm which names still fit today's reading.")
        case .rest:
            return ("Wait for Clarity", "The reading does not demand action. Let your own plan decide.")
        case .journal:
            return ("Record the Reading", "Capture the cosmic context, market setup, and portfolio implication.")
        case .rebalance:
            return ("Reflect On Exposure", "A reflection prompt only. Any change is yours alone.")
        }
    }

    // MARK: - Compatibility Framing

    /// Frame compatibility description based on level
    func frameCompatibility(
        userSign: ZodiacSign,
        stockSign: ZodiacSign,
        rating: CompatibilityRating,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return rationalCompatibility(rating: rating)
        case .leanRational:
            return leanRationalCompatibility(userSign: userSign, stockSign: stockSign, rating: rating)
        case .balanced:
            return balancedCompatibility(userSign: userSign, stockSign: stockSign, rating: rating)
        case .leanMystical:
            return leanMysticalCompatibility(userSign: userSign, stockSign: stockSign, rating: rating)
        case .mystical:
            return mysticalCompatibility(userSign: userSign, stockSign: stockSign, rating: rating)
        }
    }

    private func rationalCompatibility(rating: CompatibilityRating) -> String {
        switch rating {
        case .cosmicSoulmates:
            return "Historical correlation patterns strongly favorable."
        case .highCompatibility:
            return "Positive sector alignment indicators."
        case .neutral:
            return "No significant correlation patterns detected."
        case .challenging:
            return "Inverse correlation patterns observed historically."
        case .cosmicClash:
            return "Strong negative correlation. Exercise caution."
        }
    }

    private func leanRationalCompatibility(userSign: ZodiacSign, stockSign: ZodiacSign, rating: CompatibilityRating) -> String {
        let elementMatch = userSign.element == stockSign.element ? "Same sector characteristics." : "Different sector profiles."
        switch rating {
        case .cosmicSoulmates:
            return "Strong pattern alignment. \(elementMatch)"
        case .highCompatibility:
            return "Favorable indicators. \(elementMatch)"
        case .neutral:
            return "Mixed signals. \(elementMatch)"
        case .challenging:
            return "Contrarian relationship. \(elementMatch)"
        case .cosmicClash:
            return "Opposing patterns. Requires careful management."
        }
    }

    private func balancedCompatibility(userSign: ZodiacSign, stockSign: ZodiacSign, rating: CompatibilityRating) -> String {
        switch rating {
        case .cosmicSoulmates:
            return "\(userSign.displayName) and \(stockSign.displayName) share cosmic DNA. Natural alignment."
        case .highCompatibility:
            return "\(stockSign.displayName) energy harmonizes with your \(userSign.displayName) nature."
        case .neutral:
            return "Neither drawn nor repelled. \(stockSign.displayName) offers neutral ground."
        case .challenging:
            return "\(stockSign.displayName) challenges your \(userSign.displayName) tendencies. Growth opportunity."
        case .cosmicClash:
            return "Fundamental tension between \(userSign.displayName) and \(stockSign.displayName) energies."
        }
    }

    private func leanMysticalCompatibility(userSign: ZodiacSign, stockSign: ZodiacSign, rating: CompatibilityRating) -> String {
        switch rating {
        case .cosmicSoulmates:
            return "\(stockSign.displayName) closely mirrors your \(userSign.displayName) profile. Alignment is high."
        case .highCompatibility:
            return "Cosmic and profile signals are favorable for this \(stockSign.displayName) name."
        case .neutral:
            return "The cosmic signal is neutral. Let valuation and thesis decide."
        case .challenging:
            return "\(stockSign.displayName) creates friction with your \(userSign.displayName) profile. Review sizing."
        case .cosmicClash:
            return "Strong sign opposition. Treat this as a higher-discipline position."
        }
    }

    private func mysticalCompatibility(userSign: ZodiacSign, stockSign: ZodiacSign, rating: CompatibilityRating) -> String {
        switch rating {
        case .cosmicSoulmates:
            return "A rare alignment: your \(userSign.displayName) profile strongly matches this \(stockSign.displayName) exposure. Conviction can rise, but only with a real thesis."
        case .highCompatibility:
            return "The cosmic signal leans favorable for this \(stockSign.displayName) name. Use intuition as context, not a substitute for the chart."
        case .neutral:
            return "The cosmic read is neutral. You are not being pushed toward or away from this exposure."
        case .challenging:
            return "This \(stockSign.displayName) exposure cuts across your usual profile. Friction is useful only if the thesis is clear."
        case .cosmicClash:
            return "This \(stockSign.displayName) exposure sits in direct tension with your \(userSign.displayName) profile. Not forbidden, but it demands tighter risk control."
        }
    }

    // MARK: - News Context Framing

    /// Frame news alert context based on level
    func frameNewsContext(
        symbol: String,
        change: Double,
        stockSign: ZodiacSign?,
        level: SignalFramingLevel
    ) -> String? {
        guard abs(change) > 3 else { return nil }

        let direction = change > 0 ? "up" : "down"
        let magnitude = abs(change)

        switch level {
        case .rational:
            return "\(symbol) \(direction) \(String(format: "%.1f", magnitude))% on volume."
        case .leanRational:
            return "\(symbol) moves \(direction) \(String(format: "%.1f", magnitude))%. Watch for follow-through."
        case .balanced:
            if let sign = stockSign {
                return "\(symbol) (\(sign.displayName)) \(direction) \(String(format: "%.1f", magnitude))%. Movement aligns with \(sign.element.displayName) energy."
            }
            return "\(symbol) \(direction) \(String(format: "%.1f", magnitude))%."
        case .leanMystical:
            if let sign = stockSign {
                return "\(sign.displayName) energy is active in \(symbol)'s \(String(format: "%.1f", magnitude))% move. Watch for follow-through."
            }
            return "Cosmic currents move \(symbol) \(direction) \(String(format: "%.1f", magnitude))%."
        case .mystical:
            if let sign = stockSign {
                return "\(symbol)'s \(String(format: "%.1f", magnitude))% move activates its \(sign.displayName) signature. Let confirmation decide whether it matters."
            }
            return "\(symbol)'s \(String(format: "%.1f", magnitude))% move is the signal. Watch volume before reacting."
        }
    }

    // MARK: - Energy Headlines

    /// Get framed headlines for energy levels
    func getHeadlines(for energy: CosmicEnergyLevel, level: SignalFramingLevel) -> [String] {
        switch level {
        case .rational:
            return rationalHeadlines[energy] ?? []
        case .leanRational:
            return leanRationalHeadlines[energy] ?? []
        case .balanced:
            return balancedHeadlines[energy] ?? []
        case .leanMystical:
            return leanMysticalHeadlines[energy] ?? []
        case .mystical:
            return mysticalHeadlines[energy] ?? []
        }
    }

    private let rationalHeadlines: [CosmicEnergyLevel: [String]] = [
        .high: [
            "Conditions read as constructive.",
            "Technical context leans positive.",
            "Indicators line up - treat as context only.",
            "Volume reads as participation, not a call.",
            "Trend context is active. Not a trade signal."
        ],
        .moderate: [
            "Neutral technical conditions prevail.",
            "Standard volatility expected.",
            "No significant directional bias.",
            "Range-bound trading likely.",
            "Balanced risk-reward environment."
        ],
        .low: [
            "Low activity period typical.",
            "Consolidation pattern forming.",
            "Reduced volatility expected.",
            "Reading leans quiet; nothing in the chart demands a move.",
            "Minimal directional signals present."
        ],
        .cautious: [
            "Mixed signals across indicators.",
            "Elevated uncertainty in readings.",
            "Conflicting technical patterns.",
            "Risk management paramount today.",
            "Wait for clearer confirmation."
        ]
    ]

    private let leanRationalHeadlines: [CosmicEnergyLevel: [String]] = [
        .high: [
            "The reading leans constructive.",
            "Momentum context is on.",
            "Structure context is supportive - context only.",
            "Conditions ripe for opportunity.",
            "The data points toward growth."
        ],
        .moderate: [
            "Steady as she goes today.",
            "Neither overbought nor oversold.",
            "A day for measured moves.",
            "Balance in the indicators.",
            "Patience often outperforms action."
        ],
        .low: [
            "The market invites patience.",
            "Conservation beats aggression today.",
            "Lower activity, lower risk.",
            "Sometimes the best trade is no trade.",
            "Stillness has its own rewards."
        ],
        .cautious: [
            "Mixed readings call for care.",
            "When uncertain, observe.",
            "Conflicting signals suggest pause.",
            "Clarity emerges from patience.",
            "Today favors the cautious."
        ]
    ]

    private let balancedHeadlines: [CosmicEnergyLevel: [String]] = [
        .high: [
            "Cosmic momentum aligns with market strength.",
            "Charts and cosmic timing point in the same direction.",
            "Planetary energy amplifies technical signals.",
            "Cosmic tailwinds support growth.",
            "Data and timing read as constructive context."
        ],
        .moderate: [
            "Balance guides your path forward.",
            "Steady cosmic conditions meet steady markets.",
            "Neither rushed nor restrained today.",
            "The middle way offers clarity.",
            "Patience and persistence align."
        ],
        .low: [
            "Cosmic currents favor patience.",
            "Low cosmic energy mirrors quiet markets.",
            "Rest is part of the trading journey.",
            "Consolidation beats forced action.",
            "Quiet tape favors review over motion."
        ],
        .cautious: [
            "Mixed cosmic signals call for careful steps.",
            "Planetary crosscurrents warrant caution.",
            "Conflicting signals favor observation.",
            "Trust your instincts to wait.",
            "Not every day demands action."
        ]
    ]

    private let leanMysticalHeadlines: [CosmicEnergyLevel: [String]] = [
        .high: [
            "Cosmic momentum is elevated.",
            "Growth signals are active.",
            "Cosmic energy peaks; act with discipline.",
            "Initiative can work when confirmation is present.",
            "Planetary alignment favors controlled risk."
        ],
        .moderate: [
            "Cosmic balance holds.",
            "Equilibrium favors measured decisions.",
            "Neither surge nor retreat.",
            "Measured steps beat urgency.",
            "Harmony between ambition and patience."
        ],
        .low: [
            "The moon favors rest over risk.",
            "Cosmic energy ebbs; respect the cycle.",
            "A pause is a valid posture.",
            "Quiet conditions favor preparation.",
            "The market does not demand constant motion."
        ],
        .cautious: [
            "Planetary aspects ripple with uncertainty.",
            "Cosmic conditions ask for review.",
            "Mixed cosmic signals advise patience.",
            "When signals conflict, wait for clarity.",
            "Watching is the useful move today."
        ]
    ]

    private let mysticalHeadlines: [CosmicEnergyLevel: [String]] = [
        .high: [
            "Cosmic momentum is loud. Let confirmation choose the moment.",
            "Fire runs through the market tape. Discipline decides whether it is useful.",
            "Rare alignment is active. Awareness matters more than bravado.",
            "Cosmic conditions support initiative, but sizing still rules.",
            "The signal is constructive. Act from a plan, not a rush."
        ],
        .moderate: [
            "Cosmic balance holds. Neither rush nor retreat.",
            "The useful edge sits between action and patience.",
            "The signal neither pushes nor pulls. Choose deliberately.",
            "Cosmic equilibrium favors presence over pursuit.",
            "The tape is steady. Match its rhythm."
        ],
        .low: [
            "Cosmic conditions invite review, not risk.",
            "A quiet cycle is useful for preparation.",
            "Low signal makes discipline visible.",
            "This is not emptiness; it is a setup window.",
            "The market grants permission to stand aside."
        ],
        .cautious: [
            "The cosmic signal is noisy today. Listen for confirmation.",
            "Planetary crosscurrents argue for smaller moves.",
            "The reading offers questions, not certainty.",
            "Mixed cosmic energies invite review over action.",
            "When the signal says caution, capital preservation comes first."
        ]
    ]

    // MARK: - Moon Phase Framing

    /// Frame moon phase interpretation based on level
    func frameMoonPhase(
        phase: MoonPhase,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return rationalMoonPhase(phase)
        case .leanRational:
            return leanRationalMoonPhase(phase)
        case .balanced:
            return balancedMoonPhase(phase)
        case .leanMystical:
            return leanMysticalMoonPhase(phase)
        case .mystical:
            return mysticalMoonPhase(phase)
        }
    }

    private func rationalMoonPhase(_ phase: MoonPhase) -> String {
        switch phase {
        case .newMoon:
            return "Historically low activity period. Reduced volume typical."
        case .waxingCrescent:
            return "Early cycle. Building positions may be considered."
        case .firstQuarter:
            return "Mid-cycle checkpoint. Review current strategy."
        case .waxingGibbous:
            return "Building momentum period. Monitor for continuation."
        case .fullMoon:
            return "Historically elevated volatility. Consider position sizing."
        case .waningGibbous:
            return "Distribution phase typical. Take-profit opportunities."
        case .lastQuarter:
            return "Late cycle. Risk management focus recommended."
        case .waningCrescent:
            return "Cycle completion. Prepare for next phase."
        }
    }

    private func leanRationalMoonPhase(_ phase: MoonPhase) -> String {
        switch phase {
        case .newMoon:
            return "Quiet period. Good for planning and research."
        case .waxingCrescent:
            return "Early building phase. Small positions may accumulate."
        case .firstQuarter:
            return "Half-cycle mark. Evaluate progress."
        case .waxingGibbous:
            return "Momentum building. Watch for breakouts."
        case .fullMoon:
            return "Peak activity period. Emotions may run higher than usual."
        case .waningGibbous:
            return "Distribution phase. Consider securing gains."
        case .lastQuarter:
            return "Late cycle. Wind down aggressive positions."
        case .waningCrescent:
            return "Rest period approaching. Prepare for renewal."
        }
    }

    private func balancedMoonPhase(_ phase: MoonPhase) -> String {
        switch phase {
        case .newMoon:
            return "New Moon brings fresh starts. A time to plant seeds, not harvest."
        case .waxingCrescent:
            return "Intentions set at New Moon begin to take form. Nurture your positions."
        case .firstQuarter:
            return "First Quarter tests resolve. Challenges reveal which paths to continue."
        case .waxingGibbous:
            return "Energy builds toward culmination. Stay the course."
        case .fullMoon:
            return "Full Moon illuminates truth. Heightened volatility and clarity arrive together."
        case .waningGibbous:
            return "Time to share gains and release what no longer serves."
        case .lastQuarter:
            return "Last Quarter asks: what have you learned? Prepare to let go."
        case .waningCrescent:
            return "The dark before dawn. Rest, reflect, and prepare for the next cycle."
        }
    }

    private func leanMysticalMoonPhase(_ phase: MoonPhase) -> String {
        switch phase {
        case .newMoon:
            return "The sky goes dark. Set intentions, then turn them into watchlist criteria."
        case .waxingCrescent:
            return "The first sliver of light appears. Early ideas need confirmation."
        case .firstQuarter:
            return "Half-lit, half-shadow. The market tests your commitment."
        case .waxingGibbous:
            return "Nearly full, the Moon builds power. Trust the momentum."
        case .fullMoon:
            return "Luna at her peak illuminates hidden truths. Trade with awareness, not impulse."
        case .waningGibbous:
            return "The light begins to share itself. Time for gratitude and distribution."
        case .lastQuarter:
            return "Release what the cycle has completed. Make space for the new."
        case .waningCrescent:
            return "The balsamic moon favors endings. Rest before the next risk cycle."
        }
    }

    private func mysticalMoonPhase(_ phase: MoonPhase) -> String {
        switch phase {
        case .newMoon:
            return "In the dark moon, possibility is high but evidence is low. Define the thesis before taking risk."
        case .waxingCrescent:
            return "The first lunar light supports early conviction. Nurture ideas, but wait for proof."
        case .firstQuarter:
            return "The Moon stands at a crossroads. Choose the path with cleaner risk and better evidence."
        case .waxingGibbous:
            return "Power builds toward fullness. Momentum can work, but entries still need discipline."
        case .fullMoon:
            return "Luna reaches full light. Hidden risks and emotions surface; trade from process, not reaction."
        case .waningGibbous:
            return "The light begins to release. Review where the thesis has already played out."
        case .lastQuarter:
            return "This phase asks what to release to make room for the next setup."
        case .waningCrescent:
            return "The balsamic moon closes the cycle. Stand down, review, and prepare for the next read."
        }
    }

    // MARK: - Element Framing

    /// Frame element description based on level
    func frameElement(
        element: ZodiacSign.Element,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return rationalElement(element)
        case .leanRational:
            return leanRationalElement(element)
        case .balanced:
            return balancedElement(element)
        case .leanMystical:
            return leanMysticalElement(element)
        case .mystical:
            return mysticalElement(element)
        }
    }

    private func rationalElement(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire:
            return "Growth-oriented sector. Higher volatility, momentum-driven behavior."
        case .earth:
            return "Value-focused category. Stability emphasis, dividend potential."
        case .air:
            return "Communication/tech sector characteristics. Innovation-driven, higher P/E typical."
        case .water:
            return "Defensive positioning. Emotional market segments, consumer staples correlation."
        }
    }

    private func leanRationalElement(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire:
            return "Growth stocks with momentum characteristics. Higher risk, higher potential reward."
        case .earth:
            return "Value plays emphasizing stability. Steady compounders and dividend payers."
        case .air:
            return "Innovation-driven sectors. Tech and communication focused, growth over value."
        case .water:
            return "Intuition-sensitive sectors. Consumer and healthcare, defensive characteristics."
        }
    }

    private func balancedElement(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire:
            return "Fire energy drives bold growth. These stocks move fast and burn bright — handle with confidence, not recklessness."
        case .earth:
            return "Earth energy grounds your portfolio. Patient accumulation and steady returns define this territory."
        case .air:
            return "Air energy sparks innovation. Ideas and communication flow here — intellectual engagement required."
        case .water:
            return "Water energy runs deep. Intuition and emotional intelligence matter as much as fundamentals."
        }
    }

    private func leanMysticalElement(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire:
            return "Fire blazes through this stock's veins. It demands courage and rewards the daring. But remember: fire can warm or destroy."
        case .earth:
            return "Earth's patient wisdom animates this entity. It builds slowly, steadily, with roots that reach deep. Trust the long game."
        case .air:
            return "Air currents of thought and innovation swirl here. Quick, brilliant, ever-changing. Keep your mind sharp."
        case .water:
            return "Water's depths hold mysteries here. Trust your intuition, feel the undercurrents. Some things the charts cannot show."
        }
    }

    private func mysticalElement(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire:
            return "The primordial fire burns here — the same flame that forges stars and destroys old worlds. This stock carries the spark of creation itself. Approach as a warrior approaches the forge: with respect for its transformative power."
        case .earth:
            return "Ancient Earth energy permeates this entity. Like mountains that witnessed civilizations rise and fall, it knows the value of patience. In a world of noise, it offers the wisdom of stone."
        case .air:
            return "The breath of the cosmos flows through this stock. Ideas travel on invisible currents, connections spark across distances. Here, thought becomes reality, and the abstract takes form."
        case .water:
            return "The cosmic ocean's depths swirl within this entity. Like water, it holds memory, reflects truth, and finds paths around every obstacle. What your mind cannot grasp, your heart already knows."
        }
    }

    // MARK: - Element Dynamic Framing

    /// Frame element interaction between user and stock
    func frameElementDynamic(
        userElement: ZodiacSign.Element,
        stockElement: ZodiacSign.Element,
        level: SignalFramingLevel
    ) -> String {
        let isSame = userElement == stockElement
        let relationship = elementRelationship(userElement, stockElement)

        switch level {
        case .rational:
            if isSame {
                return "Same sector characteristics. Natural correlation expected."
            }
            return "\(relationship) sector relationship. \(elementCorrelation(userElement, stockElement))"
        case .leanRational:
            if isSame {
                return "Matching profiles suggest intuitive understanding of this stock's behavior."
            }
            return "\(relationship) dynamic. \(elementInteraction(userElement, stockElement, brief: true))"
        case .balanced:
            if isSame {
                return "\(userElement.displayName) meets \(userElement.displayName) — you speak the same elemental language."
            }
            return "\(userElement.displayName) and \(stockElement.displayName) create \(relationship.lowercased()) energy. \(elementInteraction(userElement, stockElement, brief: false))"
        case .leanMystical:
            if isSame {
                return "Your \(userElement.displayName) soul recognizes its reflection. Deep resonance flows here."
            }
            return "Your \(userElement.displayName) nature meets \(stockElement.displayName) energy. \(elementMysticalInteraction(userElement, stockElement))"
        case .mystical:
            if isSame {
                return "Element mirrors element. Your \(userElement.displayName) essence gazes into its cosmic reflection. What you see in this stock, you see in yourself."
            }
            return "\(userElement.displayName) dances with \(stockElement.displayName) in the eternal elemental ballet. \(elementDeepMysticalInteraction(userElement, stockElement))"
        }
    }

    private func elementRelationship(_ e1: ZodiacSign.Element, _ e2: ZodiacSign.Element) -> String {
        // Fire-Air and Earth-Water are harmonious, Fire-Water and Earth-Air are challenging
        let harmonious: Set<Set<ZodiacSign.Element>> = [[.fire, .air], [.earth, .water]]
        let pair = Set([e1, e2])
        if harmonious.contains(pair) {
            return "Complementary"
        } else {
            return "Contrasting"
        }
    }

    private func elementCorrelation(_ e1: ZodiacSign.Element, _ e2: ZodiacSign.Element) -> String {
        let harmonious: Set<Set<ZodiacSign.Element>> = [[.fire, .air], [.earth, .water]]
        let pair = Set([e1, e2])
        if harmonious.contains(pair) {
            return "Positive correlation patterns typical."
        } else {
            return "May provide diversification benefit."
        }
    }

    private func elementInteraction(_ e1: ZodiacSign.Element, _ e2: ZodiacSign.Element, brief: Bool) -> String {
        if e1 == .fire && e2 == .air || e1 == .air && e2 == .fire {
            return brief ? "Air fuels Fire's momentum." : "Air feeds Fire, amplifying growth potential."
        }
        if e1 == .earth && e2 == .water || e1 == .water && e2 == .earth {
            return brief ? "Water nourishes Earth's stability." : "Water nurtures Earth, deepening value roots."
        }
        if e1 == .fire && e2 == .water || e1 == .water && e2 == .fire {
            return brief ? "Steam may form — volatility possible." : "Fire and Water create steam — transformative but turbulent."
        }
        if e1 == .earth && e2 == .air || e1 == .air && e2 == .earth {
            return brief ? "Different priorities create tension." : "Earth grounds, Air floats — find the balance between stability and innovation."
        }
        if e1 == .fire && e2 == .earth || e1 == .earth && e2 == .fire {
            return brief ? "Growth meets stability." : "Fire's expansion meets Earth's caution — patience required."
        }
        if e1 == .air && e2 == .water || e1 == .water && e2 == .air {
            return brief ? "Mind meets intuition." : "Air's logic meets Water's intuition — head and heart must collaborate."
        }
        return "Unique elemental interaction."
    }

    private func elementMysticalInteraction(_ e1: ZodiacSign.Element, _ e2: ZodiacSign.Element) -> String {
        if e1 == .fire && e2 == .air || e1 == .air && e2 == .fire {
            return "Air breathes life into Fire. Together, you fan the flames of possibility."
        }
        if e1 == .earth && e2 == .water || e1 == .water && e2 == .earth {
            return "Water finds its vessel in Earth. Together, you create fertile ground."
        }
        if e1 == .fire && e2 == .water || e1 == .water && e2 == .fire {
            return "Fire and Water — creation and dissolution. Handle this alchemy with care."
        }
        if e1 == .earth && e2 == .air || e1 == .air && e2 == .earth {
            return "Earth and Air — the practical and the abstract. Bridge these worlds consciously."
        }
        if e1 == .fire && e2 == .earth || e1 == .earth && e2 == .fire {
            return "Fire blazes, Earth endures. The eternal dance of ambition and patience."
        }
        return "Air and Water — thought and feeling intertwine in mysterious ways."
    }

    private func elementDeepMysticalInteraction(_ e1: ZodiacSign.Element, _ e2: ZodiacSign.Element) -> String {
        if e1 == .fire && e2 == .air || e1 == .air && e2 == .fire {
            return "When Air embraces Fire, infernos of possibility ignite. You are the wind beneath this stock's wings — but wind can also scatter flame."
        }
        if e1 == .earth && e2 == .water || e1 == .water && e2 == .earth {
            return "Water seeks Earth to hold its form; Earth welcomes Water to bring it life. This is the primordial union of sustenance and structure."
        }
        if e1 == .fire && e2 == .water || e1 == .water && e2 == .fire {
            return "Fire meets Water across an ancient divide. One creates, one dissolves. In their steam, transformations occur that neither alone could manifest."
        }
        return "Elemental forces converge in patterns older than the stars themselves."
    }

    // MARK: - Zodiac Personality Framing

    /// Frame zodiac sign personality description based on level
    func frameZodiacPersonality(
        sign: ZodiacSign,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return rationalZodiacPersonality(sign)
        case .leanRational:
            return leanRationalZodiacPersonality(sign)
        case .balanced:
            return balancedZodiacPersonality(sign)
        case .leanMystical, .mystical:
            // For lean mystical and mystical, use the original personality descriptions
            return sign.personalityDescription
        }
    }

    private func rationalZodiacPersonality(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "First-mover characteristics. Aggressive growth positioning, higher risk tolerance typical."
        case .taurus:
            return "Value-oriented approach. Stability focus, long-term accumulation strategy."
        case .gemini:
            return "Adaptable positioning. Communication-sector correlation, quick pivot capability."
        case .cancer:
            return "Defensive characteristics. Consumer-staples correlation, stakeholder focus."
        case .leo:
            return "Brand-value emphasis. Marketing strength, leadership positioning."
        case .virgo:
            return "Operations efficiency. Detail-oriented management, quality metrics focus."
        case .libra:
            return "Partnership-oriented. Balance sheet focus, strategic alliance capability."
        case .scorpio:
            return "Transformation-driven. Deep value potential, turnaround characteristics."
        case .sagittarius:
            return "International exposure. Expansion-oriented, diversified revenue streams."
        case .capricorn:
            return "Institutional quality. Long-term track record, governance strength."
        case .aquarius:
            return "Innovation-driven. Disruption potential, technology advancement focus."
        case .pisces:
            return "Creative sector correlation. Brand storytelling, emotional connection emphasis."
        }
    }

    private func leanRationalZodiacPersonality(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "Pioneer mentality — moves first and fast. Built for growth, not preservation."
        case .taurus:
            return "Built to last. Values stability, compounds patiently, rewards the long view."
        case .gemini:
            return "Versatile and quick. Adapts rapidly, communicates well, pivots as needed."
        case .cancer:
            return "Protective of stakeholders. Defensive positioning with loyal customer base."
        case .leo:
            return "Bold brand presence. Commands attention, builds loyalty, leads its category."
        case .virgo:
            return "Excellence in execution. Sweats the details others miss."
        case .libra:
            return "Partnership-focused. Thrives on strategic alliances and balanced growth."
        case .scorpio:
            return "Transformative depth. Capable of profound reinvention and value unlocking."
        case .sagittarius:
            return "Global mindset. Expansion-driven with appetite for new territories."
        case .capricorn:
            return "Institutional backbone. Built for decades, not quarters."
        case .aquarius:
            return "Future-forward thinking. Questions conventions, builds tomorrow's solutions."
        case .pisces:
            return "Creative differentiation. Connects emotionally, tells compelling stories."
        }
    }

    private func balancedZodiacPersonality(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "Aries energy charges forward where others hesitate. A pioneer's stock for pioneer portfolios."
        case .taurus:
            return "Taurus knows the value of patience. This entity accumulates worth like ancient mountains accumulate stone."
        case .gemini:
            return "Gemini's dual nature adapts to any market. Communication flows, pivots come naturally."
        case .cancer:
            return "Cancer protects what matters. This entity nurtures stakeholders and guards its foundations."
        case .leo:
            return "Leo commands the spotlight. Brand strength and leadership define this entity's trajectory."
        case .virgo:
            return "Virgo perfects what others overlook. Operational excellence is the quiet superpower here."
        case .libra:
            return "Libra seeks harmony through partnership. Strategic alliances are this entity's strength."
        case .scorpio:
            return "Scorpio transforms through depth. Beneath the surface, profound value waits to emerge."
        case .sagittarius:
            return "Sagittarius aims for distant horizons. Global expansion and big-picture thinking drive this entity."
        case .capricorn:
            return "Capricorn builds for centuries. Institutional strength and disciplined growth define the path."
        case .aquarius:
            return "Aquarius disrupts the status quo. Innovation and unconventional thinking mark this territory."
        case .pisces:
            return "Pisces creates from intuition. Emotional resonance and creative vision flow through this entity."
        }
    }

    // MARK: - Corporate Personality Framing

    /// Frame corporate personality description based on level
    func frameCorporatePersonality(
        sign: ZodiacSign,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return rationalCorporatePersonality(sign)
        case .leanRational:
            return leanRationalCorporatePersonality(sign)
        case .balanced:
            return balancedCorporatePersonality(sign)
        case .leanMystical, .mystical:
            // For lean mystical and mystical, use the original cosmic descriptions
            return sign.corporatePersonality
        }
    }

    private func rationalCorporatePersonality(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "First-to-market positioning. Aggressive R&D spend, rapid iteration cycles."
        case .taurus:
            return "Value accumulation model. Strong balance sheet, dividend sustainability focus."
        case .gemini:
            return "Multi-channel strategy. Communication excellence, rapid adaptation capability."
        case .cancer:
            return "Stakeholder-centric governance. Customer loyalty metrics, employee retention focus."
        case .leo:
            return "Brand premium positioning. Marketing leadership, category dominance strategy."
        case .virgo:
            return "Operational excellence model. Efficiency metrics, quality assurance emphasis."
        case .libra:
            return "Strategic partnership model. M&A capability, joint venture track record."
        case .scorpio:
            return "Deep restructuring capability. Turnaround potential, hidden asset value."
        case .sagittarius:
            return "International expansion focus. Geographic diversification, emerging market exposure."
        case .capricorn:
            return "Long-term institutional model. Governance strength, regulatory compliance excellence."
        case .aquarius:
            return "Disruptive innovation model. R&D intensity, patent portfolio depth."
        case .pisces:
            return "Creative brand differentiation. Emotional marketing, lifestyle positioning."
        }
    }

    private func leanRationalCorporatePersonality(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "Moves fast, breaks things. First-mover advantage is the strategy."
        case .taurus:
            return "Builds wealth slowly but surely. Reliable returns over flashy gains."
        case .gemini:
            return "Versatile and communicative. Pivots quickly, markets effectively."
        case .cancer:
            return "Puts people first. Strong loyalty from customers and employees."
        case .leo:
            return "Commands attention. Premium brand with category leadership ambitions."
        case .virgo:
            return "Obsesses over details. Efficiency and quality drive the operation."
        case .libra:
            return "Wins through partnerships. Strategic alliances expand reach."
        case .scorpio:
            return "Transforms deeply. Unlocks value others can't see."
        case .sagittarius:
            return "Thinks globally. International expansion is the growth engine."
        case .capricorn:
            return "Plays the long game. Institutional strength built over decades."
        case .aquarius:
            return "Challenges the status quo. Innovation disrupts established players."
        case .pisces:
            return "Connects emotionally. Brand storytelling creates loyalty."
        }
    }

    private func balancedCorporatePersonality(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "A pioneer that charges where others hesitate. Speed and boldness are strategic advantages."
        case .taurus:
            return "A steady accumulator of value. What it builds, it keeps. Patience is its competitive edge."
        case .gemini:
            return "A versatile communicator. Adapts to change before competitors see it coming."
        case .cancer:
            return "A protector of its people. Stakeholder loyalty creates enduring moats."
        case .leo:
            return "A bold brand that commands attention. Premium positioning, premium returns."
        case .virgo:
            return "A meticulous optimizer. Excellence in execution creates durable advantage."
        case .libra:
            return "A partnership-oriented entity. Strategic alliances multiply its reach."
        case .scorpio:
            return "A transformative force. Capable of profound reinvention and value creation."
        case .sagittarius:
            return "An expansionist with global vision. New territories fuel growth ambitions."
        case .capricorn:
            return "A disciplined institution built to endure. Long-term thinking creates lasting value."
        case .aquarius:
            return "A disruptor that challenges industry norms. Innovation is the core strategy."
        case .pisces:
            return "An intuitive creator. Emotional connections and brand stories drive loyalty."
        }
    }

    // MARK: - CEO Insight Framing

    /// Frame CEO leadership insight based on level
    func frameCEOInsight(
        ceoName: String,
        ceoSign: ZodiacSign,
        level: SignalFramingLevel
    ) -> String {
        let firstName = ceoName.components(separatedBy: " ").first ?? "The CEO"

        switch level {
        case .rational:
            return rationalCEOInsight(firstName: firstName, sign: ceoSign)
        case .leanRational:
            return leanRationalCEOInsight(firstName: firstName, sign: ceoSign)
        case .balanced:
            return balancedCEOInsight(firstName: firstName, sign: ceoSign)
        case .leanMystical:
            return leanMysticalCEOInsight(firstName: firstName, sign: ceoSign)
        case .mystical:
            return mysticalCEOInsight(firstName: firstName, sign: ceoSign)
        }
    }

    private func rationalCEOInsight(firstName: String, sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "\(firstName)'s leadership style favors aggressive growth initiatives and first-mover positioning."
        case .taurus:
            return "\(firstName)'s approach emphasizes stability, long-term value creation, and methodical execution."
        case .gemini:
            return "\(firstName)'s style enables rapid adaptation, strong communication, and strategic pivots."
        case .cancer:
            return "\(firstName)'s focus on stakeholder relationships builds loyalty and organizational stability."
        case .leo:
            return "\(firstName)'s charismatic leadership drives brand visibility and market positioning."
        case .virgo:
            return "\(firstName)'s detail-oriented approach delivers operational excellence and quality focus."
        case .libra:
            return "\(firstName)'s diplomatic style excels at partnership development and strategic alliances."
        case .scorpio:
            return "\(firstName)'s strategic depth enables transformative initiatives and deep restructuring."
        case .sagittarius:
            return "\(firstName)'s visionary approach drives international expansion and big-picture strategy."
        case .capricorn:
            return "\(firstName)'s disciplined leadership builds sustainable long-term institutional value."
        case .aquarius:
            return "\(firstName)'s innovative thinking challenges conventions and drives disruption."
        case .pisces:
            return "\(firstName)'s creative vision shapes compelling brand narratives and emotional connections."
        }
    }

    private func leanRationalCEOInsight(firstName: String, sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "\(firstName) leads with bold, decisive action. Expect aggressive growth strategies."
        case .taurus:
            return "\(firstName) builds patiently and deliberately. Long-term value is the priority."
        case .gemini:
            return "\(firstName) adapts quickly and communicates effectively. Strategic flexibility is a strength."
        case .cancer:
            return "\(firstName) prioritizes people — employees and customers alike. Loyalty follows."
        case .leo:
            return "\(firstName) commands attention and builds strong brands. Leadership presence matters."
        case .virgo:
            return "\(firstName) sweats the details others miss. Operational excellence is the edge."
        case .libra:
            return "\(firstName) excels at partnerships and strategic alliances. Collaboration drives growth."
        case .scorpio:
            return "\(firstName) sees beneath the surface. Transformative moves unlock hidden value."
        case .sagittarius:
            return "\(firstName) thinks globally and acts boldly. International expansion is the vision."
        case .capricorn:
            return "\(firstName) builds for the long term. Discipline and structure create lasting value."
        case .aquarius:
            return "\(firstName) questions conventions and drives innovation. Disruption is the strategy."
        case .pisces:
            return "\(firstName) leads with creative vision and emotional intelligence. Stories sell."
        }
    }

    private func balancedCEOInsight(firstName: String, sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "\(firstName)'s Aries drive brings bold, pioneering leadership. Expect aggressive growth strategies and first-mover initiatives."
        case .taurus:
            return "\(firstName)'s Taurus energy emphasizes stability and long-term value creation. A methodical, patient approach to business."
        case .gemini:
            return "\(firstName)'s Gemini versatility enables quick pivots and excellent communication. Strong adaptability and media presence."
        case .cancer:
            return "\(firstName)'s Cancer intuition creates a nurturing corporate culture focused on employee and customer loyalty."
        case .leo:
            return "\(firstName)'s Leo charisma inspires teams and attracts attention. Bold vision with a flair for brand building."
        case .virgo:
            return "\(firstName)'s Virgo precision drives operational excellence. Detail-oriented approach to quality and efficiency."
        case .libra:
            return "\(firstName)'s Libra diplomacy excels at partnerships. Strategic alliance-focused leadership."
        case .scorpio:
            return "\(firstName)'s Scorpio intensity brings transformative leadership. Deep strategic thinking and resilience."
        case .sagittarius:
            return "\(firstName)'s Sagittarius optimism fuels international expansion. Adventurous big-picture thinking."
        case .capricorn:
            return "\(firstName)'s Capricorn discipline builds sustainable success. Conservative, structured approach to growth."
        case .aquarius:
            return "\(firstName)'s Aquarius innovation disrupts industries. Forward-thinking, technology-focused leadership."
        case .pisces:
            return "\(firstName)'s Pisces creativity brings imaginative solutions. Empathetic leadership with strong storytelling."
        }
    }

    private func leanMysticalCEOInsight(firstName: String, sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "\(firstName) carries the fire of Aries — a warrior spirit leading the charge. Where others see obstacles, they see opportunities to conquer."
        case .taurus:
            return "\(firstName) channels Taurus's ancient wisdom. They build like mountains form — slowly, surely, to last for ages."
        case .gemini:
            return "\(firstName)'s Gemini nature dances between worlds. Their quick mind and silver tongue navigate complexity with grace."
        case .cancer:
            return "\(firstName) leads with Cancer's protective heart. Their intuition for people creates loyalty money cannot buy."
        case .leo:
            return "\(firstName) radiates Leo's solar energy. Their presence commands rooms, their vision commands markets."
        case .virgo:
            return "\(firstName) embodies Virgo's sacred attention to detail. In their careful hands, excellence becomes inevitable."
        case .libra:
            return "\(firstName) wields Libra's gift for harmony. Partnerships flourish, balance emerges, and beauty follows."
        case .scorpio:
            return "\(firstName) carries Scorpio's transformative power. What they touch, they change — profoundly and permanently."
        case .sagittarius:
            return "\(firstName)'s Sagittarius arrow flies toward distant horizons. Their vision sees territories others haven't mapped."
        case .capricorn:
            return "\(firstName) climbs with Capricorn's patient determination. Summit by summit, they build empires meant to endure."
        case .aquarius:
            return "\(firstName) channels Aquarius's revolutionary current. They see the future before it arrives and build bridges to reach it."
        case .pisces:
            return "\(firstName) swims in Pisces's creative depths. Their imagination conjures visions that become reality."
        }
    }

    private func mysticalCEOInsight(firstName: String, sign: ZodiacSign) -> String {
        switch sign {
        case .aries:
            return "\(firstName) carries the primordial fire of Aries — the spark that ignites worlds. They lead as warriors lead: from the front, into the unknown, trusting the cosmos to light the way."
        case .taurus:
            return "\(firstName) is rooted in Taurus's eternal patience. Like the bull that knows the earth's rhythms, they understand that true value grows slowly, in darkness, before it blooms."
        case .gemini:
            return "\(firstName)'s soul speaks Gemini's twin languages — the practical and the possible. Their mercurial mind bridges worlds ordinary leaders cannot perceive."
        case .cancer:
            return "\(firstName) carries the Moon's wisdom through Cancer's waters. Their leadership nurtures, protects, and knows — instinctively — what their people need."
        case .leo:
            return "\(firstName) radiates the Sun's own fire through Leo's noble heart. Theirs is the light that others orbit — magnetic, generous, impossible to ignore."
        case .virgo:
            return "\(firstName) channels Virgo's sacred precision. In a universe of chaos, they find the perfect pattern and manifest it in material form."
        case .libra:
            return "\(firstName) holds Libra's scales — measuring not just profit, but harmony. Their gift is finding the balance point where all forces align."
        case .scorpio:
            return "\(firstName) dwells in Scorpio's depths where transformation is born. They are not afraid of endings, for they know each death births something greater."
        case .sagittarius:
            return "\(firstName)'s spirit gallops on Sagittarius's cosmic horse, arrow aimed at stars others cannot see. Their optimism is not naive — it is visionary."
        case .capricorn:
            return "\(firstName) ascends Capricorn's sacred mountain with ancient determination. Each step is measured, each stone placed for those who follow."
        case .aquarius:
            return "\(firstName) pours Aquarius's waters of future possibility. They see the world not as it is, but as it will be — and build the bridge between."
        case .pisces:
            return "\(firstName) swims in Pisces's ocean of infinite creativity. The boundary between dream and reality dissolves in their presence."
        }
    }

    // MARK: - Portfolio Balance Framing

    /// Frame portfolio balance insight based on level
    func framePortfolioBalance(
        dominantElement: ZodiacSign.Element,
        isBalanced: Bool,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return rationalPortfolioBalance(dominantElement: dominantElement, isBalanced: isBalanced)
        case .leanRational:
            return leanRationalPortfolioBalance(dominantElement: dominantElement, isBalanced: isBalanced)
        case .balanced:
            return balancedPortfolioBalance(dominantElement: dominantElement, isBalanced: isBalanced)
        case .leanMystical:
            return leanMysticalPortfolioBalance(dominantElement: dominantElement, isBalanced: isBalanced)
        case .mystical:
            return mysticalPortfolioBalance(dominantElement: dominantElement, isBalanced: isBalanced)
        }
    }

    private func rationalPortfolioBalance(dominantElement: ZodiacSign.Element, isBalanced: Bool) -> String {
        if isBalanced {
            return "Portfolio shows balanced sector exposure. Diversification adequate."
        }
        switch dominantElement {
        case .fire:
            return "Portfolio overweight in growth sectors. Consider adding value/defensive positions."
        case .earth:
            return "Portfolio concentrated in value/defensive sectors. Growth exposure may be lacking."
        case .air:
            return "Portfolio heavy in tech/communication sectors. Consider diversification."
        case .water:
            return "Portfolio tilted toward consumer/defensive sectors. Growth exposure limited."
        }
    }

    private func leanRationalPortfolioBalance(dominantElement: ZodiacSign.Element, isBalanced: Bool) -> String {
        if isBalanced {
            return "Your portfolio shows healthy sector diversification. Well-positioned for various market conditions."
        }
        switch dominantElement {
        case .fire:
            return "Growth-heavy positioning. Strong in bull markets, but consider stability additions."
        case .earth:
            return "Value-focused portfolio. Stable foundation, but may miss growth opportunities."
        case .air:
            return "Innovation-tilted allocation. High potential, but sector concentration risk exists."
        case .water:
            return "Defensive positioning dominates. Protected in downturns, but upside may be limited."
        }
    }

    private func balancedPortfolioBalance(dominantElement: ZodiacSign.Element, isBalanced: Bool) -> String {
        if isBalanced {
            return "Your portfolio holds all four elements in balance. No single exposure dominates the reading."
        }
        switch dominantElement {
        case .fire:
            return "Your portfolio runs hot with Fire exposure: bold and growth-hungry. Consider Earth exposure to stabilize gains."
        case .earth:
            return "Earth dominates your holdings: stable, but possibly too cautious. Fire exposure could add growth."
        case .air:
            return "Air dominates your portfolio: innovative, but potentially scattered. Earth could anchor the idea flow."
        case .water:
            return "Water runs deep in your holdings: intuitive and defensive. Fire could add return potential."
        }
    }

    private func leanMysticalPortfolioBalance(dominantElement: ZodiacSign.Element, isBalanced: Bool) -> String {
        if isBalanced {
            return "Your portfolio reflects elemental harmony. Fire, Earth, Air, and Water are balanced enough to keep the reading clean."
        }
        switch dominantElement {
        case .fire:
            return "Fire blazes through your portfolio. Bold energy is active, but Water can cool excess risk and Earth can preserve gains."
        case .earth:
            return "Earth grounds your holdings with patience. Air could expand the idea set; Fire could add growth."
        case .air:
            return "Air drives innovation through your portfolio. Ideas need Earth for execution and Water for defensive depth."
        case .water:
            return "Water flows through your holdings. Intuition guides the read, but Fire could counter defensive drift."
        }
    }

    private func mysticalPortfolioBalance(dominantElement: ZodiacSign.Element, isBalanced: Bool) -> String {
        if isBalanced {
            return "Your portfolio carries all elements in equilibrium. The cosmic read is cleaner because no single exposure is shouting."
        }
        switch dominantElement {
        case .fire:
            return "Fire dominates the scale. The portfolio can move fast, but burnout risk is real; Earth and Water exposure can stabilize the read."
        case .earth:
            return "Earth weighs heavy in the portfolio. Stability protects, but too much can mute upside; Fire and Air can add movement."
        case .air:
            return "Air fills the portfolio: innovation is loud, but execution risk rises. Earth and Water can ground the exposure."
        case .water:
            return "Water dominates the holdings. Defense is strong, but stagnant risk exists; Fire can add movement when confirmation appears."
        }
    }

    // MARK: - Horoscope / Cosmic Insight Framing

    /// Frame a general cosmic insight (for horoscopes) by interpolating between rational and mystical
    func frameCosmicInsight(
        rational: String,
        mystical: String,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return rational
        case .leanRational:
            // Mostly rational
            return rational
        case .balanced:
            // Could blend or alternate
            return Bool.random() ? rational : mystical
        case .leanMystical:
            return mystical
        case .mystical:
            return mystical
        }
    }

    // MARK: - IPO Birth Language Framing

    /// Frame IPO "cosmic birth" language based on level
    func frameIPOBirth(
        companyName: String,
        sign: ZodiacSign,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return "\(companyName) IPO. Sector: \(sign.element.displayName)-correlated."
        case .leanRational:
            return "\(companyName) enters the market. Founded under \(sign.displayName) characteristics."
        case .balanced:
            return "\(companyName) is born under \(sign.displayName). \(sign.element.displayName) energy shapes its market journey."
        case .leanMystical:
            return "\(companyName) takes its first cosmic breath as a \(sign.displayName). The stars have written a new name."
        case .mystical:
            return "\(companyName) emerges from the cosmic womb into \(sign.displayName)'s embrace. A new celestial entity is born — watch how it dances with the stars."
        }
    }

    // MARK: - Mercury Retrograde Framing

    /// Frame Mercury retrograde messaging based on level
    func frameMercuryRetrograde(
        status: MercuryStatus,
        level: SignalFramingLevel
    ) -> String {
        switch level {
        case .rational:
            return rationalMercuryStatus(status)
        case .leanRational:
            return leanRationalMercuryStatus(status)
        case .balanced:
            return balancedMercuryStatus(status)
        case .leanMystical:
            return leanMysticalMercuryStatus(status)
        case .mystical:
            return mysticalMercuryStatus(status)
        }
    }

    private func rationalMercuryStatus(_ status: MercuryStatus) -> String {
        switch status {
        case .direct:
            return "Communication sectors operating normally."
        case .retrograde:
            return "Historical data shows elevated volatility in communication/tech sectors during this period."
        case .preShadow:
            return "Approaching period of historically elevated miscommunication risk."
        case .postShadow:
            return "Exiting period of elevated volatility. Normal conditions returning."
        }
    }

    private func leanRationalMercuryStatus(_ status: MercuryStatus) -> String {
        switch status {
        case .direct:
            return "Clear conditions for contracts, communications, and tech decisions."
        case .retrograde:
            return "Mercury retrograde period. Review documents carefully, expect delays."
        case .preShadow:
            return "Pre-retrograde period. Finalize major decisions before slowdown."
        case .postShadow:
            return "Retrograde clearing. Forward momentum returning to communications."
        }
    }

    private func balancedMercuryStatus(_ status: MercuryStatus) -> String {
        switch status {
        case .direct:
            return "Mercury sails direct. Communications read clearer; treat it as calendar context."
        case .retrograde:
            return "Mercury retrograde invites reflection. Review before committing. Delays are teachers."
        case .preShadow:
            return "Mercury's shadow approaches. Finalize pending decisions. The slowdown nears."
        case .postShadow:
            return "Mercury emerges from shadow. Clarity returns. Resume forward motion."
        }
    }

    private func leanMysticalMercuryStatus(_ status: MercuryStatus) -> String {
        switch status {
        case .direct:
            return "Mercury's wings carry your intentions swiftly. The messenger god clears the path."
        case .retrograde:
            return "Mercury turns inward, asking you to do the same. What needs reviewing? What was left unsaid?"
        case .preShadow:
            return "Mercury's backward dance approaches. Tie loose ends. The cosmic pause nears."
        case .postShadow:
            return "Mercury stretches forward once more. Lessons integrated, you may now proceed with wisdom."
        }
    }

    private func mysticalMercuryStatus(_ status: MercuryStatus) -> String {
        switch status {
        case .direct:
            return "Mercury flies free on silver wings. The cosmic messenger delivers your intentions to the universe. Speak clearly — you are heard."
        case .retrograde:
            return "Mercury turns to face the past, and asks that you do the same. This is not punishment but invitation — to review, release, and remember. What contract with yourself needs renegotiation?"
        case .preShadow:
            return "Mercury's shadow falls ahead. The great pause approaches. What must be said before words grow slippery? What must be signed before ink becomes uncertain?"
        case .postShadow:
            return "Mercury emerges, carrying the gifts of introspection. The retrograde's lessons crystallize into wisdom. Now, move forward — but remember what standing still taught you."
        }
    }
}
