import SwiftUI

struct TodayMarketHoroscopeShareCard: View {
    let content: TodayMarketHoroscopeShareCardContent

    private let cardWidth: CGFloat = 390

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            divider
            contextLines
            divider
            provenanceFooter
        }
        .frame(width: cardWidth, alignment: .leading)
        .background(CosmicTheme.background)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(CosmicTheme.borderStrong, lineWidth: 1)
        )
        .accessibilityIdentifier("today.shareCard")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)

                Text("COSMO TRADER")
                    .font(TerminalFont.ticker(15))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1.2)

                Spacer(minLength: 8)

                Text(content.dateLabel)
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(content.headline.uppercased())
                    .font(TerminalFont.data(11, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)

                Text("Historical context, source-labeled")
                    .font(TerminalFont.headline(21))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(CosmicTheme.terminalBlack)
    }

    private var contextLines: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(content.lines) { line in
                shareLine(line)
            }
        }
        .padding(18)
        .background(CosmicTheme.cardBackground)
    }

    private func shareLine(_ line: TodayMarketHoroscopeShareCardContent.ContextLine) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(line.title)
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.8)

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: line.provenance, size: .compact)
            }

            Text(line.value)
                .font(TerminalFont.data(16, weight: .bold))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(line.detail)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if !line.metrics.isEmpty {
                metricRow(line.metrics)
            }
        }
        .padding(12)
        .background(CosmicTheme.panelElevated.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func metricRow(_ metrics: [TodayMetric]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            ForEach(metrics.prefix(3)) { metric in
                VStack(alignment: .leading, spacing: 3) {
                    Text(metric.value)
                        .font(TerminalFont.data(12, weight: .bold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)

                    Text(metric.label)
                        .font(TerminalFont.data(7, weight: .bold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(0.4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
                .padding(8)
                .background(CosmicTheme.terminalBlack.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(CosmicTheme.borderStrong, lineWidth: 0.65)
                )
            }
        }
    }

    private var provenanceFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                DataSourceIndicator(provenance: content.provenance, size: .compact)

                Text(content.provenanceDetail)
                    .font(TerminalFont.data(8))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(content.footer)
                    .font(TerminalFont.data(9, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Text("COSMOTRADER")
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1.1)
            }
        }
        .padding(18)
        .background(CosmicTheme.terminalBlack)
    }

    private var divider: some View {
        Rectangle()
            .fill(CosmicTheme.borderStrong)
            .frame(height: 1)
    }
}

@MainActor
enum TodayMarketHoroscopeShareCardRenderer {
    static func render(
        summary: TodayMarketHoroscopeSummary,
        scale: CGFloat = 2
    ) -> UIImage? {
        let content = TodayMarketHoroscopeShareCardContent.make(from: summary)
        let renderer = ImageRenderer(content: TodayMarketHoroscopeShareCard(content: content))
        renderer.scale = scale
        return renderer.uiImage
    }
}
