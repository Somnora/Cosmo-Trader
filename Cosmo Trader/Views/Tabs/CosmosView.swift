import SwiftUI

// MARK: - CosmosView
// ===================
// The Cosmos tab - personalized daily portfolio horoscopes and cosmic event tracking.
//
// STRUCTURE:
// 1. Date header with moon phase icon
// 2. Active cosmic alerts banner (if any)
// 3. Horoscope reading card (personalized based on portfolio)
// 4. Current Cosmic Weather section
// 5. Upcoming Events calendar/list
// 6. Refresh button to generate new reading
//
// DESIGN PHILOSOPHY:
// - Mystical and immersive atmosphere
// - Personal connection through user's actual holdings
// - Co-Star inspired voice: witty, direct, cosmic wisdom

struct CosmosView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var viewModel: HoroscopeViewModel?
    @State private var astroService = AstroAlertService.shared
    @State private var moonService = MoonPhaseService.shared
    @State private var selectedEvent: CosmicEvent?
    @State private var showAllEvents: Bool = false
    @State private var showLunarDetail: Bool = false
    @State private var showZodiacLeaderboard: Bool = false

    /// Animation states
    @State private var cardOpacity: Double = 0
    @State private var cardOffset: CGFloat = 20
    @State private var starsVisible: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic background with stars
                cosmicBackground

                if viewModel != nil {
                    // Main content
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 24) {
                            // 1. Date header with moon phase
                            dateHeader

                            // 2. Moon Phase Widget (Prominent - for swing traders)
                            moonPhaseWidget

                            // 3. Lunar alert banner (if significant moon event)
                            lunarAlertSection

                            // 3a. Mercury Retrograde Countdown (always visible)
                            MercuryRetrogradeBanner()

                            // 3b. Weekly Zodiac Performance Section
                            weeklyZodiacPerformanceSection

                            // 3c. Option Expiry Alignment Section
                            optionExpirySection

                            // 4. Active cosmic alert (if any important events)
                            if let alertEvent = astroService.activeAlertEvents.first {
                                AstroAlertBanner(
                                    event: alertEvent,
                                    onDismiss: {
                                        withAnimation(.spring(response: 0.3)) {
                                            astroService.dismissAlert(alertEvent)
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }

                            // 5. Main horoscope card
                            horoscopeCard

                            // 6. Cosmic Weather section (active events)
                            cosmicWeatherSection

                            // 7. Upcoming Events
                            upcomingEventsSection

                            // 8. Regenerate button
                            regenerateButton

                            Spacer(minLength: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
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
                        Image(systemName: "sparkles")
                            .foregroundColor(CosmicTheme.gold)
                        Text("Cosmos")
                            .font(.headline)
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Text(viewModel?.moonPhase.emoji ?? "🌙")
                        .font(.title2)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedEvent) { event in
                CosmicEventDetailSheet(event: event)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAllEvents) {
                AllCosmicEventsSheet(astroService: astroService)
            }
            .sheet(isPresented: $showLunarDetail) {
                LunarOutlookSheet(lunarData: moonService.getCurrentLunarData())
            }
            .sheet(isPresented: $showZodiacLeaderboard) {
                ZodiacLeaderboardView()
                    .environment(appState)
            }
        }
        .task {
            // Initialize viewModel if needed (async-safe)
            if viewModel == nil {
                viewModel = HoroscopeViewModel(appState: appState)
            }

            // Only animate and track after viewModel is ready
            animateAppearance()

            // Track horoscope viewed
            if let user = appState.currentUser {
                AnalyticsService.shared.trackHoroscopeViewed(sunSign: user.sunSign.displayName)
            }
        }
    }

    // MARK: - Cosmic Background

    private var cosmicBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    CosmicTheme.background,
                    Color(red: 0.05, green: 0.02, blue: 0.15),
                    Color(red: 0.08, green: 0.04, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated stars overlay
            if starsVisible {
                StarsOverlay()
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        VStack(spacing: 12) {
            // Moon phase display
            HStack(spacing: 8) {
                Image(systemName: viewModel?.moonPhaseIcon ?? "moon")
                    .font(.system(size: 24))
                    .foregroundStyle(CosmicTheme.goldGradient)

                Text(viewModel?.moonPhase.rawValue ?? "Moon Phase")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Date
            Text(viewModel?.formattedDate ?? "")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)

            // User sign badge
            HStack(spacing: 6) {
                if let sign = viewModel?.user.sunSign {
                    ZodiacSymbolView(sign: sign, size: 20, color: CosmicTheme.gold)
                }

                Text(viewModel?.user.sunSign.displayName ?? "")
                    .font(TerminalFont.data(13))
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.gold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Moon Phase Widget (Top of View)

    private var moonPhaseWidget: some View {
        let lunarData = moonService.getCurrentLunarData()

        return VStack(spacing: 16) {
            // Primary: Terminal-style Lunar Market Cycle view
            Button(action: { showLunarDetail = true }) {
                LunarCycleView(lunarData: lunarData, showDetailedStats: false)
            }
            .buttonStyle(.plain)

            // Secondary: Compact strip with quick countdown
            LunarCycleStrip(lunarData: lunarData)
        }
    }

    // MARK: - Lunar Alert Section

    @ViewBuilder
    private var lunarAlertSection: some View {
        let lunarData = moonService.getCurrentLunarData()
        let (isSignificant, _) = moonService.isSignificantLunarDay()

        if isSignificant {
            LunarAlertBanner(lunarData: lunarData)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
        }
    }

    // MARK: - Horoscope Card

    private var horoscopeCard: some View {
        VStack(spacing: 20) {
            // Card header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Portfolio Reading")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textMuted)

                    HStack(spacing: 8) {
                        Text("Portfolio Status:")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)

                        Text(viewModel?.performanceSentiment ?? "")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel?.performanceColor ?? CosmicTheme.textMuted)

                        Text(viewModel?.overallChangePercent ?? "")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel?.performanceColor ?? CosmicTheme.textMuted)
                    }
                }

                Spacer()

                // Large zodiac symbol
                ZStack {
                    Circle()
                        .fill(CosmicTheme.gold.opacity(0.15))
                        .frame(width: 60, height: 60)

                    if let sign = viewModel?.user.sunSign {
                        ZodiacSymbolView(sign: sign, size: 32, color: CosmicTheme.gold)
                    }
                }
            }

            // Divider with stars
            HStack {
                Rectangle()
                    .fill(CosmicTheme.textMuted.opacity(0.3))
                    .frame(height: 1)

                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.gold.opacity(0.6))

                Rectangle()
                    .fill(CosmicTheme.textMuted.opacity(0.3))
                    .frame(height: 1)
            }

            // The reading itself
            VStack(alignment: .leading, spacing: 16) {
                if viewModel?.isLoading == true {
                    loadingView
                } else {
                    Text(viewModel?.readingText ?? "")
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }

            // Dominant element badge (if applicable)
            if let element = viewModel?.dominantElement {
                dominantElementBadge(element)
            }
        }
        .padding(24)
        .background(cardBackground)
        .opacity(cardOpacity)
        .offset(y: cardOffset)
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(CosmicTheme.gold)

            Text("Consulting the stars...")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)
                .italic()
        }
        .frame(maxWidth: .infinity, minHeight: 60)
    }

    private func dominantElementBadge(_ element: ZodiacSign.Element) -> some View {
        HStack(spacing: 8) {
            ElementSymbolView(element: element, size: 14)

            Text("\(element.displayName) Energy Dominant")
                .font(TerminalFont.data(11))
                .fontWeight(.medium)
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    // MARK: - Cosmic Weather Section

    private var cosmicWeatherSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "cloud.moon.fill")
                    .foregroundColor(CosmicTheme.cosmicPurple)

                Text("Current Cosmic Weather")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                // Weather severity indicator
                let summary = astroService.todaySummary
                HStack(spacing: 4) {
                    Image(systemName: summary.severity.icon)
                        .font(.caption)
                    Text(summary.severity.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(summary.severity.color)
            }

            // Weather advice
            Text(astroService.todaySummary.advice)
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)
                .italic()

            // Active cosmic events
            if !astroService.activeEvents.isEmpty {
                VStack(spacing: 12) {
                    ForEach(astroService.activeEvents.prefix(3)) { event in
                        activeEventRow(event)
                    }
                }
            } else {
                // No active events - show calm message
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear Cosmic Skies")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text("No major cosmic events affecting markets today")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
                .padding(.vertical, 8)
            }

            // Legacy planetary events from HoroscopeViewModel
            if let events = viewModel?.planetaryEvents, !events.isEmpty {
                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))

                Text("Planetary Transits")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textMuted)

                VStack(spacing: 10) {
                    ForEach(events) { event in
                        planetaryEventRow(event)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(CosmicTheme.cosmicPurple.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func activeEventRow(_ event: CosmicEvent) -> some View {
        Button(action: { selectedEvent = event }) {
            HStack(spacing: 12) {
                // Event icon with glow
                ZStack {
                    Circle()
                        .fill(event.themeColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: event.icon)
                        .font(.system(size: 16))
                        .foregroundColor(event.themeColor)
                }

                // Event info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(event.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(CosmicTheme.textPrimary)

                        if event.intensity == .intense {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                        }
                    }

                    Text(event.subtitle)
                        .font(.caption)
                        .foregroundColor(event.themeColor)
                }

                Spacer()

                // Status
                VStack(alignment: .trailing, spacing: 2) {
                    Text(event.statusText)
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)

                    // Intensity dots
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(i < intensityLevel(event) ? event.themeColor : CosmicTheme.textMuted.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func intensityLevel(_ event: CosmicEvent) -> Int {
        switch event.intensity {
        case .mild: return 1
        case .moderate: return 2
        case .intense: return 3
        }
    }

    private func planetaryEventRow(_ event: PlanetaryEvent) -> some View {
        HStack(spacing: 12) {
            // Event icon
            ZStack {
                Circle()
                    .fill(eventTypeColor(event.type).opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: event.type.icon)
                    .font(.caption)
                    .foregroundColor(eventTypeColor(event.type))
            }

            // Event info
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(event.description)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    // MARK: - Upcoming Events Section

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(CosmicTheme.gold)

                Text("Upcoming Events")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                Button(action: { showAllEvents = true }) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.gold)
                }
            }

            // Next 7 days events
            let upcoming = astroService.eventsNext7Days
            if upcoming.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(CosmicTheme.textMuted)

                    Text("No major cosmic events in the next 7 days")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(upcoming.prefix(4)) { event in
                        Button(action: { selectedEvent = event }) {
                            UpcomingEventRow(event: event)
                        }
                        .buttonStyle(.plain)

                        if event.id != upcoming.prefix(4).last?.id {
                            Divider()
                                .background(CosmicTheme.textMuted.opacity(0.2))
                        }
                    }
                }
            }

            // Next significant event highlight
            if let nextBig = astroService.eventsNext30Days.first(where: { $0.type.isCautionEvent || $0.intensity == .intense }) {
                nextSignificantEventCard(nextBig)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func nextSignificantEventCard(_ event: CosmicEvent) -> some View {
        Button(action: { selectedEvent = event }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(event.themeColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: event.icon)
                        .font(.title3)
                        .foregroundColor(event.themeColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Major Event")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("In \(event.daysUntilStart) days · \(event.intensity.rawValue)")
                        .font(.caption)
                        .foregroundColor(event.themeColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(event.themeColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(event.themeColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Regenerate Button

    private var regenerateButton: some View {
        Button(action: {
            HapticFeedback.medium()
            withAnimation(.spring(response: 0.4)) {
                viewModel?.regenerateHoroscope()
            }
            // Track horoscope refresh
            if let user = appState.currentUser {
                AnalyticsService.shared.trackHoroscopeRefreshed(sunSign: user.sunSign.displayName)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.headline)
                    .rotationEffect(.degrees(viewModel?.refreshTrigger == true ? 360 : 0))
                    .animation(.easeInOut(duration: 0.5), value: viewModel?.refreshTrigger)

                Text("Consult the Stars Again")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(CosmicTheme.background)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(CosmicTheme.goldGradient)
            .cornerRadius(25)
            .shadow(color: CosmicTheme.gold.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel?.isLoading == true)
        .opacity(viewModel?.isLoading == true ? 0.6 : 1.0)
    }

    // MARK: - Weekly Zodiac Performance Section

    private var weeklyZodiacPerformanceSection: some View {
        let leaderboard = ZodiacPerformanceService.getLeaderboard(stocks: MockStockData.all)
        let topThree = leaderboard.prefix(3)
        let userSign = viewModel?.user.sunSign ?? .aries
        let performances = leaderboard.map { $0.performance }
        let commentary = ZodiacPerformanceService.generateWeeklyCommentary(performances: performances, userSign: userSign)

        return Button(action: { showZodiacLeaderboard = true }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(CosmicTheme.gold)

                    Text("This Week in the Cosmos")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(CosmicTheme.gold)
                }

                // Top 3 mini leaderboard
                VStack(spacing: 8) {
                    ForEach(topThree, id: \.performance.id) { item in
                        weeklyPerformanceRow(rank: item.rank, performance: item.performance, userSign: userSign)
                    }
                }

                // Commentary
                Text(commentary)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(CosmicTheme.gold.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func weeklyPerformanceRow(rank: Int, performance: ZodiacWeeklyPerformance, userSign: ZodiacSign) -> some View {
        let isUserSign = performance.sign == userSign

        return HStack(spacing: 12) {
            // Rank
            HStack(spacing: 2) {
                if rank == 1 {
                    Text("🏆")
                        .font(.caption)
                }
                Text("#\(rank)")
                    .font(TerminalFont.data(11, weight: rank == 1 ? .bold : .regular))
                    .foregroundColor(rank == 1 ? CosmicTheme.gold : CosmicTheme.textSecondary)
            }
            .frame(width: 36, alignment: .leading)

            // Sign
            HStack(spacing: 6) {
                ZodiacSymbolView(
                    sign: performance.sign,
                    size: 14,
                    color: performance.sign.element.color
                )

                Text(performance.sign.displayName)
                    .font(TerminalFont.data(12, weight: isUserSign ? .bold : .regular))
                    .foregroundColor(isUserSign ? CosmicTheme.gold : CosmicTheme.textPrimary)
            }

            Spacer()

            // Return
            Text(performance.formattedReturn)
                .font(TerminalFont.price(12))
                .foregroundColor(performance.isPositive ? CosmicTheme.positive : CosmicTheme.negative)

            // User badge
            if isUserSign {
                Text("YOU")
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(CosmicTheme.background)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(CosmicTheme.gold)
                    )
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Option Expiry Section

    private var optionExpirySection: some View {
        let userSign = viewModel?.user.sunSign ?? .aries

        return OptionExpiryView(userSign: userSign)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(CosmicTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                CosmicTheme.gold.opacity(0.4),
                                CosmicTheme.cosmicPurple.opacity(0.3),
                                CosmicTheme.nebulaBlue.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    // MARK: - Helpers

    private func eventTypeColor(_ type: PlanetaryEventType) -> Color {
        switch type {
        case .retrograde: return .orange
        case .conjunction: return .purple
        case .moonPhase: return .blue
        case .transit: return CosmicTheme.gold
        }
    }

    // MARK: - Animations

    private func animateAppearance() {
        withAnimation(.easeOut(duration: 0.6)) {
            starsVisible = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            cardOpacity = 1
            cardOffset = 0
        }
    }
}

// MARK: - Cosmic Event Detail Sheet

struct CosmicEventDetailSheet: View {
    let event: CosmicEvent

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    ZStack {
                        // Glow background - static for performance
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        event.themeColor.opacity(0.4),
                                        event.themeColor.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 240, height: 240)

                        // Icon
                        Image(systemName: event.icon)
                            .font(.system(size: 60))
                            .foregroundColor(event.themeColor)
                    }

                    // Title and subtitle
                    VStack(spacing: 8) {
                        Text(event.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(event.subtitle)
                            .font(.headline)
                            .foregroundColor(event.themeColor)

                        // Status badge
                        HStack(spacing: 8) {
                            Text(event.isActive ? "ACTIVE" : "UPCOMING")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(event.isActive ? event.themeColor : CosmicTheme.textMuted)
                                )

                            Text(event.intensity.rawValue)
                                .font(.caption)
                                .foregroundColor(CosmicTheme.textSecondary)
                        }
                    }

                    // Date range
                    HStack {
                        Image(systemName: "calendar")
                        Text(event.dateRangeFormatted)
                        Text("·")
                        Text(event.statusText)
                            .fontWeight(.medium)
                            .foregroundColor(event.themeColor)
                    }
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)

                    Divider()
                        .background(CosmicTheme.textMuted.opacity(0.3))

                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About This Event")
                            .font(.headline)
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(event.description)
                            .font(.body)
                            .foregroundColor(CosmicTheme.textSecondary)
                            .lineSpacing(6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Warning (if present)
                    if let warning = event.warningMessage {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundColor(.orange)

                            Text(warning)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }

                    // Advice
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(CosmicTheme.gold)
                            Text("Trading Advice")
                                .font(.headline)
                                .foregroundColor(CosmicTheme.gold)
                        }

                        Text(event.advice)
                            .font(.body)
                            .foregroundColor(CosmicTheme.textPrimary)
                            .lineSpacing(6)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(CosmicTheme.gold.opacity(0.1))
                    )

                    // Affected areas
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Affected Areas")
                            .font(.headline)
                            .foregroundColor(CosmicTheme.textPrimary)

                        // Elements
                        if !event.affectedElements.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Elements")
                                    .font(.caption)
                                    .foregroundColor(CosmicTheme.textMuted)

                                HStack(spacing: 12) {
                                    ForEach(event.affectedElements, id: \.self) { element in
                                        HStack(spacing: 6) {
                                            ElementSymbolView(element: element, size: 16)
                                            Text(element.displayName)
                                                .font(TerminalFont.data(12))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(element.color.opacity(0.2))
                                        )
                                    }
                                }
                            }
                        }

                        // Sectors
                        if !event.affectedSectors.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Market Sectors")
                                    .font(.caption)
                                    .foregroundColor(CosmicTheme.textMuted)

                                FlowLayout(spacing: 8) {
                                    ForEach(event.affectedSectors, id: \.self) { sector in
                                        HStack(spacing: 6) {
                                            Image(systemName: sector.icon)
                                                .font(.caption)
                                            Text(sector.rawValue)
                                                .font(.caption)
                                        }
                                        .foregroundColor(CosmicTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(CosmicTheme.secondaryBackground)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(24)
            }
            .background(CosmicTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
        }
    }
}

// MARK: - All Cosmic Events Sheet

struct AllCosmicEventsSheet: View {
    let astroService: AstroAlertService

    @Environment(\.dismiss) private var dismiss
    @State private var expandedEventId: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Active events section
                    if !astroService.activeEvents.isEmpty {
                        sectionHeader("Active Now", icon: "bolt.fill", color: .orange)

                        ForEach(astroService.activeEvents) { event in
                            CosmicEventCard(
                                event: event,
                                isExpanded: expandedEventId == event.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        expandedEventId = expandedEventId == event.id ? nil : event.id
                                    }
                                }
                            )
                        }
                    }

                    // Upcoming events section
                    let upcoming = astroService.eventsNext30Days
                    if !upcoming.isEmpty {
                        sectionHeader("Next 30 Days", icon: "calendar", color: CosmicTheme.gold)

                        ForEach(upcoming) { event in
                            CosmicEventCard(
                                event: event,
                                isExpanded: expandedEventId == event.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        expandedEventId = expandedEventId == event.id ? nil : event.id
                                    }
                                }
                            )
                        }
                    }

                    // Later events
                    let later = astroService.allEvents.filter { event in
                        !event.isActive && event.daysUntilStart > 30
                    }.prefix(10)

                    if !later.isEmpty {
                        sectionHeader("Later", icon: "clock", color: CosmicTheme.textMuted)

                        ForEach(Array(later)) { event in
                            CosmicEventCard(
                                event: event,
                                isExpanded: expandedEventId == event.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        expandedEventId = expandedEventId == event.id ? nil : event.id
                                    }
                                }
                            )
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(CosmicTheme.background)
            .navigationTitle("Cosmic Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

// MARK: - Stars Overlay

/// Static starfield background effect - no animation for performance
struct StarsOverlay: View {

    var body: some View {
        Canvas { context, size in
            // Generate deterministic star positions
            let starCount = 50
            for i in 0..<starCount {
                let x = pseudoRandom(seed: i * 2) * size.width
                let y = pseudoRandom(seed: i * 2 + 1) * size.height
                let starSize = 1.0 + pseudoRandom(seed: i * 3) * 2.0
                let brightness = 0.3 + pseudoRandom(seed: i * 4) * 0.7

                let rect = CGRect(
                    x: x - starSize / 2,
                    y: y - starSize / 2,
                    width: starSize,
                    height: starSize
                )

                context.fill(
                    Circle().path(in: rect),
                    with: .color(Color.white.opacity(brightness))
                )
            }
        }
    }

    /// Simple pseudo-random number generator for deterministic stars
    private func pseudoRandom(seed: Int) -> CGFloat {
        let x = sin(Double(seed) * 12.9898) * 43758.5453
        return CGFloat(x - floor(x))
    }
}

// MARK: - Lunar Outlook Sheet

struct LunarOutlookSheet: View {
    let lunarData: LunarData

    @Environment(\.dismiss) private var dismiss
    @State private var moonService = MoonPhaseService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Full lunar market outlook
                    LunarMarketOutlook(lunarData: lunarData)

                    // Moon phase timeline
                    MoonPhaseTimeline(entries: moonService.getUpcomingSignificantPhases())
                        .padding(.horizontal, 4)

                    // Moon phases explainer
                    moonPhasesExplainer

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(CosmicTheme.background)
            .navigationTitle("Lunar Outlook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text(lunarData.phase.emoji)
                        Text("Lunar Outlook")
                            .font(.headline)
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }
            }
        }
    }

    private var moonPhasesExplainer: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(CosmicTheme.gold)
                Text("Moon Phase Trading Guide")
                    .font(.headline)
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            Text("Some traders follow lunar cycles as one of many market indicators. Here's the traditional interpretation:")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)

            VStack(spacing: 12) {
                ForEach([MoonPhase.newMoon, .firstQuarter, .fullMoon, .lastQuarter], id: \.self) { phase in
                    phaseExplainerRow(phase)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func phaseExplainerRow(_ phase: MoonPhase) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(phase.emoji)
                .font(.title2)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(phase.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(phase.tradingSignal.summary)
                    .font(.caption)
                    .foregroundColor(phase.tradingSignal.type.color)

                Text(phase.shortDescription)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(phase == lunarData.phase ? CosmicTheme.gold.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(phase == lunarData.phase ? CosmicTheme.gold.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview("Cosmos View") {
    CosmosView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}
