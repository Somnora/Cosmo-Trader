import SwiftUI

struct StockDetailHistoryActivationCard: View {
    let state: StockDetailHistoryActivationState
    let isLoading: Bool
    let onLoadHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Text(state.detail)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(state.sectionStatuses) { item in
                    sectionRow(item)
                }
            }

            if state.shouldShowAction {
                Button(action: onLoadHistory) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.65)
                                .tint(CosmicTheme.gold)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                        }

                        Text(isLoading ? "LOADING PROVIDER HISTORY" : (state.actionTitle ?? "LOAD PROVIDER HISTORY"))
                            .font(TerminalFont.data(10, weight: .bold))
                            .tracking(0.8)
                    }
                    .foregroundColor(CosmicTheme.gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(CosmicTheme.gold.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(CosmicTheme.gold.opacity(0.35), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel(isLoading ? "Loading provider history" : (state.actionTitle ?? "Load provider history"))
            }
        }
        .padding(12)
        .background(CosmicTheme.cardBackground.opacity(0.58))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("HISTORY STATUS")
                    .font(TerminalFont.data(8, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(0.8)

                Text(state.headline)
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            Spacer(minLength: 8)

            DataSourceIndicator(provenance: state.provenance, size: .compact)
        }
    }

    private func sectionRow(_ item: StockDetailHistorySectionStatus) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(statusDotColor)
                .frame(width: 6, height: 6)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.uppercased())
                    .font(TerminalFont.data(8, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(0.6)

                Text(item.detail)
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(2)
            }
        }
    }

    private var iconName: String {
        switch state.displayMode {
        case .providerBacked, .cached:
            return "checkmark.seal"
        case .loading:
            return "clock"
        case .stale:
            return "clock.badge.exclamationmark"
        case .partial, .insufficient:
            return "chart.line.downtrend.xyaxis"
        case .notLoaded, .unavailable, .sampleOnly:
            return "tray.and.arrow.down"
        }
    }

    private var iconColor: Color {
        switch state.displayMode {
        case .providerBacked:
            return CosmicTheme.positive
        case .cached, .stale, .partial:
            return CosmicTheme.gold
        case .loading:
            return CosmicTheme.accentBlue
        case .notLoaded, .insufficient, .unavailable, .sampleOnly:
            return CosmicTheme.textMuted
        }
    }

    private var statusDotColor: Color {
        switch state.displayMode {
        case .providerBacked, .cached:
            return CosmicTheme.positive
        case .stale, .partial, .loading:
            return CosmicTheme.gold
        case .notLoaded, .insufficient, .unavailable, .sampleOnly:
            return CosmicTheme.textMuted
        }
    }

    private var borderColor: Color {
        switch state.displayMode {
        case .providerBacked:
            return CosmicTheme.positive.opacity(0.4)
        case .cached, .stale, .partial, .loading:
            return CosmicTheme.gold.opacity(0.35)
        case .notLoaded, .insufficient, .unavailable, .sampleOnly:
            return CosmicTheme.borderDim
        }
    }

    private var accessibilityText: String {
        let sections = state.sectionStatuses
            .map { "\($0.title): \($0.detail)" }
            .joined(separator: ". ")
        return "\(state.headline). \(state.detail). \(sections)"
    }
}
