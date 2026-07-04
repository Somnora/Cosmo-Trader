import SwiftUI

/// Full cosmic scorecard (specs/prediction-ledger-mvp.md, phase C): running
/// accuracy against the coin-flip baseline, per-driver breakdown, and the
/// complete call history — including the days the cosmos got wrong. The
/// graveyard is the point: the scorecard teaches the null hypothesis by
/// showing it.
struct CosmicScorecardView: View {
    let viewModel: PredictionLedgerViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppLayout.sectionSpacing) {
                accuracyHeader
                perDriverBlock
                historyBlock

                Text("Scored record of past cosmic calls against index closes. Correlation does not imply causation. Entertainment context only — not predictive and not financial advice.")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppLayout.screenHorizontalPadding)
            .padding(.vertical, 12)
        }
        .background(CosmicTheme.background)
        .navigationTitle("Cosmic Scorecard")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("cosmicScorecard.screen")
    }

    // MARK: - Accuracy header

    private var accuracyHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("COSMOS VS. THE CLOSE")
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.8)

                Spacer(minLength: 8)

                if viewModel.scorecard.scoredCount > 0 {
                    DataSourceIndicator(provenance: viewModel.scorecard.provenance, size: .compact)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hitRateDisplay)
                        .font(TerminalFont.data(28, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)

                    Text("COIN FLIP BASELINE: 50%")
                        .font(TerminalFont.data(8, weight: .semibold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(0.6)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    statLine("SCORED", "\(viewModel.scorecard.scoredCount)")
                    statLine("HITS", "\(viewModel.scorecard.hitCount)")
                    statLine("PUSHES", "\(viewModel.scorecard.flatCount)")
                    statLine("STREAK", streakDisplay)
                }
            }

            if viewModel.isEarlyDays {
                Text("Early days — \(viewModel.scorecard.scoredCount) scored calls is too small a sample to mean anything. That is the first lesson of the scorecard.")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppLayout.cardHorizontalPadding)
        .background(CosmicTheme.terminalBlack)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private var hitRateDisplay: String {
        guard let hitRate = viewModel.scorecard.hitRate else { return "—" }
        return String(format: "%.0f%%", hitRate * 100)
    }

    private var streakDisplay: String {
        let streak = viewModel.scorecard.currentStreak
        if streak > 0 { return "\(streak) HIT" + (streak > 1 ? "S" : "") }
        if streak < 0 { return "\(-streak) MISS" + (streak < -1 ? "ES" : "") }
        return "—"
    }

    private func statLine(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(TerminalFont.data(8, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.6)
            Text(value)
                .font(TerminalFont.data(10, weight: .bold))
                .foregroundColor(CosmicTheme.textPrimary)
        }
    }

    // MARK: - Per-driver breakdown

    @ViewBuilder
    private var perDriverBlock: some View {
        if !viewModel.scorecard.perDriverKind.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("BY COSMIC DRIVER")
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.8)

                ForEach(sortedDrivers, id: \.kind) { driver in
                    HStack(spacing: 8) {
                        Image(systemName: driverIcon(driver.kind))
                            .font(.system(size: 10))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .frame(width: 14)

                        Text(driverDisplayName(driver.kind))
                            .font(TerminalFont.data(10, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Spacer(minLength: 8)

                        Text("\(driver.stats.hits)/\(driver.stats.scored)")
                            .font(TerminalFont.data(10, weight: .bold))
                            .foregroundColor(CosmicTheme.textSecondary)

                        if let rate = driver.stats.hitRate {
                            Text(String(format: "%.0f%%", rate * 100))
                                .font(TerminalFont.data(10, weight: .bold))
                                .foregroundColor(rate >= 0.5 ? CosmicTheme.positive : CosmicTheme.negative)
                                .frame(width: 38, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(AppLayout.cardHorizontalPadding)
            .background(CosmicTheme.terminalBlack)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
            )
        }
    }

    private var sortedDrivers: [(kind: String, stats: PredictionScorecard.DriverStats)] {
        viewModel.scorecard.perDriverKind
            .map { (kind: $0.key, stats: $0.value) }
            .sorted { lhs, rhs in
                if lhs.stats.scored != rhs.stats.scored {
                    return lhs.stats.scored > rhs.stats.scored
                }
                return lhs.kind < rhs.kind
            }
    }

    private func driverDisplayName(_ kind: String) -> String {
        AstroOverlayEventKind(rawValue: kind)?.displayName ?? kind
    }

    private func driverIcon(_ kind: String) -> String {
        AstroOverlayEventKind(rawValue: kind)?.iconSystemName ?? "sparkles"
    }

    // MARK: - History

    @ViewBuilder
    private var historyBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CALL HISTORY")
                .font(TerminalFont.data(9, weight: .bold))
                .foregroundColor(CosmicTheme.gold)
                .tracking(0.8)

            if viewModel.history.isEmpty {
                Text("No calls recorded yet. The ledger starts with your next Today reading.")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(viewModel.history) { record in
                    historyRow(record)
                }
            }
        }
        .padding(AppLayout.cardHorizontalPadding)
        .background(CosmicTheme.terminalBlack)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func historyRow(_ record: PredictionRecord) -> some View {
        // After-close and market-closed days stay visible but muted: shown
        // for the record, excluded from the stats.
        let isMuted = record.recordedAfterClose
            || record.claims.allSatisfy { $0.outcome?.result == .marketClosed }

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(record.tradingDayDisplayLabel)
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(isMuted ? CosmicTheme.textMuted : CosmicTheme.textSecondary)

                if record.recordedAfterClose {
                    Text("AFTER CLOSE — NOT SCORED")
                        .font(TerminalFont.data(8, weight: .semibold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(0.5)
                }

                Spacer(minLength: 4)
            }

            if record.isNoCall {
                Text("Abstained — no market-backed cosmic pattern was active.")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(record.claims) { claim in
                    HStack(spacing: 6) {
                        Text(claim.subject.displayLabel)
                            .font(TerminalFont.data(9, weight: .semibold))
                            .foregroundColor(isMuted ? CosmicTheme.textMuted : CosmicTheme.textPrimary)

                        Text(claim.cosmicDriver)
                            .font(TerminalFont.data(9))
                            .foregroundColor(CosmicTheme.textMuted)
                            .lineLimit(1)

                        Text(claim.direction.displayLabel)
                            .font(TerminalFont.data(8, weight: .semibold))
                            .foregroundColor(isMuted ? CosmicTheme.textMuted : directionColor(claim.direction))

                        Spacer(minLength: 4)

                        if let outcome = claim.outcome {
                            if let actual = outcome.actualReturnPercent {
                                Text(String(format: "%+.2f%%", actual))
                                    .font(TerminalFont.data(9))
                                    .foregroundColor(isMuted ? CosmicTheme.textMuted : (actual >= 0 ? CosmicTheme.positive : CosmicTheme.negative))
                            }
                            Text(outcome.result.displayLabel)
                                .font(TerminalFont.data(8, weight: .bold))
                                .foregroundColor(isMuted ? CosmicTheme.textMuted : resultColor(outcome.result))
                        } else {
                            Text("PENDING")
                                .font(TerminalFont.data(8, weight: .semibold))
                                .foregroundColor(CosmicTheme.textMuted)
                        }
                    }
                }
            }

            Divider()
                .background(CosmicTheme.divider)
        }
        .padding(.vertical, 2)
    }

    private func directionColor(_ direction: PredictionDirection) -> Color {
        switch direction {
        case .bullish: return CosmicTheme.positive
        case .bearish: return CosmicTheme.negative
        case .neutral: return CosmicTheme.neutral
        }
    }

    private func resultColor(_ result: PredictionResult) -> Color {
        switch result {
        case .hit: return CosmicTheme.positive
        case .miss: return CosmicTheme.negative
        case .flat, .unresolved, .marketClosed: return CosmicTheme.textMuted
        }
    }
}
