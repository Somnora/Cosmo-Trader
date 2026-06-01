import SwiftUI

struct TodayMarketHoroscopeView: View {
    let viewModel: TodayMarketHoroscopeViewModel
    let setupAction: () -> Void

    var body: some View {
        Group {
            if let summary = viewModel.summary {
                summaryContent(summary)
            } else {
                loadingContent
            }
        }
        .accessibilityIdentifier("today.marketHoroscope")
    }

    private func summaryContent(_ summary: TodayMarketHoroscopeSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            header(summary)
            cosmicBlock(summary.cosmicContext)
            marketBlock(summary.marketContext)
            portfolioBlock(summary.portfolioContext)

            if let stockContext = summary.stockContext {
                stockBlock(stockContext)
            } else {
                unavailableBlock(
                    title: "STOCK / WATCHLIST LENS",
                    message: "Add a holding or watchlist symbol so Today can surface one provider-backed historical stock pattern."
                )
            }

            dataCoverageBlock(summary.dataCoverage)

            Text(summary.disclaimer)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(CosmicTheme.terminalBlack)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(CosmicTheme.gold)

                Text("Loading today's provider-backed context")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(CosmicTheme.terminalBlack)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func header(_ summary: TodayMarketHoroscopeSummary) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY MARKET HOROSCOPE")
                    .font(TerminalFont.data(12, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1.3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(formattedDate(summary.date))
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer(minLength: 8)

            DataSourceIndicator(provenance: summary.provenance, size: .compact)
        }
    }

    private func cosmicBlock(_ context: TodayCosmicContext) -> some View {
        section(title: "COSMIC / MARKET CONTEXT", icon: "moon.stars.fill") {
            Text(context.headline)
                .font(TerminalFont.headline(20))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)

            Text(context.detail)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            metricGrid([
                TodayMetric(label: "LUNAR", value: context.lunarLabel),
                TodayMetric(label: "MERCURY", value: context.mercuryLabel),
                TodayMetric(label: "MARKET TONE", value: context.marketToneLabel)
            ])

            HStack {
                Text(context.activeEvents.isEmpty ? "No active alert" : context.activeEvents.joined(separator: " / "))
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: context.provenance, size: .compact)
            }
        }
    }

    private func portfolioBlock(_ context: TodayPortfolioContext) -> some View {
        section(title: "PORTFOLIO READ", icon: "chart.pie.fill") {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(context.headline)
                        .font(TerminalFont.data(15, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(context.detail)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: context.provenance, size: .compact)
            }

            contextRows(
                eventName: context.eventName,
                windowLabel: context.windowLabel,
                eventCount: context.eventCount,
                sampleSize: context.sampleSize,
                includedWeight: context.includedPortfolioWeight,
                excludedWeight: context.excludedPortfolioWeight
            )

            if !context.metrics.isEmpty {
                metricGrid(context.metrics)
            }

            if context.displayMode == .setupRequired {
                setupButton
            }

            if !context.unavailableHoldings.isEmpty {
                excludedHoldingsNote(context.unavailableHoldings)
            }
        }
    }

    private func marketBlock(_ context: TodayMarketContext) -> some View {
        section(title: "MARKET WEATHER", icon: "cloud.sun.fill") {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(context.headline)
                            .font(TerminalFont.data(15, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 6)

                        MarketStatusIndicator(showDetails: false, size: .small)
                    }

                    Text(context.detail)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                DataSourceIndicator(provenance: context.provenance, size: .compact)
            }

            contextRows(
                eventName: context.eventName,
                windowLabel: context.windowLabel,
                eventCount: context.eventCount,
                sampleSize: context.sampleSize,
                includedWeight: context.coverage,
                excludedWeight: max(0, 1 - context.coverage)
            )

            if !context.metrics.isEmpty {
                metricGrid(context.metrics)
            }

            marketBasketRows(context)
        }
    }

    private func stockBlock(_ context: TodayStockContext) -> some View {
        section(title: "STOCK / WATCHLIST LENS", icon: "scope") {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(context.symbol) / \(context.name)")
                        .font(TerminalFont.data(10, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(context.headline)
                        .font(TerminalFont.data(15, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(context.detail)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: context.provenance, size: .compact)
            }

            contextRows(
                eventName: context.eventName,
                windowLabel: context.windowLabel,
                eventCount: context.eventCount,
                sampleSize: context.sampleSize,
                includedWeight: nil,
                excludedWeight: nil
            )

            if !context.metrics.isEmpty {
                metricGrid(context.metrics)
            }
        }
    }

    private func dataCoverageBlock(_ coverage: TodayDataCoverage) -> some View {
        section(title: "DATA COVERAGE", icon: "antenna.radiowaves.left.and.right") {
            Text(coverage.headline)
                .font(TerminalFont.data(13, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            Text(coverage.detail)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(coverage.rows) { row in
                    HStack(alignment: .center, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.label.uppercased())
                                .font(TerminalFont.data(8, weight: .bold))
                                .foregroundColor(CosmicTheme.textMuted)
                                .tracking(0.5)

                            Text(row.value)
                                .font(TerminalFont.data(10))
                                .foregroundColor(CosmicTheme.textSecondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                        }

                        Spacer(minLength: 8)

                        DataSourceIndicator(provenance: row.provenance, size: .compact)
                    }
                    .padding(.vertical, 8)

                    if row.id != coverage.rows.last?.id {
                        Rectangle()
                            .fill(CosmicTheme.borderDim)
                            .frame(height: 0.75)
                    }
                }
            }
            .padding(.horizontal, 10)
            .background(CosmicTheme.cardBackground.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
            )
        }
    }

    private func unavailableBlock(title: String, message: String) -> some View {
        section(title: title, icon: "info.circle") {
            Text(message)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func section<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
                    .frame(width: 14)

                Text(title)
                    .font(TerminalFont.data(10, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Rectangle()
                    .fill(CosmicTheme.borderDim)
                    .frame(height: 1)
            }

            content()
        }
        .padding(12)
        .background(CosmicTheme.cardBackground.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func metricGrid(_ metrics: [TodayMetric]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: 3) {
                    Text(metric.value)
                        .font(TerminalFont.data(12, weight: .bold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(metric.label)
                        .font(TerminalFont.data(8, weight: .bold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
                .padding(9)
                .background(CosmicTheme.panelElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.borderStrong, lineWidth: 0.75)
                )
            }
        }
    }

    private func contextRows(
        eventName: String?,
        windowLabel: String?,
        eventCount: Int,
        sampleSize: Int,
        includedWeight: Double?,
        excludedWeight: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            contextRow(label: "EVENT", value: eventName ?? "Pending")
            contextRow(label: "WINDOW", value: windowLabel ?? "N/A")
            contextRow(label: "EVENTS", value: "\(eventCount)")
            contextRow(label: "SAMPLE", value: "\(sampleSize)")

            if let includedWeight, let excludedWeight {
                contextRow(label: "COVERAGE", value: "\(percentRate(includedWeight)) included / \(percentRate(excludedWeight)) excluded")
            }
        }
    }

    private func contextRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)
                .frame(width: 62, alignment: .leading)

            Text(value)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }

    private var setupButton: some View {
        Button(action: setupAction) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.caption)

                Text("SET UP PORTFOLIO")
                    .font(TerminalFont.data(10, weight: .bold))
                    .tracking(0.7)
            }
            .foregroundColor(CosmicTheme.background)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(CosmicTheme.gold)
        }
        .buttonStyle(.plain)
    }

    private func excludedHoldingsNote(_ symbols: [String]) -> some View {
        let visible = symbols.prefix(5).joined(separator: ", ")
        let suffix = symbols.count > 5 ? " +" : ""

        return Text("Excluded from historical lens: \(visible)\(suffix). Provider-backed complete history was unavailable for those holdings.")
            .font(TerminalFont.data(9))
            .foregroundColor(CosmicTheme.textMuted)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func marketBasketRows(_ context: TodayMarketContext) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !context.includedSymbols.isEmpty {
                compactSymbolRow(label: "Fresh basket", symbols: context.includedSymbols, color: CosmicTheme.positive)
            }

            if !context.staleSymbols.isEmpty {
                compactSymbolRow(label: "Stale cache", symbols: context.staleSymbols, color: CosmicTheme.gold)
            }

            if !context.excludedSymbols.isEmpty {
                compactSymbolRow(label: "Unavailable", symbols: context.excludedSymbols, color: CosmicTheme.textMuted)
            }
        }
    }

    private func compactSymbolRow(label: String, symbols: [String], color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label.uppercased())
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(color)
                .tracking(0.4)

            Text(symbols.joined(separator: " / "))
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date).uppercased()
    }

    private func percentRate(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "N/A" }
        return String(format: "%.0f%%", value * 100)
    }
}
