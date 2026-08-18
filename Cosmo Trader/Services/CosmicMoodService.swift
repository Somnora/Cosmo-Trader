import Foundation
import SwiftUI

// MARK: - Cosmic Mood Service
// ===========================
// Calculates the Cosmic Mood Index based on various factors:
// - Moon phase influence
// - Provider-backed market performance when connected
// - Provider-backed volatility readings when connected
// - Planetary positions (Mercury retrograde)

@Observable
final class CosmicMoodService {

    // MARK: - Singleton

    static let shared = CosmicMoodService()

    // MARK: - Dependencies

    private let moonService = MoonPhaseService.shared
    private let retrogradeProvider = MercuryRetrogradeEphemerisProvider.shared
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

        // 3. Market Performance Factor
        factors.append(calculateMarketPerformanceFactor())

        // 4. Volatility Factor
        factors.append(calculateVolatilityFactor())

        // 5. Market Breadth Factor
        factors.append(calculateMarketBreadthFactor())

        // 6. Momentum Factor
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

    /// Mercury retrograde effect, backed by the curated ephemeris table
    private func calculateMercuryRetrogradeFactor() -> MoodFactor {
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

    // MARK: - Ephemeris Helpers

    /// Mercury retrograde status from the curated ephemeris table (2021-2030).
    /// Outside that range the provider returns no windows, which reads as
    /// direct rather than fabricating an extrapolated cycle.
    private func isMercuryRetrograde() -> Bool {
        !retrogradeProvider.windows(from: Date(), to: Date()).isEmpty
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

    /// Check if we're in an extreme mood (contrarian context)
    func isExtremeReading() -> (isExtreme: Bool, type: String?) {
        let mood = getCurrentMood()
        guard mood.isMarketBacked, let moodLevel = mood.moodLevel else {
            return (false, nil)
        }

        switch moodLevel {
        case .void:
            return (true, "Extreme Fear - potential contrarian context")
        case .supernova:
            return (true, "Extreme Greed - extreme sentiment context")
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
