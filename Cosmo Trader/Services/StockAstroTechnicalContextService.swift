import Foundation

enum StockAstroTechnicalDisplayMode: Equatable {
    case combinedContext
    case technicalOnly
    case cosmicOnly
    case unavailable
}

struct StockAstroTechnicalContext: Equatable {
    let symbol: String
    let cards: [StockAstroTechnicalContextCard]
    let technicalProvenance: FinancialDataProvenance
    let cosmicProvenance: FinancialDataProvenance
    let technicalCompleteness: HistoricalDatasetCompleteness
    let cosmicCompleteness: HistoricalDatasetCompleteness
    let footer: String

    var hasCombinedNumericClaims: Bool {
        cards.contains { $0.includesCombinedNumericContext }
    }
}

struct StockAstroTechnicalContextCard: Identifiable, Equatable {
    let id: String
    let title: String
    let iconSystemName: String
    let displayMode: StockAstroTechnicalDisplayMode
    let technicalText: String
    let cosmicText: String
    let contextText: String
    let includesCombinedNumericContext: Bool
}

final class StockAstroTechnicalContextService {
    static let shared = StockAstroTechnicalContextService()

    private init() {}

    func context(
        symbol: String,
        technicalSummary: StockTechnicalSummary,
        cosmicSummaries: [StockCosmicCorrelationSummary],
        cosmicProvenance: FinancialDataProvenance,
        cosmicCompleteness: HistoricalDatasetCompleteness
    ) -> StockAstroTechnicalContext {
        let normalizedSymbol = symbol.uppercased()
        let technicalMetrics = eligibleTechnicalMetrics(from: technicalSummary)
        let cosmicSummary = preferredCosmicSummary(from: cosmicSummaries)
        let cosmicMetrics = eligibleCosmicSummary(
            cosmicSummary,
            provenance: cosmicProvenance,
            completeness: cosmicCompleteness
        )

        let cards = [
            trendCard(
                symbol: normalizedSymbol,
                metrics: technicalMetrics,
                cosmicSummary: cosmicSummary,
                cosmicMetrics: cosmicMetrics
            ),
            momentumCard(
                metrics: technicalMetrics,
                cosmicSummary: cosmicSummary,
                cosmicMetrics: cosmicMetrics
            ),
            volumeCard(
                metrics: technicalMetrics,
                cosmicSummary: cosmicSummary,
                cosmicMetrics: cosmicMetrics
            ),
            volatilityCard(
                metrics: technicalMetrics,
                cosmicSummary: cosmicSummary,
                cosmicMetrics: cosmicMetrics
            )
        ]

        return StockAstroTechnicalContext(
            symbol: normalizedSymbol,
            cards: cards,
            technicalProvenance: technicalSummary.provenance,
            cosmicProvenance: cosmicSummary?.provenance ?? cosmicProvenance,
            technicalCompleteness: technicalSummary.completeness,
            cosmicCompleteness: cosmicCompleteness,
            footer: "Historical astro-technical context only. Not predictive and not financial advice."
        )
    }

    func unavailableContext(symbol: String, reason: String) -> StockAstroTechnicalContext {
        let provenance = FinancialDataProvenance.unavailable(reason: reason)
        let completeness = HistoricalDatasetCompleteness.insufficient(reason: reason)
        let card = StockAstroTechnicalContextCard(
            id: "unavailable",
            title: "Astro-technical context",
            iconSystemName: "sparkles.rectangle.stack",
            displayMode: .unavailable,
            technicalText: "Technical lens needs complete provider-backed candles.",
            cosmicText: "Cosmic lens needs enough gated historical event observations.",
            contextText: "\(reason). Load provider-backed history to unlock the combined view.",
            includesCombinedNumericContext: false
        )

        return StockAstroTechnicalContext(
            symbol: symbol.uppercased(),
            cards: [card],
            technicalProvenance: provenance,
            cosmicProvenance: provenance,
            technicalCompleteness: completeness,
            cosmicCompleteness: completeness,
            footer: "Historical astro-technical context only. Not predictive and not financial advice."
        )
    }

    private func eligibleTechnicalMetrics(from summary: StockTechnicalSummary) -> StockTechnicalMetrics? {
        guard case .providerBacked = summary.displayMode,
              summary.provenance.isProviderBacked,
              !summary.provenance.isCachedStale(),
              case .complete = summary.completeness else {
            return nil
        }
        return summary.metrics
    }

    private func preferredCosmicSummary(
        from summaries: [StockCosmicCorrelationSummary]
    ) -> StockCosmicCorrelationSummary? {
        summaries.first { $0.displayMode == .marketBackedResult }
            ?? summaries.first { $0.displayMode == .insufficientSample }
            ?? summaries.first
    }

    private func eligibleCosmicSummary(
        _ summary: StockCosmicCorrelationSummary?,
        provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness
    ) -> StockCosmicCorrelationSummary? {
        guard let summary,
              summary.displayMode == .marketBackedResult,
              summary.provenance.isProviderBacked,
              !summary.provenance.isCachedStale(),
              provenance.isProviderBacked,
              !provenance.isCachedStale(),
              case .complete = completeness else {
            return nil
        }
        return summary
    }

    private func trendCard(
        symbol: String,
        metrics: StockTechnicalMetrics?,
        cosmicSummary: StockCosmicCorrelationSummary?,
        cosmicMetrics: StockCosmicCorrelationSummary?
    ) -> StockAstroTechnicalContextCard {
        let technicalText: String
        if let metrics {
            technicalText = "Technical lens: \(trendText(metrics))."
        } else {
            technicalText = "Technical lens needs complete fresh provider candles."
        }

        return card(
            id: "trend",
            title: "Trend + cosmic lens",
            icon: "chart.line.uptrend.xyaxis",
            metrics: metrics,
            cosmicSummary: cosmicSummary,
            cosmicMetrics: cosmicMetrics,
            technicalText: technicalText,
            combinedText: { summary in
                "Both lenses are available for \(symbol): \(summary.eventName) history has \(summary.sampleSize) observations over \(summary.window.displayName)."
            }
        )
    }

    private func momentumCard(
        metrics: StockTechnicalMetrics?,
        cosmicSummary: StockCosmicCorrelationSummary?,
        cosmicMetrics: StockCosmicCorrelationSummary?
    ) -> StockAstroTechnicalContextCard {
        let technicalText: String
        if let rsi = metrics?.rsi14 {
            technicalText = "Momentum context: RSI 14D \(formatNumber(rsi)) is \(rsiBucket(rsi))."
        } else if metrics != nil {
            technicalText = "Momentum context needs enough provider candles for RSI."
        } else {
            technicalText = "Momentum context needs complete fresh provider candles."
        }

        return card(
            id: "momentum",
            title: "Momentum + event sample",
            icon: "waveform.path.ecg",
            metrics: metrics,
            cosmicSummary: cosmicSummary,
            cosmicMetrics: cosmicMetrics,
            technicalText: technicalText,
            combinedText: { summary in
                "Cosmic lens: \(summary.eventName) has a \(summary.confidence.displayName.lowercased()) for historical context."
            }
        )
    }

    private func volumeCard(
        metrics: StockTechnicalMetrics?,
        cosmicSummary: StockCosmicCorrelationSummary?,
        cosmicMetrics: StockCosmicCorrelationSummary?
    ) -> StockAstroTechnicalContextCard {
        let technicalText: String
        if let volumeTrend = metrics?.volumeTrend {
            technicalText = "Volume context: \(volumeTrend.label.lowercased()) from provider candles."
        } else if metrics != nil {
            technicalText = "Volume context needs provider volume observations."
        } else {
            technicalText = "Volume context needs complete fresh provider candles."
        }

        return card(
            id: "volume",
            title: "Volume + event window",
            icon: "chart.bar.xaxis",
            metrics: metrics,
            cosmicSummary: cosmicSummary,
            cosmicMetrics: cosmicMetrics,
            technicalText: technicalText,
            combinedText: { summary in
                "Cosmic lens: event windows use \(summary.window.displayName) around \(summary.eventName)."
            }
        )
    }

    private func volatilityCard(
        metrics: StockTechnicalMetrics?,
        cosmicSummary: StockCosmicCorrelationSummary?,
        cosmicMetrics: StockCosmicCorrelationSummary?
    ) -> StockAstroTechnicalContextCard {
        let technicalText: String
        if let volatility = metrics?.volatility {
            technicalText = "Volatility context: \(volatility.label.lowercased()) from \(volatility.sampleDays) observations."
        } else if metrics != nil {
            technicalText = "Volatility context needs enough provider return observations."
        } else {
            technicalText = "Volatility context needs complete fresh provider candles."
        }

        return card(
            id: "volatility",
            title: "Volatility + cosmic context",
            icon: "scope",
            metrics: metrics,
            cosmicSummary: cosmicSummary,
            cosmicMetrics: cosmicMetrics,
            technicalText: technicalText,
            combinedText: { summary in
                guard let averageReturn = summary.averageReturn,
                      let baselineReturn = summary.baselineReturn else {
                    return "Cosmic lens: numeric event-window context is not available for this event."
                }
                return "Combined context: \(summary.eventName) average window \(formatPercent(averageReturn)) vs baseline \(formatPercent(baselineReturn))."
            }
        )
    }

    private func card(
        id: String,
        title: String,
        icon: String,
        metrics: StockTechnicalMetrics?,
        cosmicSummary: StockCosmicCorrelationSummary?,
        cosmicMetrics: StockCosmicCorrelationSummary?,
        technicalText: String,
        combinedText: (StockCosmicCorrelationSummary) -> String
    ) -> StockAstroTechnicalContextCard {
        let displayMode: StockAstroTechnicalDisplayMode
        let cosmicText: String
        let contextText: String
        let includesCombinedNumericContext: Bool

        switch (metrics, cosmicMetrics, cosmicSummary) {
        case (.some, .some(let summary), _):
            displayMode = .combinedContext
            cosmicText = "Cosmic lens: \(summary.eventName) history passes provider and sample-size gates."
            contextText = combinedText(summary)
            includesCombinedNumericContext = contextText.contains("%")
        case (.some, nil, .some(let summary)):
            displayMode = .technicalOnly
            cosmicText = "Cosmic lens: \(summary.disclaimer)"
            contextText = "Review the technical side as historical context. Combined numeric context stays hidden until the cosmic sample and provenance gates pass."
            includesCombinedNumericContext = false
        case (.some, nil, nil):
            displayMode = .technicalOnly
            cosmicText = "Cosmic lens needs provider-backed history and event observations."
            contextText = "Review the technical side as historical context. Combined numeric context stays hidden until the cosmic lens is available."
            includesCombinedNumericContext = false
        case (nil, .some(let summary), _):
            displayMode = .cosmicOnly
            cosmicText = "Cosmic lens: \(summary.eventName) history passes provider and sample-size gates."
            contextText = "Technical context is unavailable, so no combined numeric context is shown."
            includesCombinedNumericContext = false
        default:
            displayMode = .unavailable
            cosmicText = cosmicSummary?.disclaimer ?? "Cosmic lens needs enough provider-backed event observations."
            contextText = "Load or refresh provider history to unlock the astro-technical view."
            includesCombinedNumericContext = false
        }

        return StockAstroTechnicalContextCard(
            id: id,
            title: title,
            iconSystemName: icon,
            displayMode: displayMode,
            technicalText: technicalText,
            cosmicText: cosmicText,
            contextText: contextText,
            includesCombinedNumericContext: includesCombinedNumericContext
        )
    }

    private func trendText(_ metrics: StockTechnicalMetrics) -> String {
        if let average50 = metrics.movingAverage50 {
            return metrics.latestClose >= average50 ? "price is above its 50D average" : "price is below its 50D average"
        }
        if let average20 = metrics.movingAverage20 {
            return metrics.latestClose >= average20 ? "price is above its 20D average" : "price is below its 20D average"
        }
        return "moving average context needs more candles"
    }

    private func rsiBucket(_ value: Double) -> String {
        switch value {
        case 70...:
            return "elevated context"
        case ..<30:
            return "low context"
        default:
            return "balanced context"
        }
    }

    private func formatNumber(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f%%", value))"
    }
}
