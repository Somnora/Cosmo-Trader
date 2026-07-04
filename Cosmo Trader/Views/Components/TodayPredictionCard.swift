import SwiftUI

/// Today-tab card for the cosmic scorecard (specs/prediction-ledger-mvp.md,
/// phase C): today's recorded call, the last scored close, the running
/// accuracy chip, and a push into the full scorecard.
///
/// Renders `PredictionLedgerViewModel` state only — no fetching here. All
/// copy is scanner-safe scored-entertainment framing; the compliance suite
/// enumerates it.
struct TodayPredictionCard: View {
    let viewModel: PredictionLedgerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let record = viewModel.todayRecord {
                todayBlock(record)
            } else {
                firstReadingBlock
            }

            if let lastScored = viewModel.lastScoredRecord {
                lastScoredBlock(lastScored)
            }

            NavigationLink {
                CosmicScorecardView(viewModel: viewModel)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 10))
                    Text("FULL SCORECARD")
                        .font(TerminalFont.data(9, weight: .bold))
                        .tracking(0.8)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(CosmicTheme.gold)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(CosmicTheme.panelGold.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.borderGold, lineWidth: 0.75)
                )
            }
            .accessibilityIdentifier("today.cosmicScorecard.openScorecard")

            Text("Scored record of past cosmic calls against index closes. Entertainment context only — not predictive and not financial advice.")
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
        .accessibilityIdentifier("today.cosmicScorecard")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("COSMIC SCORECARD")
                .font(TerminalFont.data(9, weight: .bold))
                .foregroundColor(CosmicTheme.gold)
                .tracking(0.8)

            Spacer(minLength: 8)

            if viewModel.scorecard.scoredCount > 0 {
                Text("COSMOS \(viewModel.scorecard.hitCount)/\(viewModel.scorecard.scoredCount)")
                    .font(TerminalFont.data(9, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)

                DataSourceIndicator(provenance: viewModel.scorecard.provenance, size: .compact)
            }
        }
    }

    @ViewBuilder
    private func todayBlock(_ record: PredictionRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY'S COSMIC CALL")
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.8)

            if record.isNoCall {
                Text("The cosmos abstained today. No market-backed cosmic pattern was active at reading time.")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(record.claims) { claim in
                    claimRow(claim)
                }

                if record.recordedAfterClose {
                    Text("Recorded after the close — kept for the record, never scored.")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var firstReadingBlock: some View {
        Text("Your first cosmic call records with today's reading. Scores land after the market close.")
            .font(TerminalFont.data(10))
            .foregroundColor(CosmicTheme.textSecondary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func claimRow(_ claim: PredictionClaim) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(claim.subject.displayLabel)
                    .font(TerminalFont.data(10, weight: .bold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(claim.direction.displayLabel)
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(directionColor(claim.direction))

                Spacer(minLength: 4)

                if let outcome = claim.outcome {
                    outcomeChip(outcome)
                }
            }

            Text(claim.historicalContextLine)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.panelElevated.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func lastScoredBlock(_ record: PredictionRecord) -> some View {
        let resolved = record.claims.filter { $0.outcome != nil }
        if !resolved.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("LAST SCORED CLOSE · \(record.tradingDayDisplayLabel)")
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(0.8)

                ForEach(resolved) { claim in
                    HStack(spacing: 6) {
                        Text(claim.subject.displayLabel)
                            .font(TerminalFont.data(9, weight: .semibold))
                            .foregroundColor(CosmicTheme.textSecondary)

                        Text(claim.cosmicDriver)
                            .font(TerminalFont.data(9))
                            .foregroundColor(CosmicTheme.textMuted)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        if let outcome = claim.outcome {
                            if let actual = outcome.actualReturnPercent {
                                Text(String(format: "%+.2f%%", actual))
                                    .font(TerminalFont.data(9, weight: .semibold))
                                    .foregroundColor(actual >= 0 ? CosmicTheme.positive : CosmicTheme.negative)
                            }
                            outcomeChip(outcome)
                        }
                    }
                }
            }
        }
    }

    private func outcomeChip(_ outcome: PredictionOutcome) -> some View {
        Text(outcome.result.displayLabel)
            .font(TerminalFont.data(8, weight: .bold))
            .tracking(0.5)
            .foregroundColor(resultColor(outcome.result))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(resultColor(outcome.result).opacity(0.6), lineWidth: 0.5)
            )
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
