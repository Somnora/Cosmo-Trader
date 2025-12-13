import SwiftUI

// MARK: - CosmicRoastView
// =======================
// Renders "The Cosmic Roast" as a shareable Instagram Stories image.
// Formatted like an official bank statement or audit report.
//
// Design:
// - Black background, white/gold text
// - Monospace font throughout
// - Thin borders, sharp corners
// - Instagram Stories format: 1080x1920

struct CosmicRoastView: View {

    let roast: CosmicRoast

    // Instagram Stories aspect ratio
    private let storyWidth: CGFloat = 1080
    private let storyHeight: CGFloat = 1920

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Thin divider
            terminalDivider

            // Performance Summary
            performanceSummarySection

            // Thin divider
            terminalDivider

            // Sector Analysis
            sectorAnalysisSection

            // Thin divider
            terminalDivider

            // The Roast
            roastSection

            // Thin divider
            terminalDivider

            // Worst Performer (if exists)
            if roast.weakestLink != nil {
                weakestLinkSection
                terminalDivider
            }

            // Recommendation
            recommendationSection

            Spacer(minLength: 20)

            // Footer
            footerSection
        }
        .padding(24)
        .frame(width: storyWidth, height: storyHeight)
        .background(Color.black)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Top corner decorations
            HStack {
                Text("┌")
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold.opacity(0.5))

                Spacer()

                Text("┐")
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold.opacity(0.5))
            }

            // Main title
            VStack(spacing: 8) {
                Text(roast.reportTitle)
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(4)

                HStack(spacing: 8) {
                    Text("Generated: \(roast.formattedDate)")
                    Text("|")
                    Text("Auditor: \(roast.auditorName)")
                }
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.vertical, 20)
        }
    }

    // MARK: - Performance Summary

    private var performanceSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("PERFORMANCE SUMMARY")

            VStack(spacing: 12) {
                // Portfolio Value
                HStack {
                    Text("Portfolio Value:")
                        .foregroundColor(CosmicTheme.textSecondary)
                    Spacer()
                    Text(roast.formattedPortfolioValue)
                        .foregroundColor(.white)
                }
                .font(.system(size: 22, weight: .medium, design: .monospaced))

                // YTD Return
                HStack {
                    Text("YTD Return:")
                        .foregroundColor(CosmicTheme.textSecondary)
                    Spacer()
                    Text(roast.formattedYTDReturn)
                        .foregroundColor(roast.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                }
                .font(.system(size: 22, weight: .medium, design: .monospaced))

                // Cosmic Assessment
                HStack(alignment: .top) {
                    Text("Cosmic Assessment:")
                        .foregroundColor(CosmicTheme.textSecondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: roast.assessmentIcon)
                                .foregroundColor(CosmicTheme.gold)
                            Text(roast.cosmicAssessment)
                                .foregroundColor(CosmicTheme.gold)
                        }
                    }
                }
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
            }
            .padding(20)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Sector Analysis

    private var sectorAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("SECTOR ANALYSIS")

            VStack(spacing: 8) {
                ForEach(roast.sectorBreakdown) { sector in
                    HStack {
                        // Element symbol
                        ElementSymbolView(element: sector.element, size: 18)

                        Text("\(sector.sectorName):")
                            .foregroundColor(CosmicTheme.textSecondary)

                        Text(sector.formattedPercentage)
                            .foregroundColor(.white)
                            .fontWeight(.bold)

                        Spacer()

                        Text("(\(sector.status.rawValue))")
                            .foregroundColor(sector.status.color)
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 18, design: .monospaced))
                }
            }
            .padding(16)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 1)
            )

            // Sector Diagnosis
            Text("Diagnosis: \(roast.sectorDiagnosis)")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)
                .italic()
                .padding(.horizontal, 8)
        }
    }

    // MARK: - The Roast

    private var roastSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(roast.roastTitle, icon: "flame.fill", iconColor: CosmicTheme.negative)

            Text(roast.roastContent)
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(6)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    Rectangle()
                        .stroke(CosmicTheme.gold.opacity(0.5), lineWidth: 2)
                )
        }
    }

    // MARK: - Weakest Link

    private var weakestLinkSection: some View {
        Group {
            if let weakest = roast.weakestLink {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("WEAKEST LINK", icon: "arrow.down.circle.fill", iconColor: CosmicTheme.negative)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Zodiac glyph
                            ZodiacSymbolView(sign: weakest.zodiacSign, size: 24, color: CosmicTheme.negative)

                            Text("\(weakest.symbol)")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)

                            Text("(\(weakest.formattedChange))")
                                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                                .foregroundColor(CosmicTheme.negative)
                        }

                        Text(weakest.name)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(CosmicTheme.textSecondary)

                        Text("Note: \(weakest.roastNote)")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(CosmicTheme.textMuted)
                            .italic()
                    }
                    .padding(16)
                    .overlay(
                        Rectangle()
                            .stroke(CosmicTheme.negative.opacity(0.5), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Recommendation

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("RECOMMENDATION", icon: "lightbulb.fill", iconColor: CosmicTheme.gold)

            VStack(alignment: .leading, spacing: 8) {
                Text(roast.recommendation)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)

                Text(roast.recommendationSubtext)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(CosmicTheme.textMuted)
                    .italic()
            }
            .padding(16)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 16) {
            // Disclaimer
            Text(roast.disclaimer)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(CosmicTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Watermark
            HStack {
                Spacer()
                Text("cosmotrade.app")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold.opacity(0.6))
            }

            // Bottom corner decorations
            HStack {
                Text("└")
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold.opacity(0.5))

                Spacer()

                Text("┘")
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold.opacity(0.5))
            }
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, icon: String? = nil, iconColor: Color = CosmicTheme.gold) -> some View {
        HStack(spacing: 8) {
            // Leading decoration
            Rectangle()
                .fill(CosmicTheme.gold)
                .frame(width: 4, height: 20)

            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(CosmicTheme.gold)
                .tracking(2)

            // Trailing line
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)
        }
    }

    private var terminalDivider: some View {
        Rectangle()
            .fill(CosmicTheme.border.opacity(0.5))
            .frame(height: 1)
            .padding(.vertical, 16)
    }
}

// MARK: - Preview Modal Container

struct CosmicRoastPreviewSheet: View {

    let user: UserProfile
    @State private var roast: CosmicRoast?
    @State private var isGenerating = false
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss

    private let subscriptionManager = SubscriptionManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background.ignoresSafeArea()

                if let roast = roast {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Scaled down preview
                            CosmicRoastView(roast: roast)
                                .scaleEffect(0.35)
                                .frame(width: 1080 * 0.35, height: 1920 * 0.35)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(CosmicTheme.border, lineWidth: 1)
                                )

                            // Show remaining roasts for free users
                            if !subscriptionManager.isPremium {
                                roastLimitBanner
                            }
                        }
                        .padding()
                    }
                } else if isGenerating {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(CosmicTheme.gold)
                            .scaleEffect(1.5)

                        Text("The cosmos is judging you...")
                            .font(TerminalFont.data(14))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                } else {
                    readyToRoastView
                }
            }
            .navigationTitle("The Cosmic Roast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    if roast != nil {
                        Button(action: shareRoast) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .foregroundColor(CosmicTheme.gold)
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    if roast == nil {
                        generateButton
                    } else {
                        newRoastButton
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Ready to Roast View

    private var readyToRoastView: some View {
        VStack(spacing: 24) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundColor(CosmicTheme.negative)

            Text("Ready to be roasted")
                .font(TerminalFont.headline(18))
                .foregroundColor(CosmicTheme.textPrimary)

            if !subscriptionManager.isPremium {
                let remaining = subscriptionManager.roastsRemainingToday()
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("\(remaining)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(remaining > 0 ? CosmicTheme.gold : CosmicTheme.alertRed)

                        Text("/ \(subscriptionManager.freeRoastLimit)")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }

                    Text("roasts remaining today")
                        .font(TerminalFont.data(12))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Roast Limit Banner

    private var roastLimitBanner: some View {
        let remaining = subscriptionManager.roastsRemainingToday()

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(remaining) roast\(remaining == 1 ? "" : "s") remaining today")
                    .font(TerminalFont.data(11, weight: .medium))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Unlimited roasts with Oracle Tier")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()

            Button {
                showPaywall = true
            } label: {
                OracleBadge(style: .compact)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(CosmicTheme.borderDim, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        let canGenerate = subscriptionManager.canGenerateRoast()

        return Group {
            if canGenerate {
                Button(action: generateRoast) {
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("Generate Roast")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(CosmicTheme.gold)
                    .clipShape(Capsule())
                }
                .disabled(isGenerating)
            } else {
                Button(action: { showPaywall = true }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Upgrade for More")
                    }
                    .font(.headline)
                    .foregroundColor(CosmicTheme.gold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .strokeBorder(CosmicTheme.gold, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - New Roast Button

    private var newRoastButton: some View {
        let canGenerate = subscriptionManager.canGenerateRoast()

        return Group {
            if canGenerate {
                Button(action: generateRoast) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("New Roast")
                    }
                    .font(.headline)
                    .foregroundColor(CosmicTheme.gold)
                }
            } else {
                Button(action: { showPaywall = true }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Upgrade for More")
                    }
                    .font(TerminalFont.data(12, weight: .medium))
                    .foregroundColor(CosmicTheme.gold)
                }
            }
        }
    }

    private func generateRoast() {
        guard subscriptionManager.canGenerateRoast() else {
            showPaywall = true
            AnalyticsService.shared.trackPaywallViewed(source: "cosmic_roast")
            return
        }

        isGenerating = true
        roast = nil

        // Simulate generation delay for dramatic effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            roast = CosmicRoastGenerator.generate(for: user)
            subscriptionManager.recordRoastGeneration()
            isGenerating = false

            // Track roast generated
            AnalyticsService.shared.trackRoastGenerated(forSign: user.sunSign.displayName)
        }
    }

    private func shareRoast() {
        guard let roast = roast else { return }

        // Track roast shared
        AnalyticsService.shared.trackRoastShared(forSign: user.sunSign.displayName)

        // Render to image
        let renderer = ImageRenderer(content: CosmicRoastView(roast: roast))
        renderer.scale = 3 // High resolution

        if let image = renderer.uiImage {
            let activityVC = UIActivityViewController(
                activityItems: [image],
                applicationActivities: nil
            )

            // Present share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
}

// MARK: - Compact Roast Card (for inline display)

struct CosmicRoastCard: View {

    let user: UserProfile
    @State private var showRoastSheet = false

    var body: some View {
        Button(action: { showRoastSheet = true }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(CosmicTheme.negative.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(CosmicTheme.negative)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("THE COSMIC ROAST")
                        .font(TerminalFont.data(12, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(1)

                    Text("Get roasted by the universe")
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(16)
            .background(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.negative.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showRoastSheet) {
            CosmicRoastPreviewSheet(user: user)
        }
    }
}

// MARK: - Preview

#Preview("Cosmic Roast View") {
    let mockUser = UserProfile(
        displayName: "Test User",
        email: "test@example.com",
        birthMonth: 8,
        birthDay: 15,
        birthYear: 1990,
        portfolio: {
            var stocks = MockStockData.featured
            for i in stocks.indices {
                stocks[i].sharesOwned = Double.random(in: 5...50)
            }
            return Array(stocks.prefix(5))
        }()
    )

    let roast = CosmicRoastGenerator.generate(for: mockUser)

    ScrollView {
        CosmicRoastView(roast: roast)
            .scaleEffect(0.4)
            .frame(width: 1080 * 0.4, height: 1920 * 0.4)
    }
    .background(Color.gray)
}

#Preview("Roast Preview Sheet") {
    let mockUser = UserProfile(
        displayName: "Test User",
        email: "test@example.com",
        birthMonth: 8,
        birthDay: 15,
        birthYear: 1990,
        portfolio: {
            var stocks = MockStockData.featured
            for i in stocks.indices {
                stocks[i].sharesOwned = Double.random(in: 5...50)
            }
            return Array(stocks.prefix(5))
        }()
    )

    CosmicRoastPreviewSheet(user: mockUser)
}

#Preview("Roast Card") {
    let mockUser = UserProfile(
        displayName: "Test User",
        email: "test@example.com",
        birthMonth: 8,
        birthDay: 15,
        birthYear: 1990,
        portfolio: []
    )

    VStack(spacing: 16) {
        CosmicRoastCard(user: mockUser)
    }
    .padding()
    .background(CosmicTheme.background)
}
