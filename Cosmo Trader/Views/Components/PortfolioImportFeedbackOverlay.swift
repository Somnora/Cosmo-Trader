import SwiftUI

// MARK: - PortfolioImportFeedbackOverlay
// ======================================
// Post-import confirmation banner pinned to the top of the Portfolio tab,
// extracted verbatim from PortfolioView (view-size ratchet). Reads and
// clears AppState.portfolioImportFeedback.

struct PortfolioImportFeedbackOverlay: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        if let feedback = appState.portfolioImportFeedback {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.positive)

                VStack(alignment: .leading, spacing: 3) {
                    Text(feedback.title.uppercased())
                        .font(TerminalFont.data(10, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .tracking(1)

                    Text(feedback.detail)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button {
                    appState.portfolioImportFeedback = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("Dismiss portfolio import confirmation")
            }
            .padding(12)
            .background(CosmicTheme.cardBackground.opacity(0.96))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.positive.opacity(0.45), lineWidth: 1)
            )
            .padding(.horizontal, AppLayout.screenHorizontalPadding)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityIdentifier("portfolio.importConfirmation")
        }
    }
}
