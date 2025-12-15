import Foundation
import SwiftUI

// MARK: - CosmicPatternInterpreter
// =================================
// Interprets technical chart patterns through a cosmic lens.
// Combines pattern analysis with astrological factors:
// - Mercury Retrograde status
// - Moon phase
// - Zodiac compatibility between user and stock
//
// This is the "secret sauce" that makes Cosmo Trader unique.

// MARK: - Cosmic Alignment

enum CosmicAlignment: String, CaseIterable {
    case stronglyAligned = "Strongly Aligned"
    case aligned = "Aligned"
    case neutral = "Neutral"
    case conflicted = "Conflicted"
    case stronglyConflicted = "Proceed with Caution"

    var score: Int {
        switch self {
        case .stronglyAligned: return 90
        case .aligned: return 70
        case .neutral: return 50
        case .conflicted: return 30
        case .stronglyConflicted: return 10
        }
    }

    var color: Color {
        switch self {
        case .stronglyAligned: return CosmicTheme.positive
        case .aligned: return CosmicTheme.positive.opacity(0.8)
        case .neutral: return CosmicTheme.gold
        case .conflicted: return .orange
        case .stronglyConflicted: return CosmicTheme.negative
        }
    }

    var icon: String {
        switch self {
        case .stronglyAligned: return "sparkles"
        case .aligned: return "star.fill"
        case .neutral: return "moon.stars"
        case .conflicted: return "exclamationmark.triangle"
        case .stronglyConflicted: return "xmark.octagon"
        }
    }

    static func from(score: Double) -> CosmicAlignment {
        switch score {
        case 75...: return .stronglyAligned
        case 55..<75: return .aligned
        case 45..<55: return .neutral
        case 25..<45: return .conflicted
        default: return .stronglyConflicted
        }
    }
}

// MARK: - Cosmic Pattern Insight

struct CosmicPatternInsight: Identifiable {
    let id = UUID()
    let pattern: DetectedPattern
    let headline: String
    let body: String
    let cosmicAlignment: CosmicAlignment
    let retrogradeWarning: String?
    let moonPhaseNote: String?
    let compatibilityNote: String?
    let actionAdvice: String

    /// Overall cosmic score combining pattern confidence and alignment
    var cosmicScore: Double {
        let patternWeight = pattern.confidence * 0.6
        let alignmentWeight = Double(cosmicAlignment.score) * 0.4
        return patternWeight + alignmentWeight
    }

    var formattedCosmicScore: String {
        String(format: "%.0f", cosmicScore)
    }

    /// Whether this is a premium-only insight
    var isPremium: Bool {
        pattern.isPremiumPattern
    }
}

// MARK: - Cosmic Pattern Interpreter

@MainActor
class CosmicPatternInterpreter {

    // MARK: - Dependencies

    private let retrogradeService = MercuryRetrogradeService.shared
    private let moonService = MoonPhaseService.shared

    // MARK: - Singleton

    static let shared = CosmicPatternInterpreter()

    private init() {}

    // MARK: - Interpret Pattern

    /// Interpret a detected pattern with cosmic context
    func interpret(
        pattern: DetectedPattern,
        userSign: ZodiacSign,
        stockSign: ZodiacSign
    ) -> CosmicPatternInsight {

        let isRetrograde = isInRetrograde()
        let moonPhase = moonService.getCurrentLunarData().phase
        let compatibility = userSign.compatibilityScore(with: stockSign)

        // Generate components
        let headline = generateHeadline(for: pattern.pattern)
        let body = generateBody(for: pattern, moonPhase: moonPhase, compatibility: compatibility)
        let retrogradeWarning = isRetrograde ? generateRetrogradeWarning(for: pattern.pattern) : nil
        let moonNote = generateMoonPhaseNote(moonPhase: moonPhase, pattern: pattern.pattern)
        let compatNote = generateCompatibilityNote(userSign: userSign, stockSign: stockSign, score: compatibility)
        let advice = generateActionAdvice(pattern: pattern, isRetrograde: isRetrograde, moonPhase: moonPhase)

        // Calculate cosmic alignment
        let alignment = calculateAlignment(
            pattern: pattern,
            retrograde: isRetrograde,
            moon: moonPhase,
            compatibility: compatibility
        )

        return CosmicPatternInsight(
            pattern: pattern,
            headline: headline,
            body: body,
            cosmicAlignment: alignment,
            retrogradeWarning: retrogradeWarning,
            moonPhaseNote: moonNote,
            compatibilityNote: compatNote,
            actionAdvice: advice
        )
    }

    /// Interpret multiple patterns
    func interpretAll(
        patterns: [DetectedPattern],
        userSign: ZodiacSign,
        stockSign: ZodiacSign
    ) -> [CosmicPatternInsight] {
        patterns.map { interpret(pattern: $0, userSign: userSign, stockSign: stockSign) }
    }

    // MARK: - Headline Generation

    private func generateHeadline(for pattern: ChartPattern) -> String {
        switch pattern {
        case .doji:
            return "Doji Forming — Indecision in the Stars"
        case .hammer:
            return "Hammer Pattern — Potential Reversal Ahead"
        case .shootingStar:
            return "Shooting Star — Caution at the Peak"
        case .engulfingBullish:
            return "Bullish Engulfing — Bulls Taking Control"
        case .engulfingBearish:
            return "Bearish Engulfing — Bears Taking Over"
        case .morningstar:
            return "Morning Star — Dawn of a Rally"
        case .eveningstar:
            return "Evening Star — Twilight Warning"
        case .goldenCross:
            return "GOLDEN CROSS — Major Bullish Signal"
        case .deathCross:
            return "DEATH CROSS — Major Bearish Signal"
        case .breakoutUp:
            return "Bullish Breakout — Resistance Shattered"
        case .breakoutDown:
            return "Bearish Breakdown — Support Lost"
        case .supportTest:
            return "Testing Support — Key Decision Point"
        case .resistanceTest:
            return "Testing Resistance — Bulls vs Ceiling"
        case .overbought:
            return "Overbought Territory — Cool Down Expected"
        case .oversold:
            return "Oversold Territory — Bounce Potential"
        }
    }

    // MARK: - Body Generation

    private func generateBody(for pattern: DetectedPattern, moonPhase: MoonPhase, compatibility: Int) -> String {
        let patternBody = baseBody(for: pattern.pattern)
        let details = pattern.details ?? ""

        return """
        \(patternBody)

        \(details.isEmpty ? "" : "Technical Detail: \(details)")
        """
    }

    private func baseBody(for pattern: ChartPattern) -> String {
        switch pattern {
        case .goldenCross:
            return "The 50-day moving average has crossed above the 200-day. Historically, this signals sustained upward momentum. Long-term holders take note — the cosmos favor patience here."

        case .deathCross:
            return "The 50-day moving average has crossed below the 200-day. This often precedes extended downward pressure. Defensive positioning and stop-losses become crucial."

        case .doji:
            return "Neither bulls nor bears could claim victory. A doji signals equilibrium — the next move could go either way. Wait for confirmation before committing."

        case .hammer:
            return "After testing lower prices, buyers stepped in forcefully. This classic reversal signal suggests the downtrend may be exhausting itself. The market found support."

        case .shootingStar:
            return "Prices spiked but couldn't hold their gains. Sellers overwhelmed buyers at higher levels. Upward momentum may be fading — consider protecting gains."

        case .engulfingBullish:
            return "A powerful green candle has completely engulfed the prior day's losses. Bulls have seized control. This pattern often marks the start of upward momentum."

        case .engulfingBearish:
            return "A decisive red candle has swallowed the prior day's gains. Bears have taken charge. Caution is warranted as selling pressure may continue."

        case .morningstar:
            return "A three-candle reversal pattern has formed at the bottom. The morning star heralds a potential dawn for this stock. Watch for follow-through buying."

        case .eveningstar:
            return "A three-candle reversal pattern has formed at the top. The evening star warns of potential decline. Consider taking profits or tightening stops."

        case .overbought:
            return "RSI has pushed above 70, indicating potentially unsustainable buying pressure. Profit-taking often follows these extremes. The rubber band is stretched."

        case .oversold:
            return "RSI has fallen below 30, indicating potentially excessive selling. Value hunters often emerge at these levels. Reversal potential exists."

        case .breakoutUp:
            return "Price has broken through a significant resistance level. Breakouts can lead to rapid upward moves as traders chase the new trend."

        case .breakoutDown:
            return "Price has broken below key support. Breakdowns can accelerate as stop-losses trigger and sellers gain control."

        case .supportTest:
            return "Price is testing a key support level. How it reacts here will determine the next move. Watch for buying interest at this level."

        case .resistanceTest:
            return "Price is testing overhead resistance. A breakthrough could ignite a rally, but rejection could lead to pullback."
        }
    }

    // MARK: - Retrograde Warning

    private func isInRetrograde() -> Bool {
        switch retrogradeService.status {
        case .active, .stormBeginning, .stormEnding:
            return true
        default:
            return false
        }
    }

    private func generateRetrogradeWarning(for pattern: ChartPattern) -> String {
        let baseWarning = "Mercury Retrograde Active"

        switch pattern.sentiment {
        case .bullish:
            return "\(baseWarning): Exercise extra caution with new positions. Bullish signals may give false hope during retrograde. Consider waiting for retrograde to end."

        case .bearish:
            return "\(baseWarning): Bearish patterns can be amplified during retrograde. Avoid panic selling — communication breakdowns create temporary chaos."

        case .neutral:
            return "\(baseWarning): Indecision patterns during retrograde often resolve unexpectedly. Patience is your ally. Double-check all information."
        }
    }

    // MARK: - Moon Phase Note

    private func generateMoonPhaseNote(moonPhase: MoonPhase, pattern: ChartPattern) -> String {
        let isWaxing = moonPhase.isWaxing

        switch moonPhase {
        case .fullMoon:
            return "\(moonPhase.emoji) Full Moon Energy: Emotions and volatility run high. The pattern's signal may manifest more dramatically than usual. Trade with heightened awareness."

        case .newMoon:
            return "\(moonPhase.emoji) New Moon Energy: A time for new beginnings. If the pattern suggests reversal, this lunar phase supports that transition. Plant seeds now."

        case .waxingCrescent, .waxingGibbous, .firstQuarter:
            if pattern.sentiment == .bullish {
                return "\(moonPhase.emoji) Waxing Moon: Building energy favors bullish patterns. Growth signals have cosmic tailwind."
            } else {
                return "\(moonPhase.emoji) Waxing Moon: Growing lunar energy may dampen bearish signals. Bulls have natural support."
            }

        case .waningCrescent, .waningGibbous, .lastQuarter:
            if pattern.sentiment == .bearish {
                return "\(moonPhase.emoji) Waning Moon: Diminishing energy aligns with bearish signals. A time to release and take profits."
            } else {
                return "\(moonPhase.emoji) Waning Moon: Reduced lunar energy may slow bullish momentum. Patience required."
            }
        }
    }

    // MARK: - Compatibility Note

    private func generateCompatibilityNote(userSign: ZodiacSign, stockSign: ZodiacSign, score: Int) -> String {
        let rating = CompatibilityRating.from(score: score)

        switch rating {
        case .cosmicSoulmates:
            return "Your \(userSign.displayName) energy is cosmically aligned with this \(stockSign.displayName) stock. Trust your intuition here."

        case .highCompatibility:
            return "\(userSign.displayName) and \(stockSign.displayName) share harmonious energy. The stars favor your judgment on this one."

        case .neutral:
            return "Neutral cosmic alignment between \(userSign.displayName) and \(stockSign.displayName). Let the technical signal guide you."

        case .challenging:
            return "\(userSign.displayName) faces growth lessons with \(stockSign.displayName) stocks. Extra due diligence recommended."

        case .cosmicClash:
            return "Challenging cosmic tension between your \(userSign.displayName) and this \(stockSign.displayName) stock. Proceed with elevated caution."
        }
    }

    // MARK: - Action Advice

    private func generateActionAdvice(pattern: DetectedPattern, isRetrograde: Bool, moonPhase: MoonPhase) -> String {
        var advice = ""

        // Base advice from pattern
        switch pattern.pattern.sentiment {
        case .bullish:
            advice = "Consider building a position if other indicators confirm."
        case .bearish:
            advice = "Consider reducing exposure or tightening stop-losses."
        case .neutral:
            advice = "Wait for confirmation before taking action."
        }

        // Modify for retrograde
        if isRetrograde {
            advice += " However, during Mercury Retrograde, consider delaying major decisions."
        }

        // Modify for moon phase
        if moonPhase == .fullMoon {
            advice += " Full moon volatility suggests using smaller position sizes."
        }

        return advice
    }

    // MARK: - Alignment Calculation

    private func calculateAlignment(
        pattern: DetectedPattern,
        retrograde: Bool,
        moon: MoonPhase,
        compatibility: Int
    ) -> CosmicAlignment {

        var score = 50.0  // Base neutral

        // Pattern confidence (0-100) contributes up to 30 points
        score += (pattern.confidence - 50) * 0.3

        // Retrograde penalty for bullish signals, slight bonus for caution
        if retrograde {
            if pattern.pattern.sentiment == .bullish {
                score -= 15
            } else if pattern.pattern.sentiment == .bearish {
                score -= 5  // Bearish is more appropriate during retrograde
            }
        }

        // Moon phase alignment
        let moonAligned = (moon.isWaxing && pattern.pattern.sentiment == .bullish) ||
                         (!moon.isWaxing && pattern.pattern.sentiment == .bearish)
        if moonAligned {
            score += 10
        } else {
            score -= 5
        }

        // Compatibility factor (0-100) contributes up to 20 points
        score += (Double(compatibility) - 50) * 0.2

        // Clamp to valid range
        score = min(100, max(0, score))

        return CosmicAlignment.from(score: score)
    }

    // MARK: - Get Insights for Stock

    /// Get all cosmic pattern insights for a stock
    func getInsights(
        for stock: Stock,
        userSign: ZodiacSign
    ) -> [CosmicPatternInsight] {
        let patternService = ChartPatternService.shared
        let ohlcData = patternService.getOHLCData(for: stock)
        let patterns = patternService.detectPatterns(ohlc: ohlcData)

        return interpretAll(
            patterns: patterns,
            userSign: userSign,
            stockSign: stock.zodiacSign
        )
    }
}

// MARK: - Extension for Moon Phase

extension MoonPhase {
    /// Whether this is a waning (decreasing) phase
    var isWaning: Bool {
        !isWaxing
    }
}
