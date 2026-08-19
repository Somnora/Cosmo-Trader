import Foundation

struct TodayMarketHoroscopeSummary: Equatable {
    let date: Date
    let cosmicContext: TodayCosmicContext
    /// Where the market stands right now, against its own record. Nil until
    /// provider-backed history for the anchor symbol is loaded.
    let marketState: TodayMarketStateContext?
    let marketContext: TodayMarketContext
    let portfolioContext: TodayPortfolioContext
    let stockContext: TodayStockContext?
    let firstRunSetup: TodayFirstRunSetupState
    let dataCoverage: TodayDataCoverage
    let primaryAction: TodayActivationPrompt?
    let provenance: FinancialDataProvenance
    let disclaimer: String
}

struct TodayFirstRunSetupState: Equatable {
    let isSkipped: Bool
    let steps: [TodayFirstRunSetupStep]

    var isComplete: Bool {
        !steps.isEmpty && steps.allSatisfy(\.isComplete)
    }

    var nextStep: TodayFirstRunSetupStep? {
        steps.first { !$0.isComplete }
    }
}

struct TodayFirstRunSetupStep: Equatable, Identifiable {
    let id: TodayFirstRunSetupStepID
    let title: String
    let detail: String
    let isComplete: Bool
    let actionTitle: String?
    let action: TodayFirstRunSetupAction?
}

enum TodayFirstRunSetupStepID: String, Equatable, Hashable {
    case watchlist
    case portfolio
    case providerHistory
    case labels
}

enum TodayFirstRunSetupAction: String, Equatable {
    case addWatchlist
    case addHolding
    case importPortfolio
    case loadProviderHistory
    case reviewLabels
}

/// One measured fact about the market's present, rendered for display.
struct TodayMarketStateReading: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
    let context: String
}

/// The state card: what the market is doing now, how unusual that is, and what
/// happened after the sessions that looked the same.
///
/// Deliberately has no forecast field. Two twenty-year sweeps found no lunar
/// or technical state that predicts the next week once overlap is discounted
/// and multiple comparisons are corrected, so the card reports the record and
/// says outright when the record shows nothing.
struct TodayMarketStateContext: Equatable {
    let symbol: String
    let headline: String
    let detail: String
    let readings: [TodayMarketStateReading]
    /// What happened after comparable sessions. Nil when too few of them exist.
    let historyHeadline: String?
    let historyDetail: String?
    /// Whether the historical gap clears its own margin of error, said plainly.
    let verdict: String?
    let provenance: FinancialDataProvenance
}

struct TodayCosmicContext: Equatable {
    let headline: String
    let detail: String
    let lunarLabel: String
    let mercuryLabel: String
    let marketToneLabel: String
    let activeEvents: [String]
    let provenance: FinancialDataProvenance
}

struct TodayMarketContext: Equatable {
    enum DisplayMode: Equatable {
        case marketBacked
        case partialContext
        case stale
        case insufficientSample
        case unavailable
        case sampleOnly
    }

    let headline: String
    let detail: String
    let eventName: String?
    let windowLabel: String?
    let eventCount: Int
    let sampleSize: Int
    let includedSymbols: [String]
    let excludedSymbols: [String]
    let staleSymbols: [String]
    let coverage: Double
    let metrics: [TodayMetric]
    let sectorBreadth: TodayMarketSectorBreadth?
    let provenance: FinancialDataProvenance
    let displayMode: DisplayMode
    let activation: TodayActivationPrompt?
}

struct TodayMarketSectorBreadth: Equatable {
    let headline: String
    let detail: String
    let eventName: String?
    let sampleSize: Int
    let coverage: Double
    let includedSymbols: [String]
    let excludedSymbols: [String]
    let staleSymbols: [String]
    let metrics: [TodayMetric]
    let provenance: FinancialDataProvenance
    let displayMode: CorrelationDisplayMode
}

struct TodayPortfolioContext: Equatable {
    enum DisplayMode: Equatable {
        case setupRequired
        case marketBacked
        case partialContext
        case insufficientCoverage
        case insufficientSample
        case unavailable
        case sampleOnly
    }

    let headline: String
    let detail: String
    let eventName: String?
    let windowLabel: String?
    let eventCount: Int
    let sampleSize: Int
    let includedPortfolioWeight: Double
    let excludedPortfolioWeight: Double
    let unavailableHoldings: [String]
    let metrics: [TodayMetric]
    let provenance: FinancialDataProvenance
    let displayMode: DisplayMode
    let activation: TodayActivationPrompt?
}

struct TodayStockContext: Equatable {
    enum DisplayMode: Equatable {
        case marketBacked
        case partialDataset
        case insufficientDataset
        case insufficientSample
        case unavailable
        case sampleOnly
    }

    let symbol: String
    let name: String
    let headline: String
    let detail: String
    let eventName: String?
    let windowLabel: String?
    let eventCount: Int
    let sampleSize: Int
    let metrics: [TodayMetric]
    let provenance: FinancialDataProvenance
    let displayMode: DisplayMode
    let source: TodayStockCandidateSource?
    let activation: TodayActivationPrompt?
}

struct TodayDataCoverage: Equatable {
    let headline: String
    let detail: String
    let rows: [TodayDataCoverageRow]
    let explainers: [TodayDataLabelExplainer]
}

struct TodayDataCoverageRow: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
    let provenance: FinancialDataProvenance

    init(label: String, value: String, provenance: FinancialDataProvenance) {
        self.id = label
        self.label = label
        self.value = value
        self.provenance = provenance
    }
}

struct TodayMetric: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String

    init(label: String, value: String) {
        self.id = label
        self.label = label
        self.value = value
    }
}

struct TodayActivationPrompt: Equatable {
    let title: String
    let detail: String
    let actionItems: [String]
    let primaryActionTitle: String
    let secondaryActionTitle: String?
    let tertiaryActionTitle: String?

    init(
        title: String,
        detail: String,
        actionItems: [String] = [],
        primaryActionTitle: String,
        secondaryActionTitle: String?,
        tertiaryActionTitle: String? = nil
    ) {
        self.title = title
        self.detail = detail
        self.actionItems = actionItems
        self.primaryActionTitle = primaryActionTitle
        self.secondaryActionTitle = secondaryActionTitle
        self.tertiaryActionTitle = tertiaryActionTitle
    }
}

struct TodayDataLabelExplainer: Equatable, Identifiable {
    let id: String
    let label: String
    let detail: String

    init(label: String, detail: String) {
        self.id = label
        self.label = label
        self.detail = detail
    }
}

enum TodayStockCandidateSource: Equatable {
    case watchlist
    case portfolio

    var displayName: String {
        switch self {
        case .watchlist:
            return "Watchlist"
        case .portfolio:
            return "Portfolio"
        }
    }
}

struct TodayStockCandidate: Equatable {
    let stock: Stock
    let summaries: [StockCosmicCorrelationSummary]
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness
    let source: TodayStockCandidateSource

    init(
        stock: Stock,
        summaries: [StockCosmicCorrelationSummary],
        provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness,
        source: TodayStockCandidateSource = .portfolio
    ) {
        self.stock = stock
        self.summaries = summaries
        self.provenance = provenance
        self.completeness = completeness
        self.source = source
    }
}
