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
    @State private var showFilters: Bool = false

    // MARK: - Computed

    private var user: UserProfile {
        appState.currentUser ?? .sampleWithHoldings
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
        return ipoService.sortIPOs(ipos, by: sortOption, user: user)
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
                    VStack(spacing: 24) {
                        // Header with cosmic birth theme
                        headerSection

                        // IPO Alerts (if any highly compatible)
                        ipoAlertsSection

                        // Sort and filter controls
                        sortFilterControls

                        // This Week section
                        if !thisWeekIPOs.isEmpty {
                            ipoSection(
                                title: "Births This Week",
                                subtitle: "Cosmic arrivals within 7 days",
                                ipos: thisWeekIPOs,
                                isUrgent: true
                            )
                        }

                        // Later IPOs
                        if !laterIPOs.isEmpty {
                            ipoSection(
                                title: "Upcoming Cosmic Births",
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
                        Text("Cosmic Births")
                            .font(TerminalFont.headline(16))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showFilters.toggle() }) {
                        Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
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

            Text("Upcoming Cosmic Births")
                .font(TerminalFont.headline(20))
                .foregroundColor(CosmicTheme.textPrimary)

            Text("Every IPO enters the market under a zodiac sign, born into the cosmic order of commerce.")
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
                    value: "\(ipoService.getHighlyCompatibleIPOs(for: user).count)",
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
        let alerts = ipoService.getIPOAlerts(for: user)

        if !alerts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(CosmicTheme.gold)

                    Text("COSMIC ALERTS")
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
            // Sort options
            HStack(spacing: 8) {
                Text("SORT BY")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)

                ForEach(IPOSortOption.allCases, id: \.self) { option in
                    sortButton(option)
                }

                Spacer()
            }

            // Sector filter (when expanded)
            if showFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        sectorFilterButton(nil, label: "All")

                        ForEach(MockIPOData.sectors, id: \.self) { sector in
                            sectorFilterButton(sector, label: sector)
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showFilters)
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

    private func sectorFilterButton(_ sector: String?, label: String) -> some View {
        Button(action: { selectedSector = sector }) {
            Text(label)
                .font(TerminalFont.data(11))
                .foregroundColor(selectedSector == sector ? CosmicTheme.background : CosmicTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(selectedSector == sector ? CosmicTheme.gold : CosmicTheme.cardBackground)
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
                        compatibility: ipo.compatibility(with: user),
                        onTap: { selectedIPO = ipo }
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkle")
                .font(.system(size: 48))
                .foregroundColor(CosmicTheme.textMuted)

            Text("No cosmic births found")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textSecondary)

            if selectedSector != nil || !searchText.isEmpty {
                Button("Clear Filters") {
                    selectedSector = nil
                    searchText = ""
                }
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.gold)
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
        "Born \(ipo.zodiacSign.displayName) — \(ipo.zodiacSign.element.displayName) energy"
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
