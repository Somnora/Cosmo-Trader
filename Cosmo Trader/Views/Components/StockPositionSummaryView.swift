import SwiftUI

// MARK: - StockPositionSummaryView
// ================================
// "YOUR POSITION" card on StockDetail for owned stocks: shares, cost
// basis, and unrealized P/L. The P/L needs both a stored cost basis and a
// provider-backed live price — either missing renders an honest "—" with
// the reason, never a number priced off stored/sample data.

struct StockPositionSummaryView: View {

    /// The user's holding (stored shares + cost basis).
    let holding: Stock
    /// Session price from the detail view model (provider refresh target).
    let livePrice: Double
    let priceProvenance: FinancialDataProvenance

    private var costBasisPerShare: Double? { holding.purchasePrice }

    private var canShowProfitLoss: Bool {
        costBasisPerShare != nil && priceProvenance.isProviderBacked && livePrice > 0
    }

    private var profitLoss: Double? {
        guard canShowProfitLoss, let costBasisPerShare else { return nil }
        return (livePrice - costBasisPerShare) * holding.sharesOwned
    }

    private var profitLossPercent: Double? {
        guard let profitLoss, let costBasisPerShare, costBasisPerShare > 0 else { return nil }
        let basis = costBasisPerShare * holding.sharesOwned
        return (profitLoss / basis) * 100
    }

    private var unavailableNote: String? {
        if costBasisPerShare == nil {
            return "Add cost basis via the shares editor to unlock unrealized P/L."
        }
        if !canShowProfitLoss {
            return "Unrealized P/L appears once a provider-backed quote loads."
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(CosmicTheme.gold)

                Text("YOUR POSITION")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                DataSourceIndicator(provenance: priceProvenance, size: .compact)
            }

            HStack(spacing: 0) {
                positionStat(
                    label: "SHARES",
                    value: HoldingSharesInput.displayShares(holding.sharesOwned),
                    color: CosmicTheme.textPrimary
                )

                positionStat(
                    label: "COST BASIS",
                    value: costBasisPerShare.map { String(format: "$%.2f", $0) } ?? "—",
                    color: costBasisPerShare == nil ? CosmicTheme.textMuted : CosmicTheme.textPrimary
                )

                positionStat(
                    label: "UNREALIZED P/L",
                    value: profitLossText,
                    color: profitLossColor
                )
            }

            if let note = unavailableNote {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(note)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(20)
        .accessibilityIdentifier("stockDetail.positionSummary")
    }

    private var profitLossText: String {
        guard let profitLoss else { return "—" }
        var text = (profitLoss >= 0 ? "+" : "-") + String(format: "$%.2f", abs(profitLoss))
        if let percent = profitLossPercent {
            text += String(format: " (%@%.1f%%)", percent >= 0 ? "+" : "-", abs(percent))
        }
        return text
    }

    private var profitLossColor: Color {
        guard let profitLoss else { return CosmicTheme.textMuted }
        return profitLoss >= 0 ? CosmicTheme.positive : CosmicTheme.negative
    }

    private func positionStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)

            Text(value)
                .font(TerminalFont.price(13))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
