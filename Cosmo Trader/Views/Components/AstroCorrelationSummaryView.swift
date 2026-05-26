import SwiftUI

struct AstroCorrelationSummaryView: View {
    let summaries: [AstroCorrelationSummary]

    var body: some View {
        if !summaries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(summaries.prefix(4)) { summary in
                        summaryCard(summary)
                    }
                }
            }
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(width: 18, height: 1)

            Text("HISTORICAL COMPARISON")
                .font(TerminalFont.data(10, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)
        }
    }

    private func summaryCard(_ summary: AstroCorrelationSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: summary.kind.iconSystemName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(summary.kind.overlayColor)
                Text(summary.kind.displayName.uppercased())
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                Text("×\(summary.occurrenceCount)")
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                metricColumn(
                    label: "AVG MOVE",
                    value: percent(summary.averageReturn),
                    color: color(for: summary.averageReturn),
                    alignment: .leading
                )
                Spacer(minLength: 4)
                metricColumn(
                    label: "WIN RATE",
                    value: "\(Int(round(summary.winRate * 100)))%",
                    color: CosmicTheme.textPrimary,
                    alignment: .trailing
                )
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.terminalBlack)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.kind.displayName), \(summary.occurrenceCount) occurrences, average move \(percent(summary.averageReturn)), win rate \(Int(round(summary.winRate * 100))) percent")
    }

    private func metricColumn(label: String, value: String, color: Color, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(value)
                .font(TerminalFont.price(14))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(TerminalFont.data(7, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)
        }
    }

    private func percent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }

    private func color(for value: Double) -> Color {
        value >= 0 ? CosmicTheme.positive : CosmicTheme.negative
    }
}
