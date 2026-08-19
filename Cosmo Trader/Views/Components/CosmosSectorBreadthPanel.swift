import SwiftUI

// MARK: - CosmosSectorBreadthPanel
// ================================
// The sector-breadth panel, lifted out of CosmosView so that view could take
// the free-tier reading limit without growing (view-size ratchet: views render
// state and forward intents).
//
// Its two copy helpers came with it because nothing else called them. The pill
// and percentage helpers did not: CosmosView still uses those seven other
// times, so this file carries its own rather than exporting them and giving
// two views a shared private detail to keep in step.

struct CosmosSectorBreadthPanel: View {

    let breadth: MarketSectorBreadthSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("SECTOR BREADTH")
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.5)

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: breadth.provenance, size: .compact)
            }

            Text(sectorBreadthHeadline(for: breadth))
                .font(TerminalFont.data(11, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(sectorBreadthDetail(for: breadth))
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                pill(label: "SECTORS", value: percentRate(breadth.coverage))
                pill(label: "EVENT", value: breadth.eventName ?? "Pending")
                pill(label: "SAMPLE", value: "\(breadth.sampleSize)")
            }

            if canShowSectorBreadthMetrics(breadth) {
                HStack(spacing: 8) {
                    pill(label: "AVG SECTOR", value: percent(breadth.averageSectorReturn))
                    pill(label: "ADVANCING", value: percentRate(breadth.advancingSectorRate))
                    pill(label: "WINDOW", value: breadth.window.displayName)
                }

                if !breadth.strongestSectors.isEmpty {
                    compactMarketWeatherSymbols(
                        label: "Firmest",
                        symbols: breadth.strongestSectors.map { "\($0.symbol) \(percent($0.returnPercent))" },
                        color: CosmicTheme.positive
                    )
                }

                if !breadth.weakestSectors.isEmpty {
                    compactMarketWeatherSymbols(
                        label: "Softest",
                        symbols: breadth.weakestSectors.map { "\($0.symbol) \(percent($0.returnPercent))" },
                        color: CosmicTheme.textMuted
                    )
                }
            }

            if !breadth.staleSymbols.isEmpty {
                compactMarketWeatherSymbols(label: "Stale sectors", symbols: breadth.staleSymbols, color: CosmicTheme.gold)
            }

            if !breadth.excludedSymbols.isEmpty {
                compactMarketWeatherSymbols(label: "Unavailable sectors", symbols: breadth.excludedSymbols, color: CosmicTheme.textMuted)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.panelElevated.opacity(0.78))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func sectorBreadthHeadline(for breadth: MarketSectorBreadthSummary) -> String {
        switch breadth.displayMode {
        case .marketBackedResult:
            return "Sector breadth context is ready"
        case .partialCoverage, .partialDataset:
            return "Sector breadth is partial context only"
        case .insufficientSample:
            return "Sector breadth needs more observations"
        case .insufficientDataset:
            return "Sector breadth history is insufficient"
        case .sampleOnly:
            return "Sample sector history is labeled"
        case .unavailable:
            return "Sector breadth unavailable"
        }
    }

    private func sectorBreadthDetail(for breadth: MarketSectorBreadthSummary) -> String {
        switch breadth.displayMode {
        case .marketBackedResult:
            return "Sector ETFs use complete provider-backed history for \(breadth.eventName ?? "the selected event"). Historical context only, not a prediction."
        case .partialCoverage, .partialDataset:
            return "Provider-backed sector coverage is \(percentRate(breadth.coverage)). Full sector coverage is required before sector metrics appear."
        case .insufficientSample:
            return "Sector ETF history exists, but this event does not have enough observations for a sector metric."
        case .insufficientDataset, .sampleOnly, .unavailable:
            return breadth.disclaimer
        }
    }

    private func canShowSectorBreadthMetrics(_ breadth: MarketSectorBreadthSummary) -> Bool {
        guard breadth.coverage >= 1 else { return false }
        if case .marketBackedResult = breadth.displayMode {
            return breadth.provenance.isProviderBacked && !breadth.provenance.isCachedStale()
        }
        return false
    }

    private func pill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func percentRate(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "N/A" }
        return String(format: "%.0f%%", value * 100)
    }

    private func percent(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "N/A" }
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }

    private func compactMarketWeatherSymbols(label: String, symbols: [String], color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label.uppercased())
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(color)
                .tracking(0.4)

            Text(symbols.joined(separator: " / "))
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
    }
}
