import SwiftUI

// MARK: - Cosmic Rival Card
// ==========================
// Shows the cosmic rival for a stock in the StockDetailView

struct CosmicRivalCard: View {
    let stock: Stock
    let allStocks: [Stock]

    @State private var rivalsService = CosmicRivalsService.shared
    @State private var showRivalDetail = false
    @State private var selectedRival: Stock?

    private var rivals: [Stock] {
        rivalsService.findAllRivals(for: stock, in: allStocks)
    }

    private var primaryRival: Stock? {
        rivals.first
    }

    var body: some View {
        if !rivals.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.orange)

                    Text("COSMIC RIVAL")
                        .font(TerminalFont.data(12, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Spacer()

                    // Opposition symbol
                    Text(stock.zodiacSign?.oppositionTheme ?? "Unknown opposition")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                // Main content
                VStack(spacing: 16) {
                    // Opposition visualization
                    oppositionVisualization

                    // Description
                    Text(stock.zodiacSign?.oppositionDescription ?? "Verified company sign unavailable; rival framing is hidden until the company date is known.")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineSpacing(4)

                    // Rival stocks list
                    if !rivals.isEmpty {
                        Divider()
                            .background(CosmicTheme.borderDim)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stocks in \(stock.zodiacSign?.oppositeSign.displayName ?? "Unknown")")
                                .font(TerminalFont.data(11, weight: .semibold))
                                .foregroundColor(CosmicTheme.textMuted)

                            ForEach(rivals.prefix(3)) { rival in
                                rivalRow(rival)
                            }

                            if rivals.count > 3 {
                                Text("+ \(rivals.count - 3) more")
                                    .font(TerminalFont.data(10))
                                    .foregroundColor(CosmicTheme.textMuted)
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(20)
            .background(
                Rectangle()
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(CosmicTheme.border, lineWidth: 0.5)
                    )
            )
            .onAppear {
                AnalyticsService.shared.track(.cosmicRivalViewed)
            }
        }
    }

    // MARK: - Opposition Visualization

    private var oppositionVisualization: some View {
        HStack(spacing: 0) {
            // Stock's sign
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(elementColor(for: stock.zodiacSign).opacity(0.2))
                        .frame(width: 50, height: 50)

                    if let sign = stock.zodiacSign {
                        ZodiacSymbolView(
                            sign: sign,
                            size: 24,
                            color: elementColor(for: sign)
                        )
                    } else {
                        Text("?")
                            .font(TerminalFont.body(24, weight: .semibold))
                            .foregroundColor(CosmicTheme.textMuted)
                            .accessibilityLabel("unknown sign")
                    }
                }

                Text(stock.zodiacSign?.displayName ?? "Unknown")
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.symbol)
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            // Opposition indicator
            VStack(spacing: 4) {
                Text("☍")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text("180°")
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(.orange)

                Text("OPPOSES")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            // Opposite sign
            VStack(spacing: 6) {
                ZStack {
                    let oppositeSign = stock.zodiacSign?.oppositeSign
                    Circle()
                        .fill(elementColor(for: oppositeSign).opacity(0.2))
                        .frame(width: 50, height: 50)

                    if let oppositeSign {
                        ZodiacSymbolView(
                            sign: oppositeSign,
                            size: 24,
                            color: elementColor(for: oppositeSign)
                        )
                    } else {
                        Text("?")
                            .font(TerminalFont.body(24, weight: .semibold))
                            .foregroundColor(CosmicTheme.textMuted)
                            .accessibilityLabel("unknown opposing sign")
                    }
                }

                Text(stock.zodiacSign?.oppositeSign.displayName ?? "Unknown")
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                if let rival = primaryRival {
                    Text(rival.symbol)
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                } else {
                    Text("No stocks")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Rival Row

    private func rivalRow(_ rival: Stock) -> some View {
        HStack(spacing: 10) {
            if let sign = rival.zodiacSign {
                ZodiacSymbolView(
                    sign: sign,
                    size: 16,
                    color: elementColor(for: sign)
                )
            } else {
                Text("?")
                    .font(TerminalFont.body(16, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
                    .accessibilityLabel("unknown sign")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(rival.symbol)
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(rival.name)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Text(rival.formattedPrice)
                .font(TerminalFont.price(12))
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private func elementColor(for sign: ZodiacSign?) -> Color {
        guard let sign else { return CosmicTheme.textMuted }
        switch sign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Portfolio Tension Banner
// =================================
// Banner shown in PortfolioView when cosmic tensions exist

struct PortfolioTensionBanner: View {
    let holdings: [Stock]
    @State private var rivalsService = CosmicRivalsService.shared
    @State private var showDetail = false

    private var tensions: [CosmicTension] {
        rivalsService.detectPortfolioTensions(in: holdings)
    }

    var body: some View {
        if !tensions.isEmpty {
            Button(action: { showDetail = true }) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 36, height: 36)

                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cosmic Tension Detected")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text("\(tensions.count) rival pair\(tensions.count > 1 ? "s" : "") in your portfolio")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }

                    // Preview of first tension
                    if let firstTension = tensions.first {
                        HStack(spacing: 8) {
                            Text(firstTension.stock1.symbol)
                                .font(TerminalFont.data(11, weight: .semibold))
                                .foregroundColor(elementColor(for: firstTension.stock1.zodiacSign))

                            Text("☍")
                                .font(.caption)
                                .foregroundColor(.orange)

                            Text(firstTension.stock2.symbol)
                                .font(TerminalFont.data(11, weight: .semibold))
                                .foregroundColor(elementColor(for: firstTension.stock2.zodiacSign))

                            Text("•")
                                .foregroundColor(CosmicTheme.textMuted)

                            Text(firstTension.theme)
                                .font(TerminalFont.data(10))
                                .foregroundColor(CosmicTheme.textMuted)
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showDetail) {
                PortfolioTensionSheet(tensions: tensions)
            }
        }
    }

    private func elementColor(for sign: ZodiacSign?) -> Color {
        guard let sign else { return CosmicTheme.textMuted }
        switch sign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Portfolio Tension Detail Sheet
// =======================================
// Full detail view for portfolio cosmic tensions

struct PortfolioTensionSheet: View {
    let tensions: [CosmicTension]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection

                    // Tension list
                    tensionsListSection

                    // What this means
                    interpretationSection

                    // Disclaimer
                    disclaimerSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("Cosmic Tensions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            AnalyticsService.shared.track(.portfolioTensionViewed)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Tension visualization
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(0.2),
                                Color.orange.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Opposition symbol
                Text("☍")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 8) {
                Text("Cosmic Tension")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("\(tensions.count) opposing pair\(tensions.count > 1 ? "s" : "") detected")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Tensions List Section

    private var tensionsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Rival Pairs", icon: "arrow.left.arrow.right")

            VStack(spacing: 12) {
                ForEach(tensions) { tension in
                    tensionCard(tension)
                }
            }
        }
    }

    private func tensionCard(_ tension: CosmicTension) -> some View {
        VStack(spacing: 12) {
            // Stocks in opposition
            HStack(spacing: 0) {
                // Stock 1
                VStack(spacing: 4) {
                    Text(tension.stock1.symbol)
                        .font(TerminalFont.headline(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    HStack(spacing: 4) {
                        if let sign = tension.stock1.zodiacSign {
                            ZodiacSymbolView(
                                sign: sign,
                                size: 14,
                                color: elementColor(for: sign)
                            )
                        } else {
                            Text("?")
                                .font(TerminalFont.body(14, weight: .semibold))
                                .foregroundColor(CosmicTheme.textMuted)
                                .accessibilityLabel("unknown sign")
                        }
                        Text(tension.stock1.zodiacSign?.displayName ?? "Unknown")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Opposition indicator
                VStack(spacing: 2) {
                    Text("☍")
                        .font(.title3)
                        .foregroundColor(.orange)

                    Text("vs")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                // Stock 2
                VStack(spacing: 4) {
                    Text(tension.stock2.symbol)
                        .font(TerminalFont.headline(14))
                        .foregroundColor(CosmicTheme.textPrimary)

                    HStack(spacing: 4) {
                        if let sign = tension.stock2.zodiacSign {
                            ZodiacSymbolView(
                                sign: sign,
                                size: 14,
                                color: elementColor(for: sign)
                            )
                        } else {
                            Text("?")
                                .font(TerminalFont.body(14, weight: .semibold))
                                .foregroundColor(CosmicTheme.textMuted)
                                .accessibilityLabel("unknown sign")
                        }
                        Text(tension.stock2.zodiacSign?.displayName ?? "Unknown")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Divider()
                .background(CosmicTheme.borderDim)

            // Theme
            HStack {
                Text("Theme:")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textMuted)

                Text(tension.theme)
                    .font(TerminalFont.data(11, weight: .semibold))
                    .foregroundColor(.orange)

                Spacer()

                // Intensity badge
                Text(tension.intensity.rawValue)
                    .font(TerminalFont.data(9, weight: .bold))
                    .foregroundColor(tension.intensity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(tension.intensity.color.opacity(0.15))
                    )
            }

            // Description
            Text(tension.description)
                .font(.caption)
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    // MARK: - Interpretation Section

    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "What This Means", icon: "lightbulb.fill")

            VStack(alignment: .leading, spacing: 16) {
                interpretationPoint(
                    icon: "arrow.up.arrow.down",
                    title: "Dynamic Balance",
                    text: "Opposing forces in your portfolio create dynamic tension. When one area weakens, its opposite may strengthen, providing natural diversification."
                )

                interpretationPoint(
                    icon: "waveform.path",
                    title: "Volatility Potential",
                    text: "Cosmic tensions can amplify portfolio movements as opposing energies push and pull against each other during market shifts."
                )

                interpretationPoint(
                    icon: "scale.3d",
                    title: "Natural Hedging",
                    text: "Astrologers believe opposing signs represent complementary energies. Holding both can provide balance similar to traditional hedging strategies."
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private func interpretationPoint(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(CosmicTheme.gold)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(text)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Disclaimer Section

    private var disclaimerSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .foregroundColor(.orange)

            Text("This is for entertainment purposes only. Astrological tensions have no proven effect on stock performance. Always make investment decisions based on proper financial analysis, not zodiac positions.")
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

    private func elementColor(for sign: ZodiacSign?) -> Color {
        guard let sign else { return CosmicTheme.textMuted }
        switch sign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Compact Rival Badge
// ============================
// Small badge showing opposition for stock rows

struct CosmicRivalBadge: View {
    let stock: Stock
    let hasRivalInPortfolio: Bool

    var body: some View {
        if hasRivalInPortfolio {
            HStack(spacing: 4) {
                Text("☍")
                    .font(.caption2)

                Text("RIVAL")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.15))
            )
        }
    }
}

// MARK: - Previews

#Preview("Cosmic Rival Card") {
    ScrollView {
        CosmicRivalCard(
            stock: MockStockData.knownStocks.first!,
            allStocks: MockStockData.knownStocks
        )
    }
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Portfolio Tension Banner") {
    VStack(spacing: 20) {
        PortfolioTensionBanner(holdings: MockStockData.knownStocks.prefix(6).map { $0 })
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Tension Sheet") {
    let service = CosmicRivalsService.shared
    let tensions = service.detectPortfolioTensions(in: Array(MockStockData.knownStocks.prefix(6)))
    PortfolioTensionSheet(tensions: tensions)
        .preferredColorScheme(.dark)
}
