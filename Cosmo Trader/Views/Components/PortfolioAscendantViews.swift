import SwiftUI

// MARK: - Portfolio Ascendant Views
// ==================================
// UI components for the Portfolio Ascendant feature.
// Shows the duality between what your portfolio IS vs. how it APPEARS.

// MARK: - Portfolio Ascendant Card (for PortfolioView)

struct PortfolioAscendantCard: View {
    let holdings: [Stock]
    let userSign: ZodiacSign

    @State private var showingDetail = false
    @State private var reading: PortfolioAscendantReading?

    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "theatermasks.fill")
                            .font(.title3)
                            .foregroundColor(.purple)

                        Text("Portfolio Ascendant")
                            .font(TerminalFont.body(14, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }

                if let reading = reading {
                    // Sun vs Ascendant preview
                    HStack(spacing: 16) {
                        // Sun (True Nature)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "sun.max.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("SUN")
                                    .font(TerminalFont.caption(9, weight: .bold))
                                    .foregroundColor(CosmicTheme.textMuted)
                            }

                            Text(reading.sunAnalysis.personality)
                                .font(TerminalFont.caption(11))
                                .foregroundColor(CosmicTheme.textSecondary)
                                .lineLimit(1)
                        }

                        Divider()
                            .frame(height: 30)
                            .background(CosmicTheme.textMuted.opacity(0.3))

                        // Ascendant (Perceived)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                                Text("RISING")
                                    .font(TerminalFont.caption(9, weight: .bold))
                                    .foregroundColor(CosmicTheme.textMuted)
                            }

                            Text(reading.ascendantAnalysis.perceivedAs)
                                .font(TerminalFont.caption(11))
                                .foregroundColor(.purple)
                                .lineLimit(1)
                        }
                    }

                    // Contrast indicator
                    if reading.contrast.level == .dramatic {
                        HStack(spacing: 6) {
                            Image(systemName: "theatermasks.fill")
                                .font(.caption2)
                                .foregroundColor(.purple)

                            Text("Dramatic contrast detected")
                                .font(TerminalFont.caption(10))
                                .foregroundColor(.purple)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.15))
                        )
                    }
                } else {
                    Text("Tap to discover your portfolio's dual nature")
                        .font(TerminalFont.caption(12))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            reading = PortfolioAscendantService.shared.analyzePortfolio(
                holdings: holdings,
                userSign: userSign
            )
        }
        .sheet(isPresented: $showingDetail) {
            if let reading = reading {
                PortfolioAscendantSheet(reading: reading)
            }
        }
    }
}

// MARK: - Portfolio Ascendant Sheet

struct PortfolioAscendantSheet: View {
    let reading: PortfolioAscendantReading
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with masks icon
                    headerSection

                    // Tab selector
                    tabSelector

                    // Content based on tab
                    if selectedTab == 0 {
                        sunSection
                    } else {
                        ascendantSection
                    }

                    // Contrast insight
                    contrastSection

                    // Shareable quip
                    shareableSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("Portfolio Ascendant")
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
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(text: reading.shareableQuip)
        }
        .onAppear {
            AnalyticsService.shared.track(.portfolioAscendantViewed)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Masks icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "theatermasks.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.purple)
            }

            VStack(spacing: 4) {
                Text("Your Portfolio's Duality")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("What you hold vs. how you appear")
                    .font(TerminalFont.caption(12))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Sun (True Self)",
                icon: "sun.max.fill",
                isSelected: selectedTab == 0,
                color: .orange
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                }
            }

            TabButton(
                title: "Ascendant (Perceived)",
                icon: "sparkles",
                isSelected: selectedTab == 1,
                color: .purple
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 1
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    // MARK: - Sun Section

    private var sunSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Personality badge
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)

                Text(reading.sunAnalysis.personality)
                    .font(TerminalFont.body(16, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.1))
            )

            // Description
            Text(reading.sunAnalysis.description)
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textSecondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.cardBackground)
                )

            // Element breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("ELEMENTAL COMPOSITION")
                    .font(TerminalFont.caption(10, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)

                // Sort elements by percentage (descending) with safe optional handling
                let sortedElements = reading.sunAnalysis.elementBreakdown.keys.sorted { e1, e2 in
                    let p1 = reading.sunAnalysis.elementBreakdown[e1] ?? 0
                    let p2 = reading.sunAnalysis.elementBreakdown[e2] ?? 0
                    return p1 > p2
                }

                ForEach(sortedElements, id: \.self) { element in
                    ElementBar(
                        element: element,
                        percentage: reading.sunAnalysis.elementBreakdown[element] ?? 0,
                        isDominant: element == reading.sunAnalysis.dominantElement
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Ascendant Section

    private var ascendantSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Social label badge
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)

                Text(reading.ascendantAnalysis.perceivedAs)
                    .font(TerminalFont.body(16, weight: .semibold))
                    .foregroundColor(.purple)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.1))
            )

            // Description
            Text(reading.ascendantAnalysis.description)
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textSecondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.cardBackground)
                )

            // Standout stock callout
            if let standout = reading.ascendantAnalysis.standoutStock {
                VStack(alignment: .leading, spacing: 12) {
                    Text("THE CULPRIT")
                        .font(TerminalFont.caption(10, weight: .bold))
                        .foregroundColor(CosmicTheme.textMuted)

                    HStack(spacing: 12) {
                        Text(standout.zodiacSign.symbol)
                            .font(.title)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(standout.symbol)
                                .font(TerminalFont.body(14, weight: .semibold))
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text(reading.ascendantAnalysis.standoutReason)
                                .font(TerminalFont.caption(11))
                                .foregroundColor(CosmicTheme.textSecondary)
                        }

                        Spacer()

                        Text(standout.zodiacSign.displayName)
                            .font(TerminalFont.caption(11))
                            .foregroundColor(standout.zodiacSign.element.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(standout.zodiacSign.element.color.opacity(0.2))
                            )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.cardBackground)
                )
            }

            // The roast
            VStack(alignment: .leading, spacing: 8) {
                Text("THE ROAST")
                    .font(TerminalFont.caption(10, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)

                Text("\"\(reading.ascendantAnalysis.roast)\"")
                    .font(TerminalFont.body(14))
                    .italic()
                    .foregroundColor(CosmicTheme.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Contrast Section

    private var contrastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: reading.contrast.level.icon)
                    .foregroundColor(reading.contrast.level.color)

                Text("\(reading.contrast.level.displayName) Contrast")
                    .font(TerminalFont.body(14, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            Text(reading.contrast.insight)
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textSecondary)

            // Visual comparison
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text(reading.contrast.sunSummary)
                        .font(TerminalFont.caption(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )

                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(CosmicTheme.textMuted)

                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text(reading.contrast.ascendantSummary)
                        .font(TerminalFont.caption(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.1))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    // MARK: - Shareable Section

    private var shareableSection: some View {
        VStack(spacing: 12) {
            Text("SHAREABLE INSIGHT")
                .font(TerminalFont.caption(10, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)

            Text("\"\(reading.shareableQuip)\"")
                .font(TerminalFont.body(14))
                .italic()
                .foregroundColor(CosmicTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Button(action: {
                showingShareSheet = true
                AnalyticsService.shared.track(.portfolioAscendantShared)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share My Duality")
                }
                .font(TerminalFont.body(14, weight: .medium))
                .foregroundColor(.purple)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .stroke(Color.purple, lineWidth: 1)
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(TerminalFont.caption(11, weight: .medium))
            }
            .foregroundColor(isSelected ? color : CosmicTheme.textMuted)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Element Bar

private struct ElementBar: View {
    let element: ZodiacSign.Element
    let percentage: Double
    let isDominant: Bool

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Text(element.emoji)
                    .font(.body)

                Text(element.displayName)
                    .font(TerminalFont.caption(12))
                    .foregroundColor(CosmicTheme.textPrimary)
            }
            .frame(width: 80, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(CosmicTheme.textMuted.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(element.color)
                        .frame(width: geometry.size.width * (percentage / 100), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(String(format: "%.0f", percentage))%")
                .font(TerminalFont.caption(11, weight: isDominant ? .bold : .regular))
                .foregroundColor(isDominant ? element.color : CosmicTheme.textSecondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Compact Badge (for toolbars)

struct PortfolioAscendantBadge: View {
    let ascendantLabel: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "theatermasks.fill")
                .font(.caption2)

            Text(ascendantLabel)
                .font(TerminalFont.caption(10))
        }
        .foregroundColor(.purple)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.purple.opacity(0.15))
        )
    }
}

// MARK: - Previews

#Preview("Ascendant Card") {
    VStack {
        PortfolioAscendantCard(
            holdings: Stock.ownedSamples,
            userSign: .leo
        )
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Ascendant Sheet") {
    let reading = PortfolioAscendantService.shared.analyzePortfolio(
        holdings: Stock.ownedSamples,
        userSign: .leo
    )
    return PortfolioAscendantSheet(reading: reading)
        .preferredColorScheme(.dark)
}
