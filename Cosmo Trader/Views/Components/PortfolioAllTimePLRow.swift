import SwiftUI

// MARK: - PortfolioAllTimePLRow
// =============================
// ALL-TIME P/L strip under the Portfolio header. Renders the summary's
// honest states: a provider-backed number with explicit coverage when
// only some holdings qualify, or a labeled unavailable reason — never an
// unlabeled portfolio-wide claim.

struct PortfolioAllTimePLRow: View {

    let summary: PortfolioAllTimePLSummary

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("ALL-TIME P/L")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            if summary.hasResult {
                HStack(spacing: 4) {
                    Text(summary.formattedProfitLoss)
                        .font(TerminalFont.price(14))

                    if let percent = summary.formattedPercent {
                        Text("(\(percent))")
                            .font(TerminalFont.price(11))
                    }
                }
                .foregroundColor(summary.isPositive ? CosmicTheme.positive : CosmicTheme.negative)

                if summary.isPartialCoverage {
                    Text(summary.coverageLabel)
                        .font(TerminalFont.data(8, weight: .semibold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(0.5)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(CosmicTheme.cardBackground)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: summary.provenance, size: .compact)
            } else {
                Text("—")
                    .font(TerminalFont.price(14))
                    .foregroundColor(CosmicTheme.textMuted)

                Spacer(minLength: 8)

                if let reason = summary.unavailableReason {
                    Text(reason)
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("portfolio.allTimePL")
    }
}
