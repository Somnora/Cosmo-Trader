import Foundation

@MainActor
@Observable
final class HistoricalAstroChartViewModel {
    var ohlcData: [OHLCData] = []
    var overlayEvents: [AstroOverlayEvent] = []
    var reactions: [AstroEventPriceReaction] = []
    var summaries: [StockCosmicCorrelationSummary] = []
    var selectedEvent: AstroOverlayEvent?
    var filterState = AstroOverlayFilterState()
    var historicalPriceProvenance: FinancialDataProvenance = .unavailable(reason: "Historical price data unavailable")
    var historicalDatasetCompleteness: HistoricalDatasetCompleteness = .insufficient(reason: "Historical price data unavailable")
    var chartDataQuality: HistoricalChartDataQuality = .unavailable
    var isLoading = false
    var errorMessage: String?

    private var loadedStock: Stock?
    private var loadedTimeframe: ChartTimeframe?

    var priceRange: ClosedRange<Double> {
        let prices = ohlcData.flatMap { [$0.low, $0.high, $0.close] }.filter { $0.isFinite && $0 > 0 }
        guard let minPrice = prices.min(), let maxPrice = prices.max() else { return 0...1 }
        let spread = max(maxPrice - minPrice, max(abs(maxPrice), 1) * 0.01)
        let padding = spread * 0.12
        return (minPrice - padding)...(maxPrice + padding)
    }

    var chartColor: ColorDirection {
        guard let first = ohlcData.first?.close,
              let last = ohlcData.last?.close else { return .positive }
        return last >= first ? .positive : .negative
    }

    var selectedReaction: AstroEventPriceReaction? {
        guard let selectedEvent else { return nil }
        return reactions.first { $0.event.id == selectedEvent.id }
    }

    var canShowCorrelationMetrics: Bool {
        historicalPriceProvenance.isProviderBacked
            && !historicalPriceProvenance.isCachedStale()
            && historicalDatasetCompleteness.allowsNumericCorrelationClaims
            && chartDataQuality.canRenderChart
    }

    var canRenderHistoricalChart: Bool {
        chartDataQuality.canRenderChart
    }

    var chartUnavailableTitle: String {
        chartDataQuality.unavailableTitle
    }

    var chartUnavailableMessage: String {
        chartDataQuality.unavailableMessage
    }

    var shouldShowHistoryActivation: Bool {
        guard !isLoading else { return false }
        if ohlcData.isEmpty { return true }
        if historicalPriceProvenance.isCachedStale() { return true }
        if !historicalDatasetCompleteness.allowsNumericCorrelationClaims { return true }
        if case .sample = historicalPriceProvenance { return true }
        if case .mixed = historicalPriceProvenance { return true }
        if case .unavailable = historicalPriceProvenance { return true }
        return false
    }

    var historyActivationTitle: String {
        if ohlcData.isEmpty { return "Load provider history" }
        if historicalPriceProvenance.isCachedStale() { return "Refresh stale history" }
        if !historicalDatasetCompleteness.allowsNumericCorrelationClaims { return "Refresh history range" }
        return "Refresh provider history"
    }

    var historyActivationDetail: String {
        if ohlcData.isEmpty {
            return "Chart, technical context, and cosmic correlation unlock after provider-backed historical prices are available."
        }
        if historicalPriceProvenance.isCachedStale() {
            return "Cached provider history is stale. Refresh checks the provider/cache path again."
        }
        if !historicalDatasetCompleteness.allowsNumericCorrelationClaims {
            return "Provider history exists, but the dataset is partial or insufficient for numeric context."
        }
        if case .sample = historicalPriceProvenance {
            return "Sample chart context is preview-only. Refresh uses provider-backed history only."
        }
        return "Refresh checks provider-backed history without creating sample candles."
    }

    var checkedEventKinds: [AstroOverlayEventKind] {
        let orderedKinds = AstroOverlayFilterState.defaultKinds + AstroOverlayFilterState.optionalKinds
        return orderedKinds.filter { filterState.enabledKinds.contains($0) }
    }

    var windowLabel: String {
        CorrelationWindow(daysBefore: 1, daysAfter: max(1, filterState.eventWindowDays)).displayName
    }

    var visibleLegendKinds: [AstroOverlayEventKind] {
        let priority: [AstroOverlayEventKind] = [
            .fullMoon,
            .newMoon,
            .mercuryRetrograde,
            .companyFoundingAnniversary,
            .companyBirthMonth,
            .moonInSign,
            .firstQuarter,
            .lastQuarter,
            .eclipse,
            .planetaryIngress
        ]
        let presentKinds = Set(overlayEvents.map(\.kind))
        return priority.filter { presentKinds.contains($0) }
    }

    func load(stock: Stock, timeframe: ChartTimeframe) async {
        loadedStock = stock
        loadedTimeframe = timeframe
        isLoading = true
        errorMessage = nil

        #if DEBUG
        if AppState.isScreenshotMode && !AppState.usesProviderBackedChartFixture {
            let prices = Self.demoPrices(for: stock, timeframe: timeframe)
            historicalDatasetCompleteness = .complete
            historicalPriceProvenance = .sample(reason: "DEBUG screenshot fixture")
            chartDataQuality = HistoricalChartDataQuality(
                canRenderChart: true,
                provenance: historicalPriceProvenance,
                completeness: .complete,
                unavailableTitle: "",
                unavailableMessage: ""
            )
            apply(prices: prices, stock: stock, provenance: historicalPriceProvenance)
            isLoading = false
            return
        }
        #endif

        do {
            let dataset = try await CorrelationDatasetStore.shared.dataset(
                symbol: stock.symbol,
                timeframe: timeframe
            )
            historicalDatasetCompleteness = dataset.completeness
            historicalPriceProvenance = dataset.correlationDisplayProvenance
            chartDataQuality = HistoricalChartDataQuality.evaluate(dataset: dataset)

            guard chartDataQuality.canRenderChart else {
                clearChartData()
                errorMessage = nil
                isLoading = false
                return
            }

            apply(
                prices: dataset.ohlcData,
                stock: stock,
                provenance: historicalPriceProvenance,
                completeness: dataset.completeness
            )
        } catch {
            ohlcData = []
            overlayEvents = []
            reactions = []
            summaries = []
            selectedEvent = nil
            historicalPriceProvenance = .unavailable(reason: "Historical price data unavailable")
            historicalDatasetCompleteness = .insufficient(reason: "Historical price data unavailable")
            chartDataQuality = .unavailable
            errorMessage = "Historical price data unavailable. Correlation context will appear when provider-backed history is available."
        }

        isLoading = false
    }

    func reload() async {
        guard let loadedStock, let loadedTimeframe else { return }
        await load(stock: loadedStock, timeframe: loadedTimeframe)
    }

    func toggleKinds(_ kinds: Set<AstroOverlayEventKind>) {
        let allEnabled = kinds.allSatisfy { filterState.enabledKinds.contains($0) }
        if allEnabled {
            filterState.enabledKinds.subtract(kinds)
        } else {
            filterState.enabledKinds.formUnion(kinds)
        }
        recalculate()
    }

    func select(event: AstroOverlayEvent) {
        selectedEvent = event
    }

    func recalculate() {
        guard let stock = loadedStock else { return }
        apply(prices: ohlcData, stock: stock, provenance: historicalPriceProvenance)
    }

    // MARK: - Lookups for chart scrub

    /// Nearest candle to a scrubbed date. Used by the chart overlay to snap
    /// the gold scrub dot to the closest real data point.
    func nearestCandle(to date: Date) -> OHLCData? {
        guard !ohlcData.isEmpty else { return nil }
        return ohlcData.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    /// Nearest event within `tolerance` of `date`, or nil. Range events return
    /// 0 distance if the date is inside them, otherwise the distance to the
    /// closer endpoint.
    func nearestEvent(to date: Date, within tolerance: TimeInterval) -> AstroOverlayEvent? {
        guard !overlayEvents.isEmpty else { return nil }
        let scored = overlayEvents.map { event -> (event: AstroOverlayEvent, distance: TimeInterval) in
            (event, proximity(event, to: date))
        }
        guard let candidate = scored.min(by: { $0.distance < $1.distance }),
              candidate.distance <= tolerance else {
            return nil
        }
        return candidate.event
    }

    private func proximity(_ event: AstroOverlayEvent, to date: Date) -> TimeInterval {
        if event.isRange, let end = event.endDate {
            if date >= event.startDate && date <= end { return 0 }
            return min(abs(date.timeIntervalSince(event.startDate)),
                       abs(date.timeIntervalSince(end)))
        }
        return abs(date.timeIntervalSince(event.markerDate))
    }

    // MARK: - Internal apply

    private func apply(prices: [OHLCData], stock: Stock, provenance: FinancialDataProvenance) {
        apply(prices: prices, stock: stock, provenance: provenance, completeness: historicalDatasetCompleteness)
    }

    private func apply(
        prices: [OHLCData],
        stock: Stock,
        provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness
    ) {
        ohlcData = prices.sorted { $0.date < $1.date }
        historicalPriceProvenance = provenance
        historicalDatasetCompleteness = completeness

        guard let firstDate = ohlcData.first?.date,
              let lastDate = ohlcData.last?.date else {
            overlayEvents = []
            reactions = []
            summaries = []
            selectedEvent = nil
            return
        }

        let events = AstroOverlayEventService.shared.events(
            for: stock,
            from: firstDate,
            to: lastDate,
            filters: filterState
        )

        overlayEvents = events
        reactions = AstroCorrelationService.shared.eventReactions(
            prices: ohlcData,
            events: events,
            filterState: filterState
        )
        summaries = AstroCorrelationService.shared.stockSummaries(
            symbol: stock.symbol,
            prices: ohlcData,
            events: events,
            filterState: filterState,
            provenance: provenance,
            completeness: completeness
        )

        if let selectedEvent, events.contains(where: { $0.id == selectedEvent.id }) {
            self.selectedEvent = selectedEvent
        } else {
            self.selectedEvent = preferredInitialEvent(in: events)
        }
    }

    private func clearChartData() {
        ohlcData = []
        overlayEvents = []
        reactions = []
        summaries = []
        selectedEvent = nil
    }

    /// Pick a narratively useful default selection.
    ///
    /// In screenshot mode, prefer events that produce a meaningful reaction
    /// readout (Mercury Rx with multi-day windows, Full Moons, Founding Day),
    /// then fall back to whichever event has the largest absolute move.
    private func preferredInitialEvent(in events: [AstroOverlayEvent]) -> AstroOverlayEvent? {
        guard !events.isEmpty else { return nil }

        let preferredOrder: [AstroOverlayEventKind] = [
            .mercuryRetrograde,
            .fullMoon,
            .companyFoundingAnniversary,
            .newMoon,
            .companyBirthMonth
        ]

        if AppState.isScreenshotMode {
            if let strongest = reactions.max(by: { abs($0.returnPercent) < abs($1.returnPercent) }) {
                return strongest.event
            }
            for kind in preferredOrder {
                if let candidate = events.first(where: { $0.kind == kind }) {
                    return candidate
                }
            }
        }

        return events.first
    }

    // MARK: - Demo data for screenshot mode

    #if DEBUG
    /// Deterministic random walk anchored to the stock's current price.
    /// Replaces the previous obvious sine wave so screenshots read as real
    /// price action rather than a math curve.
    static func demoPrices(for stock: Stock, timeframe: ChartTimeframe) -> [OHLCData] {
        let calendar = Calendar.current
        let end = Date()
        let days: Int = {
            switch timeframe {
            case .day: return 30
            case .week: return 45
            case .month: return 62
            case .threeMonth: return 92
            case .sixMonth: return 182
            case .year: return 180
            case .twoYear: return 504
            case .all: return 365
            }
        }()

        // Seed off the symbol so the same stock always produces the same chart.
        var seed = UInt64(truncatingIfNeeded: stock.symbol.unicodeScalars.reduce(UInt64(1469598103934665603)) { hash, scalar in
            (hash &* 1099511628211) ^ UInt64(scalar.value)
        })
        if seed == 0 { seed = 0xDEADBEEF }

        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let bits = (seed >> 33) & 0xFFFFFFFF
            let normalized = Double(bits) / Double(UInt32.max)
            return normalized * 2 - 1
        }

        // Warm up the RNG so the first few draws don't anchor an extreme run.
        for _ in 0..<6 { _ = next() }

        let basePrice = max(1.0, stock.currentPrice * 0.93)
        var closes: [Double] = []
        var current = basePrice
        for _ in 0..<days {
            // Modest volatility with a small upward drift produces a chart
            // that looks like a normal stock month without dramatic moves.
            let dailyReturn = next() * 0.011 + 0.0014
            current = max(0.5, current * (1 + dailyReturn))
            closes.append(current)
        }

        // Soft clamp: if the start-to-end move is wildly off a typical month,
        // dampen it by blending toward a more average trajectory. Keeps the
        // chart honest while preventing once-in-a-decade demo outliers.
        if let first = closes.first, let last = closes.last, first > 0 {
            let move = (last - first) / first
            if move < -0.12 || move > 0.22 {
                let targetMove = max(-0.05, min(0.10, move * 0.4))
                let blendFactor = (targetMove - move) / Double(max(1, days - 1))
                for i in 0..<closes.count {
                    closes[i] *= (1 + blendFactor * Double(i))
                }
            }
        }

        // Anchor the last close to the stock's actual current price so the
        // chart reconciles with the header price card.
        if let last = closes.last, last > 0, stock.currentPrice > 0 {
            let scale = stock.currentPrice / last
            closes = closes.map { $0 * scale }
        }

        return (0..<days).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: -(days - 1 - index), to: end) else {
                return nil
            }
            let close = closes[index]
            let intradayRange = max(0.5, close * 0.012)
            return OHLCData(
                date: date,
                open: close - intradayRange * 0.4,
                high: close + intradayRange,
                low: max(0.01, close - intradayRange * 1.2),
                close: close,
                volume: 800_000 + (index * 12_500)
            )
        }
    }
    #endif
}

enum ColorDirection {
    case positive
    case negative
}
