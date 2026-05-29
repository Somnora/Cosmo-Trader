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
            return "Sentiment is deeply risk-off. Historical return context is unavailable until provider-backed market history is connected. Entertainment lens, not a prediction."
        case .eclipse:
            return "Pessimism is elevated. Use this as a market-mood snapshot, not a buy or sell signal."
        case .twilight:
            return "The market mood is balanced. Pattern notes will appear when enough provider-backed market history is available."
        case .radiant:
            return "Optimism is elevated. Treat this as sentiment context, not an instruction to change positions."
        case .supernova:
            return "Sentiment is extremely hot. Historical return context is unavailable; this is an entertainment framing layer, not financial advice."
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

    /// Legacy display label for mood context. This is not trading advice.
    var tradingSignal: String {
        switch self {
        case .void:      return "Risk-off mood"
        case .eclipse:   return "Pessimism elevated"
        case .twilight:  return "Neutral mood"
        case .radiant:   return "Optimism elevated"
        case .supernova: return "Hot sentiment"
        }
    }

    // MARK: - Static Methods

    /// Get mood level from a value (0-100)
    nonisolated static func from(value: Int) -> CosmicMoodLevel {
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

enum CosmicMoodDisplayMode: Equatable {
    case marketBackedScore
    case cosmicContextOnly
    case unavailable
}

/// Complete mood index data at a point in time
struct CosmicMoodData: Identifiable {
    let id = UUID()
    let date: Date
    /// Provider-backed market sentiment score. Nil means no market score should be shown.
    let value: Int?
    let factors: [MoodFactor]
    let label: String
    let provenance: FinancialDataProvenance
    let marketDataCoverage: Double
    let unavailableFactorWeight: Double
    let displayMode: CosmicMoodDisplayMode
    var change: Int?

    init(
        date: Date,
        value: Int?,
        factors: [MoodFactor],
        change: Int? = nil,
        label: String? = nil,
        provenance: FinancialDataProvenance? = nil,
        marketDataCoverage: Double = 0,
        unavailableFactorWeight: Double = 0,
        displayMode: CosmicMoodDisplayMode? = nil
    ) {
        self.date = date
        self.value = value
        self.factors = factors
        self.change = change
        self.marketDataCoverage = marketDataCoverage
        self.unavailableFactorWeight = unavailableFactorWeight

        if let value {
            let level = CosmicMoodLevel.from(value: value)
            self.label = label ?? level.sentimentName
            self.displayMode = displayMode ?? .marketBackedScore
            self.provenance = provenance ?? .sample(reason: "Preview mood score")
        } else {
            self.label = label ?? "Market data unavailable"
            self.displayMode = displayMode ?? .unavailable
            self.provenance = provenance ?? .unavailable(reason: "Provider-backed market factors unavailable")
        }
    }

    /// Current mood level based on value
    var moodLevel: CosmicMoodLevel? {
        value.map(CosmicMoodLevel.from)
    }

    var isMarketBacked: Bool {
        guard displayMode == .marketBackedScore, value != nil else { return false }
        if provenance.isProviderBacked { return true }
        if case .mixed = provenance { return true }
        return false
    }

    /// Formatted value with percentage
    var formattedValue: String {
        value.map { String($0) } ?? "N/A"
    }

    var marketToneText: String {
        switch displayMode {
        case .marketBackedScore:
            if let moodLevel, let value {
                return "\(moodLevel.sentimentName) \(value)/100"
            }
            return "Market data unavailable"
        case .cosmicContextOnly:
            return "Cosmic context only"
        case .unavailable:
            return "Market data unavailable"
        }
    }

    var displayColor: Color {
        switch displayMode {
        case .marketBackedScore:
            return moodLevel?.color ?? CosmicTheme.textMuted
        case .cosmicContextOnly:
            return CosmicTheme.gold
        case .unavailable:
            return CosmicTheme.textMuted
        }
    }

    var displaySymbol: String {
        switch displayMode {
        case .marketBackedScore:
            return moodLevel?.sfSymbol ?? "chart.line.uptrend.xyaxis"
        case .cosmicContextOnly:
            return "sparkles"
        case .unavailable:
            return "exclamationmark.triangle"
        }
    }

    var displayDescription: String {
        switch displayMode {
        case .marketBackedScore:
            return moodLevel?.cosmicDescription ?? "Provider-backed market context"
        case .cosmicContextOnly:
            return "Provider-backed market factors unavailable"
        case .unavailable:
            return "Market tone will appear when provider data is available"
        }
    }

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
    /// -100 to +100 contribution. Nil means the factor input is unavailable.
    let value: Int?
    let weight: Double       // How much this factor matters (0-1)
    let description: String
    let icon: String
    let provenance: FinancialDataProvenance

    init(
        name: String,
        category: MoodFactorCategory,
        value: Int?,
        weight: Double,
        description: String,
        icon: String,
        provenance: FinancialDataProvenance? = nil
    ) {
        self.name = name
        self.category = category
        self.value = value
        self.weight = weight
        self.description = description
        self.icon = icon
        self.provenance = provenance ?? {
            if value == nil {
                return .unavailable(reason: description)
            }
            if category == .cosmic {
                return .sample(reason: "Cosmic context only")
            }
            return .sample(reason: "Preview fixture")
        }()
    }

    /// Weighted contribution to overall mood
    var weightedContribution: Double {
        guard let value else { return 0 }
        return Double(value) * weight
    }

    /// Is this factor bullish (positive) or bearish (negative)?
    var sentiment: FactorSentiment {
        guard let value else { return .unavailable }
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
        case .unavailable: return CosmicTheme.textMuted
        }
    }

    enum FactorSentiment {
        case bullish, bearish, neutral, unavailable
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
    let historicalReturn: Double?
    let timeframe: String         // e.g., "1 month"
    let sampleSize: String        // e.g., "Based on 15 similar periods"

    /// Formatted return string
    var formattedReturn: String {
        guard let historicalReturn else { return "N/A" }
        let sign = historicalReturn >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, historicalReturn)
    }

    /// Is this an extreme-mood context flag?
    var isContrarianSignal: Bool {
        guard let historicalReturn else { return false }
        // Extreme fear with positive return = positive contrarian context.
        // Extreme greed with negative return = negative contrarian context.
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
        title: "Historical Context Unavailable",
        description: "Provider-backed market history is not connected yet, so Cosmo Trader is not showing return claims for Void readings.",
        historicalReturn: nil,
        timeframe: "N/A",
        sampleSize: "Provider-backed history unavailable"
    )

    static let eclipseInsight = HistoricalInsight(
        moodLevel: .eclipse,
        title: "Historical Context Unavailable",
        description: "Pessimism notes are mood framing only until provider-backed market history can calculate comparable periods.",
        historicalReturn: nil,
        timeframe: "N/A",
        sampleSize: "Provider-backed history unavailable"
    )

    static let twilightInsight = HistoricalInsight(
        moodLevel: .twilight,
        title: "Historical Context Unavailable",
        description: "Balanced mood context is available, but statistical return history is not yet calculated from provider data.",
        historicalReturn: nil,
        timeframe: "N/A",
        sampleSize: "Provider-backed history unavailable"
    )

    static let radiantInsight = HistoricalInsight(
        moodLevel: .radiant,
        title: "Historical Context Unavailable",
        description: "Optimism notes are sentiment framing only until comparable periods are calculated from real market history.",
        historicalReturn: nil,
        timeframe: "N/A",
        sampleSize: "Provider-backed history unavailable"
    )

    static let supernovaInsight = HistoricalInsight(
        moodLevel: .supernova,
        title: "Historical Context Unavailable",
        description: "Hot sentiment can be useful context, but Cosmo Trader is not showing uncalculated return claims.",
        historicalReturn: nil,
        timeframe: "N/A",
        sampleSize: "Provider-backed history unavailable"
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
