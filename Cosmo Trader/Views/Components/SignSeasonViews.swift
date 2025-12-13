import SwiftUI

// MARK: - Sign Season Banner
// ===========================
// Prominent banner announcing the current zodiac season

struct SignSeasonBanner: View {
    let holdings: [Stock]
    let userSign: ZodiacSign

    @State private var seasonService = SignSeasonService.shared
    @State private var showSeasonDetail = false
    @State private var isExpanded = true

    private var spotlightStocks: [Stock] {
        seasonService.getSpotlightStocks(from: holdings)
    }

    private var elementStocks: [Stock] {
        seasonService.getElementAlignedStocks(from: holdings)
    }

    var body: some View {
        Button(action: { showSeasonDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Zodiac symbol with glow
                    ZStack {
                        Circle()
                            .fill(elementColor.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .blur(radius: 8)

                        Circle()
                            .fill(elementColor.opacity(0.2))
                            .frame(width: 44, height: 44)

                        ZodiacSymbolView(
                            sign: seasonService.currentSeason.sign,
                            size: 22,
                            color: elementColor
                        )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("\(seasonService.currentSeason.sign.displayName) Season")
                                .font(.headline)
                                .foregroundColor(CosmicTheme.textPrimary)

                            if seasonService.isSeasonTransitionDay || seasonService.isNewSeasonForUser {
                                Text("NEW")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(CosmicTheme.background)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(elementColor)
                                    )
                            }
                        }

                        Text(seasonService.currentSeason.formattedDateRange)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }

                    Spacer()

                    // Progress indicator
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(seasonService.currentSeason.daysRemaining) days left")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)

                        SeasonProgressBar(
                            progress: seasonService.currentSeason.progress,
                            color: elementColor
                        )
                    }
                }

                // Element activation message
                HStack(spacing: 8) {
                    ElementSymbolView(
                        element: seasonService.currentSeason.sign.element,
                        size: 14
                    )

                    Text("\(seasonService.currentSeason.sign.element.displayName) Sector Activated")
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(elementColor)

                    Spacer()

                    if !elementStocks.isEmpty {
                        Text("\(elementStocks.count) holding\(elementStocks.count > 1 ? "s" : "")")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                // Spotlight stocks preview
                if !spotlightStocks.isEmpty {
                    Divider()
                        .background(elementColor.opacity(0.3))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(seasonService.currentSeason.sign.displayName) STOCKS IN SPOTLIGHT")
                            .font(TerminalFont.data(10, weight: .bold))
                            .foregroundColor(CosmicTheme.textMuted)

                        HStack(spacing: 12) {
                            ForEach(spotlightStocks.prefix(3)) { stock in
                                SpotlightStockChip(stock: stock, color: elementColor)
                            }

                            if spotlightStocks.count > 3 {
                                Text("+\(spotlightStocks.count - 3)")
                                    .font(TerminalFont.data(11))
                                    .foregroundColor(CosmicTheme.textMuted)
                            }

                            Spacer()
                        }
                    }
                }

                // View details prompt
                HStack {
                    Text("View Season Horoscope")
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.gold)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                elementColor.opacity(0.15),
                                elementColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(elementColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSeasonDetail) {
            SignSeasonDetailSheet(
                userSign: userSign,
                holdings: holdings
            )
        }
        .onAppear {
            AnalyticsService.shared.track(.signSeasonViewed)
        }
    }

    private var elementColor: Color {
        switch seasonService.currentSeason.sign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Season Progress Bar

struct SeasonProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.2))

                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(progress))
            }
        }
        .frame(width: 50, height: 4)
    }
}

// MARK: - Spotlight Stock Chip

struct SpotlightStockChip: View {
    let stock: Stock
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(stock.symbol)
                .font(TerminalFont.data(11, weight: .semibold))
                .foregroundColor(color)

            Text(stock.formattedPercentageChange)
                .font(TerminalFont.data(9))
                .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Sign Season Detail Sheet
// =================================
// Full detail view for the current zodiac season

struct SignSeasonDetailSheet: View {
    let userSign: ZodiacSign
    let holdings: [Stock]

    @State private var seasonService = SignSeasonService.shared
    @Environment(\.dismiss) private var dismiss

    private var horoscope: SeasonHoroscope {
        seasonService.generateSeasonHoroscope(userSign: userSign, holdings: holdings)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection

                    // Personal message
                    personalMessageSection

                    // Element insight
                    elementInsightSection

                    // Spotlight stocks
                    if !horoscope.spotlightStocks.isEmpty {
                        spotlightStocksSection
                    }

                    // Element stocks
                    if !horoscope.elementStocks.isEmpty && horoscope.elementStocks != horoscope.spotlightStocks {
                        elementStocksSection
                    }

                    // Trading outlook
                    tradingOutlookSection

                    // Disclaimer
                    disclaimerSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("\(horoscope.season.sign.displayName) Season")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        seasonService.markSeasonAsSeen()
                        dismiss()
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            AnalyticsService.shared.track(.signSeasonHoroscopeViewed)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Large zodiac symbol with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                elementColor.opacity(0.4),
                                elementColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                // Symbol background
                Circle()
                    .fill(elementColor.opacity(0.2))
                    .frame(width: 100, height: 100)

                // Zodiac symbol
                ZodiacSymbolView(
                    sign: horoscope.season.sign,
                    size: 50,
                    color: elementColor
                )
            }

            // Season info
            VStack(spacing: 8) {
                Text("\(horoscope.season.sign.displayName) Season")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(horoscope.season.formattedDateRange)
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)

                // Progress
                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(elementColor.opacity(0.2))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(elementColor)
                                .frame(width: geometry.size.width * CGFloat(horoscope.season.progress))
                        }
                    }
                    .frame(height: 8)
                    .frame(maxWidth: 200)

                    Text("\(horoscope.season.daysRemaining) days remaining")
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Personal Message Section

    private var personalMessageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Your Season Reading", icon: "person.fill")

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ZodiacSymbolView(sign: userSign, size: 16, color: userElementColor)
                    Text("As a \(userSign.displayName)...")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Text(horoscope.personalMessage)
                    .font(.body)
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineSpacing(6)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Element Insight Section

    private var elementInsightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "\(horoscope.season.sign.element.displayName) Element Focus",
                icon: elementIcon
            )

            VStack(alignment: .leading, spacing: 12) {
                // Element badge
                HStack(spacing: 8) {
                    ElementSymbolView(element: horoscope.season.sign.element, size: 20)

                    Text("\(horoscope.season.sign.element.displayName.uppercased()) SECTOR ACTIVATED")
                        .font(TerminalFont.data(12, weight: .bold))
                        .foregroundColor(elementColor)
                }

                Text(horoscope.elementInsight)
                    .font(.body)
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineSpacing(6)

                // Element signs list
                HStack(spacing: 16) {
                    ForEach(elementSigns, id: \.self) { sign in
                        VStack(spacing: 4) {
                            ZodiacSymbolView(sign: sign, size: 18, color: elementColor)
                            Text(sign.displayName)
                                .font(TerminalFont.data(9))
                                .foregroundColor(CosmicTheme.textMuted)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(elementColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(elementColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Spotlight Stocks Section

    private var spotlightStocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "In the Spotlight", icon: "star.fill")

                Spacer()

                Text(formatCurrency(horoscope.spotlightValue))
                    .font(TerminalFont.price(14))
                    .foregroundColor(CosmicTheme.gold)
            }

            VStack(spacing: 8) {
                ForEach(horoscope.spotlightStocks) { stock in
                    SpotlightStockRow(stock: stock, elementColor: elementColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Element Stocks Section

    private var elementStocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(
                    title: "\(horoscope.season.sign.element.displayName) Sector Holdings",
                    icon: elementIcon
                )

                Spacer()

                Text("\(horoscope.elementStocks.count) stocks")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            VStack(spacing: 8) {
                ForEach(horoscope.elementStocks.filter { !horoscope.spotlightStocks.contains($0) }.prefix(5)) { stock in
                    ElementStockRow(stock: stock)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Trading Outlook Section

    private var tradingOutlookSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Trading Outlook", icon: "chart.line.uptrend.xyaxis")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundColor(CosmicTheme.gold.opacity(0.5))

                Text(horoscope.tradingOutlook)
                    .font(.body)
                    .italic()
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.gold.opacity(0.08))
            )
        }
    }

    // MARK: - Disclaimer Section

    private var disclaimerSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .foregroundColor(.orange)

            Text("Zodiac seasons are for entertainment purposes only. There is no scientific evidence that solar position affects stock performance. Always make investment decisions based on proper financial analysis.")
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)
                .italic()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.08))
        )
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)

            Text(title)
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textPrimary)
        }
    }

    private var elementColor: Color {
        switch horoscope.season.sign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var userElementColor: Color {
        switch userSign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var elementIcon: String {
        switch horoscope.season.sign.element {
        case .fire:  return "flame.fill"
        case .earth: return "leaf.fill"
        case .air:   return "wind"
        case .water: return "drop.fill"
        }
    }

    private var elementSigns: [ZodiacSign] {
        ZodiacSign.allCases.filter { $0.element == horoscope.season.sign.element }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Spotlight Stock Row

struct SpotlightStockRow: View {
    let stock: Stock
    let elementColor: Color

    var body: some View {
        HStack(spacing: 12) {
            // Zodiac badge
            ZStack {
                Circle()
                    .fill(elementColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                ZodiacSymbolView(
                    sign: stock.zodiacSign,
                    size: 18,
                    color: elementColor
                )
            }

            // Stock info
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(TerminalFont.headline(14))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.name)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Price info
            VStack(alignment: .trailing, spacing: 2) {
                Text(stock.formattedPrice)
                    .font(TerminalFont.price(14))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.formattedPercentageChange)
                    .font(TerminalFont.data(11))
                    .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Element Stock Row

struct ElementStockRow: View {
    let stock: Stock

    var body: some View {
        HStack(spacing: 12) {
            ZodiacSymbolView(
                sign: stock.zodiacSign,
                size: 16,
                color: elementColor
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.zodiacSign.displayName)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            Text(stock.formattedPercentageChange)
                .font(TerminalFont.data(11))
                .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
        }
        .padding(.vertical, 2)
    }

    private var elementColor: Color {
        switch stock.zodiacSign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Sign Season Notification Toggle

struct SignSeasonToggle: View {
    @State private var seasonService = SignSeasonService.shared

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(CosmicTheme.gold.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 18))
                    .foregroundColor(CosmicTheme.gold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Sign Season Alerts")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("When sun enters new zodiac sign")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            Toggle("", isOn: $seasonService.signSeasonAlertsEnabled)
                .labelsHidden()
                .tint(CosmicTheme.gold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Compact Season Badge

struct SignSeasonBadge: View {
    @State private var seasonService = SignSeasonService.shared

    var body: some View {
        HStack(spacing: 6) {
            ZodiacSymbolView(
                sign: seasonService.currentSeason.sign,
                size: 12,
                color: elementColor
            )

            Text("\(seasonService.currentSeason.sign.displayName) Season")
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(elementColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(elementColor.opacity(0.15))
        )
    }

    private var elementColor: Color {
        switch seasonService.currentSeason.sign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Previews

#Preview("Sign Season Banner") {
    VStack {
        SignSeasonBanner(
            holdings: Stock.samples,
            userSign: .leo
        )
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Sign Season Detail") {
    SignSeasonDetailSheet(
        userSign: .leo,
        holdings: Stock.samples
    )
    .preferredColorScheme(.dark)
}

#Preview("Sign Season Badge") {
    VStack {
        SignSeasonBadge()
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}
