import Foundation
import Testing
@testable import Cosmo_Trader

struct StockAstroTechnicalContextServiceTests {

    @Test("Combined card renders when technical and cosmic context are provider-backed")
    func combinedCardRendersWhenBothSidesAreProviderBacked() {
        let context = StockAstroTechnicalContextService.shared.context(
            symbol: "AAPL",
            technicalSummary: technicalSummary(),
            cosmicSummaries: [cosmicSummary()],
            cosmicProvenance: liveProvenance,
            cosmicCompleteness: .complete
        )

        #expect(context.cards.contains { $0.displayMode == .combinedContext })
        #expect(context.hasCombinedNumericClaims)
        #expect(context.cards.contains { $0.contextText.contains("Full Moon") })
        #expect(context.footer.contains("not financial advice"))
    }

    @Test("Combined card withholds numeric claims when cosmic sample size is too small")
    func combinedCardWithholdsNumericClaimsWhenCosmicSampleIsTooSmall() {
        let context = StockAstroTechnicalContextService.shared.context(
            symbol: "AAPL",
            technicalSummary: technicalSummary(),
            cosmicSummaries: [
                cosmicSummary(
                    sampleSize: 1,
                    averageReturn: nil,
                    baselineReturn: nil,
                    confidence: .insufficient,
                    displayMode: .insufficientSample,
                    disclaimer: "Not enough historical observations for this event. No return claim is shown."
                )
            ],
            cosmicProvenance: liveProvenance,
            cosmicCompleteness: .complete
        )

        #expect(context.cards.allSatisfy { $0.displayMode == .technicalOnly })
        #expect(!context.hasCombinedNumericClaims)
        #expect(context.cards.allSatisfy { $0.contextText.contains("Combined numeric context stays hidden") })
    }

    @Test("Combined card withholds technical claims when candles are insufficient")
    func combinedCardWithholdsTechnicalClaimsWhenCandlesAreInsufficient() {
        let context = StockAstroTechnicalContextService.shared.context(
            symbol: "AAPL",
            technicalSummary: technicalSummary(
                displayMode: .insufficient(reason: "Fewer than 20 candles"),
                completeness: .insufficient(reason: "Fewer than 20 candles"),
                metrics: nil
            ),
            cosmicSummaries: [cosmicSummary()],
            cosmicProvenance: liveProvenance,
            cosmicCompleteness: .complete
        )

        #expect(context.cards.allSatisfy { $0.displayMode == .cosmicOnly })
        #expect(!context.hasCombinedNumericClaims)
        #expect(context.cards.allSatisfy { $0.technicalText.localizedCaseInsensitiveContains("needs complete fresh provider candles") })
    }

    @Test("Mixed provenance does not produce confident combined claims")
    func mixedProvenanceDoesNotProduceConfidentCombinedClaims() {
        let mixed = FinancialDataProvenance.mixed(reason: "Mixed technical history")
        let context = StockAstroTechnicalContextService.shared.context(
            symbol: "AAPL",
            technicalSummary: technicalSummary(
                displayMode: .mixed(reason: "Mixed technical history"),
                provenance: mixed,
                metrics: nil
            ),
            cosmicSummaries: [
                cosmicSummary(
                    provenance: .sample(reason: "Preview fixture"),
                    displayMode: .sampleOnly,
                    disclaimer: "Sample chart data is labeled for preview only. No historical correlation claim is shown."
                )
            ],
            cosmicProvenance: .sample(reason: "Preview fixture"),
            cosmicCompleteness: .complete
        )

        #expect(context.cards.allSatisfy { $0.displayMode == .unavailable })
        #expect(!context.hasCombinedNumericClaims)
        #expect(context.technicalProvenance == mixed)
    }

    @Test("Stale-beyond-policy data does not produce confident combined claims")
    func staleBeyondPolicyDataDoesNotProduceConfidentCombinedClaims() {
        let stale = FinancialDataProvenance.cached(
            provider: "Finnhub",
            fetchedAt: Date(timeIntervalSince1970: 1_700_000_000),
            age: FinancialDataProvenance.defaultCachedStaleInterval + 60
        )

        let context = StockAstroTechnicalContextService.shared.context(
            symbol: "AAPL",
            technicalSummary: technicalSummary(
                displayMode: .staleCached,
                provenance: stale
            ),
            cosmicSummaries: [cosmicSummary(provenance: stale)],
            cosmicProvenance: stale,
            cosmicCompleteness: .complete
        )

        #expect(context.cards.allSatisfy { $0.displayMode != .combinedContext })
        #expect(!context.hasCombinedNumericClaims)
        #expect(context.technicalProvenance.isCachedStale())
        #expect(context.cosmicProvenance.isCachedStale())
    }

    @Test("Astro-technical copy avoids forbidden trading instruction phrases")
    func astroTechnicalCopyAvoidsForbiddenTradingInstructionPhrases() {
        let context = StockAstroTechnicalContextService.shared.context(
            symbol: "AAPL",
            technicalSummary: technicalSummary(),
            cosmicSummaries: [cosmicSummary()],
            cosmicProvenance: liveProvenance,
            cosmicCompleteness: .complete
        )

        let copy = ([context.footer] + context.cards.flatMap {
            [$0.title, $0.technicalText, $0.cosmicText, $0.contextText]
        }).joined(separator: " ")

        let forbidden = [
            "buy",
            "sell",
            "take profit",
            "reduce exposure",
            "position size",
            "expected upside",
            "expected downside",
            "prediction"
        ]

        for phrase in forbidden {
            #expect(!copy.localizedCaseInsensitiveContains(phrase), "Unsafe phrase found: \(phrase)")
        }
    }

    private var liveProvenance: FinancialDataProvenance {
        .live(provider: "Finnhub", fetchedAt: Date(timeIntervalSince1970: 1_800_000_000))
    }

    private func technicalSummary(
        displayMode: StockTechnicalDisplayMode = .providerBacked,
        provenance: FinancialDataProvenance? = nil,
        completeness: HistoricalDatasetCompleteness = .complete,
        metrics: StockTechnicalMetrics? = nil
    ) -> StockTechnicalSummary {
        let resolvedMetrics = metrics ?? StockTechnicalMetrics(
            latestClose: 152,
            movingAverage20: 148,
            movingAverage50: 145,
            movingAverage200: nil,
            rsi14: 54.2,
            volumeTrend: StockVolumeTrend(
                recentAverageVolume: 1_250_000,
                previousAverageVolume: 1_100_000,
                percentDifference: 13.6
            ),
            volatility: StockVolatilityContext(annualizedPercent: 31.5, sampleDays: 20),
            recentRange: StockRecentRange(low: 141, high: 155, sampleDays: 20),
            supportResistance: nil
        )

        return StockTechnicalSummary(
            symbol: "AAPL",
            displayMode: displayMode,
            provenance: provenance ?? liveProvenance,
            completeness: completeness,
            candleCount: resolvedMetrics == nil ? 8 : 80,
            metrics: resolvedMetrics,
            headline: "Technical lens: price is above its 50D average, RSI balanced.",
            explanation: "Technical lens uses provider-backed historical candles only. Read this as historical context, not financial advice."
        )
    }

    private func cosmicSummary(
        sampleSize: Int = 5,
        averageReturn: Double? = 1.2,
        baselineReturn: Double? = 0.4,
        provenance: FinancialDataProvenance? = nil,
        confidence: CorrelationConfidence = .moderate,
        displayMode: CorrelationDisplayMode = .marketBackedResult,
        disclaimer: String = "Historical context only. Correlation does not imply causation and this is not financial advice."
    ) -> StockCosmicCorrelationSummary {
        StockCosmicCorrelationSummary(
            id: "AAPL-fullMoon",
            symbol: "AAPL",
            eventName: "Full Moon",
            eventType: .fullMoon,
            eventCount: sampleSize,
            sampleSize: sampleSize,
            window: CorrelationWindow(daysBefore: 1, daysAfter: 3),
            averageReturn: averageReturn,
            medianReturn: averageReturn,
            winRate: averageReturn == nil ? nil : 0.6,
            baselineReturn: baselineReturn,
            volatilityRatio: averageReturn == nil ? nil : 1.1,
            maxDrawdown: averageReturn == nil ? nil : -2.0,
            provenance: provenance ?? liveProvenance,
            confidence: confidence,
            displayMode: displayMode,
            disclaimer: disclaimer
        )
    }
}
