import SwiftUI

// MARK: - CosmosView
// ===================
// The Cosmos tab - personalized daily portfolio horoscopes.
//
// STRUCTURE:
// 1. Date header with moon phase icon
// 2. Horoscope reading card (personalized based on portfolio)
// 3. Current Cosmic Weather section
// 4. Refresh button to generate new reading
//
// DESIGN PHILOSOPHY:
// - Mystical and immersive atmosphere
// - Personal connection through user's actual holdings
// - Co-Star inspired voice: witty, direct, cosmic wisdom

struct CosmosView: View {

    // MARK: - Properties

    @State private var viewModel = HoroscopeViewModel()

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

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // 1. Date header with moon phase
                        dateHeader

                        // 2. Main horoscope card
                        horoscopeCard

                        // 3. Cosmic Weather section
                        cosmicWeatherSection

                        // 4. Regenerate button
                        regenerateButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
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
                    Text(viewModel.moonPhase.emoji)
                        .font(.title2)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            animateAppearance()
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

            // User sign badge
            HStack(spacing: 6) {
                Text(viewModel.user.sunSign.symbol)
                    .font(.title3)

                Text(viewModel.user.sunSign.displayName)
                    .font(.subheadline)
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

                        Text(viewModel.performanceSentiment)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.performanceColor)

                        Text(viewModel.overallChangePercent)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.performanceColor)
                    }
                }

                Spacer()

                // Large zodiac symbol
                ZStack {
                    Circle()
                        .fill(CosmicTheme.gold.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Text(viewModel.user.sunSign.symbol)
                        .font(.system(size: 36))
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

            Text("Consulting the stars...")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)
                .italic()
        }
        .frame(maxWidth: .infinity, minHeight: 60)
    }

    private func dominantElementBadge(_ element: ZodiacSign.Element) -> some View {
        HStack(spacing: 8) {
            Text(element.emoji)
                .font(.caption)

            Text("\(element.displayName) Energy Dominant")
                .font(.caption)
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

                // Energy indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(energyColor)
                        .frame(width: 8, height: 8)

                    Text(viewModel.cosmicWeather.overallEnergy.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }

            // Weather advice
            Text(viewModel.cosmicWeather.advice)
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)
                .italic()

            // Planetary events
            VStack(spacing: 12) {
                ForEach(viewModel.planetaryEvents) { event in
                    planetaryEventRow(event)
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

    private func planetaryEventRow(_ event: PlanetaryEvent) -> some View {
        HStack(spacing: 12) {
            // Event icon
            ZStack {
                Circle()
                    .fill(eventTypeColor(event.type).opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: event.type.icon)
                    .font(.caption)
                    .foregroundColor(eventTypeColor(event.type))
            }

            // Event info
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(event.description)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Regenerate Button

    private var regenerateButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4)) {
                viewModel.regenerateHoroscope()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.headline)
                    .rotationEffect(.degrees(viewModel.refreshTrigger ? 360 : 0))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.refreshTrigger)

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
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
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

    private var energyColor: Color {
        switch viewModel.cosmicWeather.overallEnergy {
        case .intense: return .red
        case .active: return .orange
        case .balanced: return .green
        case .calm: return .blue
        case .turbulent: return .purple
        }
    }

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

// MARK: - Stars Overlay

/// Animated starfield background effect
struct StarsOverlay: View {

    @State private var twinkle: Bool = false

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
                    with: .color(Color.white.opacity(brightness * (twinkle ? 0.8 : 1.0)))
                )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                twinkle = true
            }
        }
    }

    /// Simple pseudo-random number generator for deterministic stars
    private func pseudoRandom(seed: Int) -> CGFloat {
        let x = sin(Double(seed) * 12.9898) * 43758.5453
        return CGFloat(x - floor(x))
    }
}

// MARK: - Preview

#Preview("Cosmos View") {
    CosmosView()
        .preferredColorScheme(.dark)
}

#Preview("Cosmos View - Loading") {
    let view = CosmosView()
    return view
        .preferredColorScheme(.dark)
}
