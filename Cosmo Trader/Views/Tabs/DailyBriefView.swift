import SwiftUI

// MARK: - DailyBriefView
// ======================
// The "Today" tab - a zen trading daily brief with cosmic conditions,
// portfolio highlights, and posture notes.
//
// DESIGN: OLED terminal aesthetic with sharp corners, monospace fonts,
// and muted gold accents. Bloomberg Terminal meets Co-Star.

struct DailyBriefView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var brief: DailyBrief?
    @State private var dailyReading: DailyFinancialReading?
    @State private var isLoading = true
    @State private var hasCheckedIn = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // OLED terminal background
                CosmicTheme.background.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let brief = brief {
                    briefContent(brief)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("DAILY BRIEF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                loadBrief()
            }
        }
    }

    // MARK: - Brief Content

    private func briefContent(_ brief: DailyBrief) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header section
                headerSection(brief)

                divider

                // Hero reading cockpit for App Store and first-open clarity
                DailyFinancialReadingCockpitView(reading: dailyReading ?? DailyFinancialReadingService.shared.compose(for: appState.currentUser)) {
                    appState.selectedTab = .portfolio
                }
                .padding(.vertical, 16)

                divider

                // Headline section
                headlineSection(brief)

                divider

                // Conditions grid (uses framed summary)
                conditionsSection(brief)

                divider

                // Suggested action (uses framed text)
                actionSection(brief)

                divider

                // Watchlist highlights
                if !brief.watchlistHighlights.isEmpty {
                    highlightsSection(brief.watchlistHighlights)
                    divider
                }

                // News alerts
                if !brief.newsAlerts.isEmpty {
                    alertsSection(brief.newsAlerts)
                    divider
                }

                // Streak section
                streakSection(brief.streak)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Header Section

    private func headerSection(_ brief: DailyBrief) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Greeting and name
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(brief.greeting.uppercased())
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)

                    if let user = appState.currentUser {
                        Text(user.displayName)
                            .font(TerminalFont.data(20, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }

                Spacer()

                // Framing indicator and zodiac badge
                VStack(alignment: .trailing, spacing: 6) {
                    // Signal framing indicator
                    SignalFramingIndicator(level: brief.framingLevel)

                    // Zodiac badge
                    if let user = appState.currentUser {
                        HStack(spacing: 4) {
                            ZodiacMark(sign: user.sunSign, size: .small, style: .badge)

                            Text(user.sunSign.displayName.uppercased())
                                .font(TerminalFont.data(8))
                                .foregroundColor(CosmicTheme.textMuted)
                                .tracking(0.5)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CosmicTheme.cardBackground)
                    }
                }
            }

            // Date
            Text(brief.formattedDate.uppercased())
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.gold)
                .tracking(1)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Headline Section

    private func headlineSection(_ brief: DailyBrief) -> some View {
        HStack(spacing: 12) {
            Image(systemName: brief.cosmicConditions.overallEnergy.sfSymbol)
                .font(.title2)
                .foregroundColor(brief.cosmicConditions.overallEnergy.color)
                .frame(width: 32)

            Text(brief.cosmicHeadline)
                .font(TerminalFont.data(14))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.vertical, 16)
    }

    // MARK: - Conditions Section

    private func conditionsSection(_ brief: DailyBrief) -> some View {
        let conditions = brief.cosmicConditions

        return VStack(alignment: .leading, spacing: 12) {
            Text("COSMIC CONDITIONS")
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            // Framed summary
            Text(brief.framedConditionsSummary)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            // 2x2 grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                conditionCard(
                    title: "ENERGY",
                    value: conditions.overallEnergy.rawValue,
                    icon: conditions.overallEnergy.sfSymbol,
                    color: conditions.overallEnergy.color
                )

                conditionCard(
                    title: "MOON",
                    value: conditions.moonPhase.rawValue,
                    icon: conditions.moonPhase.icon,
                    color: conditions.moonPhase.color
                )

                conditionCard(
                    title: "MERCURY",
                    value: conditions.mercuryStatus.rawValue,
                    icon: conditions.mercuryStatus.sfSymbol,
                    color: conditions.mercuryStatus.color
                )

                conditionCard(
                    title: "VOLATILITY",
                    value: conditions.volatilityTolerance.rawValue,
                    icon: conditions.volatilityTolerance.sfSymbol,
                    color: conditions.volatilityTolerance.color
                )
            }
        }
        .padding(.vertical, 16)
    }

    private func conditionCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(0.5)

                Spacer()

                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }

            Text(value)
                .font(TerminalFont.data(12, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
        }
        .padding(12)
        .background(CosmicTheme.cardBackground)
    }

    // MARK: - Action Section

    private func actionSection(_ brief: DailyBrief) -> some View {
        let action = brief.suggestedAction
        let framedAction = brief.framedSuggestedAction

        return VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S POSTURE")
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            HStack(spacing: 12) {
                Image(systemName: action.sfSymbol)
                    .font(.title2)
                    .foregroundColor(action.color)
                    .frame(width: 40, height: 40)
                    .background(action.color.opacity(0.15))

                VStack(alignment: .leading, spacing: 4) {
                    // Use framed title
                    Text(framedAction.title.uppercased())
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .tracking(0.5)

                    // Use framed description
                    Text(framedAction.description)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(12)
            .background(CosmicTheme.cardBackground)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Highlights Section

    private func highlightsSection(_ highlights: [WatchlistHighlight]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WATCHLIST HIGHLIGHTS")
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            VStack(spacing: 0) {
                ForEach(highlights) { highlight in
                    highlightRow(highlight)

                    if highlight.id != highlights.last?.id {
                        Rectangle()
                            .fill(CosmicTheme.border)
                            .frame(height: 1)
                    }
                }
            }
            .background(CosmicTheme.cardBackground)
        }
        .padding(.vertical, 16)
    }

    private func highlightRow(_ highlight: WatchlistHighlight) -> some View {
        HStack(spacing: 12) {
            // Symbol and zodiac
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(highlight.stock.symbol)
                        .font(TerminalFont.data(14, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    if let foundedZodiacSign = highlight.stock.foundedZodiacSign {
                        ZodiacMark(sign: foundedZodiacSign, size: .tiny, style: .element)
                    } else {
                        Text("?")
                            .font(TerminalFont.data(11, weight: .semibold))
                            .foregroundColor(CosmicTheme.textMuted)
                            .accessibilityLabel("unknown zodiac sign")
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: highlight.reason.sfSymbol)
                        .font(.caption2)
                        .foregroundColor(highlight.reason.color)

                    Text(highlight.reason.rawValue)
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            Spacer()

            // Price change
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", highlight.stock.currentPrice))
                    .font(TerminalFont.price(14))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(highlight.formattedChange)
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(highlight.changeColor)
            }
        }
        .padding(12)
    }

    // MARK: - Alerts Section

    private func alertsSection(_ alerts: [NewsAlert]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALERTS")
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            VStack(spacing: 8) {
                ForEach(alerts) { alert in
                    alertRow(alert)
                }
            }
        }
        .padding(.vertical, 16)
    }

    private func alertRow(_ alert: NewsAlert) -> some View {
        HStack(spacing: 12) {
            Image(systemName: alert.severity.sfSymbol)
                .font(.caption)
                .foregroundColor(alert.severity.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(alert.symbol)
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(alert.timeAgo)
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Text(alert.headline)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(10)
        .background(alert.severity.color.opacity(0.1))
    }

    // MARK: - Streak Section

    private func streakSection(_ streak: StreakInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHECK-IN STREAK")
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            HStack(spacing: 16) {
                // Streak count
                VStack(alignment: .leading, spacing: 4) {
                    Text(streak.streakMessage)
                        .font(TerminalFont.data(14, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    if streak.longestStreak > streak.currentStreak {
                        Text("Best: \(streak.longestStreak) days")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                Spacer()

                // Milestone badge if applicable
                if let milestone = streak.milestone {
                    HStack(spacing: 6) {
                        Image(systemName: milestone.sfSymbol)
                            .font(.caption)
                            .foregroundColor(milestone.color)

                        Text(milestone.rawValue)
                            .font(TerminalFont.data(10))
                            .foregroundColor(milestone.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(milestone.color.opacity(0.15))
                }

                // Check-in button
                if !hasCheckedIn {
                    Button(action: performCheckIn) {
                        Text("CHECK IN")
                            .font(TerminalFont.data(10, weight: .semibold))
                            .foregroundColor(CosmicTheme.background)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(CosmicTheme.gold)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.caption2)

                        Text("DONE")
                            .font(TerminalFont.data(10, weight: .semibold))
                    }
                    .foregroundColor(CosmicTheme.positive)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .padding(12)
            .background(CosmicTheme.cardBackground)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Helper Views

    private var divider: some View {
        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: CosmicTheme.gold))

            Text("GENERATING BRIEF")
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sun.max")
                .font(.largeTitle)
                .foregroundColor(CosmicTheme.textMuted)

            Text("No brief available")
                .font(TerminalFont.data(14))
                .foregroundColor(CosmicTheme.textSecondary)

            Button(action: loadBrief) {
                Text("REFRESH")
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
            }
        }
    }

    // MARK: - Actions

    private func loadBrief() {
        isLoading = true

        // Small delay for effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let user = appState.currentUser {
                brief = DailyBriefService.shared.generateBrief(for: user)

                // Check if already checked in today
                let streak = DailyBriefService.shared.calculateStreak()
                if let lastCheckIn = streak.lastCheckIn {
                    hasCheckedIn = Calendar.current.isDateInToday(lastCheckIn)
                }
                dailyReading = DailyFinancialReadingService.shared.compose(for: user)
            } else {
                dailyReading = DailyFinancialReadingService.shared.compose(for: nil)
            }
            isLoading = false
        }
    }

    private func performCheckIn() {
        DailyBriefService.shared.recordCheckIn()
        hasCheckedIn = true

        // Refresh brief to update streak
        if let user = appState.currentUser {
            brief = DailyBriefService.shared.generateBrief(for: user)
            dailyReading = DailyFinancialReadingService.shared.compose(for: user)
        }
    }
}

// MARK: - Preview

#Preview("Daily Brief") {
    DailyBriefView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}
