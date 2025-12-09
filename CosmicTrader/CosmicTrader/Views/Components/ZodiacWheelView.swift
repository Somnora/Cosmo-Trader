import SwiftUI

// MARK: - ZodiacWheelView
// ========================
// An interactive pie chart visualization showing portfolio breakdown by element.
//
// FEATURES:
// - Four colored segments for Fire, Earth, Air, Water
// - Proportional sizing based on portfolio value
// - Animated appearance with mystical fade-in
// - Tappable segments that expand and show details
// - Center display with total value or dominant element insight
// - Legend with element colors, names, percentages, and stock counts
//
// DESIGN PHILOSOPHY:
// - Mystical and premium feel with subtle animations
// - Clear data visualization without sacrificing aesthetics
// - Interactive exploration of portfolio composition

struct ZodiacWheelView: View {

    // MARK: - Properties

    /// Element breakdown data from the ViewModel
    let breakdown: [ElementBreakdown]

    /// Stocks grouped by element
    let stocksByElement: [ZodiacSign.Element: [Stock]]

    /// Total portfolio value for center display
    let totalValue: String

    /// Currently selected element (nil = none selected)
    @State private var selectedElement: ZodiacSign.Element?

    /// Animation state for wheel appearance
    @State private var wheelScale: CGFloat = 0.8
    @State private var wheelOpacity: Double = 0
    @State private var segmentRotation: Double = -90

    /// Animation state for glow effect
    @State private var glowAmount: Double = 0

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // The wheel itself
            wheelSection

            // Legend below the wheel
            legendSection

            // Selected element detail (if any)
            if let selected = selectedElement {
                selectedElementDetail(for: selected)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding(20)
        .background(cardBackground)
        .onAppear {
            animateAppearance()
        }
    }

    // MARK: - Wheel Section

    private var wheelSection: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            CosmicTheme.gold.opacity(0.3),
                            CosmicTheme.cosmicPurple.opacity(0.2),
                            CosmicTheme.nebulaBlue.opacity(0.3),
                            CosmicTheme.gold.opacity(0.3)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 220, height: 220)
                .blur(radius: glowAmount)
                .opacity(0.6)

            // The pie chart
            pieChart
                .frame(width: 200, height: 200)

            // Center content
            centerContent
        }
        .scaleEffect(wheelScale)
        .opacity(wheelOpacity)
    }

    // MARK: - Pie Chart

    private var pieChart: some View {
        ZStack {
            ForEach(Array(breakdown.enumerated()), id: \.element.id) { index, item in
                if item.percentage > 0 {
                    PieSegment(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        isSelected: selectedElement == item.element
                    )
                    .fill(colorForElement(item.element))
                    .overlay(
                        PieSegment(
                            startAngle: startAngle(for: index),
                            endAngle: endAngle(for: index),
                            isSelected: selectedElement == item.element
                        )
                        .stroke(
                            selectedElement == item.element
                                ? CosmicTheme.gold
                                : Color.white.opacity(0.1),
                            lineWidth: selectedElement == item.element ? 3 : 1
                        )
                    )
                    .scaleEffect(selectedElement == item.element ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3), value: selectedElement)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            if selectedElement == item.element {
                                selectedElement = nil
                            } else {
                                selectedElement = item.element
                            }
                        }
                    }
                }
            }
        }
        .rotationEffect(.degrees(segmentRotation))
    }

    // MARK: - Center Content

    private var centerContent: some View {
        ZStack {
            // Dark center circle
            Circle()
                .fill(CosmicTheme.background)
                .frame(width: 100, height: 100)

            // Gradient border
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            CosmicTheme.gold.opacity(0.5),
                            CosmicTheme.cosmicPurple.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 100, height: 100)

            // Content
            if let selected = selectedElement {
                // Show selected element info
                VStack(spacing: 4) {
                    Text(selected.emoji)
                        .font(.title)

                    Text(selected.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    let pct = breakdown.first { $0.element == selected }?.formattedPercentage ?? "0%"
                    Text(pct)
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            } else {
                // Show total value
                VStack(spacing: 2) {
                    Text("Total")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                        .textCase(.uppercase)

                    Text(totalValue)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Legend Section

    private var legendSection: some View {
        HStack(spacing: 16) {
            ForEach(ZodiacSign.Element.allCases, id: \.self) { element in
                let item = breakdown.first { $0.element == element }
                let percentage = item?.percentage ?? 0
                let stockCount = stocksByElement[element]?.count ?? 0

                legendItem(
                    element: element,
                    percentage: percentage,
                    stockCount: stockCount,
                    isSelected: selectedElement == element
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        if selectedElement == element {
                            selectedElement = nil
                        } else {
                            selectedElement = element
                        }
                    }
                }
            }
        }
    }

    private func legendItem(
        element: ZodiacSign.Element,
        percentage: Double,
        stockCount: Int,
        isSelected: Bool
    ) -> some View {
        VStack(spacing: 6) {
            // Color indicator
            Circle()
                .fill(colorForElement(element))
                .frame(width: isSelected ? 14 : 10, height: isSelected ? 14 : 10)
                .overlay(
                    Circle()
                        .stroke(CosmicTheme.gold, lineWidth: isSelected ? 2 : 0)
                )
                .animation(.spring(response: 0.3), value: isSelected)

            // Element emoji and name
            VStack(spacing: 2) {
                Text(element.emoji)
                    .font(.caption)

                Text(String(format: "%.0f%%", percentage))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? CosmicTheme.gold : CosmicTheme.textPrimary)

                Text("\(stockCount)")
                    .font(.system(size: 9))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? CosmicTheme.secondaryBackground : Color.clear)
        )
    }

    // MARK: - Selected Element Detail

    private func selectedElementDetail(for element: ZodiacSign.Element) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with insight
            HStack {
                Text(element.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(element.displayName) Holdings")
                        .font(.headline)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(insightForElement(element))
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                        .italic()
                }

                Spacer()

                // Close button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedElement = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            // Stocks in this element
            if let stocks = stocksByElement[element], !stocks.isEmpty {
                VStack(spacing: 8) {
                    ForEach(stocks) { stock in
                        elementStockRow(stock: stock)
                    }
                }
            } else {
                Text("No \(element.displayName.lowercased()) sign stocks in your portfolio")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CosmicTheme.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorForElement(element).opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func elementStockRow(stock: Stock) -> some View {
        HStack(spacing: 10) {
            Text(stock.zodiacSign.symbol)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.name)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(stock.formattedTotalValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(stock.formattedPercentageChange)
                    .font(.caption2)
                    .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(CosmicTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
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

    /// Calculate start angle for a segment
    private func startAngle(for index: Int) -> Angle {
        let precedingPercentage = breakdown.prefix(index).reduce(0) { $0 + $1.percentage }
        return .degrees(precedingPercentage / 100 * 360)
    }

    /// Calculate end angle for a segment
    private func endAngle(for index: Int) -> Angle {
        let throughPercentage = breakdown.prefix(index + 1).reduce(0) { $0 + $1.percentage }
        return .degrees(throughPercentage / 100 * 360)
    }

    /// Get color for each element
    private func colorForElement(_ element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire:  return Color(red: 1.0, green: 0.35, blue: 0.25)   // Vibrant fire red
        case .earth: return Color(red: 0.35, green: 0.7, blue: 0.35)   // Natural green
        case .air:   return Color(red: 0.4, green: 0.6, blue: 0.9)     // Sky blue
        case .water: return Color(red: 0.5, green: 0.3, blue: 0.8)     // Deep purple-blue
        }
    }

    /// Get insight text for each element
    private func insightForElement(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire:
            return "Your Fire holdings bring growth energy and bold momentum."
        case .earth:
            return "Your Earth holdings provide stability and grounded returns."
        case .air:
            return "Your Air holdings add intellectual diversification."
        case .water:
            return "Your Water holdings bring intuitive, flowing gains."
        }
    }

    // MARK: - Animations

    private func animateAppearance() {
        // Staggered animation for mystical effect
        withAnimation(.easeOut(duration: 0.6)) {
            wheelOpacity = 1
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            wheelScale = 1.0
        }

        withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
            segmentRotation = 0
        }

        // Pulsing glow
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowAmount = 4
        }
    }
}

// MARK: - PieSegment Shape

/// A custom shape for individual pie segments
struct PieSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var isSelected: Bool

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set {
            startAngle = .degrees(newValue.first)
            endAngle = .degrees(newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle - .degrees(90),
            endAngle: endAngle - .degrees(90),
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview("Zodiac Wheel - Mixed") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        ScrollView {
            ZodiacWheelView(
                breakdown: [
                    ElementBreakdown(element: .water, percentage: 35, value: 15000),
                    ElementBreakdown(element: .fire, percentage: 28, value: 12000),
                    ElementBreakdown(element: .earth, percentage: 22, value: 9500),
                    ElementBreakdown(element: .air, percentage: 15, value: 6500)
                ],
                stocksByElement: [
                    .fire: [MockStockData.all.first { $0.symbol == "AAPL" }!],
                    .earth: [MockStockData.all.first { $0.symbol == "GOOGL" }!],
                    .water: [
                        MockStockData.all.first { $0.symbol == "TSLA" }!,
                        MockStockData.all.first { $0.symbol == "AMZN" }!
                    ],
                    .air: [MockStockData.all.first { $0.symbol == "NVDA" }!]
                ],
                totalValue: "$43,000"
            )
            .padding()
        }
    }
}

#Preview("Zodiac Wheel - Fire Heavy") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        ZodiacWheelView(
            breakdown: [
                ElementBreakdown(element: .fire, percentage: 60, value: 26000),
                ElementBreakdown(element: .earth, percentage: 20, value: 8600),
                ElementBreakdown(element: .air, percentage: 12, value: 5200),
                ElementBreakdown(element: .water, percentage: 8, value: 3500)
            ],
            stocksByElement: [
                .fire: [
                    MockStockData.all.first { $0.symbol == "AAPL" }!,
                    MockStockData.all.first { $0.symbol == "MSFT" }!
                ],
                .earth: [MockStockData.all.first { $0.symbol == "GOOGL" }!],
                .water: [],
                .air: [MockStockData.all.first { $0.symbol == "NVDA" }!]
            ],
            totalValue: "$43,300"
        )
        .padding()
    }
}
