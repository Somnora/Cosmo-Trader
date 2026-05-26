import SwiftUI

// MARK: - Launch Screen View
// ==========================
// Animated launch screen: A price trend line draws itself,
// leaving glowing stars at peaks (green) and troughs (red).
// The line fades away, revealing a constellation of trading signals.
// "TRON meets Wall Street meets The Alchemist"

struct LaunchScreenView: View {

    // MARK: - Animation State

    @State private var lineProgress: CGFloat = 0
    @State private var lineOpacity: Double = 1
    @State private var starsRevealed: Bool = false
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var quoteOpacity: Double = 0
    @State private var risingPhase: Bool = false

    // MARK: - Constants

    private let animationDuration: Double = 2.0
    private let lineFadeDuration: Double = 0.8
    private let starRevealDelay: Double = 0.3

    var body: some View {
        ZStack {
            // Background - True OLED black
            Color.black
                .ignoresSafeArea()

            // Faint grid lines
            GridBackground()
                .opacity(0.03)

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Constellation animation area
                ConstellationAnimationView(
                    lineProgress: lineProgress,
                    lineOpacity: lineOpacity,
                    starsRevealed: starsRevealed,
                    risingPhase: risingPhase
                )
                .frame(height: 200)
                .padding(.horizontal, 40)

                Spacer()
                    .frame(height: 60)

                // Logo text
                VStack(spacing: 8) {
                    Text("COSMO")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(12)

                    Text("TRADER")
                        .font(.system(size: 36, weight: .light, design: .monospaced))
                        .foregroundColor(Color(hex: "FFD700"))
                        .tracking(12)
                }
                .opacity(logoOpacity)

                Spacer()
                    .frame(height: 24)

                // Tagline
                Text("Where the stars meet the market")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "666666"))
                    .opacity(taglineOpacity)

                Spacer()

                // Premium positioning quote - subtle, near bottom
                JPMorganQuoteView(size: .minimal, opacity: quoteOpacity)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 24)

                // Version
                Text("v1.0")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(hex: "333333"))
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation Sequence

    private func startAnimation() {
        // Phase 1: Draw the trend line
        withAnimation(.easeInOut(duration: animationDuration)) {
            lineProgress = 1.0
        }

        // Phase 2: Fade the line, reveal stars
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.2) {
            withAnimation(.easeOut(duration: lineFadeDuration)) {
                lineOpacity = 0
            }

            withAnimation(.easeIn(duration: 0.6).delay(starRevealDelay)) {
                starsRevealed = true
            }
        }

        // Phase 3: Show logo
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.8) {
            withAnimation(.easeOut(duration: 0.6)) {
                logoOpacity = 1
            }
        }

        // Phase 4: Show tagline
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 1.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                taglineOpacity = 1
            }
        }

        // Phase 5: Rising - constellation ascends upward for aspirational feeling
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 1.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                risingPhase = true
            }
        }

        // Phase 6: Show premium quote - subtle fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 1.8) {
            withAnimation(.easeIn(duration: 0.8)) {
                quoteOpacity = 1
            }
        }
    }
}

// MARK: - Constellation Animation View

struct ConstellationAnimationView: View {

    let lineProgress: CGFloat
    let lineOpacity: Double
    let starsRevealed: Bool
    let risingPhase: Bool

    // Parallax multipliers for diverse star movement (creates depth)
    private let parallaxMultipliers: [CGFloat] = [1.0, 0.6, 1.2, 0.8, 1.1, 0.7, 0.9]
    private let baseRiseAmount: CGFloat = 40

    // Define the trend line points (normalized 0-1)
    // Creates a realistic-looking price chart pattern
    private let trendPoints: [CGPoint] = [
        CGPoint(x: 0.00, y: 0.50),  // Start middle
        CGPoint(x: 0.08, y: 0.35),  // Rise
        CGPoint(x: 0.15, y: 0.55),  // Drop - trough 1
        CGPoint(x: 0.25, y: 0.20),  // Strong rise - peak 1
        CGPoint(x: 0.35, y: 0.45),  // Pullback - trough 2
        CGPoint(x: 0.45, y: 0.15),  // Higher high - peak 2
        CGPoint(x: 0.55, y: 0.40),  // Correction - trough 3
        CGPoint(x: 0.62, y: 0.30),  // Recovery
        CGPoint(x: 0.70, y: 0.60),  // Drop - trough 4
        CGPoint(x: 0.80, y: 0.25),  // Rise - peak 3
        CGPoint(x: 0.90, y: 0.45),  // Decline
        CGPoint(x: 1.00, y: 0.35),  // End
    ]

    // Identify peaks and troughs for stars
    private var starPoints: [(point: CGPoint, isPeak: Bool)] {
        var stars: [(CGPoint, Bool)] = []

        for i in 1..<(trendPoints.count - 1) {
            let prev = trendPoints[i - 1]
            let curr = trendPoints[i]
            let next = trendPoints[i + 1]

            // Peak: lower y value than neighbors (y is inverted)
            if curr.y < prev.y && curr.y < next.y {
                stars.append((curr, true))
            }
            // Trough: higher y value than neighbors
            else if curr.y > prev.y && curr.y > next.y {
                stars.append((curr, false))
            }
        }

        return stars
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // The animated trend line
                AnimatedTrendLine(
                    points: trendPoints,
                    progress: lineProgress,
                    size: size
                )
                .stroke(
                    Color(hex: "FFD700"),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                .opacity(lineOpacity)

                // Star points at peaks and troughs
                ForEach(Array(starPoints.enumerated()), id: \.offset) { index, star in
                    let screenPoint = CGPoint(
                        x: star.point.x * size.width,
                        y: star.point.y * size.height
                    )

                    // Parallax effect: each star rises at slightly different rate
                    let parallaxIndex = index % parallaxMultipliers.count
                    let riseOffset = risingPhase ? -baseRiseAmount * parallaxMultipliers[parallaxIndex] : 0

                    StarPoint(
                        isPeak: star.isPeak,
                        isRevealed: starsRevealed,
                        appearDelay: Double(index) * 0.15
                    )
                    .position(screenPoint)
                    .offset(y: riseOffset)
                }

                // Constellation lines connecting the stars (after reveal)
                if starsRevealed {
                    // Lines rise with average parallax (0.85x base) for cohesion
                    let linesRiseOffset = risingPhase ? -baseRiseAmount * 0.85 : 0

                    ConstellationLines(
                        starPoints: starPoints,
                        size: size
                    )
                    .stroke(
                        Color.white.opacity(0.15),
                        style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                    )
                    .offset(y: linesRiseOffset)
                }
            }
        }
    }
}

// MARK: - Animated Trend Line

struct AnimatedTrendLine: Shape {
    let points: [CGPoint]
    var progress: CGFloat
    let size: CGSize

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }

        let scaledPoints = points.map { pt in
            CGPoint(x: pt.x * size.width, y: pt.y * size.height)
        }

        guard let firstPoint = scaledPoints.first else { return path }
        path.move(to: firstPoint)

        // Calculate total path length
        var totalLength: CGFloat = 0
        var segmentLengths: [CGFloat] = []

        for i in 1..<scaledPoints.count {
            let length = hypot(
                scaledPoints[i].x - scaledPoints[i-1].x,
                scaledPoints[i].y - scaledPoints[i-1].y
            )
            segmentLengths.append(length)
            totalLength += length
        }

        // Draw path up to progress point
        let targetLength = totalLength * progress
        var drawnLength: CGFloat = 0

        for i in 1..<scaledPoints.count {
            let segmentLength = segmentLengths[i-1]

            if drawnLength + segmentLength <= targetLength {
                // Draw full segment
                path.addLine(to: scaledPoints[i])
                drawnLength += segmentLength
            } else {
                // Partial segment
                let remaining = targetLength - drawnLength
                let fraction = remaining / segmentLength
                let partialPoint = CGPoint(
                    x: scaledPoints[i-1].x + (scaledPoints[i].x - scaledPoints[i-1].x) * fraction,
                    y: scaledPoints[i-1].y + (scaledPoints[i].y - scaledPoints[i-1].y) * fraction
                )
                path.addLine(to: partialPoint)
                break
            }
        }

        return path
    }
}

// MARK: - Star Point

struct StarPoint: View {

    let isPeak: Bool
    let isRevealed: Bool
    let appearDelay: Double

    @State private var glowIntensity: Double = 0
    @State private var scale: CGFloat = 0

    private var starColor: Color {
        isPeak ? Color(hex: "00FF7F") : Color(hex: "FF3B30")
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            starColor.opacity(0.6 * glowIntensity),
                            starColor.opacity(0.2 * glowIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            starColor,
                            starColor.opacity(0.5)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 4
                    )
                )
                .frame(width: 8, height: 8)

            // Core
            Circle()
                .fill(Color.white)
                .frame(width: 3, height: 3)
        }
        .scaleEffect(scale)
        .onChange(of: isRevealed) { _, revealed in
            if revealed {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(appearDelay)) {
                    scale = 1.0
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(appearDelay + 0.3)) {
                    glowIntensity = 1.0
                }
            }
        }
    }
}

// MARK: - Constellation Lines

struct ConstellationLines: Shape {
    let starPoints: [(point: CGPoint, isPeak: Bool)]
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard starPoints.count > 1 else { return path }

        let scaledPoints = starPoints.map { star in
            CGPoint(x: star.point.x * size.width, y: star.point.y * size.height)
        }

        guard let firstPoint = scaledPoints.first else { return path }
        path.move(to: firstPoint)
        for i in 1..<scaledPoints.count {
            path.addLine(to: scaledPoints[i])
        }

        return path
    }
}

// MARK: - Grid Background

struct GridBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 30

            // Vertical lines
            var x: CGFloat = 0
            while x < size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white), lineWidth: 0.5)
                x += spacing
            }

            // Horizontal lines
            var y: CGFloat = 0
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white), lineWidth: 0.5)
                y += spacing
            }
        }
    }
}

// MARK: - Preview

#Preview("Launch Screen") {
    LaunchScreenView()
}

#Preview("Constellation Only") {
    ZStack {
        Color.black.ignoresSafeArea()

        ConstellationAnimationView(
            lineProgress: 1.0,
            lineOpacity: 0.3,
            starsRevealed: true,
            risingPhase: false
        )
        .frame(height: 200)
        .padding(.horizontal, 40)
    }
}

#Preview("Constellation Rising") {
    ZStack {
        Color.black.ignoresSafeArea()

        ConstellationAnimationView(
            lineProgress: 1.0,
            lineOpacity: 0.0,
            starsRevealed: true,
            risingPhase: true
        )
        .frame(height: 200)
        .padding(.horizontal, 40)
    }
}
