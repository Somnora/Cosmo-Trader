import SwiftUI
import StoreKit

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
    @State private var moonService = MoonPhaseService.shared
    @State private var audioService = TerminalAudioService.shared
    @State private var showingExportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var exportData: Data?
    @State private var showingImportPortfolio = false
    @State private var framingService = SignalFramingService.shared
    @State private var inboxUnreadCount = InboxUnreadCountStore.currentCount()
    @State private var showingManageSubscription = false

    // MARK: - Computed Properties

    /// Binding to user's signal framing level (persisted via AppState)
    private var signalFramingBinding: Binding<SignalFramingLevel> {
        Binding(
            get: { appState.currentUser?.signalFramingLevel ?? .balanced },
            set: { appState.updateSignalFramingLevel($0) }
        )
    }

    /// Access user directly from appState for simpler bindings (nil if not logged in)
    private var user: UserProfile? {
        appState.currentUser
    }

    /// Safe user access for rendering (only call when user is known to exist)
    private var safeUser: UserProfile {
        appState.currentUser ?? UserProfile(
            displayName: "",
            email: "",
            birthDate: Date()
        )
    }

    private var averageCompatibilityText: String {
        safeUser.averagePortfolioCompatibility.map { "\($0)%" } ?? "Unknown"
    }

    private var averageCompatibilityColor: Color {
        safeUser.averagePortfolioCompatibility == nil ? CosmicTheme.textMuted : CosmicTheme.gold
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic background gradient
                backgroundGradient

                if let _ = user, viewModel != nil {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            // 1. User header with zodiac prominently displayed
                            userHeader

                            // 2. Cosmic title badge
                            cosmicTitleBadge

                            // 3. Personalization and trust proof
                            personalizationTrustCard

                            // 4. Astrological investor profile card
                            investorProfileCard

                            if !AppState.isScreenshotMode {
                                // 5. Portfolio cosmic stats
                                portfolioStatsCard
                            }

                            if !AppState.isScreenshotMode {
                                // 5. Settings sections
                                settingsSections
                            }

                            if !AppState.isScreenshotMode {
                                // 6. Legal section
                                legalSection

                                // 7. Fun extras & sign out
                                funExtrasSection

                                signOutButton
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .iPadReadableContent(maxWidth: 980)
                    }
                    .contentShape(Rectangle())
                    .tabBarSafeBottomPadding()
                } else if user == nil {
                    // No user - show empty state
                    CosmicEmptyStateView(
                        title: "No Profile",
                        message: "Complete onboarding to set up your investor profile.",
                        icon: "person.crop.circle.badge.questionmark"
                    )
                } else {
                    ProgressView()
                        .tint(CosmicTheme.gold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PROFILE")
                        .font(TerminalFont.data(13, weight: .semibold))
                        .tracking(1.8)
                        .foregroundColor(CosmicTheme.textPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel?.startEditing() }) {
                        Text("Edit")
                            .foregroundColor(viewModel != nil ? CosmicTheme.gold : CosmicTheme.textMuted)
                    }
                    .disabled(viewModel == nil)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: showingShareSheetBinding) {
                ShareSheet(text: viewModel?.shareableProfileText ?? "")
            }
            .sheet(isPresented: isEditingBinding) {
                if let viewModel = viewModel {
                    ProfileEditSheet(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    DataExportShareSheet(
                        data: data,
                        filename: appState.generateExportFilename()
                    )
                }
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    AnalyticsService.shared.track(.deleteDataCancelled)
                }
                Button("Delete Everything", role: .destructive) {
                    confirmDataDeletion()
                }
            } message: {
                Text("This permanently deletes your profile, portfolio, watchlist, preferences, and usage counters on this device. The anonymous sign-in session and anonymous device ID used for backend requests are not cleared and remain until you delete the app. This action cannot be undone.")
            }
            .sheet(isPresented: $showingImportPortfolio) {
                ImportPortfolioView()
            }
        }
        .task {
            // Initialize viewModel if needed (async-safe)
            if viewModel == nil {
                viewModel = ProfileViewModel(appState: appState)
            }
            if appState.currentUser != nil {
                await ReferralService.shared.qualifyReferralIfNeeded(
                    milestone: .firstProfileOpen,
                    storageKey: ReferralMilestone.firstProfileOpen.qualificationStorageKey
                )
            }
            inboxUnreadCount = InboxUnreadCountStore.currentCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .inboxUnreadCountUpdated)) { notification in
            if let count = notification.userInfo?["count"] as? Int {
                inboxUnreadCount = max(0, count)
            } else {
                inboxUnreadCount = InboxUnreadCountStore.currentCount()
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

    private var isEditingBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.isEditing ?? false },
            set: { viewModel?.isEditing = $0 }
        )
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        // Flat OLED black. No purple wash. Dimensionality comes from
        // tinted panels, not from a tinted background.
        CosmicTheme.background
            .ignoresSafeArea()
    }

    // MARK: - User Header

    private var userHeader: some View {
        VStack(spacing: 0) {
            // Operator strip - terminal label across the top
            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.gold)

                Text("OPERATOR")
                    .font(TerminalFont.data(9, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1.4)

                Spacer()

                Text("ID / \(safeUser.sunSign.displayName.uppercased())")
                    .font(TerminalFont.data(9, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(CosmicTheme.panelElevated)
            .overlay(
                Rectangle()
                    .fill(CosmicTheme.borderNavy)
                    .frame(height: 1),
                alignment: .bottom
            )

            // Identity body
            HStack(spacing: 16) {
                // Compact zodiac glyph - thin gold ring, navy core
                ZStack {
                    Rectangle()
                        .fill(CosmicTheme.panelNavy)
                        .frame(width: 64, height: 64)

                    Rectangle()
                        .stroke(CosmicTheme.gold.opacity(0.55), lineWidth: 1)
                        .frame(width: 64, height: 64)

                    ZodiacSymbolView(sign: safeUser.sunSign, size: 32, color: CosmicTheme.gold)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(safeUser.displayName)
                        .font(TerminalFont.headline(20))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(viewModel?.formattedBirthDate.uppercased() ?? "")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)

                    HStack(spacing: 8) {
                        Text(safeUser.sunSign.displayName.uppercased())
                            .foregroundColor(CosmicTheme.gold)

                        Text("·")
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(safeUser.sunSign.element.displayName.uppercased())
                            .foregroundColor(CosmicTheme.steelBlue)

                        Text("·")
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(safeUser.sunSign.modality.displayName.uppercased())
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                    .font(TerminalFont.data(10, weight: .semibold))
                    .tracking(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .terminalPanel(.elevated, cornerRadius: 4)
    }

    // MARK: - Cosmic Title Badge

    private var cosmicTitleBadge: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(CosmicTheme.gold.opacity(0.55))
                .frame(width: 4, height: 14)

            Text((viewModel?.cosmicTitle ?? "").uppercased())
                .font(TerminalFont.data(11, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)
                .tracking(1.6)

            Rectangle()
                .fill(CosmicTheme.gold.opacity(0.55))
                .frame(width: 4, height: 14)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .terminalPanel(.gold, cornerRadius: 2)
    }

    // MARK: - Investor Profile Card

    private var investorProfileCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Card header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INVESTOR PROFILE")
                        .font(TerminalFont.data(10, weight: .semibold))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(1.4)

                    Text("Based on your \(safeUser.sunSign.displayName) energy")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()

                // Element badge - sharp square, not a soft circle
                ElementSymbolView(element: safeUser.sunSign.element, size: 24)
                    .padding(10)
                    .background(CosmicTheme.panelElevated)
                    .overlay(
                        Rectangle()
                            .stroke(safeUser.sunSign.element.color.opacity(0.4), lineWidth: 1)
                    )
            }

            // Personality quote
            Text("\"\(safeUser.sunSign.corporatePersonality)\"")
                .font(.subheadline)
                .italic()
                .foregroundColor(CosmicTheme.textSecondary)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .terminalPanel(.standard)

            // Strengths
            strengthsSection

            // Weaknesses
            weaknessesSection

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            // Compatibility matches
            compatibilityMatchesSection
        }
        .padding(16)
        .terminalPanel(.elevated, cornerRadius: 4)
    }

    private var strengthsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(CosmicTheme.positive)
                Text("Investor Strengths")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(CosmicTheme.negative)
                Text("Watch Out For")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
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
                Text("Signs You Sync With")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 4) {
                    ForEach(viewModel?.bestMatches.prefix(4) ?? [], id: \.self) { sign in
                        ZodiacSymbolView(sign: sign, size: 20, color: CosmicTheme.positive)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(CosmicTheme.positive.opacity(0.2))
                            )
                    }
                }
            }

            // Challenging matches
            VStack(alignment: .leading, spacing: 8) {
                Text("Signs To Read Carefully")
                    .font(TerminalFont.data(11, weight: .medium))
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 4) {
                    ForEach(viewModel?.challengingMatches.prefix(4) ?? [], id: \.self) { sign in
                        ZodiacSymbolView(sign: sign, size: 20, color: CosmicTheme.negative)
                            .padding(8)
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
            Text("PORTFOLIO READOUT")
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)
                .tracking(1.4)

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
                    .background(CosmicTheme.textMuted.opacity(0.4))

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
                    .background(CosmicTheme.textMuted.opacity(0.4))

                statItem(
                    icon: "percent",
                    title: "Avg Compatibility",
                    value: averageCompatibilityText,
                    color: averageCompatibilityColor
                )
            }

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.4))

            // Cosmic insights row
            HStack(spacing: 16) {
                // Dominant element
                if let element = viewModel?.dominantElement {
                    cosmicInsightItem(
                        element: element,
                        label: "Dominant Element",
                        value: element.displayName,
                        color: element.color
                    )
                }

                if viewModel?.dominantElement != nil && viewModel?.mostCompatibleStock != nil {
                    Divider()
                        .frame(height: 40)
                        .background(CosmicTheme.textMuted.opacity(0.4))
                }

                // Most compatible holding
                if let stock = viewModel?.mostCompatibleStock,
                   let foundedZodiacSign = stock.foundedZodiacSign {
                    cosmicInsightItem(
                        sign: foundedZodiacSign,
                        label: "Best Match Held",
                        value: stock.symbol,
                        color: CosmicTheme.positive
                    )
                }
            }

            // Member duration (all-time gain/loss hidden until cost basis tracking is implemented)
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(CosmicTheme.textMuted)
                Text("Member for \(viewModel?.cosmicJourneyDuration ?? "")")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                Spacer()
            }
        }
        .padding(18)
        .terminalPanel(.elevated, cornerRadius: 4)
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

    private func cosmicInsightItem(element: ZodiacSign.Element, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ElementSymbolView(element: element, size: 24, color: color)
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
                    .font(TerminalFont.data(13))
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cosmicInsightItem(sign: ZodiacSign, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZodiacSymbolView(sign: sign, size: 24, color: color)
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
                    .font(TerminalFont.data(13))
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var personalizationTrustCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.below.square.filled.and.square")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text("PERSONALIZATION / TRUST")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1.2)

                Spacer()

                SignalFramingIndicator(level: signalFramingBinding.wrappedValue)
            }

            Text("Choose how direct the reading gets: rational market context, balanced lens language, or more astrological framing.")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text("The tone changes. The guardrail does not: readings are context, not financial advice.")
                .font(TerminalFont.data(11, weight: .medium))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .terminalPanel(.standard)
        }
        .padding(14)
        .terminalPanel(.navy, cornerRadius: 4)
    }

    // MARK: - Settings Sections

    private var settingsSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(CosmicTheme.textPrimary)

            if !AppState.isScreenshotMode {
                // Subscription Status
                subscriptionSection

                // Notifications - comprehensive settings
                notificationSettingsSection

                // Lunar Alerts (quick toggles - synced with NotificationService)
                lunarAlertsSection
            }

            // Appearance
            settingsGroup(
                title: "Appearance",
                icon: "paintbrush.fill",
                settings: viewModel?.settings.filter { $0.category == .appearance } ?? []
            )

            // Signal Framing
            signalFramingSection

            // Terminal Audio
            terminalAudioSection

            // Preferences
            settingsGroup(
                title: "Preferences",
                icon: "slider.horizontal.3",
                settings: viewModel?.settings.filter { $0.category == .preferences } ?? []
            )

            // Portfolio Management
            portfolioManagementSection

            if LaunchSurfacePolicy.showsUnprovenGrowthSurfaces {
                referralSection
            }

            // Privacy & Data (GDPR)
            privacyDataSection

            if LaunchSurfacePolicy.showsInternalDiagnostics {
                backendStatusSection
            }
        }
    }

    // MARK: - Portfolio Management Section

    private var portfolioManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("Portfolio")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            VStack(spacing: 0) {
                // Import from CSV
                Button(action: { showingImportPortfolio = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.body)
                            .foregroundColor(CosmicTheme.gold)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import Portfolio")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text("Fastest path to a real daily reading: screenshot or CSV")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.cardBackground)
            )

            // Helper text
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)

                Text("Your reading gets sharper once Cosmo knows what you own. Start with 3-5 tickers and refine later.")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Privacy & Data Section (GDPR)

    private var privacyDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "hand.raised.fill")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("Privacy & Data")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            VStack(spacing: 0) {
                // Analytics Opt-Out
                HStack(spacing: 12) {
                    Image(systemName: "chart.pie.fill")
                        .font(.body)
                        .foregroundColor(CosmicTheme.textSecondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share Analytics Data")
                            .font(.subheadline)
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text("Help improve the app with anonymous usage data")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { !AnalyticsService.shared.hasOptedOut },
                        set: { isEnabled in
                            AnalyticsService.shared.setOptOut(!isEnabled)
                        }
                    ))
                    .tint(CosmicTheme.gold)
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                // Export My Data
                Button(action: { exportMyData() }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                            .foregroundColor(CosmicTheme.textSecondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export My Data")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text("Download all your data as JSON")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("profile.backendStatusLink")

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                // Delete All Data
                Button(action: { requestDataDeletion() }) {
                    HStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(CosmicTheme.negative)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete All Data")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.negative)

                            Text("Reset profile, portfolio, watchlist, preferences")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.cardBackground)
            )

            // GDPR info text
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)

                Text("Your data is stored locally on your device. Export creates a portable JSON file with all your information.")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Referral Section

    private var referralSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("Referrals")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            VStack(spacing: 0) {
                NavigationLink(destination: ReferralCodeView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "ticket.fill")
                            .font(.body)
                            .foregroundColor(CosmicTheme.gold)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Referral Code")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)
                            Text("Apply a code")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                NavigationLink(destination: ReferralLeaderboardView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "list.number")
                            .font(.body)
                            .foregroundColor(CosmicTheme.gold)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Referral Leaderboard")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)
                            Text("Top referrers")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                NavigationLink(destination: RewardsStatusView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "gift.fill")
                            .font(.body)
                            .foregroundColor(CosmicTheme.gold)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rewards")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)
                            Text("Credits and premium status")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Backend Diagnostics

    private var backendStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("App Status")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            VStack(spacing: 0) {
                NavigationLink(destination: BackendStatusView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .font(.body)
                            .foregroundColor(CosmicTheme.gold)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connection Status")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text("Check service availability")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                NavigationLink(destination: ProfileSyncView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.body)
                            .foregroundColor(CosmicTheme.gold)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Profile Sync")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)
                            Text("Sync zodiac, risk, and notifications")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                NavigationLink(destination: InboxListView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "tray.full.fill")
                            .font(.body)
                            .foregroundColor(CosmicTheme.gold)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Inbox")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)
                            Text("Messages and updates")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        if inboxUnreadCount > 0 {
                            Text(inboxUnreadCount > 99 ? "99+" : "\(inboxUnreadCount)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(CosmicTheme.background)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(CosmicTheme.gold)
                                )
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                NavigationLink(destination: DailyBriefBackendView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.image.fill")
                            .font(.body)
                            .foregroundColor(CosmicTheme.gold)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily Brief")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)
                            Text("Latest market brief with refresh")
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Data Export/Delete Actions

    private func exportMyData() {
        // Track analytics
        AnalyticsService.shared.track(.dataExported)

        // Generate export data
        if let data = appState.exportUserDataAsData() {
            exportData = data
            showingExportSheet = true
        }
    }

    private func requestDataDeletion() {
        // Track analytics
        AnalyticsService.shared.track(.deleteDataRequested)

        showingDeleteConfirmation = true
    }

    private func confirmDataDeletion() {
        // Track analytics
        AnalyticsService.shared.track(.deleteDataConfirmed)

        // Delete all data
        appState.deleteAllUserData()
    }

    // MARK: - Subscription Section

    @ViewBuilder
    private var subscriptionSection: some View {
        let subscriptionManager = SubscriptionManager.shared

        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("Subscription")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Status card
            subscriptionStatusCard(subscriptionManager)
        }
        .manageSubscriptionsSheet(isPresented: $showingManageSubscription)
    }

    @ViewBuilder
    private func subscriptionStatusCard(_ manager: SubscriptionManager) -> some View {
        if manager.isPremium {
            VStack(alignment: .leading, spacing: 10) {
            // Premium user card
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(CosmicTheme.gold.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(CosmicTheme.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Oracle Tier")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(CosmicTheme.gold)

                        if manager.isInTrial {
                            Text("TRIAL")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(CosmicTheme.terminalBlack)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(CosmicTheme.gold)
                                )
                        }
                    }

                    if manager.isInTrial {
                        Text("\(manager.trialDaysRemaining) days remaining")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                    } else {
                        Text("Full reading library unlocked")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(CosmicTheme.gold)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.gold.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                    )
            )

                Button {
                    showingManageSubscription = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gear")
                            .font(.caption2)
                        Text("Manage Subscription")
                            .font(.caption)
                    }
                    .foregroundColor(CosmicTheme.textSecondary)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Manage Subscription")
                .accessibilityHint("Open Apple subscription management")
            }
        } else {
            // Free user card with upgrade prompt
            SubscriptionUpgradeCard()
        }
    }

    // MARK: - Notification Settings Section

    private var notificationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("Notifications")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Notification settings card with navigation
            VStack(spacing: 0) {
                NotificationSettingsCard()
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Lunar Alerts Section

    private var lunarAlertsSection: some View {
        let subscriptionManager = SubscriptionManager.shared

        return VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "moon.stars.fill")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("Lunar Alerts")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()

                // Premium badge for premium features
                if !subscriptionManager.isPremium {
                    OracleBadge(style: .inline)
                }
            }

            // Settings rows
            VStack(spacing: 0) {
                // Full moon alert (free)
                LunarSettingRow(
                    icon: "circle.fill",
                    title: "Full Moon Alert",
                    subtitle: "Calendar marker reminder",
                    isEnabled: moonService.notifyOnFullMoon,
                    onToggle: {
                        moonService.notifyOnFullMoon.toggle()
                        moonService.scheduleNotifications()
                    }
                )

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                // New moon alert (free)
                LunarSettingRow(
                    icon: "circle",
                    title: "New Moon Alert",
                    subtitle: "Quiet calendar marker",
                    isEnabled: moonService.notifyOnNewMoon,
                    onToggle: {
                        moonService.notifyOnNewMoon.toggle()
                        moonService.scheduleNotifications()
                    }
                )

                // Moon in Sign Alert (PREMIUM)
                if subscriptionManager.isPremium {
                    Divider()
                        .background(CosmicTheme.textMuted.opacity(0.3))
                        .padding(.leading, 48)

                    LunarSettingRow(
                        icon: "moon.stars.fill",
                        title: "Moon in Your Sign",
                        subtitle: "Alert when moon enters \(safeUser.sunSign.displayName)",
                        isEnabled: moonService.notifyOnMoonInUserSign,
                        onToggle: {
                            moonService.notifyOnMoonInUserSign.toggle()
                            moonService.userSunSign = safeUser.sunSign
                            moonService.scheduleNotifications()
                        }
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.cardBackground)
            )

            // Premium locked feature (if not premium)
            if !subscriptionManager.isPremium {
                FeatureLockedBanner(feature: .moonSignAlerts)
            }

            // Info text
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)

                Text("Alerts sent 1 day before and on the day of significant lunar events")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Terminal Audio Section

    private var terminalAudioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("Terminal Audio")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()

                Text("IMMERSIVE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.gold.opacity(0.7))
            }

            VStack(spacing: 0) {
                // Main toggle
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.body)
                        .foregroundColor(audioService.isEnabled ? CosmicTheme.gold : CosmicTheme.textMuted)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Terminal Sounds")
                            .font(.subheadline)
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text("Subtle Bloomberg-style ambiance")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { audioService.isEnabled },
                        set: { newValue in
                            audioService.isEnabled = newValue
                            if newValue {
                                AnalyticsService.shared.track(.terminalAudioEnabled)
                            } else {
                                AnalyticsService.shared.track(.terminalAudioDisabled)
                            }
                        }
                    ))
                    .tint(CosmicTheme.gold)
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if audioService.isEnabled {
                    Divider()
                        .background(CosmicTheme.textMuted.opacity(0.3))
                        .padding(.leading, 48)

                    // Ambient volume slider
                    HStack(spacing: 12) {
                        Image(systemName: "waveform.path")
                            .font(.body)
                            .foregroundColor(CosmicTheme.textSecondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ambient Volume")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)

                            Slider(value: Binding(
                                get: { Double(audioService.ambientVolume) },
                                set: { audioService.ambientVolume = Float($0) }
                            ), in: 0...0.5)
                            .tint(CosmicTheme.gold)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider()
                        .background(CosmicTheme.textMuted.opacity(0.3))
                        .padding(.leading, 48)

                    // Effects volume slider
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.body)
                            .foregroundColor(CosmicTheme.textSecondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sound Effects")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)

                            Slider(value: Binding(
                                get: { Double(audioService.effectsVolume) },
                                set: { audioService.effectsVolume = Float($0) }
                            ), in: 0...0.5)
                            .tint(CosmicTheme.gold)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.cardBackground)
            )
            .animation(.easeInOut(duration: 0.2), value: audioService.isEnabled)

            // Info text
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)

                Text("Subtle sounds include ticker tape rhythm, price update chimes, and gentle tab transitions. Respects device silent mode.")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Reading Framing Section

    private var signalFramingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.below.square.filled.and.square")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("Reading Framing")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()

                // Current level indicator
                SignalFramingIndicator(level: signalFramingBinding.wrappedValue)
            }

            VStack(spacing: 0) {
                // Slider row
                VStack(alignment: .leading, spacing: 16) {
                    // Explanation text
                    Text("Control how market astrology readings are presented")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)

                    // The slider
                    SignalFramingSlider(level: signalFramingBinding)
                }
                .padding(16)

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))

                // Preview section
                VStack(alignment: .leading, spacing: 8) {
                    Text("PREVIEW")
                        .font(TerminalFont.data(9, weight: .semibold))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)

                    Text(framingPreviewText)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(CosmicTheme.background)
                        .overlay(
                            Rectangle()
                                .stroke(CosmicTheme.border, lineWidth: 1)
                        )
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.cardBackground)
            )

            // Info text
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)

                Text("Rational mode uses data-focused language. Mystical mode adds more astrological framing while staying grounded.")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 4)
        }
    }

    /// Preview text that changes based on framing level
    private var framingPreviewText: String {
        let level = signalFramingBinding.wrappedValue
        return framingService.frameHeadline(
            rational: "Market conditions suggest cautious context today",
            mystical: "Cosmic conditions favor patience and risk control today",
            level: level
        )
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
                            .background(CosmicTheme.textMuted.opacity(0.3))
                            .padding(.leading, 48)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Fun Extras

    private var funExtrasSection: some View {
        VStack(spacing: 12) {
            // SIGN STACK - Shareable trading card
            SignStackButton()

            // THE COSMIC ROAST - Viral share feature
            CosmicRoastCard(user: safeUser)

            // Karmic Ledger - Track losses as cosmic lessons
            KarmicLedgerCard()

            if LaunchSurfacePolicy.showsCosmicGraveyard {
                CosmicObituaryCard()
            }

            if LaunchSurfacePolicy.showsUnprovenGrowthSurfaces {
                ReferralCard()
            }

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
                    RoundedRectangle(cornerRadius: 6)
                        .fill(CosmicTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
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
                    label: "Member Since"
                )

                cosmicJourneyItem(
                    icon: "scope",
                    value: "\(safeUser.sunSign.compatibleSigns.count)",
                    label: "Compatible Signs"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 6)
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

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                Text("Legal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            VStack(spacing: 0) {
                // About
                LegalLinkRow(
                    icon: "info.circle.fill",
                    title: "About Cosmo Trader",
                    destination: { AboutView() }
                )

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                // Privacy Policy
                LegalLinkRow(
                    icon: "lock.shield.fill",
                    title: "Privacy Policy",
                    destination: { PrivacyPolicyView() }
                )

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                // Terms of Service
                LegalLinkRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    destination: { TermsOfServiceView() }
                )

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))
                    .padding(.leading, 48)

                // NFA Disclaimer (Important!)
                LegalLinkRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Not Financial Advice",
                    destination: { NFADisclaimerView() },
                    highlight: true
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.cardBackground)
            )

            // Disclaimer banner
            DisclaimerBanner()
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
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
                RoundedRectangle(cornerRadius: 6)
                    .stroke(CosmicTheme.negative.opacity(0.5), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Legal Link Row

struct LegalLinkRow<Destination: View>: View {
    let icon: String
    let title: String
    let destination: () -> Destination
    var highlight: Bool = false

    @State private var isPresented = false

    var body: some View {
        Button(action: { isPresented = true }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(highlight ? CosmicTheme.gold : CosmicTheme.textSecondary)
                    .frame(width: 28)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            destination()
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
    let items: [Any]

    init(items: [Any]) {
        self.items = items
    }

    init(text: String) {
        self.items = [text]
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Data Export Share Sheet

struct DataExportShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary file URL
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL)
        } catch {
            #if DEBUG
            print("[Export] Failed to write temp file: \(error)")
            #endif
        }

        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        // Exclude some activity types that don't make sense for JSON files
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .postToFacebook,
            .postToTwitter,
            .postToWeibo,
            .postToVimeo,
            .postToTencentWeibo,
            .postToFlickr
        ]

        // Clean up temp file after sharing
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: tempURL)
        }

        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Lunar Setting Row

struct LunarSettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(CosmicTheme.gold)
                .frame(width: 32)

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .tint(CosmicTheme.gold)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Profile Edit Sheet

struct ProfileEditSheet: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Current zodiac display (read-only)
                        currentSignDisplay

                        // Editable fields
                        VStack(spacing: 16) {
                            // Name field
                            nameField

                            // Birth date picker
                            birthDatePicker

                            // Time of birth picker
                            birthTimePicker
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(CosmicTheme.cardBackground)
                        )

                        // Info about sun sign and birth time
                        birthInfoSection

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                    .foregroundColor(CosmicTheme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.saveProfile()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Current Sign Display

    @ViewBuilder
    private var currentSignDisplay: some View {
        if let user = viewModel.user {
            VStack(spacing: 12) {
                // Zodiac symbol
                ZStack {
                    Circle()
                        .fill(user.sunSign.element.color.opacity(0.2))
                        .frame(width: 80, height: 80)

                    ZodiacSymbolView(
                        sign: user.sunSign,
                        size: 40,
                        color: CosmicTheme.gold
                    )
                }

                VStack(spacing: 4) {
                    Text(user.sunSign.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            ElementSymbolView(element: user.sunSign.element, size: 12)
                            Text(user.sunSign.element.displayName)
                        }
                        .foregroundColor(user.sunSign.element.color)

                        Text("·")
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(user.sunSign.modality.displayName)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                    .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Name Field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display Name")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CosmicTheme.textMuted)

            TextField("Your name", text: $viewModel.editingName)
                .font(.body)
                .foregroundColor(CosmicTheme.textPrimary)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(CosmicTheme.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(CosmicTheme.textMuted.opacity(0.4), lineWidth: 1)
                )
                .onChange(of: viewModel.editingName) { _, newValue in
                    if newValue.count > 50 {
                        viewModel.editingName = String(newValue.prefix(50))
                    }
                }
        }
    }

    // MARK: - Birth Date Picker

    private var birthDatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Birth Date")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CosmicTheme.textMuted)

            DatePicker(
                "",
                selection: $viewModel.editingBirthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(CosmicTheme.gold)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(CosmicTheme.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(CosmicTheme.textMuted.opacity(0.4), lineWidth: 1)
            )

            // Show new sign preview if date changed
            if let user = viewModel.user, viewModel.editingBirthDate != user.birthDate {
                newSignPreview
            }
        }
    }

    // MARK: - New Sign Preview

    @ViewBuilder
    private var newSignPreview: some View {
        if let user = viewModel.user {
            let newSign = ZodiacSign.from(date: viewModel.editingBirthDate)

            if newSign != user.sunSign {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(CosmicTheme.gold)

                    Text("Your sign will change to")
                        .foregroundColor(CosmicTheme.textSecondary)

                    HStack(spacing: 4) {
                        ZodiacSymbolView(sign: newSign, size: 14, color: newSign.element.color)
                        Text(newSign.displayName)
                            .fontWeight(.semibold)
                            .foregroundColor(newSign.element.color)
                    }
                }
                .font(.caption)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(CosmicTheme.gold.opacity(0.1))
                )
            }
        }
    }

    // MARK: - Birth Time Picker

    private var birthTimePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle for knowing birth time
            HStack {
                Text("Time of Birth")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textMuted)

                Spacer()

                Toggle("", isOn: $viewModel.knowsBirthTime)
                    .labelsHidden()
                    .tint(CosmicTheme.gold)
            }

            if viewModel.knowsBirthTime {
                // Time picker
                DatePicker(
                    "",
                    selection: Binding(
                        get: { viewModel.editingTimeOfBirth ?? Date() },
                        set: { viewModel.editingTimeOfBirth = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 120)
                .clipped()

                // Helper text
                Text("Birth time enables rising sign (ascendant) calculation")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
                    .italic()
            } else {
                // Unknown state
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(CosmicTheme.textMuted)

                    Text("I don't know my birth time")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(CosmicTheme.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.textMuted.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Birth Info Section

    private var birthInfoSection: some View {
        VStack(spacing: 12) {
            // Sun sign info
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(CosmicTheme.gold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sun Sign")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("Determined by your birth date. Changing it will update your astrological profile.")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.4))

            // Rising sign info
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sunrise.fill")
                    .foregroundColor(CosmicTheme.gold.opacity(0.7))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Rising Sign (Ascendant)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    if viewModel.knowsBirthTime {
                        Text("With your birth time, we can calculate your rising sign for deeper insights.")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)
                    } else {
                        Text("Add your birth time to unlock rising sign calculations and more precise readings.")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(CosmicTheme.cardBackground)
        )
    }
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

#Preview("Profile Edit Sheet") {
    ProfileEditSheet(viewModel: ProfileViewModel(appState: AppState.preview))
        .preferredColorScheme(.dark)
}
