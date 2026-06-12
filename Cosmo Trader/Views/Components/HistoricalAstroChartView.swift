import SwiftUI
import Charts

struct HistoricalAstroChartView: View {
    let stock: Stock
    @Binding var selectedTimeframe: ChartTimeframe
    var onProviderHistoryLoaded: (() async -> Void)?

    @State private var viewModel = HistoricalAstroChartViewModel()
    @State private var scrubDate: Date?

    private let chartHeight: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chartReadout
            content
            historyActivationPanel
            timeframeSelector
            if !viewModel.ohlcData.isEmpty {
                AstroOverlayControls(
                    filterState: viewModel.filterState,
                    hasCompanyEventDate: stock.supportsCompanyOverlayEvents
                ) { option in
                    viewModel.toggleKinds(option.kinds)
                    AnalyticsService.shared.trackAstroOverlayFilterChanged(
                        symbol: stock.symbol,
                        filter: option.label,
                        enabled: option.kinds.allSatisfy { viewModel.filterState.enabledKinds.contains($0) }
                    )
                }
            }
            if !viewModel.overlayEvents.isEmpty {
                eventStrip
            }
            selectedEventPanel
            AstroCorrelationSummaryView(
                summaries: viewModel.summaries,
                provenance: viewModel.historicalPriceProvenance,
                checkedEventKinds: viewModel.checkedEventKinds,
                eventCount: viewModel.overlayEvents.count,
                windowLabel: viewModel.windowLabel,
                hasHistoricalPrices: !viewModel.ohlcData.isEmpty
            )

            Text("Historical overlay only. Correlation view, not financial advice.")
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .accessibilityLabel("Historical overlay only. Correlation view, not financial advice.")
        }
        .task(id: "\(stock.symbol)-\(selectedTimeframe.rawValue)") {
            scrubDate = nil
            await viewModel.load(stock: stock, timeframe: selectedTimeframe)
            AnalyticsService.shared.trackAstroOverlayViewed(
                symbol: stock.symbol,
                timeframe: selectedTimeframe.rawValue
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)

                Text("COSMIC CORRELATION LAB")
                    .font(TerminalFont.data(12, weight: .bold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .tracking(1)

                Spacer()

                DataSourceIndicator(provenance: viewModel.historicalPriceProvenance, size: .compact)
                oracleBadge
            }

            Text("Provider-backed historical price action aligned with cosmic event windows.")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
        }
    }

    private var oracleBadge: some View {
        Text("ORACLE")
            .font(TerminalFont.data(9, weight: .bold))
            .foregroundColor(CosmicTheme.gold)
            .tracking(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(CosmicTheme.gold.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.gold.opacity(0.5), lineWidth: 0.75)
            )
    }

    // MARK: - Chart Readout (scrub-aware)

    private var chartReadout: some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            if let scrub = scrubPoint {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DateFormatter.astroOverlayShort.string(from: scrub.date).uppercased())
                        .font(TerminalFont.data(10, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(1)
                    Text(formatPrice(scrub.close))
                        .font(TerminalFont.price(20))
                        .foregroundColor(CosmicTheme.textPrimary)
                }
                Spacer()
                if let nearby = scrubEvent {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("NEAR")
                            .font(TerminalFont.data(8, weight: .bold))
                            .foregroundColor(CosmicTheme.textMuted)
                            .tracking(1)
                        HStack(spacing: 5) {
                            Image(systemName: nearby.iconSystemName)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(nearby.kind.overlayColor)
                            Text(nearby.title.uppercased())
                                .font(TerminalFont.data(10, weight: .bold))
                                .foregroundColor(CosmicTheme.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedTimeframe.description.uppercased())
                        .font(TerminalFont.data(10, weight: .bold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)
                    HStack(spacing: 8) {
                        Text(performancePercentText)
                            .font(TerminalFont.price(20))
                            .foregroundColor(performanceColor)
                        Text(performanceMoveText)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(viewModel.overlayEvents.count)")
                        .font(TerminalFont.price(18))
                        .foregroundColor(CosmicTheme.textPrimary)
                    Text(viewModel.overlayEvents.count == 1 ? "COSMIC EVENT" : "COSMIC EVENTS")
                        .font(TerminalFont.data(8, weight: .bold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)
                }
            }
        }
        .frame(height: 42)
        .animation(.easeOut(duration: 0.12), value: scrubDate)
    }

    // MARK: - Chart Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingState
        } else if let errorMessage = viewModel.errorMessage {
            messageState(icon: "exclamationmark.triangle", title: errorMessage)
        } else if !viewModel.canShowHistoricalChart {
            messageState(icon: "chart.line.downtrend.xyaxis", title: "Historical price data unavailable. Correlation context will appear when provider-backed history is available.")
        } else if viewModel.overlayEvents.isEmpty {
            VStack(spacing: 12) {
                chart
                messageState(icon: "moon", title: "No overlay events in this range. Try a longer timeframe or enable more event types.")
            }
        } else {
            chart
        }
    }

    @ViewBuilder
    private var historyActivationPanel: some View {
        if viewModel.needsProviderHistoryActivation {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(CosmicTheme.gold)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text("PROVIDER HISTORY")
                                .font(TerminalFont.data(10, weight: .bold))
                                .foregroundColor(CosmicTheme.textPrimary)
                                .tracking(1)

                            DataSourceIndicator(provenance: viewModel.historicalPriceProvenance, size: .compact)
                        }

                        Text(viewModel.historyActivationMessage)
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .lineSpacing(3)
                    }
                }

                VStack(spacing: 7) {
                    ForEach(viewModel.historySurfaceStatuses, id: \.label) { status in
                        HStack(spacing: 8) {
                            Image(systemName: status.isAvailable ? "checkmark.circle.fill" : "circle.dashed")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(status.isAvailable ? CosmicTheme.positive : CosmicTheme.textMuted)

                            Text(status.label.uppercased())
                                .font(TerminalFont.data(9, weight: .semibold))
                                .foregroundColor(CosmicTheme.textPrimary)
                                .frame(width: 112, alignment: .leading)

                            Text(status.detail)
                                .font(TerminalFont.data(9))
                                .foregroundColor(CosmicTheme.textMuted)
                                .lineLimit(2)

                            Spacer(minLength: 0)
                        }
                    }
                }

                Button {
                    Task {
                        let didLoadProviderBackedHistory = await viewModel.refreshProviderHistory()
                        if didLoadProviderBackedHistory {
                            await onProviderHistoryLoaded?()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(CosmicTheme.terminalBlack)
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                        }

                        Text(viewModel.historyActivationTitle.uppercased())
                            .font(TerminalFont.data(10, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(CosmicTheme.terminalBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(CosmicTheme.gold)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)

                if case .loaded(let message) = viewModel.historyLoadState {
                    Text(message)
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                        .lineSpacing(3)
                } else if case .unavailable(let message) = viewModel.historyLoadState {
                    Text(message)
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                        .lineSpacing(3)
                }

                Text("Historical context only. Not financial advice.")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CosmicTheme.terminalBlack)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
            )
        }
    }

    private var chart: some View {
        Chart {
            // Range event bands (muted)
            ForEach(viewModel.overlayEvents.filter(\.isRange)) { event in
                if let endDate = event.endDate {
                    RectangleMark(
                        xStart: .value("Start", event.startDate),
                        xEnd: .value("End", endDate),
                        yStart: .value("Low", viewModel.priceRange.lowerBound),
                        yEnd: .value("High", viewModel.priceRange.upperBound)
                    )
                    .foregroundStyle(event.kind.overlayColor.opacity(viewModel.selectedEvent?.id == event.id ? 0.16 : 0.06))
                }
            }

            // Selected event vertical line (only for point events)
            if let selected = viewModel.selectedEvent, !selected.isRange {
                RuleMark(x: .value("Selected", selected.markerDate))
                    .foregroundStyle(selected.kind.overlayColor.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.25, dash: [3, 3]))
            }

            // Price line
            ForEach(viewModel.ohlcData) { candle in
                LineMark(
                    x: .value("Date", candle.date),
                    y: .value("Close", candle.close)
                )
                .foregroundStyle(chartColor)
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }

            // Primary moon markers on the price curve
            ForEach(curveMoonEvents) { event in
                if let candle = viewModel.nearestCandle(to: event.markerDate) {
                    let isSelected = viewModel.selectedEvent?.id == event.id
                    PointMark(
                        x: .value("Moon Event", candle.date),
                        y: .value("Close", candle.close)
                    )
                    .symbol {
                        MoonCurveMarker(kind: event.kind, isSelected: isSelected)
                    }
                    .symbolSize(isSelected ? 150 : 95)
                    .foregroundStyle(event.kind.overlayColor)
                }
            }

            // Bottom event rail (always-on point markers)
            ForEach(viewModel.overlayEvents.filter { !$0.isRange }) { event in
                let isSelected = viewModel.selectedEvent?.id == event.id
                PointMark(
                    x: .value("Event", event.markerDate),
                    y: .value("Rail", viewModel.priceRange.lowerBound)
                )
                .symbolSize(isSelected ? 110 : 50)
                .foregroundStyle(event.kind.overlayColor)
            }

            // Scrub indicators (drawn last so they sit on top)
            if let scrub = scrubPoint {
                RuleMark(x: .value("Scrub", scrub.date))
                    .foregroundStyle(CosmicTheme.gold.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                PointMark(
                    x: .value("Scrub", scrub.date),
                    y: .value("Close", scrub.close)
                )
                .foregroundStyle(CosmicTheme.gold)
                .symbolSize(80)
            }
        }
        .chartYScale(domain: viewModel.priceRange)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(CosmicTheme.border)
                AxisValueLabel()
                    .font(TerminalFont.data(9))
                    .foregroundStyle(CosmicTheme.textMuted)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    .foregroundStyle(CosmicTheme.border)
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text(axisPrice(price))
                            .font(TerminalFont.data(9))
                            .foregroundStyle(CosmicTheme.textMuted)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = max(0, min(value.location.x, geometry.size.width))
                                if let date: Date = proxy.value(atX: x) {
                                    scrubDate = date
                                }
                            }
                            .onEnded { _ in
                                if let date = scrubDate,
                                   let nearby = viewModel.nearestEvent(to: date, within: 60 * 60 * 24 * 4) {
                                    viewModel.select(event: nearby)
                                    AnalyticsService.shared.trackAstroOverlayEventSelected(
                                        symbol: stock.symbol,
                                        eventKind: nearby.kind.rawValue
                                    )
                                }
                                scrubDate = nil
                            }
                    )
            }
        }
        .frame(height: chartHeight)
        .accessibilityLabel("Historical price chart with selected astrological overlays")
    }

    // MARK: - Event Strip

    private var eventStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(viewModel.overlayEvents.prefix(18))) { event in
                    let isSelected = viewModel.selectedEvent?.id == event.id
                    Button {
                        viewModel.select(event: event)
                        AnalyticsService.shared.trackAstroOverlayEventSelected(
                            symbol: stock.symbol,
                            eventKind: event.kind.rawValue
                        )
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: event.iconSystemName)
                                .font(.system(size: 10, weight: .semibold))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.title.uppercased())
                                    .font(TerminalFont.data(8, weight: .bold))
                                    .lineLimit(1)
                                Text(DateFormatter.astroOverlayShort.string(from: event.markerDate).uppercased())
                                    .font(TerminalFont.data(8))
                                    .foregroundColor(isSelected ? CosmicTheme.terminalBlack.opacity(0.75) : CosmicTheme.textMuted)
                            }
                        }
                        .foregroundColor(isSelected ? CosmicTheme.terminalBlack : CosmicTheme.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(isSelected ? event.kind.overlayColor : CosmicTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(event.kind.overlayColor.opacity(isSelected ? 1 : 0.4), lineWidth: 0.75)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(event.accessibilityDescription)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Timeframe Selector

    private var timeframeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ChartTimeframe.allCases) { timeframe in
                Button {
                    selectedTimeframe = timeframe
                    AnalyticsService.shared.trackChartTimeframeChanged(
                        symbol: stock.symbol,
                        timeframe: timeframe.rawValue
                    )
                } label: {
                    Text(timeframe.rawValue)
                        .font(TerminalFont.data(12, weight: timeframe == selectedTimeframe ? .semibold : .regular))
                        .foregroundColor(timeframe == selectedTimeframe ? CosmicTheme.gold : CosmicTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(timeframe == selectedTimeframe ? CosmicTheme.gold.opacity(0.15) : Color.clear)
                }
            }
        }
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
        .accessibilityLabel("Chart timeframe")
    }

    // MARK: - Selected Event Panel

    @ViewBuilder
    private var selectedEventPanel: some View {
        if let event = viewModel.selectedEvent {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Image(systemName: event.iconSystemName)
                        .foregroundColor(event.kind.overlayColor)
                    Text(event.title.uppercased())
                        .font(TerminalFont.data(11, weight: .bold))
                        .foregroundColor(CosmicTheme.textPrimary)
                    if event.isEstimated {
                        Text("EST.")
                            .font(TerminalFont.data(8, weight: .bold))
                            .foregroundColor(CosmicTheme.textMuted)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(CosmicTheme.borderDim, lineWidth: 0.5)
                            )
                    }
                    Spacer()
                    Text(eventDateLabel(for: event))
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                if let subtitle = event.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                if viewModel.canShowCorrelationMetrics, let reaction = viewModel.selectedReaction {
                    HStack(alignment: .top, spacing: 12) {
                        eventMetric(
                            "Window move",
                            percent(reaction.returnPercent),
                            reaction.returnPercent >= 0 ? CosmicTheme.positive : CosmicTheme.negative
                        )
                        eventMetric(
                            "Volatility",
                            percent(reaction.volatilityPercent),
                            CosmicTheme.textPrimary
                        )
                        eventMetric(
                            "Drawdown",
                            percent(-abs(reaction.maxDrawdownPercent)),
                            reaction.maxDrawdownPercent > 0 ? CosmicTheme.negative : CosmicTheme.textPrimary
                        )
                    }
                } else {
                    Text(selectedEventMetricUnavailableText)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Text("Correlation view, not financial advice.")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CosmicTheme.terminalBlack)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
            )
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(CosmicTheme.gold)
            Text("Loading historical overlay")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: chartHeight)
    }

    private func messageState(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)
            Text(title)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 86)
        .padding(12)
        .background(CosmicTheme.cardBackground.opacity(0.65))
    }

    private func eventMetric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(TerminalFont.data(8))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)
            Text(value)
                .font(TerminalFont.price(13))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private var scrubPoint: OHLCData? {
        guard let scrubDate, !viewModel.ohlcData.isEmpty else { return nil }
        return viewModel.nearestCandle(to: scrubDate)
    }

    private var scrubEvent: AstroOverlayEvent? {
        guard let scrubDate else { return nil }
        return viewModel.nearestEvent(to: scrubDate, within: 60 * 60 * 24 * 5)
    }

    private var curveMoonEvents: [AstroOverlayEvent] {
        viewModel.overlayEvents.filter { event in
            event.kind == .newMoon || event.kind == .fullMoon
        }
    }

    private var performancePercentText: String {
        guard let first = viewModel.ohlcData.first?.close,
              let last = viewModel.ohlcData.last?.close,
              first > 0 else { return "--" }
        let pct = ((last - first) / first) * 100
        let sign = pct >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, pct)
    }

    private var performanceMoveText: String {
        guard let first = viewModel.ohlcData.first?.close,
              let last = viewModel.ohlcData.last?.close else { return "" }
        let move = last - first
        let sign = move >= 0 ? "+" : "-"
        return "\(sign)$\(String(format: "%.2f", abs(move)))"
    }

    private var performanceColor: Color {
        guard let first = viewModel.ohlcData.first?.close,
              let last = viewModel.ohlcData.last?.close else { return CosmicTheme.textPrimary }
        return last >= first ? CosmicTheme.positive : CosmicTheme.negative
    }

    private var chartColor: Color {
        viewModel.chartColor == .positive ? CosmicTheme.positive : CosmicTheme.negative
    }

    private var selectedEventMetricUnavailableText: String {
        switch viewModel.historicalPriceProvenance {
        case .sample:
            return "Sample chart mode is labeled for preview only; event-window metrics are hidden."
        case .mixed:
            return "Mixed data freshness. Metric unavailable for this event."
        case .unavailable:
            return "Provider-backed history is required before event-window metrics are shown."
        default:
            return "Not enough provider-backed price action for the selected window."
        }
    }

    private func axisPrice(_ price: Double) -> String {
        if price >= 100 { return String(format: "$%.0f", price) }
        return String(format: "$%.1f", price)
    }

    private func percent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }

    private func formatPrice(_ price: Double) -> String {
        String(format: "$%.2f", price)
    }

    private func eventDateLabel(for event: AstroOverlayEvent) -> String {
        if event.isRange, let end = event.endDate,
           !Calendar.current.isDate(end, inSameDayAs: event.startDate) {
            return "\(DateFormatter.astroOverlayMonthDay.string(from: event.startDate)) to \(DateFormatter.astroOverlayMonthDay.string(from: end))"
        }
        return DateFormatter.astroOverlayShort.string(from: event.markerDate)
    }
}

private struct MoonCurveMarker: View {
    let kind: AstroOverlayEventKind
    let isSelected: Bool

    private var size: CGFloat {
        isSelected ? 11 : 8
    }

    var body: some View {
        switch kind {
        case .newMoon:
            Circle()
                .fill(CosmicTheme.steelBlue)
                .overlay(Circle().stroke(CosmicTheme.textPrimary, lineWidth: isSelected ? 1.4 : 1))
                .frame(width: size, height: size)
        case .fullMoon:
            Circle()
                .fill(CosmicTheme.terminalBlack)
                .overlay(Circle().stroke(CosmicTheme.gold, lineWidth: isSelected ? 2.4 : 1.8))
                .frame(width: size + 1, height: size + 1)
        default:
            Circle()
                .fill(kind.overlayColor)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Event Kind Color Mapping
//
// Centralized so the chart, filter chips, event strip, selected event panel,
// and summary cards all draw from the same palette.

extension AstroOverlayEventKind {
    var overlayColor: Color {
        switch self {
        case .newMoon:
            return CosmicTheme.steelBlue
        case .fullMoon:
            return CosmicTheme.gold
        case .firstQuarter, .lastQuarter:
            return CosmicTheme.textSecondary
        case .moonInSign:
            return CosmicTheme.accentBlue
        case .mercuryRetrograde:
            return .orange
        case .companyBirthMonth:
            return CosmicTheme.gold.opacity(0.9)
        case .companyFoundingAnniversary:
            return CosmicTheme.positive
        case .eclipse:
            return CosmicTheme.negative
        case .planetaryIngress:
            return CosmicTheme.textSecondary
        }
    }
}

// MARK: - Locked State Card

struct HistoricalAstroOverlayLockedCard: View {
    @State private var showUpgradeSheet = false

    var body: some View {
        Button {
            AnalyticsService.shared.trackPaywallViewed(source: "historical_astro_overlay")
            showUpgradeSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(CosmicTheme.gold)

                    Text("COSMIC CORRELATION LAB")
                        .font(TerminalFont.data(12, weight: .bold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .tracking(1)

                    Spacer()

                    Text("ORACLE")
                        .font(TerminalFont.data(8, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                }

                Text("Overlay moon phases, Mercury retrograde, and company birth cycles against historical price action. Explore historical context, including when no pattern appears.")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text("UNLOCK WITH ORACLE")
                        .font(TerminalFont.data(10, weight: .bold))
                        .foregroundColor(CosmicTheme.terminalBlack)
                        .tracking(1)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(CosmicTheme.terminalBlack)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(CosmicTheme.gold)

                Text("Correlation view, not financial advice.")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(14)
            .background(CosmicTheme.terminalBlack)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.gold.opacity(0.45), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showUpgradeSheet) {
            FeatureUpgradeSheet(feature: .historicalAstroOverlay)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .accessibilityLabel("Unlock Cosmic Correlation Lab with Oracle")
    }
}
