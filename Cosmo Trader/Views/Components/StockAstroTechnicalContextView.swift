import SwiftUI

struct StockAstroTechnicalContextView: View {
    let context: StockAstroTechnicalContext
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if isLoading {
                loadingState
            } else {
                VStack(spacing: 10) {
                    ForEach(context.cards) { card in
                        contextCard(card)
                    }
                }
            }

            Text(context.footer)
                .font(TerminalFont.data(8))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(2)
        }
        .accessibilityIdentifier("stock.astroTechnicalContext")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)

            VStack(alignment: .leading, spacing: 3) {
                Text("ASTRO-TECHNICAL CONTEXT")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .tracking(0.8)

                Text("Technical lens plus gated historical cosmic context")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer(minLength: 8)
        }
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.7)
                .tint(CosmicTheme.gold)

            Text("Loading provider-backed astro-technical context...")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(CosmicTheme.secondaryBackground.opacity(0.7))
    }

    private func contextCard(_ card: StockAstroTechnicalContextCard) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: card.iconSystemName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color(for: card.displayMode))

                Text(card.title.uppercased())
                    .font(TerminalFont.data(10, weight: .bold))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .tracking(0.7)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 8)

                Text(label(for: card.displayMode))
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(color(for: card.displayMode))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(color(for: card.displayMode).opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(color(for: card.displayMode).opacity(0.35), lineWidth: 0.5)
                    )
            }

            contextLine(card.technicalText)
            contextLine(card.cosmicText)

            Text(card.contextText)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                labeledIndicator(title: "TECH", provenance: context.technicalProvenance, completeness: context.technicalCompleteness)
                labeledIndicator(title: "COSMIC", provenance: context.cosmicProvenance, completeness: context.cosmicCompleteness)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.secondaryBackground.opacity(0.68))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color(for: card.displayMode).opacity(0.22), lineWidth: 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stock.astroTechnicalContext.card.\(card.id)")
    }

    private func contextLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Circle()
                .fill(CosmicTheme.textMuted.opacity(0.6))
                .frame(width: 4, height: 4)
                .padding(.top, 5)

            Text(text)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func labeledIndicator(
        title: String,
        provenance: FinancialDataProvenance,
        completeness: HistoricalDatasetCompleteness
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(TerminalFont.data(7, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.7)

            DataSourceIndicator(provenance: provenance, size: .compact)
                .fixedSize(horizontal: false, vertical: true)

            Text(completeness.label.uppercased())
                .font(TerminalFont.data(7, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(CosmicTheme.cardBackground.opacity(0.55))
    }

    private func label(for mode: StockAstroTechnicalDisplayMode) -> String {
        switch mode {
        case .combinedContext:
            return "COMBINED"
        case .technicalOnly:
            return "TECH ONLY"
        case .cosmicOnly:
            return "COSMIC"
        case .unavailable:
            return "GATED"
        }
    }

    private func color(for mode: StockAstroTechnicalDisplayMode) -> Color {
        switch mode {
        case .combinedContext:
            return CosmicTheme.gold
        case .technicalOnly:
            return CosmicTheme.accentBlue
        case .cosmicOnly:
            return CosmicTheme.gold.opacity(0.85)
        case .unavailable:
            return CosmicTheme.textMuted
        }
    }
}
