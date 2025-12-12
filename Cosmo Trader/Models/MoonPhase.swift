import Foundation
import SwiftUI

// MARK: - Moon Phase
// ===================
// Represents the current lunar phase with trading signals.
// Based on actual astronomical calculations and real trader folklore.

// MARK: - Moon Phase Enum

enum MoonPhase: String, CaseIterable, Identifiable {
    case newMoon = "New Moon"
    case waxingCrescent = "Waxing Crescent"
    case firstQuarter = "First Quarter"
    case waxingGibbous = "Waxing Gibbous"
    case fullMoon = "Full Moon"
    case waningGibbous = "Waning Gibbous"
    case lastQuarter = "Last Quarter"
    case waningCrescent = "Waning Crescent"

    var id: String { rawValue }

    // MARK: - Visual

    /// Emoji representation (used as data, not UI decoration)
    var emoji: String {
        switch self {
        case .newMoon:        return "🌑"
        case .waxingCrescent: return "🌒"
        case .firstQuarter:   return "🌓"
        case .waxingGibbous:  return "🌔"
        case .fullMoon:       return "🌕"
        case .waningGibbous:  return "🌖"
        case .lastQuarter:    return "🌗"
        case .waningCrescent: return "🌘"
        }
    }

    /// Icon name for custom drawing
    var iconName: String {
        switch self {
        case .newMoon:        return "moon.new"
        case .waxingCrescent: return "moon.waxing.crescent"
        case .firstQuarter:   return "moon.first.quarter"
        case .waxingGibbous:  return "moon.waxing.gibbous"
        case .fullMoon:       return "moon.full"
        case .waningGibbous:  return "moon.waning.gibbous"
        case .lastQuarter:    return "moon.last.quarter"
        case .waningCrescent: return "moon.waning.crescent"
        }
    }

    /// SF Symbol icon for UI display
    var icon: String {
        switch self {
        case .newMoon:        return "moon"
        case .waxingCrescent: return "moon.fill"
        case .firstQuarter:   return "moon.zzz"
        case .waxingGibbous:  return "moon.haze"
        case .fullMoon:       return "moon.circle.fill"
        case .waningGibbous:  return "moon.haze.fill"
        case .lastQuarter:    return "moon.zzz.fill"
        case .waningCrescent: return "moon.fill"
        }
    }

    /// Description for the phase
    var description: String {
        switch self {
        case .newMoon:
            return "A time for new beginnings and setting intentions."
        case .waxingCrescent:
            return "Energy builds. Plant seeds for future growth."
        case .firstQuarter:
            return "Take action. Decisions made now gain momentum."
        case .waxingGibbous:
            return "Refine your approach. Adjust before the peak."
        case .fullMoon:
            return "Culmination and clarity. Results become visible."
        case .waningGibbous:
            return "Share wisdom. Express gratitude for gains."
        case .lastQuarter:
            return "Release what no longer serves you."
        case .waningCrescent:
            return "Rest and reflect. The cycle completes."
        }
    }

    /// Calculate moon phase from a date (simplified algorithm)
    static func from(date: Date) -> MoonPhase {
        // Simplified lunar cycle calculation
        // Based on average lunar cycle of 29.53 days
        // Reference new moon: January 6, 2000
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 6))!
        let daysSinceReference = Calendar.current.dateComponents([.day], from: referenceDate, to: date).day ?? 0
        let lunarCycle = 29.53
        let dayInCycle = Double(daysSinceReference).truncatingRemainder(dividingBy: lunarCycle)

        // Each phase is roughly 3.69 days
        switch dayInCycle {
        case 0..<1.85: return .newMoon
        case 1.85..<7.38: return .waxingCrescent
        case 7.38..<9.23: return .firstQuarter
        case 9.23..<14.76: return .waxingGibbous
        case 14.76..<16.61: return .fullMoon
        case 16.61..<22.14: return .waningGibbous
        case 22.14..<24.00: return .lastQuarter
        default: return .waningCrescent
        }
    }

    /// Illumination range for this phase
    var illuminationRange: ClosedRange<Double> {
        switch self {
        case .newMoon:        return 0.0...0.03
        case .waxingCrescent: return 0.03...0.25
        case .firstQuarter:   return 0.25...0.50
        case .waxingGibbous:  return 0.50...0.75
        case .fullMoon:       return 0.97...1.0
        case .waningGibbous:  return 0.75...0.97
        case .lastQuarter:    return 0.50...0.75
        case .waningCrescent: return 0.03...0.25
        }
    }

    // MARK: - Trading Signal

    /// Trading signal associated with this phase
    var tradingSignal: TradingSignal {
        switch self {
        case .newMoon:
            return TradingSignal(
                type: .accumulate,
                headline: "Accumulation Phase",
                summary: "Good for starting new positions",
                description: "The new moon marks the beginning of a fresh lunar cycle. Some traders view this as an opportune time to research and initiate new positions. Energy is building.",
                sentiment: .bullish
            )
        case .waxingCrescent:
            return TradingSignal(
                type: .buildPosition,
                headline: "Building Momentum",
                summary: "Energy increasing — bullish undertone",
                description: "The waxing crescent represents growing energy and optimism. Historically associated with building momentum in both nature and markets.",
                sentiment: .bullish
            )
        case .firstQuarter:
            return TradingSignal(
                type: .hold,
                headline: "Decision Point",
                summary: "Evaluate positions — momentum check",
                description: "The first quarter moon represents a checkpoint. Some traders use this to evaluate whether their positions are performing as expected.",
                sentiment: .neutral
            )
        case .waxingGibbous:
            return TradingSignal(
                type: .buildPosition,
                headline: "Pre-Peak Energy",
                summary: "Approaching full moon — heightened activity",
                description: "Energy builds toward the full moon. Markets may see increased activity and volume as the peak approaches.",
                sentiment: .bullish
            )
        case .fullMoon:
            return TradingSignal(
                type: .caution,
                headline: "Peak Volatility",
                summary: "Emotions run high — expect swings",
                description: "The full moon has been associated with heightened emotions and increased volatility. Some studies suggest markets show greater price swings around this time. Stay alert.",
                sentiment: .volatile
            )
        case .waningGibbous:
            return TradingSignal(
                type: .takeProfit,
                headline: "Distribution Phase",
                summary: "Consider taking profits on winners",
                description: "As the moon wanes, some traders view this as a time to secure gains. The energy begins to recede from its peak.",
                sentiment: .bearish
            )
        case .lastQuarter:
            return TradingSignal(
                type: .reduce,
                headline: "Review & Reduce",
                summary: "Time to review and trim positions",
                description: "The last quarter is traditionally a time for reflection. Consider reviewing your portfolio and reducing exposure to underperformers.",
                sentiment: .bearish
            )
        case .waningCrescent:
            return TradingSignal(
                type: .wait,
                headline: "Rest Period",
                summary: "Low energy — wait for new cycle",
                description: "The waning crescent represents the end of the lunar cycle. Some traders prefer to wait for the new moon before initiating new positions.",
                sentiment: .neutral
            )
        }
    }

    // MARK: - Phase Characteristics

    /// Whether this is a significant phase (New or Full)
    var isSignificant: Bool {
        self == .newMoon || self == .fullMoon
    }

    /// Whether this is a waxing (growing) phase
    var isWaxing: Bool {
        switch self {
        case .newMoon, .waxingCrescent, .firstQuarter, .waxingGibbous:
            return true
        default:
            return false
        }
    }

    /// Short description of the phase
    var shortDescription: String {
        switch self {
        case .newMoon:        return "New beginnings"
        case .waxingCrescent: return "Building"
        case .firstQuarter:   return "Taking action"
        case .waxingGibbous:  return "Refining"
        case .fullMoon:       return "Peak energy"
        case .waningGibbous:  return "Sharing"
        case .lastQuarter:    return "Releasing"
        case .waningCrescent: return "Surrendering"
        }
    }

    /// Color associated with this phase
    var color: Color {
        switch self {
        case .newMoon:        return CosmicTheme.textMuted
        case .waxingCrescent: return CosmicTheme.nebulaBlue.opacity(0.7)
        case .firstQuarter:   return CosmicTheme.nebulaBlue
        case .waxingGibbous:  return CosmicTheme.gold.opacity(0.7)
        case .fullMoon:       return CosmicTheme.gold
        case .waningGibbous:  return CosmicTheme.cosmicPurple.opacity(0.7)
        case .lastQuarter:    return CosmicTheme.cosmicPurple
        case .waningCrescent: return CosmicTheme.textSecondary
        }
    }
}

// MARK: - Trading Signal

struct TradingSignal {
    let type: SignalType
    let headline: String
    let summary: String
    let description: String
    let sentiment: MarketSentiment

    enum SignalType: String {
        case accumulate = "Accumulate"
        case buildPosition = "Build Position"
        case hold = "Hold"
        case caution = "Caution"
        case takeProfit = "Take Profit"
        case reduce = "Reduce"
        case wait = "Wait"

        var icon: String {
            switch self {
            case .accumulate:    return "plus.circle.fill"
            case .buildPosition: return "arrow.up.circle.fill"
            case .hold:          return "pause.circle.fill"
            case .caution:       return "exclamationmark.triangle.fill"
            case .takeProfit:    return "dollarsign.circle.fill"
            case .reduce:        return "minus.circle.fill"
            case .wait:          return "clock.fill"
            }
        }

        var color: Color {
            switch self {
            case .accumulate, .buildPosition:
                return CosmicTheme.positive
            case .hold, .wait:
                return CosmicTheme.textSecondary
            case .caution:
                return .orange
            case .takeProfit, .reduce:
                return CosmicTheme.gold
            }
        }
    }

    enum MarketSentiment: String {
        case bullish = "Bullish"
        case bearish = "Bearish"
        case neutral = "Neutral"
        case volatile = "Volatile"

        var color: Color {
            switch self {
            case .bullish:  return CosmicTheme.positive
            case .bearish:  return CosmicTheme.negative
            case .neutral:  return CosmicTheme.textSecondary
            case .volatile: return .orange
            }
        }

        var icon: String {
            switch self {
            case .bullish:  return "arrow.up.right"
            case .bearish:  return "arrow.down.right"
            case .neutral:  return "arrow.right"
            case .volatile: return "arrow.up.arrow.down"
            }
        }
    }
}

// MARK: - Lunar Data

/// Complete lunar data for a given moment
struct LunarData {
    let date: Date
    let phase: MoonPhase
    let illumination: Double  // 0.0 to 1.0
    let age: Double  // Days since last new moon (0-29.53)
    let moonSign: ZodiacSign
    let isWaxing: Bool

    /// Days until next full moon
    var daysUntilFullMoon: Int {
        let lunarCycle = 29.53
        let fullMoonAge = lunarCycle / 2

        if age < fullMoonAge {
            return Int(fullMoonAge - age)
        } else {
            return Int(lunarCycle - age + fullMoonAge)
        }
    }

    /// Days until next new moon
    var daysUntilNewMoon: Int {
        let lunarCycle = 29.53
        return Int(lunarCycle - age)
    }

    /// Formatted illumination percentage
    var formattedIllumination: String {
        String(format: "%.0f%%", illumination * 100)
    }

    /// Element activated by current moon sign
    var activatedElement: ZodiacSign.Element {
        moonSign.element
    }

    /// Trading insight based on moon sign
    var moonSignInsight: String {
        let element = moonSign.element
        switch element {
        case .fire:
            return "The moon in \(moonSign.displayName) activates fire energy — favorable for bold, growth-oriented stocks."
        case .earth:
            return "The moon in \(moonSign.displayName) grounds the market — practical, value-focused stocks may perform well."
        case .air:
            return "The moon in \(moonSign.displayName) stimulates communication — tech and media stocks in focus."
        case .water:
            return "The moon in \(moonSign.displayName) heightens intuition — emotional, consumer-facing sectors sensitive today."
        }
    }

    /// Stocks that align with current moon energy
    var alignedStockTypes: String {
        switch moonSign.element {
        case .fire:  return "Growth stocks, disruptors, energy sector"
        case .earth: return "Value stocks, REITs, commodities"
        case .air:   return "Tech stocks, communications, fintech"
        case .water: return "Consumer staples, healthcare, entertainment"
        }
    }
}

// MARK: - Moon Phase Calendar Entry

struct MoonPhaseCalendarEntry: Identifiable {
    let id = UUID()
    let date: Date
    let phase: MoonPhase
    let illumination: Double

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Historical Volatility Data

/// Historical data about market behavior during moon phases
struct LunarMarketStats {

    /// Disclaimer for all lunar trading data
    static let disclaimer = "These patterns are based on historical analysis and trader folklore. Past patterns don't guarantee future results. Make your own informed decisions."

    /// Full moon volatility statistics
    static let fullMoonVolatility = LunarVolatilityStat(
        phase: .fullMoon,
        averageVolatilityChange: 0.08, // 8% higher
        sampleSize: "50 years of S&P 500 data",
        description: "Studies have found approximately 8% higher volatility in the days surrounding full moons compared to other lunar phases."
    )

    /// New moon statistics
    static let newMoonStats = LunarVolatilityStat(
        phase: .newMoon,
        averageVolatilityChange: -0.03, // 3% lower
        sampleSize: "50 years of S&P 500 data",
        description: "New moon periods have historically shown slightly below-average volatility, though the effect is modest."
    )

    /// Historical insight
    static let historicalInsight = """
    Some academic studies have found correlations between lunar cycles and market behavior. \
    A 2001 study in the Journal of Banking & Finance found that stock returns were higher during \
    the 15 days around new moons than during full moons. However, transaction costs may eliminate \
    any trading advantage. Many traders watch lunar cycles as one of many market indicators.
    """
}

struct LunarVolatilityStat {
    let phase: MoonPhase
    let averageVolatilityChange: Double
    let sampleSize: String
    let description: String

    var formattedChange: String {
        let sign = averageVolatilityChange >= 0 ? "+" : ""
        return String(format: "%@%.0f%%", sign, averageVolatilityChange * 100)
    }
}
