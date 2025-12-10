import SwiftUI

// MARK: - ProfileView
// ====================
// The Profile tab - the user's cosmic investor identity.
//
// STRUCTURE:
// 1. User Header - Avatar, name, birth date, sun sign with element/modality
// 2. Cosmic Title Badge - Fun title based on sign
// 3. Astrological Investor Profile - Strengths, weaknesses, matches
// 4. Portfolio Stats - Value, holdings, dominant element, compatibility
// 5. Settings - Grouped by category
// 6. Fun Extras - Share profile, cosmic journey, sign out
//
// DESIGN: Personal, shareable, screenshot-worthy with cosmic personality

struct ProfileView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var viewModel: ProfileViewModel?

    // MARK: - Computed Properties

    /// Access user directly from appState for simpler bindings
    private var user: UserProfile {
        appState.currentUser ?? .sampleWithHoldings
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic background gradient
                backgroundGradient

                if let vm = viewModel {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // 1. User header with zodiac prominently displayed
                            userHeader

                            // 2. Cosmic title badge
                            cosmicTitleBadge

                            // 3. Astrological investor profile card
                            investorProfileCard

                            // 4. Portfolio cosmic stats
                            portfolioStatsCard

                            // 5. Settings sections
                            settingsSections

                            // 6. Fun extras & sign out
                            funExtrasSection

                            signOutButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                } else {
                    ProgressView()
                        .tint(CosmicTheme.gold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(CosmicTheme.gold)
                        Text("Profile")
                            .font(.headline)
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel?.startEditing() }) {
                        Text("Edit")
                            .foregroundColor(CosmicTheme.gold)
                    }
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: showingShareSheetBinding) {
                ShareSheet(text: viewModel?.shareableProfileText ?? "")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ProfileViewModel(appState: appState)
            }
        }
    }

    // MARK: - Bindings

    private var showingShareSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.showingShareSheet ?? false },
            set: { viewModel?.showingShareSheet = $0 }
        )
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                CosmicTheme.background,
                Color(red: 0.08, green: 0.04, blue: 0.20)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - User Header

    private var userHeader: some View {
        VStack(spacing: 16) {
            // Large zodiac avatar
            ZStack {
                // Outer ring with element color
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                user.sunSign.element.color,
                                user.sunSign.element.color.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 120, height: 120)

                // Inner circle with cosmic gradient
                Circle()
                    .fill(CosmicTheme.cosmicGradient)
                    .frame(width: 108, height: 108)

                // Zodiac symbol
                Text(user.sunSign.symbol)
                    .font(.system(size: 56))
            }

            // User name and info
            VStack(spacing: 8) {
                Text(user.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                // Birth date
                HStack(spacing: 4) {
                    Image(systemName: "birthday.cake")
                        .font(.caption)
                    Text(viewModel?.formattedBirthDate ?? "")
                }
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)

                // Sun sign with element and modality
                HStack(spacing: 12) {
                    // Sun sign
                    HStack(spacing: 4) {
                        Text(user.sunSign.symbol)
                        Text(user.sunSign.displayName)
                    }
                    .foregroundColor(CosmicTheme.gold)

                    Text("·")
                        .foregroundColor(CosmicTheme.textMuted)

                    // Element
                    HStack(spacing: 4) {
                        Text(user.sunSign.element.emoji)
                        Text(user.sunSign.element.displayName)
                    }
                    .foregroundColor(user.sunSign.element.color)

                    Text("·")
                        .foregroundColor(CosmicTheme.textMuted)

                    // Modality
                    Text(user.sunSign.modality.displayName)
                        .foregroundColor(CosmicTheme.textSecondary)
                }
                .font(.caption)
                .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(user.sunSign.element.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Cosmic Title Badge

    private var cosmicTitleBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(CosmicTheme.goldGradient)

            Text(viewModel?.cosmicTitle ?? "")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(CosmicTheme.textPrimary)

            Image(systemName: "sparkles")
                .foregroundStyle(CosmicTheme.goldGradient)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    Capsule()
                        .stroke(CosmicTheme.goldGradient, lineWidth: 1)
                )
        )
    }

    // MARK: - Investor Profile Card

    private var investorProfileCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Card header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Astrological Investor Profile")
                        .font(.headline)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("Based on your \(user.sunSign.displayName) energy")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()

                // Element badge
                Text(user.sunSign.element.emoji)
                    .font(.title)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(user.sunSign.element.color.opacity(0.2))
                    )
            }

            // Personality quote
            Text("\"\(user.sunSign.corporatePersonality)\"")
                .font(.subheadline)
                .italic()
                .foregroundColor(CosmicTheme.textSecondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(user.sunSign.element.color.opacity(0.1))
                )

            // Strengths
            strengthsSection

            // Weaknesses
            weaknessesSection

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.3))

            // Compatibility matches
            compatibilityMatchesSection
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private var strengthsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(CosmicTheme.positive)
                Text("Investor Strengths")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel?.investorStrengths ?? [], id: \.self) { strength in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(CosmicTheme.positive)
                            .frame(width: 6, height: 6)
                        Text(strength)
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }
            }
            .padding(.leading, 4)
        }
    }

    private var weaknessesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(CosmicTheme.negative)
                Text("Watch Out For")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel?.investorWeaknesses ?? [], id: \.self) { weakness in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(CosmicTheme.negative)
                            .frame(width: 6, height: 6)
                        Text(weakness)
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }
            }
            .padding(.leading, 4)
        }
    }

    private var compatibilityMatchesSection: some View {
        HStack(spacing: 24) {
            // Best matches
            VStack(alignment: .leading, spacing: 8) {
                Text("Best Stock Signs")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 4) {
                    ForEach(viewModel?.bestMatches.prefix(4) ?? [], id: \.self) { sign in
                        Text(sign.symbol)
                            .font(.title3)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(CosmicTheme.positive.opacity(0.2))
                            )
                    }
                }
            }

            // Challenging matches
            VStack(alignment: .leading, spacing: 8) {
                Text("Challenging Signs")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 4) {
                    ForEach(viewModel?.challengingMatches.prefix(4) ?? [], id: \.self) { sign in
                        Text(sign.symbol)
                            .font(.title3)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(CosmicTheme.negative.opacity(0.2))
                            )
                    }
                }
            }
        }
    }

    // MARK: - Portfolio Stats Card

    private var portfolioStatsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("Portfolio Cosmic Stats")
                .font(.headline)
                .foregroundColor(CosmicTheme.textPrimary)

            // Main stats row
            HStack(spacing: 0) {
                statItem(
                    icon: "dollarsign.circle.fill",
                    title: "Total Value",
                    value: viewModel?.formattedPortfolioValue ?? "$0",
                    color: CosmicTheme.gold
                )

                Divider()
                    .frame(height: 50)
                    .background(CosmicTheme.textMuted.opacity(0.3))

                statItem(
                    icon: (viewModel?.isPositive ?? true) ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                    title: "Today",
                    value: "\(viewModel?.formattedDailyChange ?? "$0") (\(viewModel?.formattedDailyChangePercent ?? "0%"))",
                    color: (viewModel?.isPositive ?? true) ? CosmicTheme.positive : CosmicTheme.negative
                )
            }

            // Secondary stats
            HStack(spacing: 0) {
                statItem(
                    icon: "chart.pie.fill",
                    title: "Holdings",
                    value: "\(viewModel?.holdingsCount ?? 0) positions",
                    color: CosmicTheme.textSecondary
                )

                Divider()
                    .frame(height: 50)
                    .background(CosmicTheme.textMuted.opacity(0.3))

                statItem(
                    icon: "percent",
                    title: "Avg Compatibility",
                    value: "\(user.averagePortfolioCompatibility)%",
                    color: CosmicTheme.gold
                )
            }

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.3))

            // Cosmic insights row
            HStack(spacing: 16) {
                // Dominant element
                if let element = viewModel?.dominantElement {
                    cosmicInsightItem(
                        emoji: element.emoji,
                        label: "Dominant Element",
                        value: element.displayName,
                        color: element.color
                    )
                }

                if viewModel?.dominantElement != nil && viewModel?.mostCompatibleStock != nil {
                    Divider()
                        .frame(height: 40)
                        .background(CosmicTheme.textMuted.opacity(0.3))
                }

                // Most compatible holding
                if let stock = viewModel?.mostCompatibleStock {
                    cosmicInsightItem(
                        emoji: stock.zodiacSign.symbol,
                        label: "Best Match Held",
                        value: stock.symbol,
                        color: CosmicTheme.positive
                    )
                }
            }

            // All-time gain
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(CosmicTheme.textMuted)
                Text("All-time: \(viewModel?.formattedAllTimeGainLoss ?? "$0")")
                    .font(.caption)
                    .foregroundColor((viewModel?.allTimeGainLoss ?? 0) >= 0 ? CosmicTheme.positive : CosmicTheme.negative)

                Spacer()

                Text("Member for \(viewModel?.cosmicJourneyDuration ?? "")")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func statItem(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private func cosmicInsightItem(emoji: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.title2)
                .padding(8)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Settings Sections

    private var settingsSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(CosmicTheme.textPrimary)

            // Notifications
            settingsGroup(
                title: "Notifications",
                icon: "bell.fill",
                settings: viewModel?.settings.filter { $0.category == .notifications } ?? []
            )

            // Appearance
            settingsGroup(
                title: "Appearance",
                icon: "paintbrush.fill",
                settings: viewModel?.settings.filter { $0.category == .appearance } ?? []
            )

            // Preferences
            settingsGroup(
                title: "Preferences",
                icon: "slider.horizontal.3",
                settings: viewModel?.settings.filter { $0.category == .preferences } ?? []
            )
        }
    }

    private func settingsGroup(title: String, icon: String, settings: [SettingItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Settings rows
            VStack(spacing: 0) {
                ForEach(settings) { setting in
                    SettingRow(
                        setting: setting,
                        onToggle: { viewModel?.toggleSetting(setting) }
                    )

                    if setting.id != settings.last?.id {
                        Divider()
                            .background(CosmicTheme.textMuted.opacity(0.2))
                            .padding(.leading, 48)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Fun Extras

    private var funExtrasSection: some View {
        VStack(spacing: 12) {
            // Share profile button
            Button(action: { viewModel?.showingShareSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share My Cosmic Profile")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Let the world know your investor identity")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .foregroundColor(CosmicTheme.textPrimary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(CosmicTheme.goldGradient, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            // Cosmic journey stats
            HStack(spacing: 16) {
                cosmicJourneyItem(
                    icon: "star.fill",
                    value: "\(viewModel?.holdingsCount ?? 0)",
                    label: "Stocks Held"
                )

                cosmicJourneyItem(
                    icon: "calendar",
                    value: viewModel?.cosmicJourneyDuration ?? "",
                    label: "Cosmic Journey"
                )

                cosmicJourneyItem(
                    icon: "sparkles",
                    value: "\(user.sunSign.compatibleSigns.count)",
                    label: "Compatible Signs"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private func cosmicJourneyItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button(action: { viewModel?.signOut() }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(CosmicTheme.negative)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CosmicTheme.negative.opacity(0.5), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Setting Row Component

struct SettingRow: View {
    let setting: SettingItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: setting.icon)
                .font(.body)
                .foregroundColor(CosmicTheme.gold)
                .frame(width: 28)

            Text(setting.name)
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textPrimary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { setting.isEnabled },
                set: { _ in onToggle() }
            ))
            .tint(CosmicTheme.gold)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Profile View") {
    ProfileView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}

#Preview("Profile View - Light") {
    ProfileView()
        .environment(AppState.preview)
        .preferredColorScheme(.light)
}
