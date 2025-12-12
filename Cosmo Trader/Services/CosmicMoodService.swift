import Foundation
import SwiftUI

// MARK: - Cosmic Mood Service
// ===========================
// Calculates the Cosmic Mood Index based on various factors:
// - Moon phase influence
// - Simulated market performance
// - Volatility readings
// - Planetary positions (Mercury retrograde, Jupiter transit, etc.)

@Observable
final class CosmicMoodService {

    // MARK: - Singleton

    static let shared = CosmicMoodService()

    // MARK: - Dependencies

    private let moonService = MoonPhaseService.shared

    // MARK: - State

    /// Current mood data (cached)
    private(set) var currentMoodData: CosmicMoodData?

    /// Historical mood readings
    private(set) var moodHistory: [MoodHistoryEntry] = []

    /// Last calculation time
    private var lastCalculation: Date?

    // MARK: - Init

    private init() {
        // Generate initial data
        currentMoodData = calculateCurrentMood()
        moodHistory = generateMockHistory()
    }

    // MARK: - Public Methods

    /// Get current mood data, recalculating if stale
    func getCurrentMood() -> CosmicMoodData {
        let now = Date()

        // Recalculate if more than 30 minutes have passed
        if let lastCalc = lastCalculation,
           now.timeIntervalSince(lastCalc) < 1800,
           let cached = currentMoodData {
            return cached
        }

        let data = calculateCurrentMood()
        currentMoodData = data
        lastCalculation = now
        return data
    }

    /// Get historical insight for the current mood level
    func getCurrentHistoricalInsight() -> HistoricalInsight {
        let mood = getCurrentMood()
        return HistoricalInsight.insight(for: mood.moodLevel)
    }

    /// Get mood history for charting
    func getMoodHistory(days: Int = 30) -> [MoodHistoryEntry] {
        return Array(moodHistory.suffix(days))
    }

    /// Force refresh the mood calculation
    func refresh() {
        currentMoodData = calculateCurrentMood()
        lastCalculation = Date()
    }

    // MARK: - Calculation Methods

    /// Calculate the current mood index
    private func calculateCurrentMood() -> CosmicMoodData {
        // Calculate each factor
        let factors = calculateAllFactors()

        // Calculate weighted average
        let totalWeight = factors.reduce(0.0) { $0 + $1.weight }
        let weightedSum = factors.reduce(0.0) { $0 + $1.weightedContribution }

        // Convert from -100..+100 range to 0..100 range
        let normalizedValue = (weightedSum / totalWeight + 100) / 2
        let value = Int(max(0, min(100, normalizedValue)))

        // Calculate change from yesterday
        let change = calculateDailyChange()

        return CosmicMoodData(
            date: Date(),
            value: value,
            factors: factors,
            change: change
        )
    }

    /// Calculate all mood factors
    private func calculateAllFactors() -> [MoodFactor] {
        var factors: [MoodFactor] = []

        // 1. Moon Phase Factor
        factors.append(calculateMoonPhaseFactor())

        // 2. Mercury Retrograde Factor
        factors.append(calculateMercuryRetrogradeFactor())

        // 3. Jupiter Transit Factor
        factors.append(calculateJupiterTransitFactor())

        // 4. Market Performance Factor
        factors.append(calculateMarketPerformanceFactor())

        // 5. Volatility Factor
        factors.append(calculateVolatilityFactor())

        // 6. Market Breadth Factor
        factors.append(calculateMarketBreadthFactor())

        // 7. Momentum Factor
        factors.append(calculateMomentumFactor())

        return factors
    }

    // MARK: - Individual Factor Calculations

    /// Moon phase influence on sentiment
    private func calculateMoonPhaseFactor() -> MoodFactor {
        let lunarData = moonService.getCurrentLunarData()
        let phase = lunarData.phase

        // Full moon = more volatility/uncertainty (slightly bearish)
        // New moon = fresh starts (slightly bullish)
        // Waxing = building energy (bullish)
        // Waning = declining energy (bearish)

        var value: Int
        var description: String

        switch phase {
        case .newMoon:
            value = 15
            description = "New moon energy — fresh beginnings favor optimism"
        case .waxingCrescent, .firstQuarter:
            value = 20
            description = "Waxing moon builds bullish momentum"
        case .waxingGibbous:
            value = 10
            description = "Approaching full moon — energy peaks"
        case .fullMoon:
            value = -15
            description = "Full moon heightens emotions and volatility"
        case .waningGibbous:
            value = -10
            description = "Post-peak energy beginning to decline"
        case .lastQuarter:
            value = -5
            description = "Waning energy — caution increasing"
        case .waningCrescent:
            value = 0
            description = "End of lunar cycle — neutral sentiment"
        }

        return MoodFactor(
            name: "Moon Phase",
            category: .cosmic,
            value: value,
            weight: 0.15,
            description: description,
            icon: phase.emoji
        )
    }

    /// Mercury retrograde effect (simulated)
    private func calculateMercuryRetrogradeFactor() -> MoodFactor {
        // Simulate mercury retrograde periods
        // In reality, Mercury is retrograde about 3 times per year for ~3 weeks
        let isRetrograde = isMercuryRetrograde()

        let value: Int
        let description: String

        if isRetrograde {
            value = -25
            description = "Mercury retrograde — communication issues, delays expected"
        } else {
            value = 5
            description = "Mercury direct — clear communication supports markets"
        }

        return MoodFactor(
            name: "Mercury",
            category: .cosmic,
            value: value,
            weight: 0.10,
            description: description,
            icon: isRetrograde ? "arrow.uturn.backward.circle.fill" : "arrow.right.circle.fill"
        )
    }

    /// Jupiter transit effect (simulated)
    private func calculateJupiterTransitFactor() -> MoodFactor {
        // Jupiter = expansion, optimism
        // Simulate favorable Jupiter aspects periodically
        let jupiterInfluence = calculateJupiterInfluence()

        let value: Int
        let description: String

        if jupiterInfluence > 0.5 {
            value = 20
            description = "Jupiter favorable — expansion energy supports growth"
        } else if jupiterInfluence > 0.3 {
            value = 10
            description = "Jupiter moderate — mild optimism in the cosmos"
        } else {
            value = 0
            description = "Jupiter neutral — standard cosmic conditions"
        }

        return MoodFactor(
            name: "Jupiter",
            category: .cosmic,
            value: value,
            weight: 0.10,
            description: description,
            icon: "circle.hexagonpath.fill"
        )
    }

    /// Recent market performance (simulated)
    private func calculateMarketPerformanceFactor() -> MoodFactor {
        // Simulate recent market returns
        // In production, this would use real S&P 500 data
        let weeklyReturn = simulateWeeklyReturn()
        let monthlyReturn = simulateMonthlyReturn()

        let value = Int((weeklyReturn * 2 + monthlyReturn) * 10)
        let clampedValue = max(-50, min(50, value))

        let description: String
        if clampedValue > 20 {
            description = "Markets trending higher — bullish momentum"
        } else if clampedValue > 0 {
            description = "Markets slightly positive — cautious optimism"
        } else if clampedValue > -20 {
            description = "Markets slightly negative — mild concern"
        } else {
            description = "Markets trending lower — fear increasing"
        }

        return MoodFactor(
            name: "Market Trend",
            category: .market,
            value: clampedValue,
            weight: 0.20,
            description: description,
            icon: clampedValue >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis"
        )
    }

    /// Volatility level (simulated VIX-like indicator)
    private func calculateVolatilityFactor() -> MoodFactor {
        // Simulate VIX-like volatility
        // Low VIX = complacency (bullish for mood, but contrarian warning)
        // High VIX = fear (bearish for mood, but contrarian opportunity)
        let vix = simulateVIX()

        let value: Int
        let description: String

        if vix < 15 {
            value = 30
            description = "Low volatility — calm markets, potential complacency"
        } else if vix < 20 {
            value = 15
            description = "Normal volatility — healthy market conditions"
        } else if vix < 25 {
            value = 0
            description = "Elevated volatility — increased uncertainty"
        } else if vix < 30 {
            value = -20
            description = "High volatility — fear rising in markets"
        } else {
            value = -40
            description = "Extreme volatility — panic selling possible"
        }

        return MoodFactor(
            name: "Volatility",
            category: .volatility,
            value: value,
            weight: 0.20,
            description: description,
            icon: "waveform.path.ecg"
        )
    }

    /// Market breadth (simulated advance/decline ratio)
    private func calculateMarketBreadthFactor() -> MoodFactor {
        // Simulate advance/decline ratio
        let advanceDecline = simulateAdvanceDecline()

        let value = Int(advanceDecline * 40)
        let clampedValue = max(-40, min(40, value))

        let description: String
        if clampedValue > 20 {
            description = "Strong breadth — widespread participation in rally"
        } else if clampedValue > 0 {
            description = "Positive breadth — more stocks advancing"
        } else if clampedValue > -20 {
            description = "Negative breadth — more stocks declining"
        } else {
            description = "Weak breadth — broad-based selling"
        }

        return MoodFactor(
            name: "Market Breadth",
            category: .market,
            value: clampedValue,
            weight: 0.15,
            description: description,
            icon: "chart.bar.fill"
        )
    }

    /// Price momentum (simulated)
    private func calculateMomentumFactor() -> MoodFactor {
        // Simulate price momentum
        let momentum = simulateMomentum()

        let value = Int(momentum * 30)
        let clampedValue = max(-30, min(30, value))

        let description: String
        if clampedValue > 15 {
            description = "Strong bullish momentum — trend following favored"
        } else if clampedValue > 0 {
            description = "Mild bullish momentum — gradual uptrend"
        } else if clampedValue > -15 {
            description = "Mild bearish momentum — gradual downtrend"
        } else {
            description = "Strong bearish momentum — downtrend accelerating"
        }

        return MoodFactor(
            name: "Momentum",
            category: .momentum,
            value: clampedValue,
            weight: 0.10,
            description: description,
            icon: clampedValue >= 0 ? "gauge.high" : "gauge.low"
        )
    }

    // MARK: - Simulation Helpers

    /// Simulate Mercury retrograde based on approximate cycles
    private func isMercuryRetrograde() -> Bool {
        // Mercury retrograde occurs roughly 3 times per year
        // Each retrograde lasts about 3 weeks
        // This is a simplified simulation based on day of year

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1

        // Simulate retrograde periods around days 45-65, 150-170, 255-275
        let retrogradePeriods: [ClosedRange<Int>] = [
            45...65,    // Mid-February to early March
            150...170,  // Late May to mid-June
            255...275   // Mid-September to early October
        ]

        return retrogradePeriods.contains { $0.contains(dayOfYear) }
    }

    /// Calculate Jupiter influence based on simulated transit
    private func calculateJupiterInfluence() -> Double {
        // Jupiter takes ~12 years to orbit, spends ~1 year in each sign
        // Simulate favorable periods based on month
        let month = Calendar.current.component(.month, from: Date())

        // More favorable during certain months (simplified)
        switch month {
        case 1, 4, 7, 10: return 0.6  // Start of quarters = expansion
        case 12:          return 0.7  // Year-end optimism
        default:          return 0.3
        }
    }

    /// Simulate weekly market return
    private func simulateWeeklyReturn() -> Double {
        // Generate pseudo-random return based on date for consistency
        let seed = Calendar.current.ordinality(of: .weekOfYear, in: .year, for: Date()) ?? 1
        return sin(Double(seed) * 1.5) * 3 + cos(Double(seed) * 0.8) * 2
    }

    /// Simulate monthly market return
    private func simulateMonthlyReturn() -> Double {
        let seed = Calendar.current.component(.month, from: Date())
        return sin(Double(seed) * 2.1) * 4 + 1
    }

    /// Simulate VIX-like volatility index
    private func simulateVIX() -> Double {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        // Base VIX around 18 with some variation
        return 18 + sin(Double(dayOfYear) * 0.1) * 8 + cos(Double(dayOfYear) * 0.05) * 5
    }

    /// Simulate advance/decline ratio (-1 to +1)
    private func simulateAdvanceDecline() -> Double {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return sin(Double(dayOfYear) * 0.15) * 0.8
    }

    /// Simulate price momentum (-1 to +1)
    private func simulateMomentum() -> Double {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return cos(Double(dayOfYear) * 0.12) * 0.9
    }

    /// Calculate daily change in mood index
    private func calculateDailyChange() -> Int {
        // Compare to yesterday's simulated value
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            return 0
        }

        let todayValue = getCurrentMood().value
        let yesterdaySeed = Calendar.current.ordinality(of: .day, in: .year, for: yesterday) ?? 1
        let yesterdayValue = 50 + Int(sin(Double(yesterdaySeed) * 0.2) * 30)

        return todayValue - yesterdayValue
    }

    // MARK: - History Generation

    /// Generate mock historical mood data
    private func generateMockHistory() -> [MoodHistoryEntry] {
        var entries: [MoodHistoryEntry] = []
        let calendar = Calendar.current

        // Generate 90 days of history
        for daysAgo in (0..<90).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }

            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

            // Generate consistent pseudo-random value based on date
            let baseValue = 50.0
            let variation1 = sin(Double(dayOfYear) * 0.2) * 25
            let variation2 = cos(Double(dayOfYear) * 0.08) * 15
            let variation3 = sin(Double(dayOfYear) * 0.5) * 10

            let value = Int(baseValue + variation1 + variation2 + variation3)
            let clampedValue = max(0, min(100, value))

            entries.append(MoodHistoryEntry(date: date, value: clampedValue))
        }

        return entries
    }
}

// MARK: - Cosmic Mood Service Extensions

extension CosmicMoodService {

    /// Get a brief summary suitable for dashboard display
    func getDashboardSummary() -> (value: Int, level: CosmicMoodLevel, change: String) {
        let mood = getCurrentMood()
        return (mood.value, mood.moodLevel, mood.formattedChange)
    }

    /// Check if we're in an extreme mood (contrarian signal)
    func isExtremeReading() -> (isExtreme: Bool, type: String?) {
        let mood = getCurrentMood()
        switch mood.moodLevel {
        case .void:
            return (true, "Extreme Fear — potential contrarian buy signal")
        case .supernova:
            return (true, "Extreme Greed — potential contrarian sell signal")
        default:
            return (false, nil)
        }
    }

    /// Get factors sorted by absolute contribution
    func getTopFactors(count: Int = 3) -> [MoodFactor] {
        let mood = getCurrentMood()
        return mood.factors
            .sorted { abs($0.weightedContribution) > abs($1.weightedContribution) }
            .prefix(count)
            .map { $0 }
    }
}
