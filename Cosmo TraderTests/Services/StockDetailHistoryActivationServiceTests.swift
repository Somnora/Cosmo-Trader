import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct StockDetailHistoryActivationServiceTests {
    @Test("Load action requests provider-backed history")
    func loadActionRequestsProviderBackedHistory() async {
        let service = StockDetailHistoryActivationService()
        var requestedSymbol: String?
        var requestedTimeframe: ChartTimeframe?

        let result = await service.loadProviderHistory(symbol: "aapl", timeframe: .year) { symbol, timeframe in
            requestedSymbol = symbol
            requestedTimeframe = timeframe
            return dataset(count: 220)
        }

        #expect(requestedSymbol == "AAPL")
        #expect(requestedTimeframe == .year)
        #expect(result.dataset != nil)
        #expect(result.state.displayMode == .providerBacked)
        #expect(result.state.isProviderBacked)
        #expect(result.state.candleCount == 220)
    }

    @Test("Refresh action does not promote sample history")
    func refreshActionDoesNotCreateSampleData() async {
        let service = StockDetailHistoryActivationService()

        let result = await service.loadProviderHistory(symbol: "AAPL") { _, _ in
            dataset(count: 220, provenance: .sample(reason: "Preview-only fixture"))
        }

        #expect(result.state.displayMode == .sampleOnly)
        #expect(!result.state.isProviderBacked)
        #expect(result.state.shouldShowAction)
        #expect(result.state.provenance == .sample(reason: "Preview-only fixture"))
    }

    @Test("Insufficient history keeps chart correlation and technical context unavailable")
    func insufficientHistoryKeepsSectionsUnavailable() async {
        let service = StockDetailHistoryActivationService()

        let result = await service.loadProviderHistory(symbol: "MSFT") { _, _ in
            dataset(count: 1)
        }

        #expect(result.state.displayMode == .insufficient)
        #expect(result.state.candleCount == 1)
        #expect(result.state.shouldShowAction)
        #expect(result.state.sectionStatuses.contains { $0.title == "Chart" && $0.detail.contains("Not enough") })
        #expect(result.state.sectionStatuses.contains { $0.title == "Technical context" && $0.detail.contains("Not enough") })
        #expect(result.state.sectionStatuses.contains { $0.title == "Cosmic correlation" && $0.detail.contains("Not enough") })
    }

    @Test("Stale history is labeled stale and remains refreshable")
    func staleHistoryIsLabeledStale() async {
        let service = StockDetailHistoryActivationService()
        let staleFetchedAt = date("2026-05-20")

        let result = await service.loadProviderHistory(symbol: "TSLA") { _, _ in
            dataset(
                count: 220,
                provenance: .cached(
                    provider: FinancialDataProvenance.finnhubProvider,
                    fetchedAt: staleFetchedAt,
                    age: HistoricalPriceDataset.defaultStaleInterval + 120
                )
            )
        }

        #expect(result.state.displayMode == .stale)
        #expect(result.state.provenance.indicatorLabel == "Finnhub stale")
        #expect(result.state.shouldShowAction)
        #expect(result.state.sectionStatuses.contains { $0.detail.localizedCaseInsensitiveContains("stale") })
    }

    @Test("Successful history load exposes refreshable sections")
    func successfulHistoryLoadRefreshesStockDetailState() async {
        let service = StockDetailHistoryActivationService()

        let result = await service.loadProviderHistory(symbol: "NVDA") { _, _ in
            dataset(count: 220)
        }

        #expect(result.state.displayMode == .providerBacked)
        #expect(result.state.actionTitle == nil)
        #expect(result.state.sectionStatuses.contains { $0.title == "Chart" && $0.detail.contains("220") })
        #expect(result.state.sectionStatuses.contains { $0.title == "Technical context" })
        #expect(result.state.sectionStatuses.contains { $0.title == "Cosmic correlation" })
    }

    @Test("Unavailable stock detail history state renders cleanly")
    func unavailableStateRendersCleanly() {
        let state = StockDetailHistoryActivationState.unavailable(
            symbol: "AAPL",
            reason: "Provider-backed historical candles unavailable."
        )
        let view = StockDetailHistoryActivationCard(state: state, isLoading: false, onLoadHistory: {})

        #expect(state.displayMode == .unavailable)
        #expect(state.shouldShowAction)
        #expect(state.headline == "Provider history unavailable")
        #expect(state.detail.contains("Provider-backed historical candles unavailable"))
        _ = view
    }

    @Test("History activation copy contains no trading instructions")
    func historyActivationCopyIsComplianceSafe() {
        let state = StockDetailHistoryActivationState.notLoaded(symbol: "AAPL")
        let copy = (
            [state.headline, state.detail, state.actionTitle ?? ""]
                + state.sectionStatuses.flatMap { [$0.title, $0.detail] }
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

    private func dataset(
        count: Int,
        provenance: FinancialDataProvenance? = nil
    ) -> HistoricalPriceDataset {
        let candles = candles(count: count)
        let requestedStart = date("2025-01-01")
        let requestedEnd = date("2025-12-31")
        let fetchedAt = date("2026-05-30")

        return HistoricalPriceDataset.providerBacked(
            symbol: "AAPL",
            candles: candles,
            provider: FinancialDataProvenance.finnhubProvider,
            fetchedAt: fetchedAt,
            requestedRange: DateInterval(start: requestedStart, end: requestedEnd),
            provenance: provenance ?? .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)
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
            let close = 100 + Double(index) * 0.25
            return OHLCData(
                date: candleDate,
                open: close - 0.4,
                high: close + 1.0,
                low: max(1, close - 1.0),
                close: close,
                volume: 1_000_000 + index * 1_000
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
