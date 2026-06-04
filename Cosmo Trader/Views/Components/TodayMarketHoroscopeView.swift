import SwiftUI

struct TodayMarketHoroscopeView: View {
    let viewModel: TodayMarketHoroscopeViewModel
    let marketRefreshAction: () -> Void
    let portfolioSetupAction: () -> Void
    let portfolioImportAction: () -> Void
    let watchlistSetupAction: () -> Void
    let discoverSearchAction: () -> Void

    @State private var isLabelGuideExpanded = false

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
        VStack(alignment: .leading, spacing: 12) {
            header(summary)
            loopSnapshot(summary)
            marketBlock(summary.marketContext)
            portfolioBlock(summary.portfolioContext)

            if let stockContext = summary.stockContext {
                stockBlock(stockContext)
            }

            cosmicBlock(summary.cosmicContext)
            dataCoverageBlock(summary.dataCoverage)

            Text(summary.disclaimer)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppLayout.cardHorizontalPadding)
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
        .padding(AppLayout.cardHorizontalPadding)
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

    private func loopSnapshot(_ summary: TodayMarketHoroscopeSummary) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 72), spacing: 8),
                GridItem(.flexible(minimum: 72), spacing: 8),
                GridItem(.flexible(minimum: 72), spacing: 8)
            ],
            spacing: 8
        ) {
            snapshotCard(
                label: "MARKET",
                value: snapshotValue(for: summary.marketContext.displayMode),
                detail: summary.marketContext.eventName ?? "Weather pending",
                provenance: summary.marketContext.provenance
            )

            snapshotCard(
                label: "PORTFOLIO",
                value: snapshotValue(for: summary.portfolioContext.displayMode),
                detail: portfolioCoverageLabel(summary.portfolioContext),
                provenance: summary.portfolioContext.provenance
            )

            if let stockContext = summary.stockContext {
                snapshotCard(
                    label: "STOCK",
                    value: stockContext.symbol,
                    detail: snapshotValue(for: stockContext.displayMode),
                    provenance: stockContext.provenance
                )
            } else {
                snapshotCard(
                    label: "WATCH",
                    value: "SETUP",
                    detail: "Add ticker",
                    provenance: .unavailable(reason: "No stock or watchlist pattern available")
                )
            }
        }
    }

    private func snapshotCard(
        label: String,
        value: String,
        detail: String,
        provenance: FinancialDataProvenance
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)
                .lineLimit(1)

            Text(value)
                .font(TerminalFont.data(12, weight: .bold))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(TerminalFont.data(8))
                .foregroundColor(CosmicTheme.textMuted)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            DataSourceIndicator(provenance: provenance, size: .compact)
                .padding(.top, 1)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
        .padding(8)
        .background(CosmicTheme.panelElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderStrong, lineWidth: 0.75)
        )
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

            if let activation = context.activation {
                activationPrompt(
                    activation,
                    primaryAction: action(for: activation.primaryActionTitle) ?? watchlistSetupAction,
                    secondaryAction: action(for: activation.secondaryActionTitle),
                    tertiaryAction: action(for: activation.tertiaryActionTitle)
                )
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
            sectorBreadthRows(context.sectorBreadth)

            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(CosmicTheme.gold)
                    Text("Refreshing provider/cache history")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            if let activation = context.activation {
                activationPrompt(
                    activation,
                    primaryAction: action(for: activation.primaryActionTitle) ?? marketRefreshAction,
                    secondaryAction: action(for: activation.secondaryActionTitle),
                    tertiaryAction: action(for: activation.tertiaryActionTitle)
                )
            }
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

            if let activation = context.activation {
                activationPrompt(
                    activation,
                    primaryAction: action(for: activation.primaryActionTitle) ?? watchlistSetupAction,
                    secondaryAction: action(for: activation.secondaryActionTitle),
                    tertiaryAction: action(for: activation.tertiaryActionTitle)
                )
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

            labelExplainerDisclosure(coverage.explainers)
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

    @ViewBuilder
    private func sectorBreadthRows(_ breadth: TodayMarketSectorBreadth?) -> some View {
        if let breadth {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("SECTOR BREADTH")
                        .font(TerminalFont.data(8, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(0.4)

                    Text("\(percentRate(breadth.coverage)) coverage")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)

                    Spacer(minLength: 8)

                    DataSourceIndicator(provenance: breadth.provenance, size: .compact)
                }

                Text(breadth.detail)
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if !breadth.metrics.isEmpty {
                    metricGrid(breadth.metrics)
                }

                if !breadth.staleSymbols.isEmpty {
                    compactSymbolRow(label: "Stale sectors", symbols: breadth.staleSymbols, color: CosmicTheme.gold)
                }

                if !breadth.excludedSymbols.isEmpty {
                    compactSymbolRow(label: "Unavailable sectors", symbols: breadth.excludedSymbols, color: CosmicTheme.textMuted)
                }
            }
            .padding(10)
            .background(CosmicTheme.panelElevated.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
            )
        }
    }

    private func activationPrompt(
        _ prompt: TodayActivationPrompt,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)?,
        tertiaryAction: (() -> Void)? = nil
    ) -> some View {
        let actions: [(title: String, isPrimary: Bool, handler: () -> Void)] = [
            (prompt.primaryActionTitle, true, primaryAction)
        ] + [
            prompt.secondaryActionTitle.map { ($0, false, secondaryAction ?? {}) },
            prompt.tertiaryActionTitle.map { ($0, false, tertiaryAction ?? {}) }
        ].compactMap { $0 }

        return VStack(alignment: .leading, spacing: 8) {
            Text(prompt.title)
                .font(TerminalFont.data(10, weight: .bold))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(prompt.detail)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if !prompt.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(prompt.actionItems, id: \.self) { item in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Circle()
                                .fill(CosmicTheme.gold.opacity(0.75))
                                .frame(width: 4, height: 4)

                            Text(item)
                                .font(TerminalFont.data(8))
                                .foregroundColor(CosmicTheme.textSecondary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 1)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    actionButton(
                        title: action.title,
                        systemImage: actionIcon(for: action.title),
                        isPrimary: action.isPrimary,
                        action: action.handler
                    )
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.panelElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderStrong, lineWidth: 0.75)
        )
    }

    private func actionButton(
        title: String,
        systemImage: String,
        isPrimary: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))

                Text(title)
                    .font(TerminalFont.data(9, weight: .bold))
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundColor(isPrimary ? CosmicTheme.background : CosmicTheme.gold)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isPrimary ? CosmicTheme.gold : CosmicTheme.gold.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(CosmicTheme.gold.opacity(isPrimary ? 0 : 0.45), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }

    private func actionIcon(for title: String) -> String {
        if title.localizedCaseInsensitiveContains("refresh")
            || title.localizedCaseInsensitiveContains("fetch")
            || title.localizedCaseInsensitiveContains("load") {
            return "arrow.clockwise"
        }
        if title.localizedCaseInsensitiveContains("discover") || title.localizedCaseInsensitiveContains("search") {
            return "magnifyingglass"
        }
        if title.localizedCaseInsensitiveContains("portfolio") || title.localizedCaseInsensitiveContains("holding") {
            return "chart.pie.fill"
        }
        return "plus"
    }

    private func labelExplainerDisclosure(_ explainers: [TodayDataLabelExplainer]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isLabelGuideExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("LABEL GUIDE")
                        .font(TerminalFont.data(8, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(0.7)

                    Text("Tap for data label meanings")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer(minLength: 8)

                    Image(systemName: isLabelGuideExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(CosmicTheme.panelElevated.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
                )
            }
            .buttonStyle(.plain)

            if isLabelGuideExpanded {
                labelExplainerGrid(explainers)
            }
        }
    }

    private func labelExplainerGrid(_ explainers: [TodayDataLabelExplainer]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LABEL GUIDE")
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.gold)
                .tracking(0.7)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(explainers) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.label.uppercased())
                            .font(TerminalFont.data(8, weight: .bold))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text(item.detail)
                            .font(TerminalFont.data(8))
                            .foregroundColor(CosmicTheme.textMuted)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
                    .padding(8)
                    .background(CosmicTheme.panelElevated.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
                    )
                }
            }
        }
    }

    private func action(for title: String?) -> (() -> Void)? {
        guard let title else { return nil }
        if title.localizedCaseInsensitiveContains("refresh")
            || title.localizedCaseInsensitiveContains("fetch")
            || title.localizedCaseInsensitiveContains("load") {
            return marketRefreshAction
        }
        if title.localizedCaseInsensitiveContains("import") {
            return portfolioImportAction
        }
        if title.localizedCaseInsensitiveContains("holding") || title.localizedCaseInsensitiveContains("portfolio") {
            return portfolioSetupAction
        }
        if title.localizedCaseInsensitiveContains("discover")
            || title.localizedCaseInsensitiveContains("search")
            || title.localizedCaseInsensitiveContains("watchlist")
            || title.localizedCaseInsensitiveContains("symbol") {
            return discoverSearchAction
        }
        return watchlistSetupAction
    }

    private func snapshotValue(for mode: TodayMarketContext.DisplayMode) -> String {
        switch mode {
        case .marketBacked:
            return "READY"
        case .partialContext:
            return "PARTIAL"
        case .stale:
            return "STALE"
        case .insufficientSample:
            return "THIN"
        case .unavailable:
            return "UNAVAILABLE"
        case .sampleOnly:
            return "SAMPLE"
        }
    }

    private func snapshotValue(for mode: TodayPortfolioContext.DisplayMode) -> String {
        switch mode {
        case .setupRequired:
            return "SETUP"
        case .marketBacked:
            return "READY"
        case .partialContext:
            return "PARTIAL"
        case .insufficientCoverage:
            return "LOW COVER"
        case .insufficientSample:
            return "THIN"
        case .unavailable:
            return "UNAVAILABLE"
        case .sampleOnly:
            return "SAMPLE"
        }
    }

    private func snapshotValue(for mode: TodayStockContext.DisplayMode) -> String {
        switch mode {
        case .marketBacked:
            return "Pattern ready"
        case .partialDataset:
            return "Partial history"
        case .insufficientDataset:
            return "Thin history"
        case .insufficientSample:
            return "Thin sample"
        case .unavailable:
            return "Unavailable"
        case .sampleOnly:
            return "Sample"
        }
    }

    private func portfolioCoverageLabel(_ context: TodayPortfolioContext) -> String {
        if context.displayMode == .setupRequired {
            return "Add holdings"
        }

        return "\(percentRate(context.includedPortfolioWeight)) covered"
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
