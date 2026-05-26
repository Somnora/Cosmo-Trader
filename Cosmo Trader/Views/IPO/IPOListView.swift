import SwiftUI

// MARK: - IPO List View
// ======================
// Shows upcoming IPOs as "cosmic births" with zodiac compatibility.
// Treat IPOs like births - each company enters the market under a zodiac sign.

struct IPOListView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var ipoService = IPOService.shared
    @State private var selectedIPO: IPO?
    @State private var sortOption: IPOSortOption = .date
    @State private var selectedSector: String?
    @State private var searchText: String = ""

    // MARK: - Computed

    private var user: UserProfile? {
        appState.currentUser
    }

    /// Safe user access for sorting (only call when user is known to exist)
    private var safeUser: UserProfile {
        appState.currentUser ?? UserProfile(
            displayName: "",
            email: "",
            birthDate: Date()
        )
    }

    // MARK: - Framing

    /// User's signal framing level
    private var framingLevel: SignalFramingLevel {
        appState.currentUser?.signalFramingLevel ?? .balanced
    }

    /// Framed this week section title
    private var framedThisWeekTitle: String {
        switch framingLevel {
        case .rational, .leanRational:
            return "IPOs This Week"
        default:
            return "Births This Week"
        }
    }

    /// Framed this week subtitle
    private var framedThisWeekSubtitle: String {
        switch framingLevel {
        case .rational:
            return "Listings within 7 days"
        case .leanRational:
            return "Arrivals within 7 days"
        default:
            return "Cosmic arrivals within 7 days"
        }
    }

    /// Framed upcoming section title
    private var framedUpcomingTitle: String {
        switch framingLevel {
        case .rational, .leanRational:
            return "Upcoming IPOs"
        default:
            return "Upcoming Cosmic Births"
        }
    }

    /// Framed header title
    private var framedHeaderTitle: String {
        switch framingLevel {
        case .rational, .leanRational:
            return "Upcoming IPOs"
        default:
            return "Upcoming Cosmic Births"
        }
    }

    /// Framed header description
    private var framedHeaderDescription: String {
        switch framingLevel {
        case .rational:
            return "Track upcoming initial public offerings and their sector characteristics."
        case .leanRational:
            return "Each IPO enters the market with distinct characteristics based on timing."
        default:
            return "Every IPO enters the market under a zodiac sign, born into the cosmic order of commerce."
        }
    }

    /// Framed navigation title
    private var framedNavTitle: String {
        switch framingLevel {
        case .rational, .leanRational:
            return "IPOs"
        default:
            return "Cosmic Births"
        }
    }

    /// Framed empty state message
    private var framedEmptyMessage: String {
        switch framingLevel {
        case .rational, .leanRational:
            return "No IPOs found"
        default:
            return "No cosmic births found"
        }
    }

    /// Framed alerts section title
    private var framedAlertsTitle: String {
        switch framingLevel {
        case .rational, .leanRational:
            return "IPO ALERTS"
        default:
            return "COSMIC ALERTS"
        }
    }

    private var filteredIPOs: [IPO] {
        var ipos = ipoService.getUpcomingIPOs()

        // Filter by sector
        if let sector = selectedSector {
            ipos = ipos.filter { $0.sector == sector }
        }

        // Filter by search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            ipos = ipos.filter {
                $0.companyName.lowercased().contains(query) ||
                ($0.ticker?.lowercased().contains(query) ?? false) ||
                $0.sector.lowercased().contains(query)
            }
        }

        // Sort
        return ipoService.sortIPOs(ipos, by: sortOption, user: safeUser)
    }

    private var thisWeekIPOs: [IPO] {
        filteredIPOs.filter { $0.isThisWeek }
    }

    private var laterIPOs: [IPO] {
        filteredIPOs.filter { !$0.isThisWeek }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                TerminalBackground(starCount: 30, showGrid: false)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // Header with cosmic birth theme
                        headerSection

                        // IPO Alerts (if any highly compatible)
                        ipoAlertsSection

                        // Sort and filter controls
                        sortFilterControls

                        // This Week section (framed)
                        if !thisWeekIPOs.isEmpty {
                            ipoSection(
                                title: framedThisWeekTitle,
                                subtitle: framedThisWeekSubtitle,
                                ipos: thisWeekIPOs,
                                isUrgent: true
                            )
                        }

                        // Later IPOs (framed)
                        if !laterIPOs.isEmpty {
                            ipoSection(
                                title: framedUpcomingTitle,
                                subtitle: "Future market arrivals",
                                ipos: laterIPOs,
                                isUrgent: false
                            )
                        }

                        // Empty state
                        if filteredIPOs.isEmpty {
                            emptyState
                        }

                        // Statistics footer
                        statisticsFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("IPO Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .foregroundColor(CosmicTheme.gold)
                        Text(framedNavTitle)
                            .font(TerminalFont.headline(16))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task {
                            await ipoService.forceRefresh()
                        }
                    }) {
                        if ipoService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: CosmicTheme.textSecondary))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(CosmicTheme.textSecondary)
                        }
                    }
                    .disabled(ipoService.isLoading)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search IPOs...")
            .navigationDestination(item: $selectedIPO) { ipo in
                IPODetailView(ipo: ipo)
                    .onAppear {
                        // Track IPO detail viewed
                        AnalyticsService.shared.trackIPODetailViewed(
                            ticker: ipo.ticker ?? "unknown",
                            zodiacSign: ipo.zodiacSign.displayName
                        )
                    }
            }
            .onAppear {
                // Track IPO list viewed
                AnalyticsService.shared.trackIPOListViewed()
            }
            .task {
                // Refresh IPO data from API on appear
                await ipoService.refresh()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Cosmic birth icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [CosmicTheme.gold.opacity(0.3), CosmicTheme.cosmicPurple.opacity(0.1)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(CosmicTheme.goldGradient)
            }

            Text(framedHeaderTitle)
                .font(TerminalFont.headline(20))
                .foregroundColor(CosmicTheme.textPrimary)

            Text(framedHeaderDescription)
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Quick stats
            HStack(spacing: 20) {
                statBadge(
                    value: "\(ipoService.getUpcomingIPOs().count)",
                    label: "Upcoming"
                )

                statBadge(
                    value: "\(ipoService.getIPOsThisWeek().count)",
                    label: "This Week"
                )

                statBadge(
                    value: "\(ipoService.getHighlyCompatibleIPOs(for: safeUser).count)",
                    label: "High Match"
                )
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 20)
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(TerminalFont.price(20))
                .foregroundColor(CosmicTheme.gold)

            Text(label.uppercased())
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(width: 80)
    }

    // MARK: - IPO Alerts Section

    @ViewBuilder
    private var ipoAlertsSection: some View {
        let alerts = ipoService.getIPOAlerts(for: safeUser)

        if !alerts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(CosmicTheme.gold)

                    Text(framedAlertsTitle)
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textSecondary)

                    Spacer()
                }

                ForEach(alerts) { alert in
                    IPOAlertBanner(alert: alert) {
                        selectedIPO = alert.ipo
                    }
                }
            }
        }
    }

    // MARK: - Sort & Filter Controls

    @ViewBuilder
    private var sortFilterControls: some View {
        VStack(spacing: 12) {
            // Sort options row
            HStack(spacing: 8) {
                Text("SORT")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)

                ForEach(IPOSortOption.allCases, id: \.self) { option in
                    sortButton(option)
                }

                Spacer()

                // Sector filter dropdown (always visible)
                Menu {
                    Button(action: { selectedSector = nil }) {
                        HStack {
                            Text("All Sectors")
                            if selectedSector == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Divider()

                    ForEach(MockIPOData.sectors, id: \.self) { sector in
                        Button(action: { selectedSector = sector }) {
                            HStack {
                                Text(sector)
                                if selectedSector == sector {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.system(size: 10))
                        Text(selectedSector ?? "Sector")
                            .font(TerminalFont.data(10))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(selectedSector != nil ? CosmicTheme.background : CosmicTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(selectedSector != nil ? CosmicTheme.gold : CosmicTheme.cardBackground)
                    )
                }
            }
        }
    }

    private func sortButton(_ option: IPOSortOption) -> some View {
        Button(action: { sortOption = option }) {
            HStack(spacing: 4) {
                Image(systemName: option.icon)
                    .font(.system(size: 10))
                Text(option.rawValue)
                    .font(TerminalFont.data(10))
            }
            .foregroundColor(sortOption == option ? CosmicTheme.background : CosmicTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(sortOption == option ? CosmicTheme.gold : CosmicTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - IPO Section

    private func ipoSection(
        title: String,
        subtitle: String,
        ipos: [IPO],
        isUrgent: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if isUrgent {
                            Circle()
                                .fill(CosmicTheme.gold)
                                .frame(width: 8, height: 8)
                        }

                        Text(title.uppercased())
                            .font(TerminalFont.headline(14))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }

                    Text(subtitle)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()

                Text("\(ipos.count)")
                    .font(TerminalFont.price(16))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // IPO cards
            LazyVStack(spacing: 12) {
                ForEach(ipos) { ipo in
                    IPORowView(
                        ipo: ipo,
                        compatibility: ipo.compatibility(with: safeUser),
                        framingLevel: framingLevel,
                        onTap: { selectedIPO = ipo }
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            if ipoService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: CosmicTheme.gold))
                    .scaleEffect(1.2)

                Text("Loading IPOs...")
                    .font(TerminalFont.data(14))
                    .foregroundColor(CosmicTheme.textSecondary)
            } else if let error = ipoService.lastError {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundColor(CosmicTheme.negative)

                Text("Unable to load IPOs")
                    .font(TerminalFont.headline(16))
                    .foregroundColor(CosmicTheme.textSecondary)

                Text(error.localizedDescription)
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Button(action: {
                    Task {
                        await ipoService.forceRefresh()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.gold)
                }
            } else {
                Image(systemName: "sparkle")
                    .font(.system(size: 48))
                    .foregroundColor(CosmicTheme.textMuted)

                Text(framedEmptyMessage)
                    .font(TerminalFont.headline(16))
                    .foregroundColor(CosmicTheme.textSecondary)

                if selectedSector != nil || !searchText.isEmpty {
                    Button("Clear Filters") {
                        selectedSector = nil
                        searchText = ""
                    }
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.gold)
                } else {
                    Text("No upcoming IPOs in this date range")
                        .font(TerminalFont.data(12))
                        .foregroundColor(CosmicTheme.textMuted)

                    Button(action: {
                        Task {
                            await ipoService.forceRefresh()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .font(TerminalFont.data(12))
                        .foregroundColor(CosmicTheme.gold)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Statistics Footer

    private var statisticsFooter: some View {
        let stats = ipoService.getStatistics()

        return VStack(spacing: 12) {
            Divider()
                .background(CosmicTheme.border)

            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text(stats.formattedTotalValuation)
                        .font(TerminalFont.price(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("TOTAL VALUE")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 0.5, height: 30)

                VStack(spacing: 2) {
                    Text("\(stats.thisMonthCount)")
                        .font(TerminalFont.price(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("THIS MONTH")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 0.5, height: 30)

                VStack(spacing: 2) {
                    if let topSector = stats.topSectors.first {
                        Text(topSector.0)
                            .font(TerminalFont.data(12))
                            .foregroundColor(CosmicTheme.textPrimary)
                            .lineLimit(1)

                        Text("TOP SECTOR")
                            .font(TerminalFont.data(8))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - IPO Row View

struct IPORowView: View {

    let ipo: IPO
    let compatibility: IPOCompatibilityResult
    let framingLevel: SignalFramingLevel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Zodiac badge
                zodiacBadge

                // Company info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(ipo.companyName)
                            .font(TerminalFont.headline(14))
                            .foregroundColor(CosmicTheme.textPrimary)
                            .lineLimit(1)

                        if ipo.isThisWeek {
                            Text("SOON")
                                .font(TerminalFont.data(8, weight: .bold))
                                .foregroundColor(CosmicTheme.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(CosmicTheme.gold)
                                )
                        }
                    }

                    HStack(spacing: 8) {
                        Text(ipo.displayTicker)
                            .font(TerminalFont.data(11, weight: .semibold))
                            .foregroundColor(CosmicTheme.gold)

                        Text("•")
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(ipo.sector)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }

                    // Birth narrative
                    Text(birthSummary)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                // Right side info
                VStack(alignment: .trailing, spacing: 4) {
                    Text(ipo.relativeDateDescription)
                        .font(TerminalFont.data(11))
                        .foregroundColor(ipo.isThisWeek ? CosmicTheme.gold : CosmicTheme.textSecondary)

                    // Compatibility score
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("\(compatibility.score)%")
                            .font(TerminalFont.price(14))
                    }
                    .foregroundColor(compatibilityColor)

                    if let priceRange = ipo.formattedPriceRange {
                        Text(priceRange)
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(CosmicTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        ipo.isThisWeek ? CosmicTheme.gold.opacity(0.3) : CosmicTheme.border,
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var zodiacBadge: some View {
        ZStack {
            Circle()
                .fill(elementColor.opacity(0.2))
                .frame(width: 44, height: 44)

            Circle()
                .stroke(elementColor.opacity(0.5), lineWidth: 1)
                .frame(width: 44, height: 44)

            ZodiacSymbolView(sign: ipo.zodiacSign, size: 22, color: elementColor)
        }
    }

    private var birthSummary: String {
        switch framingLevel {
        case .rational:
            return "IPO Date: \(ipo.expectedDate.formatted(.dateTime.month(.abbreviated).day())) — \(ipo.sector)"
        case .leanRational:
            return "Listing \(ipo.expectedDate.formatted(.dateTime.month(.abbreviated).day())) — \(ipo.zodiacSign.element.displayName) sector traits"
        default:
            return "Born \(ipo.zodiacSign.displayName) — \(ipo.zodiacSign.element.displayName) energy"
        }
    }

    private var elementColor: Color {
        switch ipo.zodiacSign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var compatibilityColor: Color {
        switch compatibility.score {
        case 80...100: return CosmicTheme.gold
        case 65..<80:  return CosmicTheme.positive
        case 50..<65:  return CosmicTheme.textSecondary
        default:       return CosmicTheme.negative
        }
    }
}

// MARK: - IPO Alert Banner

struct IPOAlertBanner: View {

    let alert: IPOAlert
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Zodiac badge
                ZStack {
                    Circle()
                        .fill(CosmicTheme.gold.opacity(0.2))
                        .frame(width: 40, height: 40)

                    ZodiacSymbolView(sign: alert.ipo.zodiacSign, size: 20, color: CosmicTheme.gold)
                }

                // Message
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.ipo.companyName)
                        .font(TerminalFont.headline(13))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(alert.message)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Urgency indicator
                if alert.isUrgent {
                    VStack(spacing: 2) {
                        Text(alert.ipo.relativeDateDescription)
                            .font(TerminalFont.data(10, weight: .bold))
                            .foregroundColor(CosmicTheme.gold)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(CosmicTheme.gold.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("IPO List") {
    IPOListView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}
