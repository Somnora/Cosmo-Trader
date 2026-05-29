import Foundation
import SwiftUI

// MARK: - Cosmic Mood Service
// ===========================
// Calculates the Cosmic Mood Index based on various factors:
// - Moon phase influence
// - Provider-backed market performance when connected
// - Provider-backed volatility readings when connected
// - Planetary positions (Mercury retrograde, Jupiter transit, etc.)

@Observable
final class CosmicMoodService {

    // MARK: - Singleton

    static let shared = CosmicMoodService()

    // MARK: - Dependencies

    private let moonService = MoonPhaseService.shared
    private let minimumMarketCoverageForScore = 0.50

    // MARK: - State

    /// Current mood data (cached)
    private(set) var currentMoodData: CosmicMoodData?

    /// Historical mood readings
    private(set) var moodHistory: [MoodHistoryEntry] = []

    /// Last calculation time
    private var lastCalculation: Date?

    // MARK: - Init

    private init() {
        currentMoodData = calculateCurrentMood()
        moodHistory = []
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
    func getCurrentHistoricalInsight() -> HistoricalInsight? {
        let mood = getCurrentMood()
        guard mood.isMarketBacked, let moodLevel = mood.moodLevel else { return nil }
        return HistoricalInsight.insight(for: moodLevel)
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
        let totalWeight = factors.reduce(0.0) { $0 + $1.weight }
        let unavailableFactorWeight = totalWeight > 0
            ? factors.filter { $0.value == nil }.reduce(0.0) { $0 + $1.weight } / totalWeight
            : 1

        let marketFactors = factors.filter(\.requiresProviderMarketData)
        let totalMarketWeight = marketFactors.reduce(0.0) { $0 + $1.weight }
        let availableMarketWeight = marketFactors
            .filter { $0.value != nil && $0.provenance.isProviderBacked }
            .reduce(0.0) { $0 + $1.weight }
        let marketDataCoverage = totalMarketWeight > 0 ? availableMarketWeight / totalMarketWeight : 0

        guard marketDataCoverage >= minimumMarketCoverageForScore else {
            let hasCosmicContext = factors.contains { !$0.requiresProviderMarketData && $0.value != nil }
            return CosmicMoodData(
                date: Date(),
                value: nil,
                factors: factors,
                change: nil,
                label: hasCosmicContext ? "Cosmic context only" : "Market data unavailable",
                provenance: hasCosmicContext
                    ? .sample(reason: "Provider-backed market factors unavailable")
                    : .unavailable(reason: "Provider-backed market factors unavailable"),
                marketDataCoverage: marketDataCoverage,
                unavailableFactorWeight: unavailableFactorWeight,
                displayMode: hasCosmicContext ? .cosmicContextOnly : .unavailable
            )
        }

        // Calculate weighted average from available inputs only.
        let availableFactors = factors.filter { $0.value != nil }
        let availableWeight = availableFactors.reduce(0.0) { $0 + $1.weight }
        guard availableWeight > 0 else {
            return CosmicMoodData(
                date: Date(),
                value: nil,
                factors: factors,
                change: nil,
                label: "Market data unavailable",
                provenance: .unavailable(reason: "Provider-backed market factors unavailable"),
                marketDataCoverage: marketDataCoverage,
                unavailableFactorWeight: unavailableFactorWeight,
                displayMode: .unavailable
            )
        }

        let weightedSum = availableFactors.reduce(0.0) { $0 + $1.weightedContribution }

        // Convert from -100..+100 range to 0..100 range
        let normalizedValue = (weightedSum / availableWeight + 100) / 2
        let value = Int(max(0, min(100, normalizedValue)))

        return CosmicMoodData(
            date: Date(),
            value: value,
            factors: factors,
            change: nil,
            label: CosmicMoodLevel.from(value: value).sentimentName,
            provenance: scoreProvenance(from: marketFactors),
            marketDataCoverage: marketDataCoverage,
            unavailableFactorWeight: unavailableFactorWeight,
            displayMode: .marketBackedScore
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
            description = "Waxing moon builds constructive cosmic context"
        case .waxingGibbous:
            value = 10
            description = "Approaching full moon — energy peaks"
        case .fullMoon:
            value = -15
            description = "Full moon heightens the emotional backdrop"
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
            icon: phase.sfSymbol,
            provenance: .sample(reason: "Cosmic context only")
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
            description = "Mercury direct — clearer communication backdrop"
        }

        return MoodFactor(
            name: "Mercury",
            category: .cosmic,
            value: value,
            weight: 0.10,
            description: description,
            icon: isRetrograde ? "arrow.uturn.backward.circle.fill" : "arrow.right.circle.fill",
            provenance: .sample(reason: "Cosmic context only")
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
            description = "Jupiter favorable — expansion energy reads constructive"
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
            icon: "circle.hexagonpath.fill",
            provenance: .sample(reason: "Cosmic context only")
        )
    }

    /// Recent market performance from provider-backed data when available
    private func calculateMarketPerformanceFactor() -> MoodFactor {
        return MoodFactor(
            name: "Market Trend",
            category: .market,
            value: nil,
            weight: 0.20,
            description: "Provider-backed market trend unavailable",
            icon: "chart.line.uptrend.xyaxis",
            provenance: .unavailable(reason: "Provider-backed market trend unavailable")
        )
    }

    /// Volatility level from provider-backed market data when available
    private func calculateVolatilityFactor() -> MoodFactor {
        return MoodFactor(
            name: "Volatility",
            category: .volatility,
            value: nil,
            weight: 0.20,
            description: "Provider-backed volatility unavailable",
            icon: "waveform.path.ecg",
            provenance: .unavailable(reason: "Provider-backed volatility unavailable")
        )
    }

    /// Market breadth from provider-backed market data when available
    private func calculateMarketBreadthFactor() -> MoodFactor {
        return MoodFactor(
            name: "Market Breadth",
            category: .market,
            value: nil,
            weight: 0.15,
            description: "Provider-backed breadth unavailable",
            icon: "chart.bar.fill",
            provenance: .unavailable(reason: "Provider-backed breadth unavailable")
        )
    }

    /// Price momentum from provider-backed market data when available
    private func calculateMomentumFactor() -> MoodFactor {
        return MoodFactor(
            name: "Momentum",
            category: .momentum,
            value: nil,
            weight: 0.10,
            description: "Provider-backed momentum unavailable",
            icon: "gauge.medium",
            provenance: .unavailable(reason: "Provider-backed momentum unavailable")
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

    private func scoreProvenance(from marketFactors: [MoodFactor]) -> FinancialDataProvenance {
        let available = marketFactors.filter { $0.value != nil && $0.provenance.isProviderBacked }
        let liveFetches = available.compactMap { factor -> Date? in
            guard case .live(_, let fetchedAt) = factor.provenance else { return nil }
            return fetchedAt
        }
        let cachedFetches = available.compactMap { factor -> Date? in
            guard case .cached(_, let fetchedAt, _) = factor.provenance else { return nil }
            return fetchedAt
        }

        if !liveFetches.isEmpty && cachedFetches.isEmpty, let newest = liveFetches.max() {
            return .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: newest)
        }

        if liveFetches.isEmpty && !cachedFetches.isEmpty, let newest = cachedFetches.max() {
            return .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: newest)
        }

        if !available.isEmpty {
            return .mixed(reason: "Market score combines live and cached provider-backed factors")
        }

        return .unavailable(reason: "Provider-backed market factors unavailable")
    }
}

// MARK: - Cosmic Mood Service Extensions

extension CosmicMoodService {

    /// Get a brief summary suitable for dashboard display
    func getDashboardSummary() -> (value: Int?, label: String, level: CosmicMoodLevel?, change: String) {
        let mood = getCurrentMood()
        return (mood.value, mood.marketToneText, mood.moodLevel, mood.formattedChange)
    }

    /// Check if we're in an extreme mood (contrarian signal)
    func isExtremeReading() -> (isExtreme: Bool, type: String?) {
        let mood = getCurrentMood()
        guard mood.isMarketBacked, let moodLevel = mood.moodLevel else {
            return (false, nil)
        }

        switch moodLevel {
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

private extension MoodFactor {
    var requiresProviderMarketData: Bool {
        category != .cosmic
    }
}
