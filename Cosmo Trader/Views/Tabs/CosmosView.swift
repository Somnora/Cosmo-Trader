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

    /// ViewModel - initialized immediately to avoid race conditions
    @State private var viewModel = HoroscopeViewModel()
    @State private var astroService = AstroAlertService.shared
    @State private var moonService = MoonPhaseService.shared
    @State private var marketWeatherSummary: MarketWeatherSummary?

    // MARK: - Framing

    /// User's signal framing level
    private var framingLevel: SignalFramingLevel {
        appState.currentUser?.signalFramingLevel ?? .balanced
    }

    /// Framed section title for the horoscope card
    private var framedHoroscopeTitle: String {
        switch framingLevel {
        case .rational, .leanRational:
            return "Local Portfolio Context"
        case .balanced:
            return "Local Portfolio Context"
        case .leanMystical, .mystical:
            return "Local Portfolio Context"
        }
    }

    /// Framed loading message
    private var framedLoadingMessage: String {
        switch framingLevel {
        case .rational:
            return "Generating market analysis..."
        case .leanRational:
            return "Analyzing portfolio exposure..."
        case .balanced:
            return "Synthesizing market and lunar context..."
        case .leanMystical:
            return "Reading cosmic market conditions..."
        case .mystical:
            return "Composing today's market astrology..."
        }
    }

    /// Framed regenerate button text
    private var framedRegenerateText: String {
        switch framingLevel {
        case .rational:
            return "Refresh Analysis"
        case .leanRational:
            return "Refresh Market Reading"
        case .balanced:
            return "Refresh Reading"
        case .leanMystical:
            return "Refresh Reading"
        case .mystical:
            return "Refresh Reading"
        }
    }

    /// Framed "no events" title
    private var framedNoEventsTitle: String {
        switch framingLevel {
        case .rational, .leanRational:
            return "No Major Events"
        case .balanced:
            return "No Major Cosmic Events"
        case .leanMystical, .mystical:
            return "Quiet Cosmic Tape"
        }
    }

    /// Framed "no events" message
    private var framedNoEventsMessage: String {
        switch framingLevel {
        case .rational:
            return "No significant market-affecting events scheduled today."
        case .leanRational:
            return "No major events affecting markets today."
        case .balanced:
            return "No major cosmic events affecting markets today."
        case .leanMystical:
            return "No active cosmic catalysts are adding pressure to today's market read."
        case .mystical:
            return "Cosmic conditions are quiet; price action and portfolio exposure should carry more weight today."
        }
    }

    /// Framed cosmic weather advice
    private var framedWeatherAdvice: String {
        let advice = astroService.todaySummary.advice
        // For rational modes, simplify cosmic language
        switch framingLevel {
        case .rational:
            return advice
                .replacingOccurrences(of: "cosmic", with: "market")
                .replacingOccurrences(of: "celestial", with: "current")
                .replacingOccurrences(of: "stars", with: "indicators")
        case .leanRational:
            return advice
                .replacingOccurrences(of: "cosmic ", with: "")
        default:
            return advice
        }
    }
    @State private var selectedEvent: CosmicEvent?
    @State private var showAllEvents: Bool = false
    @State private var showLunarDetail: Bool = false
    @State private var showZodiacLeaderboard: Bool = false

    /// Animation states
    @State private var cardOpacity: Double = 0
    @State private var cardOffset: CGFloat = 20
    @State private var starsVisible: Bool = false
    @State private var hasAppeared: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic background with stars
                cosmicBackground

                // Main content - viewModel is always ready
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        if AppState.isScreenshotCalendarMode {
                            monthlyCalendarScreenshotContent
                        } else {
                            // 1. Date header with moon phase
                            dateHeader

                            cosmosEngineStrip

                            marketWeatherCosmosSection

                            // 2. Moon Phase Widget (Prominent - for swing traders)
                            moonPhaseWidget

                            // 3. Lunar alert banner (if significant moon event)
                            lunarAlertSection

                            // 3a. Mercury Retrograde Countdown (always visible)
                            MercuryRetrogradeBanner()

                            // 3b. Weekly Zodiac Performance Section
                            weeklyZodiacPerformanceSection

                            // 3c. Monthly cosmic calendar section
                            monthlyCalendarSection

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
                        }
                    }
                    .padding(.horizontal, AppLayout.screenHorizontalPadding)
                    .padding(.top, 4)
                    .iPadReadableContent(maxWidth: 980)
                }
                .tabBarSafeBottomPadding(extra: AppLayout.bottomTabBarExtraClearance)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("COSMOS")
                        .font(TerminalFont.data(13, weight: .semibold))
                        .tracking(1.8)
                        .foregroundColor(CosmicTheme.textPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    viewModel.moonPhase.sfImage
                        .font(.title2)
                        .foregroundColor(CosmicTheme.gold)
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
            if viewModel.user == nil, appState.currentUser != nil {
                viewModel = HoroscopeViewModel(appState: appState)
            }

            // Prevent duplicate animations on re-appear
            guard !hasAppeared else { return }
            hasAppeared = true

            // Animate appearance
            animateAppearance()
            await loadMarketWeatherIfNeeded()

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
                    CosmicTheme.deepBlue.opacity(0.78),
                    CosmicTheme.terminalNavy.opacity(0.86)
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
        VStack(spacing: 9) {
            // Moon phase display
            HStack(spacing: 8) {
                Image(systemName: viewModel.moonPhaseIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(CosmicTheme.goldGradient)

                Text(viewModel.moonPhase.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Date
            Text(viewModel.formattedDate)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)

            // User sign badge (only if user exists)
            if let user = viewModel.user {
                HStack(spacing: 6) {
                    ZodiacSymbolView(sign: user.sunSign, size: 20, color: CosmicTheme.gold)

                    Text(user.sunSign.displayName)
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Moon Phase Widget (Top of View)

    private var moonPhaseWidget: some View {
        let lunarData = moonService.getCurrentLunarData()

        return VStack(spacing: 14) {
            // Primary: Terminal-style Lunar Market Cycle view
            Button(action: { showLunarDetail = true }) {
                LunarCycleView(lunarData: lunarData, showDetailedStats: false)
            }
            .buttonStyle(.plain)

            // Secondary: Compact strip with quick countdown
            LunarCycleStrip(lunarData: lunarData)
        }
    }

    private var cosmosEngineStrip: some View {
        let lunarData = moonService.getCurrentLunarData()
        let eventCount = astroService.activeEvents.count
        let holdingsCount = appState.currentUser?.portfolio.filter(\.isOwned).count ?? 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "function")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text("COSMIC TAPE LENS")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1.1)
            }

            Text("\(lunarData.phase.rawValue) moon activates \(lunarData.activatedElement.displayName.lowercased()) exposure. \(eventCount == 0 ? "No major active event override." : "\(eventCount) active event\(eventCount == 1 ? "" : "s") in the tape.")")
                .font(TerminalFont.data(13, weight: .medium))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(holdingsCount > 0 ? "Mapped against \(holdingsCount) portfolio holding\(holdingsCount == 1 ? "" : "s") before the reading becomes portfolio context." : "Add holdings to turn cosmic weather into portfolio-specific context.")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppLayout.cardHorizontalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .terminalPanel(.navy)
    }

    private var marketWeatherCosmosSection: some View {
        let event = preferredMarketWeatherEvent(from: marketWeatherSummary?.eventSummaries ?? [])
        let summaryProvenance = event?.provenance
            ?? marketWeatherSummary?.provenance
            ?? .unavailable(reason: "Provider-backed market ETF history unavailable")
        let coverage = marketWeatherSummary?.coverage ?? 0
        let included = marketWeatherSummary?.includedSymbols ?? []
        let excluded = marketWeatherSummary?.excludedSymbols ?? MarketWeatherService.v1Symbols.map(\.symbol)
        let stale = marketWeatherSummary?.staleSymbols ?? []
        let canShowMetrics = canShowMarketWeatherMetrics(event, summary: marketWeatherSummary)
        let sectorBreadth = marketWeatherSummary?.sectorBreadth

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text("MARKET WEATHER")
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1.1)

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: summaryProvenance, size: .compact)
            }

            Text(marketWeatherHeadline(for: event))
                .font(TerminalFont.data(13, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(marketWeatherDetail(for: event, coverage: coverage, staleSymbols: stale))
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                marketWeatherPill(label: "COVERAGE", value: percentRate(coverage))
                marketWeatherPill(label: "EVENT", value: event?.eventName ?? "Pending")
                marketWeatherPill(label: "SAMPLE", value: "\(event?.sampleSize ?? 0)")
            }

            if canShowMetrics, let event {
                HStack(spacing: 8) {
                    marketWeatherPill(label: "AVG MKT", value: percent(event.averageMarketReturn))
                    marketWeatherPill(label: "WIN", value: percentRate(event.winRate))
                    marketWeatherPill(label: "WINDOW", value: event.window.displayName)
                }
            }

            if !included.isEmpty || !excluded.isEmpty || !stale.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    if !included.isEmpty {
                        compactMarketWeatherSymbols(label: "Fresh", symbols: included, color: CosmicTheme.positive)
                    }

                    if !stale.isEmpty {
                        compactMarketWeatherSymbols(label: "Stale", symbols: stale, color: CosmicTheme.gold)
                    }

                    if !excluded.isEmpty {
                        compactMarketWeatherSymbols(label: "Unavailable", symbols: excluded, color: CosmicTheme.textMuted)
                    }
                }
            }

            if let sectorBreadth {
                sectorBreadthCosmosPanel(sectorBreadth)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .terminalPanel(.navy)
    }

    private func sectorBreadthCosmosPanel(_ breadth: MarketSectorBreadthSummary) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("SECTOR BREADTH")
                    .font(TerminalFont.data(8, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.5)

                Spacer(minLength: 8)

                DataSourceIndicator(provenance: breadth.provenance, size: .compact)
            }

            Text(sectorBreadthHeadline(for: breadth))
                .font(TerminalFont.data(11, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(sectorBreadthDetail(for: breadth))
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                marketWeatherPill(label: "SECTORS", value: percentRate(breadth.coverage))
                marketWeatherPill(label: "EVENT", value: breadth.eventName ?? "Pending")
                marketWeatherPill(label: "SAMPLE", value: "\(breadth.sampleSize)")
            }

            if canShowSectorBreadthMetrics(breadth) {
                HStack(spacing: 8) {
                    marketWeatherPill(label: "AVG SECTOR", value: percent(breadth.averageSectorReturn))
                    marketWeatherPill(label: "ADVANCING", value: percentRate(breadth.advancingSectorRate))
                    marketWeatherPill(label: "WINDOW", value: breadth.window.displayName)
                }

                if !breadth.strongestSectors.isEmpty {
                    compactMarketWeatherSymbols(
                        label: "Firmest",
                        symbols: breadth.strongestSectors.map { "\($0.symbol) \(percent($0.returnPercent))" },
                        color: CosmicTheme.positive
                    )
                }

                if !breadth.weakestSectors.isEmpty {
                    compactMarketWeatherSymbols(
                        label: "Softest",
                        symbols: breadth.weakestSectors.map { "\($0.symbol) \(percent($0.returnPercent))" },
                        color: CosmicTheme.textMuted
                    )
                }
            }

            if !breadth.staleSymbols.isEmpty {
                compactMarketWeatherSymbols(label: "Stale sectors", symbols: breadth.staleSymbols, color: CosmicTheme.gold)
            }

            if !breadth.excludedSymbols.isEmpty {
                compactMarketWeatherSymbols(label: "Unavailable sectors", symbols: breadth.excludedSymbols, color: CosmicTheme.textMuted)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.panelElevated.opacity(0.78))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
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
                    Text(framedHoroscopeTitle)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textMuted)

                    HStack(spacing: 8) {
                        Text("Stored context:")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)

                        Text(viewModel.performanceSentiment)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.performanceColor)

                        Text(viewModel.overallChangePercent)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.performanceColor)
                    }

                    DataSourceIndicator(
                        provenance: .mixed(reason: "Local portfolio reading. Market Weather below carries provider-backed source state."),
                        size: .compact
                    )
                }

                Spacer()

                // Large zodiac symbol (only if user exists)
                if let user = viewModel.user {
                    ZStack {
                        Circle()
                            .fill(CosmicTheme.gold.opacity(0.15))
                            .frame(width: 60, height: 60)

                        ZodiacSymbolView(sign: user.sunSign, size: 32, color: CosmicTheme.gold)
                    }
                }
            }

            // Divider with stars
            HStack {
                Rectangle()
                    .fill(CosmicTheme.textMuted.opacity(0.4))
                    .frame(height: 1)

                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.gold.opacity(0.6))

                Rectangle()
                    .fill(CosmicTheme.textMuted.opacity(0.4))
                    .frame(height: 1)
            }

            // The reading itself
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    loadingView
                } else {
                    Text(viewModel.readingText)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }

            // Dominant element badge (if applicable)
            if let element = viewModel.dominantElement {
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

            Text(framedLoadingMessage)
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
                    .foregroundColor(CosmicTheme.accentBlue)

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

            // Weather advice (framed)
            HStack(alignment: .top, spacing: 8) {
                Text(framedWeatherAdvice)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                DataSourceIndicator(
                    provenance: .sample(reason: "Astrology-only context. Market data provenance is shown in Market Weather."),
                    size: .compact
                )
            }

            // Active cosmic events
            if !astroService.activeEvents.isEmpty {
                VStack(spacing: 12) {
                    ForEach(astroService.activeEvents.prefix(3)) { event in
                        activeEventRow(event)
                    }
                }
            } else {
                // No active events - show calm message (framed)
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(framedNoEventsTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text(framedNoEventsMessage)
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
                .padding(.vertical, 8)
            }

            // Legacy planetary events from HoroscopeViewModel
            if !viewModel.planetaryEvents.isEmpty {
                let events = viewModel.planetaryEvents
                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.4))

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
                        .stroke(CosmicTheme.accentBlue.opacity(0.22), lineWidth: 1)
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
                                .fill(i < intensityLevel(event) ? event.themeColor : CosmicTheme.textMuted.opacity(0.4))
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
                                .background(CosmicTheme.textMuted.opacity(0.3))
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
                viewModel.regenerateHoroscope()
            }
            // Track horoscope refresh
            if let user = appState.currentUser {
                AnalyticsService.shared.trackHoroscopeRefreshed(sunSign: user.sunSign.displayName)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.headline)
                    .rotationEffect(.degrees(viewModel.refreshTrigger ? 360 : 0))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.refreshTrigger)

                Text(framedRegenerateText)
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
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
    }

    // MARK: - Weekly Zodiac Performance Section

    private var weeklyZodiacPerformanceSection: some View {
        Button(action: { showZodiacLeaderboard = true }) {
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

                Text("Weekly zodiac performance needs provider-backed returns. Rankings are hidden until real performance data is available.")
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
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.gold)
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

    // MARK: - Monthly Cosmic Calendar Section

    private var monthlyCalendarScreenshotContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(CosmicTheme.goldGradient)

                VStack(alignment: .leading, spacing: 4) {
                    Text("MONTHLY COSMIC CALENDAR")
                        .font(TerminalFont.data(13, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .tracking(1.2)

                    Text("Aspects, signs, and dates for reflective context")
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                Spacer()

                Text((viewModel.user?.sunSign ?? .leo).displayName.uppercased())
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(CosmicTheme.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(CosmicTheme.gold))
            }

            monthlyCalendarSection
        }
    }

    private var monthlyCalendarSection: some View {
        OptionExpiryView(userSign: viewModel.user?.sunSign ?? .aries)
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
                                CosmicTheme.accentBlue.opacity(0.3),
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

    private func loadMarketWeatherIfNeeded() async {
        guard marketWeatherSummary == nil, !AppState.isScreenshotMode else { return }

        let filterState = AstroOverlayFilterState(
            enabledKinds: [.fullMoon, .newMoon, .mercuryRetrograde],
            showEstimatedEvents: true,
            eventWindowDays: 3
        )
        marketWeatherSummary = await MarketWeatherService.shared.loadSummary(filterState: filterState)
    }

    private func preferredMarketWeatherEvent(from summaries: [MarketWeatherEventSummary]) -> MarketWeatherEventSummary? {
        summaries.sorted { lhs, rhs in
            let lhsRank = marketWeatherModeRank(lhs.displayMode)
            let rhsRank = marketWeatherModeRank(rhs.displayMode)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            if lhs.sampleSize != rhs.sampleSize { return lhs.sampleSize > rhs.sampleSize }
            return lhs.eventName < rhs.eventName
        }
        .first
    }

    private func marketWeatherModeRank(_ mode: CorrelationDisplayMode) -> Int {
        switch mode {
        case .marketBackedResult:
            return 0
        case .partialCoverage:
            return 1
        case .insufficientSample:
            return 2
        case .partialDataset:
            return 3
        case .insufficientDataset:
            return 4
        case .unavailable:
            return 5
        case .sampleOnly:
            return 6
        }
    }

    private func canShowMarketWeatherMetrics(
        _ event: MarketWeatherEventSummary?,
        summary: MarketWeatherSummary?
    ) -> Bool {
        guard let event, let summary, summary.coverage >= 1 else { return false }
        if case .marketBackedResult = event.displayMode {
            return event.provenance.isProviderBacked && !event.provenance.isCachedStale()
        }
        return false
    }

    private func canShowSectorBreadthMetrics(_ breadth: MarketSectorBreadthSummary) -> Bool {
        guard breadth.coverage >= 1 else { return false }
        if case .marketBackedResult = breadth.displayMode {
            return breadth.provenance.isProviderBacked && !breadth.provenance.isCachedStale()
        }
        return false
    }

    private func sectorBreadthHeadline(for breadth: MarketSectorBreadthSummary) -> String {
        switch breadth.displayMode {
        case .marketBackedResult:
            return "Sector breadth context is ready"
        case .partialCoverage, .partialDataset:
            return "Sector breadth is partial context only"
        case .insufficientSample:
            return "Sector breadth needs more observations"
        case .insufficientDataset:
            return "Sector breadth history is insufficient"
        case .sampleOnly:
            return "Sample sector history is labeled"
        case .unavailable:
            return "Sector breadth unavailable"
        }
    }

    private func sectorBreadthDetail(for breadth: MarketSectorBreadthSummary) -> String {
        switch breadth.displayMode {
        case .marketBackedResult:
            return "Sector ETFs use complete provider-backed history for \(breadth.eventName ?? "the selected event"). Historical context only, not a prediction."
        case .partialCoverage, .partialDataset:
            return "Provider-backed sector coverage is \(percentRate(breadth.coverage)). Full sector coverage is required before sector metrics appear."
        case .insufficientSample:
            return "Sector ETF history exists, but this event does not have enough observations for a sector metric."
        case .insufficientDataset, .sampleOnly, .unavailable:
            return breadth.disclaimer
        }
    }

    private func marketWeatherHeadline(for event: MarketWeatherEventSummary?) -> String {
        guard let event else { return "Broad market lens pending" }

        switch event.displayMode {
        case .marketBackedResult:
            return "\(event.eventName) market context is ready"
        case .partialCoverage, .partialDataset:
            return "Market Weather is partial context only"
        case .insufficientSample:
            return "Market Weather needs more observations"
        case .insufficientDataset:
            return "Market Weather history is insufficient"
        case .sampleOnly:
            return "Sample market history is labeled"
        case .unavailable:
            return "Market Weather unavailable"
        }
    }

    private func marketWeatherDetail(
        for event: MarketWeatherEventSummary?,
        coverage: Double,
        staleSymbols: [String]
    ) -> String {
        guard let event else {
            return "SPY, QQQ, DIA, and IWM provider-backed history is required before broad market context appears."
        }

        if !staleSymbols.isEmpty {
            return "Cached market history is stale for \(staleSymbols.joined(separator: ", ")). Market Weather stays context-only until fresh provider-backed history is available."
        }

        switch event.displayMode {
        case .marketBackedResult:
            return "The broad market lens uses SPY, QQQ, DIA, and IWM with the \(event.window.displayName) event window. Historical context only, not a prediction."
        case .partialCoverage, .partialDataset:
            return "Fresh provider-backed market coverage is \(percentRate(coverage)). Full fresh coverage is required before headline market metrics appear."
        case .insufficientSample:
            return "Provider-backed market history exists, but this event does not have enough observations for a headline metric."
        case .insufficientDataset, .unavailable, .sampleOnly:
            return event.disclaimer
        }
    }

    private func marketWeatherPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(CosmicTheme.panelElevated.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private func compactMarketWeatherSymbols(label: String, symbols: [String], color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label.uppercased())
                .font(TerminalFont.data(8, weight: .bold))
                .foregroundColor(color)
                .tracking(0.4)

            Text(symbols.joined(separator: " / "))
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }

    private func percent(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "N/A" }
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }

    private func percentRate(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "N/A" }
        return String(format: "%.0f%%", value * 100)
    }

    private func eventTypeColor(_ type: PlanetaryEventType) -> Color {
        switch type {
        case .retrograde: return .orange
        case .conjunction: return CosmicTheme.accentBlue
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
                        .background(CosmicTheme.textMuted.opacity(0.4))

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
                            Image(systemName: "chart.line.uptrend.xyaxis")
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
                    Text("LUNAR OUTLOOK")
                        .font(TerminalFont.data(13, weight: .semibold))
                        .tracking(1.8)
                        .foregroundColor(CosmicTheme.textPrimary)
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
            phase.sfImage
                .font(.title2)
                .foregroundColor(phase.color)
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
