import SwiftUI

/// TerminalBackground
/// -----------------
/// Flat black. No decoration. No stars. No gradients.
/// Bloomberg Terminal aesthetic.

// MARK: - Terminal Background

struct TerminalBackground: View {

    /// Ignored - kept for API compatibility
    var starCount: Int = 0

    /// Whether to show grid lines (for charts only)
    var showGrid: Bool = false

    /// Grid spacing in points
    var gridSpacing: CGFloat = 40

    /// Ignored - kept for API compatibility
    var seed: Int = 42

    var body: some View {
        ZStack {
            // Flat black. Nothing else.
            CosmicTheme.background

            // Optional grid lines for charts
            if showGrid {
                GridPattern(spacing: gridSpacing)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Grid Pattern (for charts only)

struct GridPattern: View {
    let spacing: CGFloat
    let lineColor: Color = CosmicTheme.border
    let lineWidth: CGFloat = 1

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

// MARK: - Star Field (REMOVED - kept as empty struct for compatibility)

struct StarField: View {
    let count: Int
    let size: CGSize
    let seed: Int

    var body: some View {
        Color.clear // No stars. Too decorative.
    }
}

// MARK: - Seeded Random Number Generator (kept for compatibility)

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(truncatingIfNeeded: seed)
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - View Extensions

extension View {
    /// Apply flat black background
    func terminalBackground(stars: Int = 0, showGrid: Bool = false) -> some View {
        self.background(CosmicTheme.background)
    }

    /// Apply chart background with grid lines
    func chartBackground(gridSpacing: CGFloat = 40) -> some View {
        self.background(
            TerminalBackground(showGrid: true, gridSpacing: gridSpacing)
        )
    }
}

// MARK: - Preview

#Preview("Terminal Background") {
    VStack(spacing: 0) {
        Text("TERMINAL BACKGROUND")
            .font(TerminalFont.data(14))
            .foregroundColor(CosmicTheme.textMuted)
            .tracking(2)
            .padding(.vertical, 12)

        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)

        // Sample data
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AAPL")
                    .font(TerminalFont.ticker(14))
                    .foregroundColor(CosmicTheme.textPrimary)
                Text("Apple Inc.")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
            .padding(12)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$178.52")
                    .font(TerminalFont.price(18))
                    .foregroundColor(CosmicTheme.textPrimary)
                Text("+1.33%")
                    .font(TerminalFont.price(12))
                    .foregroundColor(CosmicTheme.positive)
            }
            .padding(12)
        }

        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)

        Spacer()
    }
    .background(CosmicTheme.background)
}
