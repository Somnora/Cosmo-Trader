import SwiftUI

/// CosmicTheme
/// -----------
/// This struct holds all our app's colors in one place.
/// Why? So if we want to change a color, we only change it HERE,
/// and it updates everywhere in the app automatically.

struct CosmicTheme {

    // MARK: - Background Colors

    /// The main background - a deep space purple/blue
    static let background = Color(red: 0.05, green: 0.02, blue: 0.15)

    /// Slightly lighter background for cards and sections
    static let cardBackground = Color(red: 0.10, green: 0.05, blue: 0.22)

    /// Even lighter for hover states or secondary cards
    static let secondaryBackground = Color(red: 0.15, green: 0.08, blue: 0.28)

    // MARK: - Accent Colors

    /// Gold accent for important elements (like profits, stars)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)

    /// Softer gold for less prominent accents
    static let softGold = Color(red: 0.85, green: 0.70, blue: 0.30)

    /// Cosmic purple for gradients and highlights
    static let cosmicPurple = Color(red: 0.55, green: 0.20, blue: 0.80)

    /// Nebula blue for variety in gradients
    static let nebulaBlue = Color(red: 0.20, green: 0.30, blue: 0.80)

    // MARK: - Text Colors

    /// Primary text - bright white for readability
    static let textPrimary = Color.white

    /// Secondary text - dimmed for less important info
    static let textSecondary = Color(white: 0.7)

    /// Muted text - for hints and placeholders
    static let textMuted = Color(white: 0.5)

    // MARK: - Status Colors

    /// Green for positive changes (stock going up!)
    static let positive = Color(red: 0.20, green: 0.85, blue: 0.50)

    /// Red for negative changes (stock going down)
    static let negative = Color(red: 0.95, green: 0.30, blue: 0.35)

    // MARK: - Gradients

    /// A beautiful cosmic gradient for headers and special elements
    static let cosmicGradient = LinearGradient(
        colors: [cosmicPurple, nebulaBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gold gradient for premium/highlighted elements
    static let goldGradient = LinearGradient(
        colors: [gold, softGold],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Preview Helper

/// This extension lets us preview our colors in Xcode
#Preview("Color Theme") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Cosmic Theme Colors")
                .font(.title)
                .foregroundColor(CosmicTheme.textPrimary)

            HStack(spacing: 10) {
                colorSwatch("Background", CosmicTheme.background)
                colorSwatch("Card BG", CosmicTheme.cardBackground)
                colorSwatch("Secondary", CosmicTheme.secondaryBackground)
            }

            HStack(spacing: 10) {
                colorSwatch("Gold", CosmicTheme.gold)
                colorSwatch("Purple", CosmicTheme.cosmicPurple)
                colorSwatch("Blue", CosmicTheme.nebulaBlue)
            }

            HStack(spacing: 10) {
                colorSwatch("Positive", CosmicTheme.positive)
                colorSwatch("Negative", CosmicTheme.negative)
            }
        }
        .padding()
    }
    .background(CosmicTheme.background)
}

private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 80, height: 60)
        Text(name)
            .font(.caption)
            .foregroundColor(CosmicTheme.textSecondary)
    }
}
