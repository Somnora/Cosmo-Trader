import Foundation
import Testing
@testable import Cosmo_Trader

@MainActor
struct StockDetailHistoryActivationViewModelTests {

    @Test("Load action requests provider-backed history")
    func loadActionRequestsProviderBackedHistory() async throws {
        var requestedSymbol: String?
        var requestedTimeframe: ChartTimeframe?
        let now = date("2026-01-15")
        let viewModel = StockDetailHistoryActivationViewModel { symbol, timeframe in
            requestedSymbol = symbol
            requestedTimeframe = timeframe
            return result(
                closes: [100, 101, 102],
                source: .provider,
                provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: now),
                requestedStart: date("2026-01-01"),
                requestedEnd: date("2026-01-03")
            )
        }

        let didLoad = await viewModel.refresh(symbol: "aapl", timeframe: .month)

        #expect(didLoad)
        #expect(requestedSymbol == "AAPL")
        #expect(requestedTimeframe == .month)
        if case .loaded(let source, let provenance, let completeness, let candleCount) = viewModel.state {
            #expect(source == .provider)
            #expect(provenance.isProviderBacked)
            #expect(completeness.allowsNumericCorrelationClaims)
            #expect(candleCount == 3)
        } else {
            Issue.record("Expected provider-backed loaded state")
        }
    }

    @Test("Load action does not create sample data on provider failure")
    func loadActionDoesNotCreateSampleDataOnProviderFailure() async {
        let viewModel = StockDetailHistoryActivationViewModel { _, _ in
            throw HistoricalPriceError.noHistoricalData
        }

        let didLoad = await viewModel.refresh(symbol: "AAPL", timeframe: .month)

        #expect(!didLoad)
        #expect(viewModel.state.provenance == .unavailable(reason: "Provider-backed historical prices unavailable. Try again later."))
    }

    @Test("Insufficient history keeps chart technical and correlation metrics unavailable")
    func insufficientHistoryKeepsContextGated() async throws {
        let now = date("2026-01-15")
        let viewModel = StockDetailHistoryActivationViewModel { _, _ in
            result(
                closes: [100],
                source: .provider,
                provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: now),
                requestedStart: date("2026-01-01"),
                requestedEnd: now
            )
        }

        let didLoad = await viewModel.refresh(symbol: "AAPL", timeframe: .month)

        #expect(didLoad)
        #expect(viewModel.state.title == "Insufficient provider history")
        #expect(viewModel.state.contextRows.contains(StockDetailHistoryContextRow(
            title: "Cosmic correlation",
            status: "Numeric claims remain gated"
        )))
        #expect(viewModel.state.contextRows.contains(StockDetailHistoryContextRow(
            title: "Technical lens",
            status: "Needs complete fresh history"
        )))
    }

    @Test("Partial history keeps numeric context gated")
    func partialHistoryKeepsNumericContextGated() async throws {
        let now = date("2026-01-15")
        let viewModel = StockDetailHistoryActivationViewModel { _, _ in
            result(
                closes: [100, 101, 102],
                source: .provider,
                provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: now),
                requestedStart: date("2026-01-01"),
                requestedEnd: now
            )
        }

        let didLoad = await viewModel.refresh(symbol: "AAPL", timeframe: .month)

        #expect(didLoad)
        #expect(viewModel.state.title == "Partial provider history")
        #expect(viewModel.state.message.contains("Provider returned a limited portion"))
        #expect(viewModel.state.contextRows.contains(StockDetailHistoryContextRow(
            title: "Cosmic correlation",
            status: "Numeric claims remain gated"
        )))
    }

    @Test("Stale history is labeled stale")
    func staleHistoryIsLabeledStale() async throws {
        let fetchedAt = date("2026-01-01")
        let viewModel = StockDetailHistoryActivationViewModel { _, _ in
            result(
                closes: [100, 101, 102, 103, 104],
                source: .cache,
                provenance: .cached(
                    provider: FinancialDataProvenance.finnhubProvider,
                    fetchedAt: fetchedAt,
                    age: FinancialDataProvenance.defaultCachedStaleInterval + 60
                ),
                requestedStart: date("2026-01-01"),
                requestedEnd: date("2026-01-05")
            )
        }

        let didLoad = await viewModel.refresh(symbol: "AAPL", timeframe: .month)

        #expect(didLoad)
        #expect(viewModel.state.title == "Stale cached history")
        #expect(viewModel.state.message.contains("stale provider-backed cache"))
        #expect(viewModel.state.contextRows.contains(StockDetailHistoryContextRow(
            title: "Technical lens",
            status: "Needs complete fresh history"
        )))
    }

    @Test("Successful history load refreshes stock detail state")
    func successfulHistoryLoadRefreshesState() async throws {
        let now = date("2026-01-15")
        let viewModel = StockDetailHistoryActivationViewModel { _, _ in
            result(
                closes: [100, 101, 102, 103, 104],
                source: .provider,
                provenance: .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: now),
                requestedStart: date("2026-01-01"),
                requestedEnd: date("2026-01-05")
            )
        }

        #expect(viewModel.state.title == "Provider history needed")

        let didLoad = await viewModel.refresh(symbol: "AAPL", timeframe: .year)

        #expect(didLoad)
        #expect(viewModel.state.title == "Provider history loaded")
        #expect(viewModel.state.actionTitle == "Refresh history")
        #expect(viewModel.state.contextRows.contains(StockDetailHistoryContextRow(
            title: "Chart",
            status: "Provider history available"
        )))
    }

    private func result(
        closes: [Double],
        source: HistoricalPriceSource,
        provenance: FinancialDataProvenance,
        requestedStart: Date,
        requestedEnd: Date
    ) -> HistoricalPriceResult {
        let dataset = HistoricalPriceDataset.providerBacked(
            symbol: "AAPL",
            candles: prices(closes, start: requestedStart),
            provider: provenance.provider ?? FinancialDataProvenance.finnhubProvider,
            fetchedAt: provenance.fetchedAt ?? requestedEnd,
            requestedRange: DateInterval(start: requestedStart, end: requestedEnd),
            provenance: provenance
        )
        return HistoricalPriceResult(dataset: dataset, source: source)
    }

    private func prices(_ closes: [Double], start: Date) -> [OHLCData] {
        closes.enumerated().map { index, close in
            OHLCData(
                date: Calendar.current.date(byAdding: .day, value: index, to: start) ?? start,
                open: close,
                high: close + 1,
                low: max(0.01, close - 1),
                close: close,
                volume: 1_000
            )
        }
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
