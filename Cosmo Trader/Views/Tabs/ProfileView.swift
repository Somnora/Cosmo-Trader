import SwiftUI

/// ProfileView
/// -----------
/// The Profile tab - user info, settings, and account management.

struct ProfileView: View {

    @State private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        profileHeader

                        // Stats card
                        statsCard

                        // Settings list
                        settingsSection

                        // Sign out button
                        signOutButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Subviews

    /// User profile header with avatar
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar with zodiac
            ZStack {
                Circle()
                    .fill(CosmicTheme.cosmicGradient)
                    .frame(width: 100, height: 100)

                Text(viewModel.user.zodiacSign.symbol)
                    .font(.system(size: 50))
            }

            // User info
            VStack(spacing: 4) {
                Text(viewModel.user.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(viewModel.user.email)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)

                HStack(spacing: 4) {
                    Text(viewModel.user.zodiacSign.symbol)
                    Text(viewModel.user.zodiacSign.displayName)
                }
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
        )
    }

    /// Portfolio stats card
    private var statsCard: some View {
        VStack(spacing: 16) {
            Text("Portfolio Summary")
                .font(.headline)
                .foregroundColor(CosmicTheme.textSecondary)

            HStack(spacing: 0) {
                statItem(
                    title: "Total Value",
                    value: viewModel.formattedPortfolioValue,
                    color: CosmicTheme.textPrimary
                )

                Divider()
                    .frame(height: 40)
                    .background(CosmicTheme.textMuted)

                statItem(
                    title: "Today",
                    value: viewModel.formattedDailyChange,
                    color: viewModel.user.dailyChange >= 0 ? CosmicTheme.positive : CosmicTheme.negative
                )
            }

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(CosmicTheme.textMuted)
                Text("Member since \(viewModel.memberSinceFormatted)")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
        )
    }

    /// Single stat item
    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(CosmicTheme.textSecondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    /// Settings toggle section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)

            VStack(spacing: 0) {
                ForEach(viewModel.settings) { setting in
                    SettingRow(
                        setting: setting,
                        onToggle: { viewModel.toggleSetting(setting) }
                    )

                    if setting.id != viewModel.settings.last?.id {
                        Divider()
                            .background(CosmicTheme.textMuted.opacity(0.3))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    /// Sign out button
    private var signOutButton: some View {
        Button(action: { viewModel.signOut() }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(.headline)
            .foregroundColor(CosmicTheme.negative)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CosmicTheme.negative, lineWidth: 1)
            )
        }
    }
}

// MARK: - Setting Row Component

struct SettingRow: View {
    let setting: SettingItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: setting.icon)
                .font(.title3)
                .foregroundColor(CosmicTheme.gold)
                .frame(width: 30)

            Text(setting.name)
                .foregroundColor(CosmicTheme.textPrimary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { setting.isEnabled },
                set: { _ in onToggle() }
            ))
            .tint(CosmicTheme.gold)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
