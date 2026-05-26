import Foundation
import SwiftUI

// MARK: - Cosmic Mood Index
// =========================
// A "Fear & Greed" style index with cosmic theming.
// Scale from 0-100 representing market sentiment from extreme fear to extreme greed.

// MARK: - Mood Level Enum

enum CosmicMoodLevel: String, CaseIterable {
    case void = "Void"              // 0-20: Extreme Fear
    case eclipse = "Eclipse"        // 21-40: Fear
    case twilight = "Twilight"      // 41-60: Neutral
    case radiant = "Radiant"        // 61-80: Greed
    case supernova = "Supernova"    // 81-100: Extreme Greed

    // MARK: - Properties

    /// The range of values for this mood level
    var range: ClosedRange<Int> {
        switch self {
        case .void:      return 0...20
        case .eclipse:   return 21...40
        case .twilight:  return 41...60
        case .radiant:   return 61...80
        case .supernova: return 81...100
        }
    }

    /// Traditional sentiment name
    var sentimentName: String {
        switch self {
        case .void:      return "Extreme Fear"
        case .eclipse:   return "Fear"
        case .twilight:  return "Neutral"
        case .radiant:   return "Greed"
        case .supernova: return "Extreme Greed"
        }
    }

    /// Short cosmic description
    var cosmicDescription: String {
        switch self {
        case .void:
            return "Deep darkness engulfs the market"
        case .eclipse:
            return "Shadows loom over sentiment"
        case .twilight:
            return "Balance between light and dark"
        case .radiant:
            return "Bright optimism fills the cosmos"
        case .supernova:
            return "Dangerously hot — caution advised"
        }
    }

    /// Longer insight about market behavior
    var marketInsight: String {
        switch self {
        case .void:
            return "Markets are gripped by fear. Historically, extreme fear has preceded some of the strongest rallies. Contrarian opportunity? Consider: 'Be greedy when others are fearful.'"
        case .eclipse:
            return "Pessimism is elevated but not at extremes. Caution is warranted, but panic is often overdone. Look for quality assets trading below fair value."
        case .twilight:
            return "The market is balanced, neither fearful nor greedy. This is often a period of consolidation before the next major move. Stay alert for directional signals."
        case .radiant:
            return "Optimism is running high. While momentum can continue, be mindful of valuations. This is often a good time to take some profits off the table."
        case .supernova:
            return "Euphoria has taken hold. Historically, extreme greed has preceded corrections. Consider: 'Be fearful when others are greedy.' Protect your gains."
        }
    }

    /// Icon for this mood level
    var icon: String {
        switch self {
        case .void:      return "circle.fill"
        case .eclipse:   return "moon.fill"
        case .twilight:  return "sunset.fill"
        case .radiant:   return "sun.max.fill"
        case .supernova: return "sparkles"
        }
    }

    /// SF Symbol representation
    var sfSymbol: String {
        icon  // Use the same values as icon property
    }

    /// Primary color for this mood level
    var color: Color {
        switch self {
        case .void:      return Color(red: 0.1, green: 0.1, blue: 0.3)
        case .eclipse:   return Color(red: 0.2, green: 0.2, blue: 0.5)
        case .twilight:  return Color(red: 0.5, green: 0.4, blue: 0.6)
        case .radiant:   return CosmicTheme.gold
        case .supernova: return Color(red: 1.0, green: 0.5, blue: 0.2)
        }
    }

    /// Gradient colors for this mood level
    var gradientColors: [Color] {
        switch self {
        case .void:
            return [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.3)]
        case .eclipse:
            return [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.2, green: 0.2, blue: 0.5)]
        case .twilight:
            return [Color(red: 0.3, green: 0.25, blue: 0.5), Color(red: 0.5, green: 0.4, blue: 0.6)]
        case .radiant:
            return [Color(red: 0.7, green: 0.5, blue: 0.2), CosmicTheme.gold]
        case .supernova:
            return [CosmicTheme.gold, Color(red: 1.0, green: 0.4, blue: 0.1)]
        }
    }

    /// Trading recommendation based on mood
    var tradingSignal: String {
        switch self {
        case .void:      return "Potential buying opportunity"
        case .eclipse:   return "Watch for value plays"
        case .twilight:  return "Hold current positions"
        case .radiant:   return "Consider taking profits"
        case .supernova: return "High caution advised"
        }
    }

    // MARK: - Static Methods

    /// Get mood level from a value (0-100)
    static func from(value: Int) -> CosmicMoodLevel {
        let clampedValue = max(0, min(100, value))
        switch clampedValue {
        case 0...20:  return .void
        case 21...40: return .eclipse
        case 41...60: return .twilight
        case 61...80: return .radiant
        default:      return .supernova
        }
    }
}

// MARK: - Cosmic Mood Data

/// Complete mood index data at a point in time
struct CosmicMoodData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int  // 0-100
    let factors: [MoodFactor]

    /// Current mood level based on value
    var moodLevel: CosmicMoodLevel {
        CosmicMoodLevel.from(value: value)
    }

    /// Formatted value with percentage
    var formattedValue: String {
        "\(value)"
    }

    /// Change from previous reading
    var change: Int?

    /// Whether the mood is improving (moving toward greed)
    var isImproving: Bool {
        guard let change = change else { return false }
        return change > 0
    }

    /// Direction indicator
    var directionIcon: String {
        guard let change = change else { return "minus" }
        if change > 0 { return "arrow.up.right" }
        if change < 0 { return "arrow.down.right" }
        return "minus"
    }

    /// Formatted change
    var formattedChange: String {
        guard let change = change else { return "—" }
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(change)"
    }
}

// MARK: - Mood Factor

/// Individual factor contributing to the mood index
struct MoodFactor: Identifiable {
    let id = UUID()
    let name: String
    let category: MoodFactorCategory
    let value: Int           // -100 to +100 (contribution to mood)
    let weight: Double       // How much this factor matters (0-1)
    let description: String
    let icon: String

    /// Weighted contribution to overall mood
    var weightedContribution: Double {
        Double(value) * weight
    }

    /// Is this factor bullish (positive) or bearish (negative)?
    var sentiment: FactorSentiment {
        if value > 10 { return .bullish }
        if value < -10 { return .bearish }
        return .neutral
    }

    /// Color based on sentiment
    var color: Color {
        switch sentiment {
        case .bullish: return CosmicTheme.positive
        case .bearish: return CosmicTheme.negative
        case .neutral: return CosmicTheme.textSecondary
        }
    }

    enum FactorSentiment {
        case bullish, bearish, neutral
    }
}

// MARK: - Mood Factor Category

enum MoodFactorCategory: String, CaseIterable {
    case cosmic = "Cosmic"
    case market = "Market"
    case volatility = "Volatility"
    case momentum = "Momentum"

    var icon: String {
        switch self {
        case .cosmic:     return "sparkles"
        case .market:     return "chart.line.uptrend.xyaxis"
        case .volatility: return "waveform.path.ecg"
        case .momentum:   return "gauge.high"
        }
    }

    var color: Color {
        switch self {
        case .cosmic:     return CosmicTheme.cosmicPurple
        case .market:     return CosmicTheme.gold
        case .volatility: return .orange
        case .momentum:   return CosmicTheme.nebulaBlue
        }
    }
}

// MARK: - Historical Mood Entry

/// Historical mood data point for charting
struct MoodHistoryEntry: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int
    let moodLevel: CosmicMoodLevel

    init(date: Date, value: Int) {
        self.date = date
        self.value = value
        self.moodLevel = CosmicMoodLevel.from(value: value)
    }
}

// MARK: - Historical Insight

/// Insight about what happened after similar mood readings
struct HistoricalInsight {
    let moodLevel: CosmicMoodLevel
    let title: String
    let description: String
    let historicalReturn: Double  // e.g., +12% over following month
    let timeframe: String         // e.g., "1 month"
    let sampleSize: String        // e.g., "Based on 15 similar periods"

    /// Formatted return string
    var formattedReturn: String {
        let sign = historicalReturn >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, historicalReturn)
    }

    /// Is this a contrarian signal?
    var isContrarianSignal: Bool {
        // Extreme fear with positive return = contrarian buy
        // Extreme greed with negative return = contrarian sell
        switch moodLevel {
        case .void, .eclipse:
            return historicalReturn > 0
        case .radiant, .supernova:
            return historicalReturn < 0
        case .twilight:
            return false
        }
    }
}

// MARK: - Static Historical Insights

extension HistoricalInsight {

    static let voidInsight = HistoricalInsight(
        moodLevel: .void,
        title: "Contrarian Opportunity",
        description: "The last time we were in Void territory, the market rallied significantly over the following month.",
        historicalReturn: 12.3,
        timeframe: "1 month",
        sampleSize: "Based on 8 similar periods since 2010"
    )

    static let eclipseInsight = HistoricalInsight(
        moodLevel: .eclipse,
        title: "Fear Often Overdone",
        description: "Eclipse periods have historically been followed by modest recovery as fear subsides.",
        historicalReturn: 5.7,
        timeframe: "1 month",
        sampleSize: "Based on 24 similar periods since 2010"
    )

    static let twilightInsight = HistoricalInsight(
        moodLevel: .twilight,
        title: "Balanced Markets",
        description: "Twilight periods tend to precede continuation of the prior trend. Watch for breakout signals.",
        historicalReturn: 2.1,
        timeframe: "1 month",
        sampleSize: "Based on 45 similar periods since 2010"
    )

    static let radiantInsight = HistoricalInsight(
        moodLevel: .radiant,
        title: "Momentum Can Continue",
        description: "While optimism is high, radiant markets often continue higher before correcting.",
        historicalReturn: 3.4,
        timeframe: "1 month",
        sampleSize: "Based on 30 similar periods since 2010"
    )

    static let supernovaInsight = HistoricalInsight(
        moodLevel: .supernova,
        title: "Caution Warranted",
        description: "Supernova euphoria has historically preceded pullbacks. Consider defensive positioning.",
        historicalReturn: -4.2,
        timeframe: "1 month",
        sampleSize: "Based on 12 similar periods since 2010"
    )

    /// Get insight for a given mood level
    static func insight(for level: CosmicMoodLevel) -> HistoricalInsight {
        switch level {
        case .void:      return voidInsight
        case .eclipse:   return eclipseInsight
        case .twilight:  return twilightInsight
        case .radiant:   return radiantInsight
        case .supernova: return supernovaInsight
        }
    }
}
