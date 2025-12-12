import SwiftUI

/// TerminalBackground
/// -----------------
/// A subtle star field background that evokes a planetarium without
/// being cartoonish. Sparse, barely visible dots on deep black.
///
/// Design Philosophy:
/// - Less is more - only a few dozen stars visible
/// - Very low opacity (0.1-0.3) for subtlety
/// - Random but deterministic positioning (seeded)
/// - Optional grid lines for chart backgrounds

// MARK: - Star Field Background

struct TerminalBackground: View {

    /// Number of stars to render
    var starCount: Int = 40

    /// Whether to show subtle grid lines
    var showGrid: Bool = false

    /// Grid spacing in points
    var gridSpacing: CGFloat = 40

    /// Seed for deterministic star positions
    var seed: Int = 42

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep black base
                CosmicTheme.background

                // Subtle gradient overlay (barely perceptible)
                LinearGradient(
                    colors: [
                        Color(hex: "0A0A0A"),
                        CosmicTheme.background,
                        Color(hex: "0F0F10")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.5)

                // Optional grid lines
                if showGrid {
                    GridPattern(spacing: gridSpacing)
                }

                // Star field
                StarField(
                    count: starCount,
                    size: geometry.size,
                    seed: seed
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Star Field

struct StarField: View {
    let count: Int
    let size: CGSize
    let seed: Int

    var body: some View {
        Canvas { context, _ in
            // Use seeded random for consistent star positions
            var random = SeededRandomNumberGenerator(seed: seed)

            for _ in 0..<count {
                let x = CGFloat.random(in: 0..<size.width, using: &random)
                let y = CGFloat.random(in: 0..<size.height, using: &random)
                let starSize = CGFloat.random(in: 0.5...1.5, using: &random)
                let opacity = Double.random(in: 0.08...0.25, using: &random)

                // Vary star color slightly (mostly white, some with hints of blue/gold)
                let colorVariant = Int.random(in: 0..<10, using: &random)
                let starColor: Color
                switch colorVariant {
                case 0:
                    starColor = CosmicTheme.gold.opacity(opacity * 1.5)
                case 1:
                    starColor = CosmicTheme.accentBlue.opacity(opacity * 1.2)
                default:
                    starColor = Color.white.opacity(opacity)
                }

                let rect = CGRect(
                    x: x - starSize / 2,
                    y: y - starSize / 2,
                    width: starSize,
                    height: starSize
                )

                context.fill(
                    Circle().path(in: rect),
                    with: .color(starColor)
                )
            }
        }
    }
}

// MARK: - Grid Pattern

struct GridPattern: View {
    let spacing: CGFloat
    let lineColor: Color = CosmicTheme.gridLine
    let lineWidth: CGFloat = 0.5

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Vertical lines
                var x: CGFloat = spacing
                while x < size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(
                        path,
                        with: .color(lineColor),
                        lineWidth: lineWidth
                    )
                    x += spacing
                }

                // Horizontal lines
                var y: CGFloat = spacing
                while y < size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(
                        path,
                        with: .color(lineColor),
                        lineWidth: lineWidth
                    )
                    y += spacing
                }
            }
        }
    }
}

// MARK: - Seeded Random Number Generator

/// A deterministic random number generator for consistent star positions
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(truncatingIfNeeded: seed)
    }

    mutating func next() -> UInt64 {
        // Simple xorshift64 algorithm
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - View Extensions

extension View {
    /// Apply terminal background with subtle star field
    func terminalBackground(stars: Int = 40, showGrid: Bool = false) -> some View {
        self.background(
            TerminalBackground(starCount: stars, showGrid: showGrid)
        )
    }

    /// Apply chart background with grid lines
    func chartBackground(gridSpacing: CGFloat = 40) -> some View {
        self.background(
            TerminalBackground(starCount: 20, showGrid: true, gridSpacing: gridSpacing)
        )
    }
}

// MARK: - Preview

#Preview("Terminal Background") {
    VStack(spacing: 20) {
        Text("TERMINAL BACKGROUND")
            .font(TerminalFont.headline(24))
            .foregroundColor(CosmicTheme.textPrimary)

        Text("Subtle star field, not cartoonish")
            .font(TerminalFont.data(14))
            .foregroundColor(CosmicTheme.textMuted)

        Spacer()

        // Sample data card
        VStack(alignment: .leading, spacing: 8) {
            Text("AAPL")
                .font(TerminalFont.data(16))
                .foregroundColor(CosmicTheme.textPrimary)
            Text("$178.52")
                .font(TerminalFont.price(32))
                .foregroundColor(CosmicTheme.textPrimary)
            Text("+2.34 (+1.33%)")
                .font(TerminalFont.data(14))
                .foregroundColor(CosmicTheme.positive)
        }
        .padding(16)
        .terminalCard()

        Spacer()
    }
    .padding()
    .terminalBackground()
}

#Preview("Chart Background") {
    VStack(spacing: 20) {
        Text("CHART BACKGROUND")
            .font(TerminalFont.headline(24))
            .foregroundColor(CosmicTheme.textPrimary)

        // Chart placeholder
        RoundedRectangle(cornerRadius: 0)
            .fill(Color.clear)
            .frame(height: 200)
            .chartBackground(gridSpacing: 30)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )

        Text("Grid spacing: 30pt")
            .font(TerminalFont.data(12))
            .foregroundColor(CosmicTheme.textMuted)
    }
    .padding()
    .background(CosmicTheme.background)
}

#Preview("Star Density Comparison") {
    HStack(spacing: 0) {
        VStack {
            Text("20 stars")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .terminalBackground(stars: 20)

        VStack {
            Text("40 stars")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .terminalBackground(stars: 40)

        VStack {
            Text("60 stars")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .terminalBackground(stars: 60)
    }
}
