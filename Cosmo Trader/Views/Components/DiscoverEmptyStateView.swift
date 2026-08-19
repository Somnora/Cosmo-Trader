import SwiftUI

// MARK: - DiscoverEmptyStateView
// ==============================
// The "All Caught Up" state, lifted verbatim out of DiscoverView so that view
// could take the free-tier paywall without growing (view-size ratchet: views
// render state and forward intents).
//
// It only ever forwarded three intents, so it takes three closures rather than
// a reference to the view model.

struct DiscoverEmptyStateView: View {

    let onSearch: () -> Void
    let onClearFilters: () -> Void
    let onResetSkipped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 60))
                .foregroundStyle(CosmicTheme.goldGradient)

            VStack(spacing: 8) {
                Text("All Caught Up")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Search a ticker to add it directly, or reset skipped names to rebuild the swipe deck.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: 12) {
                Button(action: {
                    HapticFeedback.medium()
                    onSearch()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                        Text("Search Symbols")
                    }
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.background)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(CosmicTheme.gold)
                    )
                }
                .accessibilityLabel("Search symbols to add to watchlist")

                HStack(spacing: 12) {
                    Button(action: {
                        HapticFeedback.light()
                        withAnimation {
                            onClearFilters()
                        }
                    }) {
                        Text("Clear Filters")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .stroke(CosmicTheme.textMuted, lineWidth: 1)
                            )
                    }

                    Button(action: {
                        HapticFeedback.medium()
                        withAnimation {
                            onResetSkipped()
                        }
                    }) {
                        Text("Reset Skipped")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(CosmicTheme.gold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .stroke(CosmicTheme.gold, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(40)
    }
}
