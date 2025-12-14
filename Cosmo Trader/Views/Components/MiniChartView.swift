import SwiftUI

/// MiniChartView
/// -------------
/// Tiny sparkline chart for inline display with stock data.
/// Shows price movement without axes - just the line.
///
/// Features:
/// - No axes, labels, or gridlines - just the price line
/// - Green if up overall, red if down
/// - Smooth curve interpolation
/// - Optional gradient fill below line
/// - Fits in table rows next to stock info

// MARK: - Mini Chart View

struct MiniChartView: View {

    /// Price data points (oldest to newest)
    let data: [Double]

    /// Chart dimensions
    var width: CGFloat = 60
    var height: CGFloat = 24

    /// Line thickness
    var lineWidth: CGFloat = 1.5

    /// Show gradient fill below line
    var showFill: Bool = false

    /// Force a specific color (otherwise auto green/red)
    var overrideColor: Color?

    /// Computed trend direction
    private var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }

    /// Chart color based on trend
    private var chartColor: Color {
        overrideColor ?? (isPositive ? CosmicTheme.positive : CosmicTheme.negative)
    }

    var body: some View {
        Canvas { context, size in
            guard data.count > 1 else { return }

            let points = normalizedPoints(in: size)

            // Draw fill gradient if enabled
            if showFill {
                var fillPath = Path()
                fillPath.move(to: CGPoint(x: points[0].x, y: size.height))
                fillPath.addLine(to: points[0])

                for point in points.dropFirst() {
                    fillPath.addLine(to: point)
                }

                fillPath.addLine(to: CGPoint(x: points.last!.x, y: size.height))
                fillPath.closeSubpath()

                context.fill(
                    fillPath,
                    with: .linearGradient(
                        Gradient(colors: [
                            chartColor.opacity(0.3),
                            chartColor.opacity(0.05)
                        ]),
                        startPoint: CGPoint(x: size.width / 2, y: 0),
                        endPoint: CGPoint(x: size.width / 2, y: size.height)
                    )
                )
            }

            // Draw the line
            var linePath = Path()
            linePath.move(to: points[0])

            for point in points.dropFirst() {
                linePath.addLine(to: point)
            }

            context.stroke(
                linePath,
                with: .color(chartColor),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )

            // Draw endpoint dot
            if let lastPoint = points.last {
                let dotPath = Path(ellipseIn: CGRect(
                    x: lastPoint.x - 2,
                    y: lastPoint.y - 2,
                    width: 4,
                    height: 4
                ))
                context.fill(dotPath, with: .color(chartColor))
            }
        }
        .frame(width: width, height: height)
    }

    // MARK: - Helpers

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard data.count > 1 else { return [] }

        let minValue = data.min() ?? 0
        let maxValue = data.max() ?? 1
        let range = max(maxValue - minValue, 0.001) // Avoid division by zero

        let padding: CGFloat = 2 // Small padding so line doesn't touch edges

        return data.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(data.count - 1) * size.width
            let normalizedY = (value - minValue) / range
            let y = size.height - padding - (normalizedY * (size.height - padding * 2))
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Smooth Mini Chart (Bezier curves)

/// A smoother version using bezier curves instead of straight lines
struct SmoothMiniChartView: View {

    let data: [Double]
    var width: CGFloat = 60
    var height: CGFloat = 24
    var lineWidth: CGFloat = 1.5
    var showFill: Bool = false
    var overrideColor: Color?

    private var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }

    private var chartColor: Color {
        overrideColor ?? (isPositive ? CosmicTheme.positive : CosmicTheme.negative)
    }

    var body: some View {
        Canvas { context, size in
            guard data.count > 1 else { return }

            let points = normalizedPoints(in: size)

            // Draw fill if enabled
            if showFill {
                var fillPath = smoothPath(through: points)

                // Close the path to bottom
                fillPath.addLine(to: CGPoint(x: points.last!.x, y: size.height))
                fillPath.addLine(to: CGPoint(x: points[0].x, y: size.height))
                fillPath.closeSubpath()

                context.fill(
                    fillPath,
                    with: .linearGradient(
                        Gradient(colors: [
                            chartColor.opacity(0.25),
                            chartColor.opacity(0.02)
                        ]),
                        startPoint: CGPoint(x: size.width / 2, y: 0),
                        endPoint: CGPoint(x: size.width / 2, y: size.height)
                    )
                )
            }

            // Draw smooth line
            let linePath = smoothPath(through: points)

            context.stroke(
                linePath,
                with: .color(chartColor),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )

            // Endpoint glow
            if let lastPoint = points.last {
                // Outer glow
                let glowPath = Path(ellipseIn: CGRect(
                    x: lastPoint.x - 4,
                    y: lastPoint.y - 4,
                    width: 8,
                    height: 8
                ))
                context.fill(glowPath, with: .color(chartColor.opacity(0.3)))

                // Inner dot
                let dotPath = Path(ellipseIn: CGRect(
                    x: lastPoint.x - 2,
                    y: lastPoint.y - 2,
                    width: 4,
                    height: 4
                ))
                context.fill(dotPath, with: .color(chartColor))
            }
        }
        .frame(width: width, height: height)
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard data.count > 1 else { return [] }

        let minValue = data.min() ?? 0
        let maxValue = data.max() ?? 1
        let range = max(maxValue - minValue, 0.001)

        let padding: CGFloat = 3

        return data.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(data.count - 1) * size.width
            let normalizedY = (value - minValue) / range
            let y = size.height - padding - (normalizedY * (size.height - padding * 2))
            return CGPoint(x: x, y: y)
        }
    }

    /// Create a smooth bezier path through points
    private func smoothPath(through points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }

        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        for i in 1..<points.count {
            let current = points[i]
            let previous = points[i - 1]

            let midPoint = CGPoint(
                x: (previous.x + current.x) / 2,
                y: (previous.y + current.y) / 2
            )

            if i == 1 {
                path.addLine(to: midPoint)
            } else {
                // Previous midpoint calculation reserved for smoother curves
                _ = CGPoint(
                    x: (points[i - 2].x + previous.x) / 2,
                    y: (points[i - 2].y + previous.y) / 2
                )
                path.addQuadCurve(to: midPoint, control: previous)
            }
        }

        // Connect to last point
        path.addLine(to: points.last!)

        return path
    }
}

// MARK: - Animated Mini Chart

/// Mini chart with drawing animation on appear
struct AnimatedMiniChartView: View {

    let data: [Double]
    var width: CGFloat = 80
    var height: CGFloat = 32
    var duration: Double = 0.8

    @State private var progress: CGFloat = 0

    private var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }

    private var chartColor: Color {
        isPositive ? CosmicTheme.positive : CosmicTheme.negative
    }

    var body: some View {
        MiniChartShape(data: data)
            .trim(from: 0, to: progress)
            .stroke(
                chartColor,
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    progress = 1
                }
            }
    }
}

// MARK: - Mini Chart Shape

struct MiniChartShape: Shape {

    let data: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard data.count > 1 else { return path }

        let minValue = data.min() ?? 0
        let maxValue = data.max() ?? 1
        let range = max(maxValue - minValue, 0.001)

        let padding: CGFloat = 3

        let points: [CGPoint] = data.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(data.count - 1) * rect.width
            let normalizedY = (value - minValue) / range
            let y = rect.height - padding - (normalizedY * (rect.height - padding * 2))
            return CGPoint(x: x, y: y)
        }

        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        return path
    }
}

// MARK: - Sample Data Generator

extension MiniChartView {
    /// Generate sample price data for previews/testing
    static func sampleData(days: Int = 7, trend: Double = 0.02, volatility: Double = 0.03, startPrice: Double = 100) -> [Double] {
        var prices: [Double] = []
        var price = startPrice

        for _ in 0..<days {
            prices.append(price)
            let dailyReturn = trend + Double.random(in: -volatility...volatility)
            price *= (1 + dailyReturn)
        }

        return prices
    }

    /// Generate uptrend data
    static var uptrendSample: [Double] {
        sampleData(trend: 0.01, volatility: 0.02)
    }

    /// Generate downtrend data
    static var downtrendSample: [Double] {
        sampleData(trend: -0.015, volatility: 0.02)
    }

    /// Generate flat/volatile data
    static var volatileSample: [Double] {
        sampleData(trend: 0, volatility: 0.04)
    }
}

// MARK: - Preview

#Preview("Mini Charts") {
    VStack(spacing: 24) {
        Text("MINI CHARTS")
            .font(TerminalFont.headline(16))
            .foregroundColor(CosmicTheme.textPrimary)

        // Basic charts
        HStack(spacing: 20) {
            VStack {
                MiniChartView(data: MiniChartView.uptrendSample)
                Text("Up")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            VStack {
                MiniChartView(data: MiniChartView.downtrendSample)
                Text("Down")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            VStack {
                MiniChartView(data: MiniChartView.volatileSample)
                Text("Volatile")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }

        Divider()
            .background(CosmicTheme.border)

        // Smooth charts with fill
        Text("SMOOTH WITH FILL")
            .font(TerminalFont.data(12))
            .foregroundColor(CosmicTheme.textSecondary)

        HStack(spacing: 20) {
            SmoothMiniChartView(
                data: MiniChartView.uptrendSample,
                width: 80,
                height: 32,
                showFill: true
            )

            SmoothMiniChartView(
                data: MiniChartView.downtrendSample,
                width: 80,
                height: 32,
                showFill: true
            )
        }

        Divider()
            .background(CosmicTheme.border)

        // Animated chart
        Text("ANIMATED")
            .font(TerminalFont.data(12))
            .foregroundColor(CosmicTheme.textSecondary)

        AnimatedMiniChartView(
            data: [100, 102, 98, 105, 103, 108, 112, 110, 115],
            width: 120,
            height: 40
        )

        Divider()
            .background(CosmicTheme.border)

        // In-row example
        Text("IN TABLE ROW")
            .font(TerminalFont.data(12))
            .foregroundColor(CosmicTheme.textSecondary)

        HStack {
            Text("AAPL")
                .font(TerminalFont.data(14, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            Spacer()

            MiniChartView(
                data: MiniChartView.uptrendSample,
                width: 50,
                height: 20
            )

            Text("$178.52")
                .font(TerminalFont.price(14))
                .foregroundColor(CosmicTheme.textPrimary)
                .frame(width: 70, alignment: .trailing)

            Text("+1.2%")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.positive)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }
    .padding()
    .background(CosmicTheme.background)
}

#Preview("Large Chart") {
    VStack(spacing: 16) {
        Text("30-DAY PERFORMANCE")
            .font(TerminalFont.headline(14))
            .foregroundColor(CosmicTheme.textSecondary)

        SmoothMiniChartView(
            data: MiniChartView.sampleData(days: 30, trend: 0.005, volatility: 0.02),
            width: 300,
            height: 80,
            lineWidth: 2,
            showFill: true
        )
    }
    .padding()
    .background(CosmicTheme.background)
}
