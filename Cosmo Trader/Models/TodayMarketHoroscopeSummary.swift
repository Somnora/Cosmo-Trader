import Foundation

struct TodayMarketHoroscopeSummary: Equatable {
    let date: Date
    let cosmicContext: TodayCosmicContext
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

struct TodayStockCandidate: Equatable {
    let stock: Stock
    let summaries: [StockCosmicCorrelationSummary]
    let provenance: FinancialDataProvenance
    let completeness: HistoricalDatasetCompleteness
}
