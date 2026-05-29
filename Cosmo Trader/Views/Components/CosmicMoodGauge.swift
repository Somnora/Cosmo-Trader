import SwiftUI

// MARK: - Cosmic Mood Gauge
// =========================
// A semicircle speedometer-style gauge showing the Cosmic Mood Index.
// Gradient from dark blue (fear) through purple (neutral) to gold/orange (greed).

struct CosmicMoodGauge: View {

    // MARK: - Properties

    let moodData: CosmicMoodData
    var size: GaugeSize = .large
    var showLabels: Bool = true
    var animated: Bool = true

    // MARK: - State

    @State private var animatedValue: Double = 0
    @State private var needleRotation: Double = -90

    // MARK: - Body

    var body: some View {
        VStack(spacing: size.labelSpacing) {
            // Gauge
            ZStack {
                // Background arc
                arcBackground

                // Gradient arc fill
                arcGradient

                // Tick marks
                tickMarks

                // Needle
                needle

                // Center value display
                centerDisplay
            }
            .frame(width: size.gaugeWidth, height: size.gaugeHeight)

            if showLabels {
                // Mood level and sentiment labels
                moodLabels
            }
        }
        .onAppear {
            if animated {
                animateNeedle()
            } else {
                animatedValue = Double(gaugeValue)
                needleRotation = valueToRotation(gaugeValue)
            }
        }
        .onChange(of: moodData.value) { _, newValue in
            let value = newValue ?? 50
            if animated {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    animatedValue = Double(value)
                    needleRotation = valueToRotation(value)
                }
            } else {
                animatedValue = Double(value)
                needleRotation = valueToRotation(value)
            }
        }
    }

    // MARK: - Arc Background

    private var arcBackground: some View {
        Arc(startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            .stroke(
                CosmicTheme.secondaryBackground,
                style: StrokeStyle(lineWidth: size.arcWidth, lineCap: .round)
            )
            .frame(width: size.arcDiameter, height: size.arcDiameter / 2)
    }

    // MARK: - Gradient Arc

    private var arcGradient: some View {
        Arc(startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: gaugeGradientColors),
                    center: .bottom,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0)
                ),
                style: StrokeStyle(lineWidth: size.arcWidth - 4, lineCap: .round)
            )
            .frame(width: size.arcDiameter - 4, height: (size.arcDiameter - 4) / 2)
    }

    /// Gradient colors from fear (left) to greed (right)
    private var gaugeGradientColors: [Color] {
        [
            Color(red: 0.1, green: 0.1, blue: 0.3),   // Void - deep blue
            Color(red: 0.2, green: 0.15, blue: 0.4), // Eclipse - dark purple
            Color(red: 0.4, green: 0.3, blue: 0.5),  // Twilight - purple
            Color(red: 0.6, green: 0.45, blue: 0.3), // Transition
            CosmicTheme.gold,                         // Radiant - gold
            Color(red: 1.0, green: 0.5, blue: 0.2)   // Supernova - orange
        ]
    }

    // MARK: - Tick Marks

    private var tickMarks: some View {
        ZStack {
            // Major tick marks at 0, 25, 50, 75, 100
            ForEach([0, 25, 50, 75, 100], id: \.self) { value in
                tickMark(at: value, isMajor: true)
            }

            // Minor tick marks
            ForEach([10, 20, 30, 40, 60, 70, 80, 90], id: \.self) { value in
                tickMark(at: value, isMajor: false)
            }
        }
        .frame(width: size.arcDiameter + 20, height: (size.arcDiameter + 20) / 2)
    }

    private func tickMark(at value: Int, isMajor: Bool) -> some View {
        let angle = valueToRotation(value)
        let length: CGFloat = isMajor ? size.majorTickLength : size.minorTickLength
        let width: CGFloat = isMajor ? 2 : 1

        return VStack {
            Rectangle()
                .fill(isMajor ? CosmicTheme.textSecondary : CosmicTheme.textMuted.opacity(0.5))
                .frame(width: width, height: length)
            Spacer()
        }
        .frame(height: size.arcDiameter / 2 + 10)
        .rotationEffect(.degrees(angle), anchor: .bottom)
    }

    // MARK: - Needle

    private var needle: some View {
        ZStack {
            // Needle shadow
            NeedleShape()
                .fill(Color.black.opacity(0.3))
                .frame(width: size.needleWidth + 2, height: size.needleHeight + 2)
                .offset(x: 1, y: 1)

            // Needle body
            NeedleShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size.needleWidth, height: size.needleHeight)

            // Center cap
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.95), Color(white: 0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.centerCapRadius
                    )
                )
                .frame(width: size.centerCapRadius * 2, height: size.centerCapRadius * 2)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .rotationEffect(.degrees(needleRotation), anchor: .bottom)
        .offset(y: -size.arcDiameter / 4 + size.centerCapRadius)
    }

    // MARK: - Center Display

    private var centerDisplay: some View {
        VStack(spacing: 2) {
            Spacer()

            // Large value
            Text(moodData.value == nil ? "N/A" : "\(Int(animatedValue))")
                .font(TerminalFont.price(size.valueFontSize))
                .foregroundColor(moodData.displayColor)
                .contentTransition(.numericText())

            // Change indicator
            if moodData.value == nil {
                Text(moodData.displayMode == .cosmicContextOnly ? "COSMIC ONLY" : "UNAVAILABLE")
                    .font(TerminalFont.data(size.changeFontSize, weight: .semibold))
                    .foregroundColor(moodData.displayColor)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: moodData.directionIcon)
                        .font(.system(size: size.changeFontSize))
                    Text(moodData.formattedChange)
                        .font(TerminalFont.data(size.changeFontSize))
                }
                .foregroundColor(moodData.isImproving ? CosmicTheme.positive : CosmicTheme.negative)
            }
        }
        .frame(height: size.arcDiameter / 2)
        .offset(y: size.arcDiameter / 6)
    }

    // MARK: - Mood Labels

    private var moodLabels: some View {
        VStack(spacing: 8) {
            // Cosmic mood name
            HStack(spacing: 8) {
                Image(systemName: moodData.displaySymbol)
                    .font(.title2)
                    .foregroundColor(moodData.displayColor)

                Text(moodData.moodLevel?.rawValue ?? moodData.label)
                    .font(TerminalFont.headline(size.moodNameFontSize))
                    .foregroundColor(moodData.displayColor)
            }

            // Traditional sentiment name
            Text(moodData.isMarketBacked ? (moodData.moodLevel?.sentimentName ?? moodData.label) : moodData.marketToneText)
                .font(TerminalFont.data(size.sentimentFontSize))
                .foregroundColor(CosmicTheme.textSecondary)

            // Cosmic description
            Text(moodData.displayDescription)
                .font(TerminalFont.body(size.descriptionFontSize))
                .foregroundColor(CosmicTheme.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

    /// Convert value (0-100) to rotation angle (-90 to +90)
    private func valueToRotation(_ value: Int) -> Double {
        // 0 = -90 degrees (left), 100 = +90 degrees (right)
        return Double(value) * 1.8 - 90
    }

    private var gaugeValue: Int {
        moodData.value ?? 50
    }

    /// Animate needle from 0 to current value
    private func animateNeedle() {
        animatedValue = 0
        needleRotation = -90

        withAnimation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.3)) {
            animatedValue = Double(gaugeValue)
            needleRotation = valueToRotation(gaugeValue)
        }
    }
}

// MARK: - Gauge Size

enum GaugeSize {
    case compact
    case medium
    case large

    var gaugeWidth: CGFloat {
        switch self {
        case .compact: return 160
        case .medium:  return 220
        case .large:   return 280
        }
    }

    var gaugeHeight: CGFloat {
        gaugeWidth / 2 + 40
    }

    var arcDiameter: CGFloat {
        switch self {
        case .compact: return 140
        case .medium:  return 190
        case .large:   return 240
        }
    }

    var arcWidth: CGFloat {
        switch self {
        case .compact: return 14
        case .medium:  return 18
        case .large:   return 22
        }
    }

    var needleWidth: CGFloat {
        switch self {
        case .compact: return 4
        case .medium:  return 5
        case .large:   return 6
        }
    }

    var needleHeight: CGFloat {
        switch self {
        case .compact: return 55
        case .medium:  return 75
        case .large:   return 95
        }
    }

    var centerCapRadius: CGFloat {
        switch self {
        case .compact: return 8
        case .medium:  return 10
        case .large:   return 12
        }
    }

    var majorTickLength: CGFloat {
        switch self {
        case .compact: return 8
        case .medium:  return 10
        case .large:   return 12
        }
    }

    var minorTickLength: CGFloat {
        switch self {
        case .compact: return 4
        case .medium:  return 6
        case .large:   return 8
        }
    }

    var valueFontSize: CGFloat {
        switch self {
        case .compact: return 28
        case .medium:  return 36
        case .large:   return 44
        }
    }

    var changeFontSize: CGFloat {
        switch self {
        case .compact: return 10
        case .medium:  return 12
        case .large:   return 14
        }
    }

    var moodNameFontSize: CGFloat {
        switch self {
        case .compact: return 16
        case .medium:  return 20
        case .large:   return 24
        }
    }

    var sentimentFontSize: CGFloat {
        switch self {
        case .compact: return 11
        case .medium:  return 13
        case .large:   return 14
        }
    }

    var descriptionFontSize: CGFloat {
        switch self {
        case .compact: return 10
        case .medium:  return 11
        case .large:   return 12
        }
    }

    var labelSpacing: CGFloat {
        switch self {
        case .compact: return 8
        case .medium:  return 12
        case .large:   return 16
        }
    }
}

// MARK: - Arc Shape

struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )

        return path
    }
}

// MARK: - Needle Shape

struct NeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Tapered needle pointing up
        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.85))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.85),
            control: CGPoint(x: width / 2, y: height)
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - Compact Mood Widget

/// Smaller widget for dashboard display
struct CosmicMoodWidget: View {

    let moodData: CosmicMoodData
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                // Mini gauge representation
                ZStack {
                    // Background circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    moodData.displayColor.opacity(0.3),
                                    moodData.displayColor.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)

                    // Value
                    VStack(spacing: 2) {
                        Text(moodData.value.map { String($0) } ?? "N/A")
                            .font(TerminalFont.price(22))
                            .foregroundColor(moodData.displayColor)

                        // Mini direction indicator
                        if moodData.value == nil {
                            Text(moodData.displayMode == .cosmicContextOnly ? "COSMIC" : "N/A")
                                .font(TerminalFont.data(8, weight: .semibold))
                                .foregroundColor(moodData.displayColor)
                        } else {
                            HStack(spacing: 2) {
                                Image(systemName: moodData.directionIcon)
                                    .font(.system(size: 8))
                                Text(moodData.formattedChange)
                                    .font(TerminalFont.data(8))
                            }
                            .foregroundColor(moodData.isImproving ? CosmicTheme.positive : CosmicTheme.negative)
                        }
                    }
                }

                // Labels
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cosmic Mood")
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textMuted)

                    HStack(spacing: 6) {
                        Image(systemName: moodData.displaySymbol)
                            .font(.system(size: 14))
                            .foregroundColor(moodData.displayColor)
                        Text(moodData.moodLevel?.rawValue ?? moodData.label)
                            .font(TerminalFont.headline(15))
                            .foregroundColor(moodData.displayColor)
                    }

                    Text(moodData.marketToneText)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(moodData.displayColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Cosmic Mood Gauge") {
    let service = CosmicMoodService.shared
    let moodData = service.getCurrentMood()

    return ScrollView {
        VStack(spacing: 32) {
            Text("COSMIC MOOD GAUGE")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            // Large gauge
            CosmicMoodGauge(moodData: moodData, size: .large)

            // Medium gauge
            CosmicMoodGauge(moodData: moodData, size: .medium)

            // Compact gauge
            CosmicMoodGauge(moodData: moodData, size: .compact)

            // Widget
            CosmicMoodWidget(moodData: moodData)
                .padding(.horizontal)
        }
        .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("All Mood Levels") {
    ScrollView(.horizontal) {
        HStack(spacing: 20) {
            ForEach([5, 30, 50, 70, 95], id: \.self) { value in
                VStack {
                    let mockData = CosmicMoodData(
                        date: Date(),
                        value: value,
                        factors: [],
                        change: Int.random(in: -10...10)
                    )
                    CosmicMoodGauge(moodData: mockData, size: .compact, animated: false)
                }
            }
        }
        .padding()
    }
    .background(CosmicTheme.background)
}
