import SwiftUI

// MARK: - Sign Stack Views
// ========================
// Shareable "trading card" showing user's cosmic investing profile.
// Perfect for Twitter/Instagram sharing.
//
// WHY IT WORKS: Social proof. Viral potential. User identity expression.

// MARK: - Sign Stack Card (Main Shareable View)

struct SignStackCard: View {
    let stackData: SignStackData
    let showShareButton: Bool

    @State private var showShareSheet: Bool = false

    init(stackData: SignStackData, showShareButton: Bool = true) {
        self.stackData = stackData
        self.showShareButton = showShareButton
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with user sign
            cardHeader

            // Divider line
            Rectangle()
                .fill(CosmicTheme.gold.opacity(0.3))
                .frame(height: 1)

            // Main content
            VStack(spacing: 16) {
                // Cosmic title
                cosmicTitleSection

                // Top holdings
                if !stackData.topHoldings.isEmpty {
                    topHoldingsSection
                }

                // Element breakdown
                elementBreakdownSection

                // Investing style quote
                investingStyleSection
            }
            .padding(20)

            // Footer
            cardFooter
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [CosmicTheme.gold, CosmicTheme.gold.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: CosmicTheme.gold.opacity(0.2), radius: 20, x: 0, y: 10)
    }

    // MARK: - Card Header

    private var cardHeader: some View {
        HStack(spacing: 12) {
            // Large zodiac symbol
            ZStack {
                Circle()
                    .fill(stackData.userSign.element.color.opacity(0.2))
                    .frame(width: 56, height: 56)

                ZodiacMark(sign: stackData.userSign, size: 32, style: .element)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(stackData.displayName)
                    .font(TerminalFont.headline(18))
                    .foregroundColor(CosmicTheme.textPrimary)

                HStack(spacing: 6) {
                    Text(stackData.userSign.displayName)
                        .font(TerminalFont.body(14, weight: .medium))
                        .foregroundColor(stackData.userSign.element.color)

                    Text("•")
                        .foregroundColor(CosmicTheme.textMuted)

                    Text("\(stackData.holdingsCount) positions")
                        .font(TerminalFont.caption(12))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }

            Spacer()

            // Sign Stack badge
            VStack(spacing: 2) {
                Text("SIGN")
                    .font(TerminalFont.caption(8, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                Text("STACK")
                    .font(TerminalFont.caption(8, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.gold, lineWidth: 1)
            )
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    stackData.userSign.element.color.opacity(0.15),
                    CosmicTheme.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Cosmic Title Section

    private var cosmicTitleSection: some View {
        VStack(spacing: 8) {
            Text(stackData.cosmicTitle)
                .font(TerminalFont.headline(20))
                .foregroundColor(CosmicTheme.gold)
                .multilineTextAlignment(.center)

            // Decorative stars
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(CosmicTheme.gold.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Top Holdings Section

    private var topHoldingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TOP HOLDINGS")
                .font(TerminalFont.caption(10, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            VStack(spacing: 8) {
                ForEach(Array(stackData.topHoldings.enumerated()), id: \.element.id) { index, holding in
                    HStack(spacing: 12) {
                        // Rank badge
                        Text("\(index + 1)")
                            .font(TerminalFont.caption(10, weight: .bold))
                            .foregroundColor(CosmicTheme.background)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(CosmicTheme.gold))

                        // Stock info
                        HStack(spacing: 6) {
                            Text(holding.symbol)
                                .font(TerminalFont.body(14, weight: .bold))
                                .foregroundColor(CosmicTheme.textPrimary)

                            ZodiacMark(sign: holding.sign, size: 14, style: .element)
                        }

                        Spacer()

                        // Performance
                        Text(holding.formattedChange)
                            .font(TerminalFont.data(12))
                            .foregroundColor(holding.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(CosmicTheme.background.opacity(0.5))
            )
        }
    }

    // MARK: - Element Breakdown Section

    private var elementBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ELEMENT MIX")
                .font(TerminalFont.caption(10, weight: .bold))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(stackData.elementBreakdown) { element in
                    elementBar(element)
                }
            }
        }
    }

    private func elementBar(_ element: SignStackElement) -> some View {
        VStack(spacing: 4) {
            // Percentage
            Text(element.formattedPercentage)
                .font(TerminalFont.data(10))
                .foregroundColor(element.percentage > 0 ? CosmicTheme.textPrimary : CosmicTheme.textMuted)

            // Bar
            RoundedRectangle(cornerRadius: 2)
                .fill(element.element.color.opacity(element.percentage > 0 ? 1 : 0.2))
                .frame(height: max(4, CGFloat(element.percentage) * 0.4))
                .frame(maxHeight: 40)

            // Element icon
            Image(systemName: element.element.sfSymbol)
                .font(.system(size: 14))
                .foregroundColor(element.element.color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Investing Style Section

    private var investingStyleSection: some View {
        VStack(spacing: 8) {
            Text("\"")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(CosmicTheme.gold.opacity(0.5))

            Text(stackData.investingStyle)
                .font(TerminalFont.body(14, weight: .medium))
                .foregroundColor(CosmicTheme.textPrimary)
                .multilineTextAlignment(.center)
                .italic()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Card Footer

    private var cardFooter: some View {
        HStack {
            // App branding
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.gold)

                Text("Cosmo Trader")
                    .font(TerminalFont.caption(10, weight: .medium))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            // Date
            Text(stackData.formattedDate)
                .font(TerminalFont.caption(10))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CosmicTheme.background.opacity(0.5))
    }
}

// MARK: - Sign Stack Preview Card (Compact Version)

struct SignStackPreviewCard: View {
    let stackData: SignStackData
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // User sign
                ZStack {
                    Circle()
                        .fill(stackData.userSign.element.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    ZodiacMark(sign: stackData.userSign, size: 24, style: .element)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Sign Stack")
                        .font(TerminalFont.body(14, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("\"\(stackData.cosmicTitle)\"")
                        .font(TerminalFont.caption(12))
                        .foregroundColor(CosmicTheme.gold)
                        .lineLimit(1)
                }

                Spacer()

                // Share icon
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                    .foregroundColor(CosmicTheme.gold)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sign Stack Sheet

struct SignStackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var stackData: SignStackData?
    @State private var showShareSheet: Bool = false
    @State private var cardImage: UIImage?

    private let service = SignStackService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let data = stackData {
                        // The shareable card
                        SignStackCard(stackData: data, showShareButton: false)
                            .padding(.horizontal, 20)
                            .background(
                                GeometryReader { _ in
                                    Color.clear
                                        .onAppear {
                                            // Capture card for sharing
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                captureCard(data: data)
                                            }
                                        }
                                }
                            )

                        // Share buttons
                        shareButtonsSection(data: data)

                        // Regenerate hint
                        Text("Your Sign Stack updates as your portfolio changes")
                            .font(TerminalFont.caption(11))
                            .foregroundColor(CosmicTheme.textMuted)
                            .multilineTextAlignment(.center)
                    } else {
                        // Loading or empty state
                        emptyStateView
                    }
                }
                .padding(.vertical, 20)
            }
            .background(CosmicTheme.background)
            .navigationTitle("Sign Stack")
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
        .onAppear {
            generateStack()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = cardImage, let data = stackData {
                ShareSheet(items: [image, service.generateShareText(for: data)])
            }
        }
    }

    private func generateStack() {
        guard let user = appState.currentUser else { return }
        stackData = service.generateSignStack(for: user)
        AnalyticsService.shared.track(.signStackGenerated)
    }

    @MainActor
    private func captureCard(data: SignStackData) {
        let cardView = SignStackCard(stackData: data, showShareButton: false)
            .frame(width: 340)
            .padding(20)
            .background(CosmicTheme.background)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3.0 // High resolution
        cardImage = renderer.uiImage
    }

    private func shareButtonsSection(data: SignStackData) -> some View {
        VStack(spacing: 12) {
            // Main share button
            Button(action: {
                showShareSheet = true
                AnalyticsService.shared.track(.signStackShared)
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Share Your Sign Stack")
                        .font(TerminalFont.body(14, weight: .semibold))
                }
                .foregroundColor(CosmicTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.gold)
                )
            }
            .buttonStyle(.plain)

            // Copy text button
            Button(action: {
                UIPasteboard.general.string = service.generateShareText(for: data)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)

                    Text("Copy Text")
                        .font(TerminalFont.caption(12))
                }
                .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(CosmicTheme.gold.opacity(0.5))

            Text("Add holdings to generate your Sign Stack")
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Sign Stack Button (For Profile View)

struct SignStackButton: View {
    @Environment(AppState.self) private var appState
    @State private var showSheet: Bool = false
    @State private var previewData: SignStackData?

    private let service = SignStackService.shared

    var body: some View {
        VStack(spacing: 12) {
            if let data = previewData {
                SignStackPreviewCard(stackData: data) {
                    showSheet = true
                }
            } else {
                // Placeholder button
                Button(action: { showSheet = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 20))
                            .foregroundColor(CosmicTheme.gold)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share Your Sign Stack")
                                .font(TerminalFont.body(14, weight: .semibold))
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text("Create a shareable trading card")
                                .font(TerminalFont.caption(11))
                                .foregroundColor(CosmicTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(CosmicTheme.cardBackground)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            updatePreview()
        }
        .sheet(isPresented: $showSheet) {
            SignStackSheet()
        }
    }

    private func updatePreview() {
        guard let user = appState.currentUser else { return }
        let holdings = user.portfolio.filter { $0.sharesOwned > 0 }
        if !holdings.isEmpty {
            previewData = service.generateSignStack(for: user)
        }
    }
}

// MARK: - Previews

#Preview("Sign Stack Card") {
    ScrollView {
        SignStackCard(
            stackData: SignStackData(
                userSign: .sagittarius,
                displayName: "Cosmic Trader",
                topHoldings: MockStockData.all.prefix(3).map { SignStackHolding(stock: $0) },
                elementBreakdown: [
                    SignStackElement(element: .fire, percentage: 45, value: 4500),
                    SignStackElement(element: .earth, percentage: 25, value: 2500),
                    SignStackElement(element: .air, percentage: 20, value: 2000),
                    SignStackElement(element: .water, percentage: 10, value: 1000)
                ],
                investingStyle: "Global exposure, no borders. Chasing growth.",
                cosmicTitle: "The Visionary Trader",
                totalValue: 10000,
                holdingsCount: 8,
                generatedDate: Date()
            )
        )
        .padding(20)
    }
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Sign Stack Sheet") {
    SignStackSheet()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}

#Preview("Sign Stack Button") {
    VStack {
        SignStackButton()
    }
    .padding()
    .background(CosmicTheme.background)
    .environment(AppState.preview)
    .preferredColorScheme(.dark)
}
