import SwiftUI

/// Profile row that shows account-link status and opens the sign-in /
/// sign-up sheet for Cosmic Cloud Sync.
struct CosmicCloudSyncSection: View {
    @Environment(AppState.self) private var appState
    @State private var showingAuthSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "icloud.and.arrow.up.fill")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("Cosmic Cloud Sync")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            VStack(spacing: 0) {
                Button(action: { showingAuthSheet = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.key.fill")
                            .foregroundColor(CosmicTheme.gold)
                            .frame(width: 24, height: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Account Status")
                                .font(TerminalFont.data(13, weight: .semibold))
                                .foregroundColor(CosmicTheme.textPrimary)

                            if let email = appState.currentUser?.email, !email.contains("@cosmictrader.com") {
                                Text("Linked: \(email)")
                                    .font(TerminalFont.data(11))
                                    .foregroundColor(CosmicTheme.positive)
                            } else {
                                Text("Anonymous Guest Session")
                                    .font(TerminalFont.data(11))
                                    .foregroundColor(CosmicTheme.textMuted)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .terminalPanel(.standard)
        }
        .sheet(isPresented: $showingAuthSheet) {
            AuthenticationView()
                .environment(appState)
        }
    }
}
