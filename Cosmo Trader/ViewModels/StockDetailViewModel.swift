import Foundation

/// Owns the provider-backed data loading for the Stock Detail screen: the
/// live quote, key stats, technical analysis, and cosmic pattern insights.
///
/// `StockDetailView` renders this state and forwards user intents; it holds
/// no fetch orchestration of its own. This is the extraction pattern for
/// the app's large views — see AGENTS.md ("Views render, view models load").
@MainActor
@Observable
final class StockDetailViewModel {

    /// The stock this screen was opened with (stored local snapshot).
    let stock: Stock

    // MARK: - Rendered State

    /// Stored stock updated with the live quote once it arrives.
    private(set) var liveStock: Stock
    private(set) var isLoadingPrice = false
    private(set) var lastPriceUpdate: Date?
    private(set) var priceError: NetworkError?
    private(set) var priceProvenance: FinancialDataProvenance = .sample(reason: "Stored local price until provider quote loads")

    private(set) var keyStats: StockKeyStats?
    private(set) var keyStatsProvenance: FinancialDataProvenance = .unavailable(reason: "Provider fundamentals unavailable")

    private(set) var technicalSummary: StockTechnicalSummary
    private(set) var astroTechnicalContext: StockAstroTechnicalContext
    private(set) var isLoadingTechnicalAnalysis: Bool = !AppState.isScreenshotMode

    private(set) var cosmicInsights: [CosmicPatternInsight] = []
    private(set) var isLoadingPatterns: Bool = !AppState.isScreenshotMode

    // MARK: - Dependencies

    private let stockAPIService: StockAPIService
    private let historicalPriceService: HistoricalPriceService
    private let technicalAnalysisService: StockTechnicalAnalysisService
    private let overlayEventService: AstroOverlayEventService
    private let astroCorrelationService: AstroCorrelationService
    private let astroTechnicalContextService: StockAstroTechnicalContextService
    private let patternInterpreter: CosmicPatternInterpreter

    init(
        stock: Stock,
        stockAPIService: StockAPIService? = nil,
        historicalPriceService: HistoricalPriceService? = nil,
        technicalAnalysisService: StockTechnicalAnalysisService? = nil,
        overlayEventService: AstroOverlayEventService? = nil,
        astroCorrelationService: AstroCorrelationService? = nil,
        astroTechnicalContextService: StockAstroTechnicalContextService? = nil,
        patternInterpreter: CosmicPatternInterpreter? = nil
    ) {
        let technicalService = technicalAnalysisService ?? StockTechnicalAnalysisService.shared
        let contextService = astroTechnicalContextService ?? StockAstroTechnicalContextService.shared

        self.stock = stock
        self.liveStock = stock
        self.stockAPIService = stockAPIService ?? StockAPIService.shared
        self.historicalPriceService = historicalPriceService ?? HistoricalPriceService.shared
        self.technicalAnalysisService = technicalService
        self.overlayEventService = overlayEventService ?? AstroOverlayEventService.shared
        self.astroCorrelationService = astroCorrelationService ?? AstroCorrelationService.shared
        self.astroTechnicalContextService = contextService
        self.patternInterpreter = patternInterpreter ?? CosmicPatternInterpreter.shared

        self.technicalSummary = technicalService.unavailableSummary(
            symbol: stock.symbol,
            reason: "Provider-backed historical candles not loaded"
        )
        self.astroTechnicalContext = contextService.unavailableContext(
            symbol: stock.symbol,
            reason: "Provider-backed historical candles not loaded"
        )
    }

    // MARK: - Loading

    /// Initial load for the screen: price and key stats are independent of
    /// each other; technical and cosmic context read `liveStock`, so they
    /// start once the quote has landed.
    func loadInitialContent(companySign: ZodiacSign?, userSign: ZodiacSign) async {
        if AppState.isScreenshotMode {
            isLoadingPrice = false
            isLoadingPatterns = false
            return
        }

        async let priceTask: Void = fetchLivePrice()
        async let statsTask: Void = fetchKeyStats()
        _ = await (priceTask, statsTask)

        async let technicalTask: Void = loadTechnicalAnalysis()
        async let cosmicTask: Void = loadCosmicPatterns(companySign: companySign, userSign: userSign)
        _ = await (technicalTask, cosmicTask)
    }

    func fetchLivePrice() async {
        isLoadingPrice = true
        priceError = nil

        let result = await stockAPIService.getQuoteWithProvenance(symbol: stock.symbol)

        if let quote = result.quote {
            liveStock = stock.withQuote(quote)
            lastPriceUpdate = result.provenance.fetchedAt ?? Date()
            priceProvenance = result.provenance
        } else {
            priceProvenance = .sample(reason: "Stored local price; provider quote unavailable")
        }
        if let error = result.error {
            priceError = error
        }
        isLoadingPrice = false
    }

    func fetchKeyStats() async {
        let result = await stockAPIService.fetchKeyStatsResult(symbol: stock.symbol)
        keyStats = result.value
        keyStatsProvenance = result.provenance
    }

    func loadTechnicalAnalysis() async {
        isLoadingTechnicalAnalysis = true

        do {
            let result = try await historicalPriceService.fetchHistoricalPriceResult(
                symbol: liveStock.symbol,
                timeframe: .year
            )
            let summary = technicalAnalysisService.summary(for: result.dataset)
            let filters = AstroOverlayFilterState()
            let prices = result.dataset.ohlcData
            let events: [AstroOverlayEvent]
            if let firstDate = prices.first?.date,
               let lastDate = prices.last?.date {
                events = overlayEventService.events(
                    for: liveStock,
                    from: firstDate,
                    to: lastDate,
                    filters: filters
                )
            } else {
                events = []
            }
            let cosmicProvenance = result.dataset.correlationDisplayProvenance
            let cosmicSummaries = astroCorrelationService.stockSummaries(
                symbol: liveStock.symbol,
                prices: prices,
                events: events,
                filterState: filters,
                provenance: cosmicProvenance,
                completeness: result.dataset.completeness
            )
            let combinedContext = astroTechnicalContextService.context(
                symbol: liveStock.symbol,
                technicalSummary: summary,
                cosmicSummaries: cosmicSummaries,
                cosmicProvenance: cosmicProvenance,
                cosmicCompleteness: result.dataset.completeness
            )

            technicalSummary = summary
            astroTechnicalContext = combinedContext
            isLoadingTechnicalAnalysis = false
        } catch {
            technicalSummary = technicalAnalysisService.unavailableSummary(
                symbol: liveStock.symbol,
                reason: "Provider-backed historical candles unavailable"
            )
            astroTechnicalContext = astroTechnicalContextService.unavailableContext(
                symbol: liveStock.symbol,
                reason: "Provider-backed historical candles unavailable"
            )
            isLoadingTechnicalAnalysis = false
        }
    }

    func loadCosmicPatterns(companySign: ZodiacSign?, userSign: ZodiacSign) async {
        guard companySign != nil else {
            cosmicInsights = []
            isLoadingPatterns = false
            return
        }

        isLoadingPatterns = true

        let insights = await patternInterpreter.getProviderBackedInsights(
            for: liveStock,
            userSign: userSign
        )

        cosmicInsights = insights
        isLoadingPatterns = false
    }
}
