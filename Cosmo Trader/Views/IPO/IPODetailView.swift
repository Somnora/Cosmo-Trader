import SwiftUI

// MARK: - IPO Detail View
// ========================
// Full profile view for an upcoming IPO.
// Treats the IPO like a birth - emphasizes the "birth chart" and cosmic personality.

struct IPODetailView: View {

    // MARK: - Properties

    let ipo: IPO

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed

    private var user: UserProfile {
        appState.currentUser ?? .sampleWithHoldings
    }

    private var compatibility: IPOCompatibilityResult {
        ipo.compatibility(with: user)
    }

    private var isOnWatchlist: Bool {
        guard let ticker = ipo.ticker else { return false }
        return user.watchlist.contains(ticker)
    }

    // MARK: - State

    @State private var appearAnimation: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showAddedConfirmation: Bool = false
    @State private var confirmationMessage: String = ""

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 1. Birth Header
                birthHeaderSection

                // 2. Countdown to Birth
                countdownSection

                // 3. Cosmic Compatibility
                compatibilitySection

                // 4. Birth Chart / Astrological Profile
                birthChartSection

                // 5. Company Profile
                companyProfileSection

                // 6. Predicted Personality
                personalitySection

                // 7. IPO Details (Price, Valuation)
                ipoDetailsSection

                // 8. Action Buttons
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(TerminalBackground(starCount: 30, showGrid: false))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(ipo.displayTicker)
                    .font(TerminalFont.headline(16))
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
        .toolbarBackground(CosmicTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimation = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            shareSheet
        }
    }

    // MARK: - Birth Header Section

    private var birthHeaderSection: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                // Company "embryo" visual
                ZStack {
                    // Cosmic glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [elementColor.opacity(0.4), elementColor.opacity(0.1), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)

                    // Inner circle
                    Circle()
                        .fill(CosmicTheme.secondaryBackground)
                        .frame(width: 72, height: 72)

                    // Zodiac symbol
                    ZodiacSymbolView(sign: ipo.zodiacSign, size: 36, color: elementColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(ipo.companyName)
                        .font(TerminalFont.headline(20))
                        .foregroundColor(CosmicTheme.textPrimary)

                    HStack(spacing: 8) {
                        Text(ipo.displayTicker)
                            .font(TerminalFont.data(14, weight: .semibold))
                            .foregroundColor(CosmicTheme.gold)

                        Text("•")
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(ipo.sector)
                            .font(TerminalFont.data(13))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }

                    // Birth status badge
                    birthStatusBadge
                }

                Spacer()
            }

            // Birth narrative quote
            VStack(spacing: 8) {
                Text("\"")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundColor(CosmicTheme.gold.opacity(0.5))
                    .offset(y: 10)

                Text(ipo.birthNarrative)
                    .font(TerminalFont.data(14))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private var birthStatusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(TerminalFont.data(11, weight: .semibold))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
    }

    private var statusText: String {
        if ipo.isToday {
            return "BORN TODAY"
        } else if ipo.daysUntilIPO == 1 {
            return "TOMORROW"
        } else if ipo.isThisWeek {
            return "THIS WEEK"
        } else {
            return "UPCOMING"
        }
    }

    private var statusColor: Color {
        if ipo.isToday {
            return CosmicTheme.positive
        } else if ipo.isThisWeek {
            return CosmicTheme.gold
        } else {
            return CosmicTheme.textSecondary
        }
    }

    // MARK: - Countdown Section

    private var countdownSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(CosmicTheme.gold)

                Text("TIME UNTIL BIRTH")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()
            }

            HStack(spacing: 20) {
                if ipo.isToday {
                    countdownUnit(value: "TODAY", label: "IPO DAY", isHighlighted: true)
                } else if ipo.daysUntilIPO > 0 {
                    countdownUnit(value: "\(ipo.daysUntilIPO)", label: "DAYS", isHighlighted: ipo.isThisWeek)
                } else {
                    countdownUnit(value: "LIVE", label: "TRADING", isHighlighted: true)
                }

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 0.5, height: 40)

                VStack(spacing: 4) {
                    Text(ipo.formattedDate)
                        .font(TerminalFont.price(16))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(ipo.weekdayName.uppercased())
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(CosmicTheme.secondaryBackground)
            )
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.05), value: appearAnimation)
    }

    private func countdownUnit(value: String, label: String, isHighlighted: Bool) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(TerminalFont.price(28))
                .foregroundColor(isHighlighted ? CosmicTheme.gold : CosmicTheme.textPrimary)

            Text(label)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Compatibility Section

    private var compatibilitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(CosmicTheme.gold)

                Text("YOUR COSMIC ALIGNMENT")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()

                if compatibility.isHighlyCompatible {
                    cosmicMatchBadge
                }
            }

            // Large score
            HStack(spacing: 16) {
                Text("\(compatibility.score)%")
                    .font(TerminalFont.price(56))
                    .foregroundStyle(scoreGradient)

                VStack(alignment: .leading, spacing: 4) {
                    Text("COMPATIBILITY")
                        .font(TerminalFont.data(12))
                        .foregroundColor(CosmicTheme.textMuted)

                    HStack(spacing: 6) {
                        Text(compatibility.rating.emoji)
                        Text(compatibility.rating.displayName.uppercased())
                            .font(TerminalFont.data(12, weight: .semibold))
                            .foregroundColor(ratingColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Description
            Text(compatibility.description)
                .font(TerminalFont.data(13))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(4)

            // Element synergy
            elementSynergyCard

            // Advice
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(CosmicTheme.gold)

                Text(compatibility.advice)
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(CosmicTheme.gold.opacity(0.1))
            )

            // Original holder message
            if !ipo.hasLaunched {
                originalHolderMessage
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimation)
    }

    private var cosmicMatchBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10))
            Text("COSMIC MATCH")
                .font(TerminalFont.data(9, weight: .bold))
        }
        .foregroundColor(CosmicTheme.background)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(CosmicTheme.goldGradient)
        )
    }

    private var elementSynergyCard: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ElementSymbolView(element: user.sunSign.element, size: 20)
                Text("+")
                    .font(TerminalFont.data(14))
                    .foregroundColor(CosmicTheme.textMuted)
                ElementSymbolView(element: ipo.zodiacSign.element, size: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(user.sunSign.element.displayName) + \(ipo.zodiacSign.element.displayName)")
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(compatibility.elementSynergy)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    private var originalHolderMessage: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill")
                .foregroundColor(CosmicTheme.gold)

            Text("If you invest at IPO, you'll be an original holder since birth.")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CosmicTheme.cosmicPurple.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(CosmicTheme.cosmicPurple.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Birth Chart Section

    private var birthChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(CosmicTheme.cosmicBlue)

                Text("BIRTH CHART")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()
            }

            // Zodiac sign details
            HStack(spacing: 16) {
                ZodiacSymbolView(sign: ipo.zodiacSign, size: 48, color: elementColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(ipo.zodiacSign.displayName)
                        .font(TerminalFont.headline(22))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(ipo.zodiacSign.dateRangeDescription)
                        .font(TerminalFont.data(12))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()
            }

            // Birth chart grid
            StatsGridView(stats: [
                .text("Sun Sign", ipo.zodiacSign.displayName),
                StatItem(label: "Element", value: ipo.zodiacSign.element.displayName, color: elementColor),
                .text("Modality", ipo.zodiacSign.modality.displayName),
                .text("Ruler", ipo.zodiacSign.rulingPlanet),
                .text("Birth Date", ipo.shortFormattedDate),
                .gold("Match", "\(compatibility.score)%")
            ], columns: 3)

            // Sign description
            Text(ipo.zodiacSign.personalityDescription)
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)

            // Key traits
            HStack(spacing: 8) {
                ForEach(ipo.zodiacSign.keyTraits.prefix(3), id: \.self) { trait in
                    Text(trait)
                        .font(TerminalFont.data(10))
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
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.15), value: appearAnimation)
    }

    // MARK: - Company Profile Section

    private var companyProfileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(CosmicTheme.nebulaBlue)

                Text("COMPANY PROFILE")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()
            }

            Text(ipo.description)
                .font(TerminalFont.data(13))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(4)

            // Company details grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if !ipo.headquarters.isEmpty {
                    detailItem(label: "Headquarters", value: ipo.headquarters)
                }
                if let year = ipo.foundedYear {
                    detailItem(label: "Founded", value: "\(year)")
                }
                detailItem(label: "Sector", value: ipo.sector)
                detailItem(label: "Industry", value: ipo.industry)
                if let employees = ipo.employeeCount {
                    detailItem(label: "Employees", value: formatNumber(employees))
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)
    }

    private func detailItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)

            Text(value)
                .font(TerminalFont.data(13))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }

    // MARK: - Personality Section

    private var personalitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill.viewfinder")
                    .foregroundColor(CosmicTheme.cosmicPurple)

                Text("PREDICTED MARKET PERSONALITY")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()
            }

            Text(ipo.predictedPersonality)
                .font(TerminalFont.data(14))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(4)
                .italic()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(elementColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(elementColor.opacity(0.3), lineWidth: 0.5)
                        )
                )
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.25), value: appearAnimation)
    }

    // MARK: - IPO Details Section

    private var ipoDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(CosmicTheme.positive)

                Text("IPO DETAILS")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()
            }

            // Price range display
            if let priceRange = ipo.formattedPriceRange {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EXPECTED PRICE RANGE")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(priceRange)
                            .font(TerminalFont.price(28))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }

                    Spacer()

                    if let midPrice = ipo.midPrice {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("MIDPOINT")
                                .font(TerminalFont.data(10))
                                .foregroundColor(CosmicTheme.textMuted)

                            Text(String(format: "$%.2f", midPrice))
                                .font(TerminalFont.price(18))
                                .foregroundColor(CosmicTheme.gold)
                        }
                    }
                }
            }

            // Valuation
            if let valuation = ipo.formattedValuation {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ESTIMATED VALUATION")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(valuation)
                            .font(TerminalFont.price(24))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }

                    Spacer()
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: appearAnimation)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Add to Watchlist
            Button(action: toggleWatchlist) {
                HStack {
                    Image(systemName: isOnWatchlist ? "heart.fill" : "heart")
                    Text(isOnWatchlist ? "On Watchlist" : "Add to Watchlist")
                        .fontWeight(.semibold)
                }
                .foregroundColor(isOnWatchlist ? CosmicTheme.positive : CosmicTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isOnWatchlist ? CosmicTheme.positive.opacity(0.2) : nil)
                .background(isOnWatchlist ? nil : CosmicTheme.goldGradient)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isOnWatchlist ? CosmicTheme.positive : Color.clear, lineWidth: 2)
                )
            }
            .disabled(ipo.ticker == nil)
            .opacity(ipo.ticker == nil ? 0.5 : 1)

            if ipo.ticker == nil {
                Text("Ticker not yet assigned — watchlist available soon")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            // Share button
            Button(action: { showShareSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Birth Announcement")
                        .fontWeight(.medium)
                }
                .foregroundColor(CosmicTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.border, lineWidth: 0.5)
                )
            }

            // Confirmation message
            if showAddedConfirmation {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(CosmicTheme.positive)
                    Text(confirmationMessage)
                        .font(TerminalFont.data(13))
                        .foregroundColor(CosmicTheme.textPrimary)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(CosmicTheme.positive.opacity(0.15))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.35), value: appearAnimation)
    }

    // MARK: - Actions

    private func toggleWatchlist() {
        guard let ticker = ipo.ticker else { return }

        if isOnWatchlist {
            appState.removeFromWatchlist(ticker)
            confirmationMessage = "\(ticker) removed from watchlist"
        } else {
            appState.addToWatchlist(ticker)
            confirmationMessage = "\(ticker) added to watchlist — you'll be notified at birth!"
        }

        withAnimation(.spring(response: 0.4)) {
            showAddedConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut) {
                showAddedConfirmation = false
            }
        }
    }

    // MARK: - Share Sheet

    private var shareSheet: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Preview card
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            ZodiacSymbolView(sign: ipo.zodiacSign, size: 40, color: elementColor)

                            VStack(alignment: .leading) {
                                Text(ipo.companyName)
                                    .font(TerminalFont.headline(16))
                                    .foregroundColor(CosmicTheme.textPrimary)

                                Text("\(ipo.displayTicker) • Born \(ipo.zodiacSign.displayName)")
                                    .font(TerminalFont.data(12))
                                    .foregroundColor(CosmicTheme.textSecondary)
                            }

                            Spacer()
                        }

                        Text("\"\(ipo.birthNarrative)\"")
                            .font(TerminalFont.data(13))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .italic()
                            .multilineTextAlignment(.center)

                        HStack {
                            Text("IPO Date: \(ipo.formattedDate)")
                                .font(TerminalFont.data(11))
                                .foregroundColor(CosmicTheme.textMuted)

                            Spacer()

                            Text("\(compatibility.score)% Match")
                                .font(TerminalFont.price(14))
                                .foregroundColor(CosmicTheme.gold)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(CosmicTheme.cardBackground)
                    )

                    Text("Share this cosmic birth announcement!")
                        .font(TerminalFont.data(12))
                        .foregroundColor(CosmicTheme.textMuted)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Share Birth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showShareSheet = false
                    }
                    .foregroundColor(CosmicTheme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share") {
                        showShareSheet = false
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private var cardBackground: some View {
        Rectangle()
            .fill(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
    }

    private var elementColor: Color {
        switch ipo.zodiacSign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var ratingColor: Color {
        switch compatibility.rating {
        case .cosmicSoulmates:   return CosmicTheme.gold
        case .highCompatibility: return CosmicTheme.positive
        case .neutral:           return CosmicTheme.textSecondary
        case .challenging:       return .orange
        case .cosmicClash:       return CosmicTheme.negative
        }
    }

    private var scoreGradient: LinearGradient {
        if compatibility.score >= 85 {
            return CosmicTheme.goldGradient
        } else if compatibility.score >= 65 {
            return LinearGradient(
                colors: [CosmicTheme.cosmicPurple, CosmicTheme.nebulaBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [CosmicTheme.textPrimary, CosmicTheme.textSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - ZodiacSign Extensions for IPO

extension ZodiacSign {

    /// The ruling planet for this sign
    var rulingPlanet: String {
        switch self {
        case .aries: return "Mars"
        case .taurus: return "Venus"
        case .gemini: return "Mercury"
        case .cancer: return "Moon"
        case .leo: return "Sun"
        case .virgo: return "Mercury"
        case .libra: return "Venus"
        case .scorpio: return "Pluto"
        case .sagittarius: return "Jupiter"
        case .capricorn: return "Saturn"
        case .aquarius: return "Uranus"
        case .pisces: return "Neptune"
        }
    }

    /// Key traits for the sign
    var keyTraits: [String] {
        switch self {
        case .aries: return ["Bold", "Pioneering", "Competitive", "Direct"]
        case .taurus: return ["Steady", "Reliable", "Patient", "Practical"]
        case .gemini: return ["Adaptable", "Curious", "Versatile", "Quick"]
        case .cancer: return ["Nurturing", "Protective", "Intuitive", "Loyal"]
        case .leo: return ["Confident", "Generous", "Creative", "Dramatic"]
        case .virgo: return ["Analytical", "Precise", "Helpful", "Methodical"]
        case .libra: return ["Diplomatic", "Fair", "Social", "Harmonious"]
        case .scorpio: return ["Intense", "Strategic", "Resourceful", "Transformative"]
        case .sagittarius: return ["Optimistic", "Adventurous", "Philosophical", "Free-spirited"]
        case .capricorn: return ["Ambitious", "Disciplined", "Practical", "Patient"]
        case .aquarius: return ["Innovative", "Independent", "Progressive", "Humanitarian"]
        case .pisces: return ["Intuitive", "Compassionate", "Creative", "Empathetic"]
        }
    }
}

// MARK: - Preview

#Preview("IPO Detail") {
    NavigationStack {
        IPODetailView(ipo: MockIPOData.all[0])
    }
    .environment(AppState.preview)
    .preferredColorScheme(.dark)
}

#Preview("IPO Detail - This Week") {
    NavigationStack {
        IPODetailView(ipo: MockIPOData.thisWeek.first ?? MockIPOData.all[0])
    }
    .environment(AppState.preview)
    .preferredColorScheme(.dark)
}
