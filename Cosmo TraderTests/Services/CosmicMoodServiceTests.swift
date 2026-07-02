import Foundation
import Testing
@testable import Cosmo_Trader

/// Unit tests for the Cosmic Mood pipeline.
///
/// These tests exist because the previous mood implementation silently treated
/// missing provider-backed factors as numeric zero, producing a real-looking
/// market sentiment score from astrology data alone.
///
/// The contract these tests enforce:
///
/// 1. A factor whose `value` is nil contributes 0 to the weighted sum **and 0
///    to the denominator** (it is not pulled toward neutral).
/// 2. `CosmicMoodData.value` is nil unless provider-backed market factors meet
///    the safe coverage threshold.
/// 3. `displayMode` reports `.unavailable` / `.cosmicContextOnly` /
///    `.marketBackedScore` honestly.
/// 4. `marketToneText`, `isMarketBacked`, and `provenance` agree with the
///    `displayMode` so downstream consumers (Daily Brief, Discover, gauges)
///    cannot accidentally quote a cosmic-only score as a market measurement.
@MainActor
struct CosmicMoodServiceTests {

    // MARK: - MoodFactor semantics

    @Test("Unavailable factor contributes nothing to the weighted sum")
    func unavailableFactorContributesZero() {
        let factor = MoodFactor(
            name: "Market Trend",
            category: .market,
            value: nil,
            weight: 0.20,
            description: "Provider-backed market trend unavailable",
            icon: "chart.line.uptrend.xyaxis"
        )

        #expect(factor.weightedContribution == 0)
        #expect(factor.sentiment == .unavailable)
    }

    @Test("Available factor contributes value × weight")
    func availableFactorContributesValueTimesWeight() {
        let factor = MoodFactor(
            name: "Moon Phase",
            category: .cosmic,
            value: 15,
            weight: 0.10,
            description: "New moon energy",
            icon: "moon.fill"
        )

        #expect(factor.weightedContribution == 1.5)
        #expect(factor.sentiment == .bullish)
    }

    @Test("Negative available factor reads as bearish")
    func negativeFactorIsBearish() {
        let factor = MoodFactor(
            name: "Mercury",
            category: .cosmic,
            value: -25,
            weight: 0.10,
            description: "Retrograde",
            icon: "arrow.uturn.backward"
        )

        #expect(factor.weightedContribution == -2.5)
        #expect(factor.sentiment == .bearish)
    }

    @Test("Unspecified provenance defaults to unavailable when value is nil")
    func unspecifiedProvenanceDefaultsToUnavailableForNilValue() {
        let factor = MoodFactor(
            name: "Volatility",
            category: .volatility,
            value: nil,
            weight: 0.20,
            description: "Provider-backed volatility unavailable",
            icon: "waveform.path.ecg"
        )

        if case .unavailable(let reason) = factor.provenance {
            #expect(reason == "Provider-backed volatility unavailable")
        } else {
            Issue.record("Factor with nil value must default to unavailable provenance, got \(factor.provenance)")
        }
    }

    // MARK: - CosmicMoodData semantics by displayMode

    @Test("Cosmic-only mood withholds the numeric score")
    func cosmicOnlyModeHidesNumericScore() {
        let data = CosmicMoodData(
            date: Date(),
            value: nil,
            factors: [],
            label: "Cosmic context only",
            provenance: .sample(reason: "Provider-backed market factors unavailable"),
            marketDataCoverage: 0,
            unavailableFactorWeight: 0.65,
            displayMode: .cosmicContextOnly
        )

        #expect(data.value == nil)
        #expect(data.moodLevel == nil)
        #expect(data.marketToneText == "Cosmic context only")
        #expect(data.formattedValue == "N/A")
        #expect(!data.isMarketBacked)
    }

    @Test("Unavailable mood reports unavailable provenance and text")
    func unavailableModeReportsUnavailable() {
        let data = CosmicMoodData(
            date: Date(),
            value: nil,
            factors: [],
            label: "Market data unavailable",
            provenance: .unavailable(reason: "Provider-backed market factors unavailable"),
            marketDataCoverage: 0,
            unavailableFactorWeight: 1,
            displayMode: .unavailable
        )

        #expect(data.value == nil)
        #expect(data.marketToneText == "Market data unavailable")
        #expect(!data.isMarketBacked)
        #expect(data.provenance == .unavailable(reason: "Provider-backed market factors unavailable"))
    }

    @Test("Market-backed mood reports a numeric score and sentiment")
    func marketBackedModeReportsScore() {
        let data = CosmicMoodData(
            date: Date(),
            value: 72,
            factors: [],
            label: "Greed",
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: Date()),
            marketDataCoverage: 1,
            unavailableFactorWeight: 0,
            displayMode: .marketBackedScore
        )

        #expect(data.value == 72)
        #expect(data.moodLevel == .radiant)
        #expect(data.marketToneText == "Greed 72/100")
        #expect(data.isMarketBacked)
    }

    @Test("Market-backed but sample-provenance mood is not treated as market-backed")
    func sampleProvenanceIsNotMarketBacked() {
        // Belt and suspenders: even if displayMode optimistically says
        // .marketBackedScore, downstream consumers must not quote a score
        // whose provenance is sample (e.g. preview fixture).
        let data = CosmicMoodData(
            date: Date(),
            value: 55,
            factors: [],
            label: "Twilight",
            provenance: .sample(reason: "Preview fixture"),
            marketDataCoverage: 1,
            unavailableFactorWeight: 0,
            displayMode: .marketBackedScore
        )

        #expect(!data.isMarketBacked)
    }

    @Test("Mixed provenance counts as market-backed for headline rendering")
    func mixedProvenanceCountsAsMarketBacked() {
        let data = CosmicMoodData(
            date: Date(),
            value: 60,
            factors: [],
            label: "Twilight",
            provenance: .mixed(reason: "Live + cached market factors"),
            marketDataCoverage: 0.75,
            unavailableFactorWeight: 0.10,
            displayMode: .marketBackedScore
        )

        #expect(data.isMarketBacked)
    }

    // MARK: - Service behavior (current shipping configuration)

    @Test("Shipping mood returns cosmic context only until provider market factors are wired")
    func shippingMoodIsCosmicContextOnly() {
        let mood = CosmicMoodService.shared.getCurrentMood()

        #expect(mood.value == nil)
        #expect(mood.displayMode == .cosmicContextOnly)
        #expect(mood.marketToneText == "Cosmic context only")
        #expect(!mood.isMarketBacked)

        let marketFactors = mood.factors.filter { factor in
            factor.category == .market || factor.category == .volatility || factor.category == .momentum
        }
        #expect(!marketFactors.isEmpty)
        #expect(marketFactors.allSatisfy { $0.value == nil })
        #expect(mood.marketDataCoverage == 0)
    }

    @Test("Historical insight is withheld while mood is not market-backed")
    func historicalInsightIsNilForCosmicOnlyMood() {
        // The service can only return a market-history insight when the score
        // itself is provider-backed. Otherwise the contrarian framing would
        // be making claims grounded in zero market data.
        let insight = CosmicMoodService.shared.getCurrentHistoricalInsight()
        #expect(insight == nil)
    }

    @Test("Extreme-reading flag is false while mood is not market-backed")
    func extremeReadingIsFalseForCosmicOnlyMood() {
        let extreme = CosmicMoodService.shared.isExtremeReading()
        #expect(!extreme.isExtreme)
        #expect(extreme.type == nil)
    }

    @Test("Dashboard summary surfaces nil value and cosmic-only label")
    func dashboardSummaryHidesNumericValue() {
        let summary = CosmicMoodService.shared.getDashboardSummary()
        #expect(summary.value == nil)
        #expect(summary.label == "Cosmic context only")
        #expect(summary.level == nil)
    }

    // MARK: - Daily Brief integration

    @Test("Daily Brief marketTone reflects mood provenance honestly")
    func dailyBriefMarketToneIsCosmicOnly() async {
        let reading = await DailyFinancialReadingService.shared.compose(for: .sampleWithHoldings)

        #expect(reading.marketTone == "Cosmic context only")
        // The cell-level provenance must agree with the text. The cockpit
        // view branches on this to render the per-cell indicator.
        #expect(!reading.marketToneProvenance.isProviderBacked)
        // No `score/100` phrasing, and no leftover "Market tone is X" copy
        // that quotes the score as a market signal.
        #expect(!reading.marketCosmicPosture.contains("/100"))
        #expect(!reading.marketCosmicPosture.localizedCaseInsensitiveContains("Market tone is "))
        #expect(!reading.marketCosmicPosture.localizedCaseInsensitiveContains("Risk appetite is elevated"))
    }
}
