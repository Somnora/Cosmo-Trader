import SwiftUI

// MARK: - CosmicBalanceCard
// ==========================
// A card showing the elemental breakdown of the portfolio:
// - Horizontal bar chart showing Fire/Earth/Air/Water percentages
// - Each element has its emoji, color, and percentage
// - A one-line insight about the portfolio's cosmic energy
//
// DESIGN PHILOSOPHY:
// - Visual representation of abstract concept (elemental balance)
// - Color-coded segments make it easy to scan
// - The insight adds personality and engagement

struct CosmicBalanceCard: View {

    // MARK: - Properties

    /// The breakdown of portfolio by element
    let breakdown: [ElementBreakdown]

    /// One-line insight about the elemental balance
    let insight: String

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection

            // Element bar chart
            elementBar

            // Element legend
            elementLegend

            // Insight text
            insightSection
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - Subviews

    /// Card header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cosmic Balance")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Portfolio by element")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            // Sparkle icon
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(CosmicTheme.goldGradient)
        }
    }

    /// Horizontal stacked bar showing element proportions
    private var elementBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(breakdown) { item in
                    if item.percentage > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForElement(item.element))
                            .frame(width: max(
                                geometry.size.width * CGFloat(item.percentage / 100) - 2,
                                0
                            ))
                    }
                }
            }
        }
        .frame(height: 24)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.secondaryBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// Legend showing each element with emoji and percentage
    private var elementLegend: some View {
        HStack(spacing: 0) {
            ForEach(ZodiacSign.Element.allCases, id: \.self) { element in
                let item = breakdown.first { $0.element == element }
                let percentage = item?.percentage ?? 0

                elementLegendItem(element: element, percentage: percentage)

                if element != ZodiacSign.Element.allCases.last {
                    Spacer()
                }
            }
        }
    }

    /// Single legend item for an element
    private func elementLegendItem(element: ZodiacSign.Element, percentage: Double) -> some View {
        HStack(spacing: 6) {
            // Element glyph
            ElementSymbolView(element: element, size: 12)

            // Percentage
            Text(String(format: "%.0f%%", percentage))
                .font(TerminalFont.data(11))
                .fontWeight(.medium)
                .foregroundColor(percentage > 0 ? CosmicTheme.textPrimary : CosmicTheme.textMuted)
        }
    }

    /// One-line insight about the balance
    private var insightSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.caption)
                .foregroundColor(CosmicTheme.gold.opacity(0.6))

            Text(insight)
                .font(.subheadline)
                .italic()
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    /// Card background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(CosmicTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(CosmicTheme.cosmicPurple.opacity(0.2), lineWidth: 1)
            )
    }

    // MARK: - Helpers

    /// Get color for each element
    private func colorForElement(_ element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire:  return Color(red: 1.0, green: 0.4, blue: 0.3)   // Warm red-orange
        case .earth: return Color(red: 0.4, green: 0.75, blue: 0.4)  // Natural green
        case .air:   return Color(red: 0.95, green: 0.85, blue: 0.4) // Soft yellow
        case .water: return Color(red: 0.3, green: 0.6, blue: 0.9)   // Ocean blue
        }
    }
}

// MARK: - Font Style Extension

extension View {
    /// Apply italic style to text
    func fontStyle(_ style: Font.TextStyle) -> some View {
        self.italic()
    }
}

// MARK: - Preview

#Preview("Cosmic Balance - Mixed") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        CosmicBalanceCard(
            breakdown: [
                ElementBreakdown(element: .water, percentage: 35, value: 15000),
                ElementBreakdown(element: .fire, percentage: 28, value: 12000),
                ElementBreakdown(element: .earth, percentage: 22, value: 9500),
                ElementBreakdown(element: .air, percentage: 15, value: 6500)
            ],
            insight: "Water flows through your portfolio — intuitive balance of risk and reward."
        )
        .padding()
    }
}

#Preview("Cosmic Balance - Fire Heavy") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        CosmicBalanceCard(
            breakdown: [
                ElementBreakdown(element: .fire, percentage: 65, value: 28000),
                ElementBreakdown(element: .earth, percentage: 20, value: 8600),
                ElementBreakdown(element: .air, percentage: 10, value: 4300),
                ElementBreakdown(element: .water, percentage: 5, value: 2150)
            ],
            insight: "Heavy in Fire energy — high growth potential, high volatility. Bold moves ahead."
        )
        .padding()
    }
}

#Preview("Cosmic Balance - Balanced") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        CosmicBalanceCard(
            breakdown: [
                ElementBreakdown(element: .earth, percentage: 28, value: 12000),
                ElementBreakdown(element: .water, percentage: 26, value: 11000),
                ElementBreakdown(element: .fire, percentage: 24, value: 10000),
                ElementBreakdown(element: .air, percentage: 22, value: 9000)
            ],
            insight: "Elementally balanced — you're diversified across cosmic energies. The universe approves."
        )
        .padding()
    }
}
