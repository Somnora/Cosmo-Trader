import SwiftUI

// MARK: - TodayDataLabelGuideView
// ===============================
// The collapsible "what do these data labels mean" guide, lifted verbatim out
// of TodayMarketHoroscopeView so that view can carry the market-state card
// without growing (view-size ratchet: views render state and forward intents).
//
// Expansion stays a binding rather than local state because the first-run
// setup flow opens this guide from the parent.

struct TodayDataLabelGuideView: View {

    let explainers: [TodayDataLabelExplainer]
    @Binding var isExpanded: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("LABEL GUIDE")
                        .font(TerminalFont.data(8, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(0.7)

                    Text("Tap for data label meanings")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer(minLength: 8)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(CosmicTheme.panelElevated.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                grid
            }
        }
    }

    private var grid: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LABEL GUIDE")
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.gold)
                .tracking(0.7)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(explainers) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.label.uppercased())
                            .font(TerminalFont.data(8, weight: .bold))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text(item.detail)
                            .font(TerminalFont.data(8))
                            .foregroundColor(CosmicTheme.textMuted)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
                    .padding(8)
                    .background(CosmicTheme.panelElevated.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
                    )
                }
            }
        }
    }
}
