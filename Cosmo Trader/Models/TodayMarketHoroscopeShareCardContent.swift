import Foundation

struct TodayMarketHoroscopeShareCardContent: Equatable {
    struct ContextLine: Equatable, Identifiable {
        let id: String
        let title: String
        let value: String
        let detail: String
        let provenance: FinancialDataProvenance
        let metrics: [TodayMetric]

        init(
            title: String,
            value: String,
            detail: String,
            provenance: FinancialDataProvenance,
            metrics: [TodayMetric]
        ) {
            self.id = title
            self.title = title
            self.value = value
            self.detail = detail
            self.provenance = provenance
            self.metrics = metrics
        }
    }

    let dateLabel: String
    let headline: String
    let marketLine: ContextLine
    let portfolioLine: ContextLine?
    let stockLine: ContextLine?
    let provenance: FinancialDataProvenance
    let provenanceLabel: String
    let provenanceDetail: String
    let footer: String
    let shareText: String

    var lines: [ContextLine] {
        [marketLine, portfolioLine, stockLine].compactMap { $0 }
    }

    var searchableText: String {
        let lineText = lines.flatMap { line in
            [
                line.title,
                line.value,
                line.detail,
                line.provenance.indicatorLabel,
                line.metrics.map { "\($0.label) \($0.value)" }.joined(separator: " ")
            ]
        }
        return ([dateLabel, headline, provenanceLabel, provenanceDetail, footer, shareText] + lineText)
            .joined(separator: "\n")
    }

    static func make(from summary: TodayMarketHoroscopeSummary) -> TodayMarketHoroscopeShareCardContent {
        let dateLabel = Self.dateFormatter.string(from: summary.date).uppercased()
        let marketLine = ContextLine(
            title: "MARKET WEATHER",
            value: summary.marketContext.shareStateLabel,
            detail: summary.marketContext.shareDetail,
            provenance: summary.marketContext.provenance,
            metrics: summary.marketContext.metrics
        )
        let portfolioLine = ContextLine(
            title: "PORTFOLIO LENS",
            value: summary.portfolioContext.shareStateLabel,
            detail: summary.portfolioContext.shareDetail,
            provenance: summary.portfolioContext.provenance,
            metrics: summary.portfolioContext.metrics
        )
        let stockLine = summary.stockContext.map { stockContext in
            ContextLine(
                title: stockContext.symbol == "WATCH" ? "WATCHLIST LENS" : "\(stockContext.symbol) LENS",
                value: stockContext.shareStateLabel,
                detail: stockContext.shareDetail,
                provenance: stockContext.provenance,
                metrics: stockContext.metrics
            )
        }
        let provenanceLabel = summary.provenance.indicatorLabel
        let provenanceDetail = summary.provenance.detailText
        let footer = "Historical context only. No forecast. Not financial advice."

        return TodayMarketHoroscopeShareCardContent(
            dateLabel: dateLabel,
            headline: "Daily Market Horoscope",
            marketLine: marketLine,
            portfolioLine: portfolioLine,
            stockLine: stockLine,
            provenance: summary.provenance,
            provenanceLabel: provenanceLabel,
            provenanceDetail: provenanceDetail,
            footer: footer,
            shareText: Self.shareText(
                dateLabel: dateLabel,
                market: marketLine,
                portfolio: portfolioLine,
                stock: stockLine,
                provenanceLabel: provenanceLabel,
                footer: footer
            )
        )
    }

    private static func shareText(
        dateLabel: String,
        market: ContextLine,
        portfolio: ContextLine?,
        stock: ContextLine?,
        provenanceLabel: String,
        footer: String
    ) -> String {
        let portfolioText = portfolio.map { "\($0.title): \($0.value)" } ?? "PORTFOLIO LENS: Unavailable"
        let stockText = stock.map { "\($0.title): \($0.value)" } ?? "STOCK LENS: Unavailable"

        return """
        Cosmo Trader Daily Market Horoscope - \(dateLabel)
        MARKET WEATHER: \(market.value)
        \(portfolioText)
        \(stockText)
        Source: \(provenanceLabel)
        \(footer)
        """
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

private extension TodayMarketContext {
    var shareStateLabel: String {
        switch displayMode {
        case .marketBacked:
            return eventName.map { "\($0) ready" } ?? "Market context ready"
        case .partialContext:
            return "Partial market context"
        case .stale:
            return "Stale market cache"
        case .insufficientSample:
            return "Thin market sample"
        case .unavailable:
            return "Market Weather unavailable"
        case .sampleOnly:
            return "Sample market context"
        }
    }

    var shareDetail: String {
        switch displayMode {
        case .marketBacked:
            return "Provider-backed basket history cleared the Market Weather gate."
        case .partialContext:
            return "Market Weather stays context-only until SPY, QQQ, DIA, and IWM all have usable history."
        case .stale:
            return "Cached basket history is stale under the current freshness policy."
        case .insufficientSample:
            return "Provider-backed market history exists, but event observations are still too thin."
        case .unavailable:
            return "SPY, QQQ, DIA, and IWM provider-backed history is not available yet."
        case .sampleOnly:
            return "Demo context only, not market data."
        }
    }
}

private extension TodayPortfolioContext {
    var shareStateLabel: String {
        switch displayMode {
        case .setupRequired:
            return "Portfolio setup needed"
        case .marketBacked:
            return eventName.map { "\($0) ready" } ?? "Portfolio context ready"
        case .partialContext:
            return "Partial portfolio context"
        case .insufficientCoverage:
            return "Portfolio coverage too thin"
        case .insufficientSample:
            return "Thin portfolio sample"
        case .unavailable:
            return "Portfolio history unavailable"
        case .sampleOnly:
            return "Sample portfolio context"
        }
    }

    var shareDetail: String {
        switch displayMode {
        case .setupRequired:
            return "Add or import holdings to unlock portfolio context."
        case .marketBacked:
            return "Provider-backed holding history cleared the portfolio coverage gate."
        case .partialContext:
            return "Portfolio metrics stay hidden until usable coverage reaches the required gate."
        case .insufficientCoverage:
            return "Provider-backed history covers too little portfolio value for context."
        case .insufficientSample:
            return "Portfolio history exists, but event observations are still too thin."
        case .unavailable:
            return "Provider-backed holding history is not available yet."
        case .sampleOnly:
            return "Demo context only, not portfolio data."
        }
    }
}

private extension TodayStockContext {
    var shareStateLabel: String {
        switch displayMode {
        case .marketBacked:
            return "\(symbol) context ready"
        case .partialDataset:
            return "\(symbol) partial history"
        case .insufficientDataset:
            return "\(symbol) thin history"
        case .insufficientSample:
            return "\(symbol) thin sample"
        case .unavailable:
            return symbol == "WATCH" ? "Watchlist setup needed" : "\(symbol) history unavailable"
        case .sampleOnly:
            return "\(symbol) sample context"
        }
    }

    var shareDetail: String {
        switch displayMode {
        case .marketBacked:
            return "Provider-backed stock history cleared the stock context gate."
        case .partialDataset:
            return "Some required provider-backed stock history is missing."
        case .insufficientDataset:
            return "Provider-backed stock history is not long enough yet."
        case .insufficientSample:
            return "Stock history exists, but event observations are still too thin."
        case .unavailable:
            return symbol == "WATCH"
                ? "Add a watchlist symbol or holding to unlock the stock lens."
                : "Provider-backed stock history is not available yet."
        case .sampleOnly:
            return "Demo context only, not stock data."
        }
    }
}
