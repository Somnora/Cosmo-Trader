import SwiftUI

// MARK: - SparklineView
// =====================
// A minimal line chart for displaying price history trends.
// Automatically colors green if trending up, red if trending down.
//
// Design Philosophy:
// - Minimal, no axes or labels - pure data visualization
// - Terminal-style thin stroke
// - Optional gradient fill beneath the line
// - Configurable size and appearance

struct SparklineView: View {

    // MARK: - Properties

    /// Price history data points
    let data: [Double]

    /// Size of the sparkline
    var width: CGFloat = 60
    var height: CGFloat = 24

    /// Line stroke width
    var strokeWidth: CGFloat = 1.5

    /// Show gradient fill below line
    var showFill: Bool = false

    /// Optional override color (otherwise auto green/red)
    var overrideColor: Color? = nil

    // MARK: - Computed Properties

    /// Determine if trending up (last > first)
    private var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }

    /// Line color based on trend
    private var lineColor: Color {
        overrideColor ?? (isPositive ? CosmicTheme.positive : CosmicTheme.negative)
    }

    /// Normalized data points (0 to 1 range)
    private var normalizedData: [CGFloat] {
        guard !data.isEmpty else { return [] }
        let minVal = data.min() ?? 0
        let maxVal = data.max() ?? 1
        let range = maxVal - minVal

        if range == 0 {
            return data.map { _ in CGFloat(0.5) }
        }

        return data.map { CGFloat(($0 - minVal) / range) }
    }

    // MARK: - Body

    var body: some View {
        Canvas { context, size in
            guard normalizedData.count > 1 else { return }

            let stepX = size.width / CGFloat(normalizedData.count - 1)
            let padding: CGFloat = 2

            // Build path
            var linePath = Path()
            var fillPath = Path()

            for (index, value) in normalizedData.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - padding - (value * (size.height - padding * 2))

                if index == 0 {
                    linePath.move(to: CGPoint(x: x, y: y))
                    fillPath.move(to: CGPoint(x: x, y: size.height))
                    fillPath.addLine(to: CGPoint(x: x, y: y))
                } else {
                    linePath.addLine(to: CGPoint(x: x, y: y))
                    fillPath.addLine(to: CGPoint(x: x, y: y))
                }
            }

            // Close fill path
            fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
            fillPath.closeSubpath()

            // Draw gradient fill
            if showFill {
                let gradient = Gradient(colors: [
                    lineColor.opacity(0.3),
                    lineColor.opacity(0.05)
                ])
                context.fill(
                    fillPath,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
            }

            // Draw line
            context.stroke(
                linePath,
                with: .color(lineColor),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
            )

            // Draw endpoint dot
            if let lastValue = normalizedData.last {
                let lastX = size.width
                let lastY = size.height - padding - (lastValue * (size.height - padding * 2))

                let dotPath = Path(ellipseIn: CGRect(
                    x: lastX - 2.5,
                    y: lastY - 2.5,
                    width: 5,
                    height: 5
                ))
                context.fill(dotPath, with: .color(lineColor))
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Sparkline Variants

/// Sparkline with value label
struct SparklineWithValue: View {

    let data: [Double]
    let currentValue: String
    var width: CGFloat = 50
    var height: CGFloat = 20

    private var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }

    var body: some View {
        HStack(spacing: 8) {
            SparklineView(data: data, width: width, height: height)

            Text(currentValue)
                .font(TerminalFont.data(11))
                .foregroundColor(isPositive ? CosmicTheme.positive : CosmicTheme.negative)
        }
    }
}

/// Larger sparkline for detail views
struct DetailSparkline: View {

    let data: [Double]
    var height: CGFloat = 60
    var showFill: Bool = true

    private var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }

    var body: some View {
        GeometryReader { geometry in
            SparklineView(
                data: data,
                width: geometry.size.width,
                height: height,
                strokeWidth: 2,
                showFill: showFill
            )
        }
        .frame(height: height)
    }
}

/// Mini sparkline for tight spaces (holding rows)
struct MiniSparkline: View {

    let data: [Double]
    var size: CGSize = CGSize(width: 40, height: 16)

    var body: some View {
        SparklineView(
            data: data,
            width: size.width,
            height: size.height,
            strokeWidth: 1.0
        )
    }
}

// MARK: - Sample Data Generator

extension SparklineView {

    /// Generate sample price data for previews
    static func sampleData(count: Int = 20, trend: Trend = .up) -> [Double] {
        var values: [Double] = []
        var current = 100.0

        for _ in 0..<count {
            let change: Double
            switch trend {
            case .up:
                change = Double.random(in: -2...4)
            case .down:
                change = Double.random(in: -4...2)
            case .flat:
                change = Double.random(in: -2...2)
            case .volatile:
                change = Double.random(in: -8...8)
            }
            current += change
            current = max(50, min(150, current))
            values.append(current)
        }

        return values
    }

    enum Trend {
        case up, down, flat, volatile
    }
}

// MARK: - Preview

#Preview("Sparkline Variants") {
    VStack(spacing: 24) {
        Text("SPARKLINES")
            .font(TerminalFont.headline(16))
            .foregroundColor(CosmicTheme.textPrimary)

        HStack(spacing: 24) {
            VStack(spacing: 8) {
                SparklineView(data: SparklineView.sampleData(trend: .up))
                Text("Up Trend")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            VStack(spacing: 8) {
                SparklineView(data: SparklineView.sampleData(trend: .down))
                Text("Down Trend")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            VStack(spacing: 8) {
                SparklineView(data: SparklineView.sampleData(trend: .flat))
                Text("Flat")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            VStack(spacing: 8) {
                SparklineView(data: SparklineView.sampleData(trend: .volatile))
                Text("Volatile")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }

        Divider()
            .background(CosmicTheme.border)

        Text("WITH FILL")
            .font(TerminalFont.headline(14))
            .foregroundColor(CosmicTheme.textSecondary)

        HStack(spacing: 24) {
            SparklineView(
                data: SparklineView.sampleData(trend: .up),
                width: 80,
                height: 32,
                showFill: true
            )

            SparklineView(
                data: SparklineView.sampleData(trend: .down),
                width: 80,
                height: 32,
                showFill: true
            )
        }

        Divider()
            .background(CosmicTheme.border)

        Text("DETAIL SPARKLINE")
            .font(TerminalFont.headline(14))
            .foregroundColor(CosmicTheme.textSecondary)

        DetailSparkline(data: SparklineView.sampleData(count: 30, trend: .up))
            .padding(.horizontal)

        Divider()
            .background(CosmicTheme.border)

        Text("WITH VALUE")
            .font(TerminalFont.headline(14))
            .foregroundColor(CosmicTheme.textSecondary)

        HStack(spacing: 32) {
            SparklineWithValue(
                data: SparklineView.sampleData(trend: .up),
                currentValue: "+2.34%"
            )

            SparklineWithValue(
                data: SparklineView.sampleData(trend: .down),
                currentValue: "-1.23%"
            )
        }

        Divider()
            .background(CosmicTheme.border)

        Text("MINI SPARKLINES")
            .font(TerminalFont.headline(14))
            .foregroundColor(CosmicTheme.textSecondary)

        HStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { i in
                MiniSparkline(
                    data: SparklineView.sampleData(
                        count: 15,
                        trend: i % 2 == 0 ? .up : .down
                    )
                )
            }
        }
    }
    .padding()
    .background(CosmicTheme.background)
}

#Preview("In Context") {
    VStack(spacing: 16) {
        // Simulated holding row
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AAPL")
                    .font(TerminalFont.ticker(14))
                    .foregroundColor(CosmicTheme.textPrimary)
                Text("Apple Inc.")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            MiniSparkline(data: SparklineView.sampleData(trend: .up))

            VStack(alignment: .trailing, spacing: 2) {
                Text("$178.52")
                    .font(TerminalFont.price(14))
                    .foregroundColor(CosmicTheme.textPrimary)
                Text("+1.33%")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.positive)
            }
        }
        .padding(12)
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )

        // Another row
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TSLA")
                    .font(TerminalFont.ticker(14))
                    .foregroundColor(CosmicTheme.textPrimary)
                Text("Tesla Inc.")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            MiniSparkline(data: SparklineView.sampleData(trend: .down))

            VStack(alignment: .trailing, spacing: 2) {
                Text("$245.67")
                    .font(TerminalFont.price(14))
                    .foregroundColor(CosmicTheme.textPrimary)
                Text("-2.15%")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.negative)
            }
        }
        .padding(12)
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }
    .padding()
    .background(CosmicTheme.background)
}
