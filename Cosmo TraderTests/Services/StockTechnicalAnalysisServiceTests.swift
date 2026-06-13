import Foundation
import Testing
@testable import Cosmo_Trader

struct StockTechnicalAnalysisServiceTests {
    private let service = StockTechnicalAnalysisService()

    @Test("RSI requires enough provider-backed candles")
    func rsiRequiresEnoughRealCandles() {
        let dataset = dataset(count: 49)

        let summary = service.summary(dataset: dataset)

        #expect(summary.displayMode == .insufficientDataset)
        #expect(summary.rsi14 == nil)
        #expect(summary.metrics.isEmpty)
        #expect(summary.canShowNumericMetrics == false)
    }

    @Test("Moving averages require enough provider-backed candles")
    func movingAverageRequiresEnoughRealCandles() {
        let shortDataset = dataset(count: 199)
        let longDataset = dataset(count: 220)

        let shortSummary = service.summary(dataset: shortDataset)
        let longSummary = service.summary(dataset: longDataset)

        #expect(shortSummary.displayMode == .providerBacked)
        #expect(shortSummary.movingAverage20 != nil)
        #expect(shortSummary.movingAverage50 != nil)
        #expect(shortSummary.movingAverage200 == nil)
        #expect(shortSummary.metrics.contains { $0.id == "ma-20" })
        #expect(shortSummary.metrics.contains { $0.id == "ma-50" })
        #expect(!shortSummary.metrics.contains { $0.id == "ma-200" })

        #expect(longSummary.displayMode == .providerBacked)
        #expect(longSummary.movingAverage200 != nil)
        #expect(longSummary.metrics.contains { $0.id == "ma-200" })
    }

    @Test("Sample and unavailable history produces no numeric technical claims")
    func sampleAndUnavailableHistoryWithholdMetrics() {
        let sampleSummary = service.summary(
            dataset: dataset(
                count: 90,
                provenance: .sample(reason: "Preview-only historical fixture")
            )
        )
        let unavailableSummary = service.summary(
            dataset: dataset(
                count: 90,
                provenance: .unavailable(reason: "Provider-backed candles unavailable")
            )
        )

        #expect(sampleSummary.displayMode == .sampleOnly)
        #expect(unavailableSummary.displayMode == .unavailable)
        #expect(sampleSummary.metrics.isEmpty)
        #expect(unavailableSummary.metrics.isEmpty)
        #expect(sampleSummary.rsi14 == nil)
        #expect(unavailableSummary.movingAverage50 == nil)
    }

    @Test("Partial and insufficient datasets produce no numeric technical claims")
    func partialAndInsufficientDatasetsWithholdMetrics() {
        let partialSummary = service.summary(dataset: partialDataset(count: 90))
        let insufficientSummary = service.summary(dataset: dataset(count: 1))

        #expect(partialSummary.displayMode == .partialDataset)
        #expect(insufficientSummary.displayMode == .insufficientDataset)
        #expect(partialSummary.metrics.isEmpty)
        #expect(insufficientSummary.metrics.isEmpty)
        #expect(partialSummary.canShowNumericMetrics == false)
        #expect(insufficientSummary.canShowNumericMetrics == false)
    }

    @Test("Support and resistance are withheld when candles are insufficient")
    func supportResistanceRequiresEnoughProviderBackedCandles() {
        let shortSummary = service.summary(dataset: dataset(count: 55))
        let fullSummary = service.summary(dataset: dataset(count: 90))

        #expect(shortSummary.displayMode == .providerBacked)
        #expect(shortSummary.supportCandidate == nil)
        #expect(shortSummary.resistanceCandidate == nil)
        #expect(shortSummary.supportResistanceMetric == nil)

        #expect(fullSummary.supportCandidate != nil)
        #expect(fullSummary.resistanceCandidate != nil)
        #expect(fullSummary.supportResistanceMetric != nil)
    }

    @Test("Stale cached provider data is labeled and withholds numeric metrics")
    func staleDataIsLabeledAndWithholdsMetrics() {
        let fetchedAt = date("2026-05-20")
        let summary = service.summary(
            dataset: dataset(
                count: 220,
                provenance: .cached(
                    provider: FinancialDataProvenance.finnhubProvider,
                    fetchedAt: fetchedAt,
                    age: HistoricalPriceDataset.defaultStaleInterval + 60
                )
            )
        )

        #expect(summary.displayMode == .staleDataset)
        #expect(!summary.canShowNumericMetrics)
        #expect(summary.metrics.isEmpty)
        #expect(summary.rsi14 == nil)
        #expect(summary.provenance.indicatorLabel == "Finnhub stale")
        #expect(summary.provenance.isCachedStale())
    }

    @Test("Generated technical copy contains no trading instructions")
    func generatedCopyIsComplianceSafe() {
        let summary = service.summary(dataset: dataset(count: 220))
        let copy = (
            [
                summary.trendContext,
                summary.momentumContext,
                summary.volumeContext,
                summary.volatilityContext,
                summary.rangeContext,
                summary.explanation,
                summary.disclaimer
            ] + summary.metrics.flatMap { [$0.label, $0.value, $0.detail] }
        )
        .joined(separator: "\n")
        .lowercased()

        for banned in [
            "buy signal",
            "sell signal",
            "buying opportunity",
            "take profits",
            "reduce exposure",
            "reduce position",
            "position size",
            "smaller position",
            "delay major decisions",
            "high-risk positions",
            "expected upside",
            "expected downside",
            "trade signal",
            "trading signal"
        ] {
            #expect(!copy.contains(banned), "Unexpected trading-instruction copy: \(banned)")
        }
    }

    @Test("Unavailable stock technical state renders a clean no-metric summary")
    func unavailableStateRendersCleanly() {
        let summary = StockTechnicalSummary.unavailable(
            symbol: "AAPL",
            reason: "Provider-backed daily candles unavailable."
        )
        let view = StockTechnicalContextView(summary: summary, isLoading: false, onRefresh: {})

        #expect(summary.displayMode == .unavailable)
        #expect(summary.metrics.isEmpty)
        #expect(summary.canShowNumericMetrics == false)
        #expect(summary.explanation.contains("Provider-backed daily candles unavailable"))
        _ = view
    }

    private func dataset(
        count: Int,
        provenance: FinancialDataProvenance? = nil
    ) -> HistoricalPriceDataset {
        let candles = candles(count: count)
        let requestedRange = DateInterval(
            start: candles.first?.date ?? date("2025-01-01"),
            end: candles.last?.date ?? date("2025-01-01").addingTimeInterval(86_400)
        )
        let fetchedAt = date("2026-05-30")

        return HistoricalPriceDataset.providerBacked(
            symbol: "AAPL",
            candles: candles,
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: fetchedAt,
            requestedRange: requestedRange,
            provenance: provenance ?? .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        )
    }

    private func partialDataset(count: Int) -> HistoricalPriceDataset {
        let candles = candles(count: count)
        let fetchedAt = date("2026-05-30")
        let end = candles.last?.date ?? fetchedAt
        let requestedStart = Calendar(identifier: .gregorian).date(byAdding: .day, value: -365, to: end) ?? end

        return HistoricalPriceDataset.providerBacked(
            symbol: "AAPL",
            candles: candles,
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: fetchedAt,
            requestedRange: DateInterval(start: requestedStart, end: end),
            provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
        )
    }

    private func candles(count: Int) -> [OHLCData] {
        guard count > 0 else { return [] }
        let calendar = Calendar(identifier: .gregorian)
        let start = date("2025-01-01")

        return (0..<count).compactMap { index in
            guard let candleDate = calendar.date(byAdding: .day, value: index, to: start) else {
                return nil
            }
            let drift = Double(index) * 0.35
            let cycle = Double(index % 9) - 4
            let close = 100 + drift + cycle
            let open = close - 0.6
            return OHLCData(
                date: candleDate,
                open: open,
                high: close + 1.4,
                low: max(1, open - 1.2),
                close: close,
                volume: 1_000_000 + (index % 17) * 12_000
            )
        }
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
