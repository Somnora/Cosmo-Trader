import SwiftUI

// MARK: - Moon Phase View
// ========================
// Visual component showing the current moon phase with custom drawing.
// Includes phase name, illumination, and trading signal summary.

struct MoonPhaseView: View {

    // MARK: - Properties

    let lunarData: LunarData
    var size: MoonSize = .medium
    var showDetails: Bool = true
    var showSignal: Bool = true

    // MARK: - Body

    var body: some View {
        HStack(spacing: size.spacing) {
            // Custom drawn moon
            MoonVisual(
                illumination: lunarData.illumination,
                isWaxing: lunarData.isWaxing,
                size: size.moonSize
            )

            if showDetails {
                VStack(alignment: .leading, spacing: 4) {
                    // Phase name
                    Text(lunarData.phase.rawValue)
                        .font(TerminalFont.headline(size.titleSize))
                        .foregroundColor(CosmicTheme.textPrimary)

                    // Illumination
                    Text("\(lunarData.formattedIllumination) illuminated")
                        .font(TerminalFont.data(size.subtitleSize))
                        .foregroundColor(CosmicTheme.textSecondary)

                    if showSignal {
                        // Trading signal badge
                        HStack(spacing: 4) {
                            Image(systemName: lunarData.phase.tradingSignal.type.icon)
                                .font(.system(size: size.iconSize))

                            Text(lunarData.phase.tradingSignal.headline)
                                .font(TerminalFont.data(size.badgeSize))
                        }
                        .foregroundColor(lunarData.phase.tradingSignal.type.color)
                    }
                }
            }
        }
    }
}

// MARK: - Moon Size Preset

enum MoonSize {
    case small
    case medium
    case large
    case hero

    var moonSize: CGFloat {
        switch self {
        case .small:  return 32
        case .medium: return 48
        case .large:  return 64
        case .hero:   return 100
        }
    }

    var titleSize: CGFloat {
        switch self {
        case .small:  return 12
        case .medium: return 14
        case .large:  return 18
        case .hero:   return 24
        }
    }

    var subtitleSize: CGFloat {
        switch self {
        case .small:  return 10
        case .medium: return 11
        case .large:  return 13
        case .hero:   return 16
        }
    }

    var badgeSize: CGFloat {
        switch self {
        case .small:  return 9
        case .medium: return 10
        case .large:  return 12
        case .hero:   return 14
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small:  return 8
        case .medium: return 10
        case .large:  return 12
        case .hero:   return 16
        }
    }

    var spacing: CGFloat {
        switch self {
        case .small:  return 8
        case .medium: return 12
        case .large:  return 16
        case .hero:   return 20
        }
    }
}

// MARK: - Moon Visual (Custom Drawn)

struct MoonVisual: View {

    let illumination: Double
    let isWaxing: Bool
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2 - 2

            // Draw base moon (dark side)
            let moonPath = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.fill(moonPath, with: .color(Color(white: 0.15)))

            // Draw illuminated portion
            if illumination > 0.01 {
                let illuminatedPath = createIlluminatedPath(
                    center: center,
                    radius: radius,
                    illumination: illumination,
                    isWaxing: isWaxing
                )
                context.fill(illuminatedPath, with: .linearGradient(
                    Gradient(colors: [
                        Color(white: 0.95),
                        Color(white: 0.85)
                    ]),
                    startPoint: isWaxing ? CGPoint(x: 0, y: 0) : CGPoint(x: canvasSize.width, y: 0),
                    endPoint: isWaxing ? CGPoint(x: canvasSize.width, y: canvasSize.height) : CGPoint(x: 0, y: canvasSize.height)
                ))
            }

            // Draw crater details (subtle)
            drawCraters(context: context, center: center, radius: radius)

            // Draw outer glow
            let glowPath = Path(ellipseIn: CGRect(
                x: center.x - radius - 2,
                y: center.y - radius - 2,
                width: (radius + 2) * 2,
                height: (radius + 2) * 2
            ))
            context.stroke(glowPath, with: .color(Color.white.opacity(0.2)), lineWidth: 1)
        }
        .frame(width: size, height: size)
    }

    private func createIlluminatedPath(center: CGPoint, radius: CGFloat, illumination: Double, isWaxing: Bool) -> Path {
        var path = Path()

        // Calculate the terminator (shadow line) position
        // illumination 0 = new moon (all dark)
        // illumination 0.5 = quarter moon (half lit)
        // illumination 1 = full moon (all lit)

        let terminatorOffset = (illumination - 0.5) * 2 * radius

        if illumination <= 0.5 {
            // Crescent phase - draw a crescent
            let startAngle: Double = isWaxing ? -90 : 90
            let endAngle: Double = isWaxing ? 90 : -90

            // Outer arc (full circle edge)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: !isWaxing
            )

            // Inner arc (terminator - elliptical)
            let innerRadius = abs(terminatorOffset)
            if innerRadius > 0.1 {
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(endAngle),
                    endAngle: .degrees(startAngle),
                    clockwise: isWaxing
                )
            }

        } else {
            // Gibbous phase - draw more than half
            let startAngle: Double = isWaxing ? -90 : 90
            let endAngle: Double = isWaxing ? 90 : -90

            // Full half circle
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: !isWaxing
            )

            // Add the bulging part
            let bulgeFactor = (illumination - 0.5) * 2
            let controlOffset = radius * bulgeFactor

            // Reference points for potential bezier curve refinement
            _ = CGPoint(
                x: center.x + (isWaxing ? -radius : radius) * cos(.pi / 2),
                y: center.y - radius
            )
            _ = CGPoint(
                x: center.x + (isWaxing ? -radius : radius) * cos(.pi / 2),
                y: center.y + radius
            )
            let controlPoint = CGPoint(
                x: center.x + (isWaxing ? controlOffset : -controlOffset),
                y: center.y
            )

            path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - radius), control: controlPoint)
        }

        path.closeSubpath()
        return path
    }

    private func drawCraters(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Add subtle crater details
        let craterPositions: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
            (-0.2, -0.3, 0.08),
            (0.1, 0.2, 0.06),
            (-0.3, 0.1, 0.05),
            (0.25, -0.15, 0.04),
            (0.0, 0.35, 0.07)
        ]

        for crater in craterPositions {
            let craterCenter = CGPoint(
                x: center.x + crater.x * radius,
                y: center.y + crater.y * radius
            )
            let craterRadius = crater.r * radius

            let craterPath = Path(ellipseIn: CGRect(
                x: craterCenter.x - craterRadius,
                y: craterCenter.y - craterRadius,
                width: craterRadius * 2,
                height: craterRadius * 2
            ))
            context.fill(craterPath, with: .color(Color.black.opacity(0.1)))
        }
    }
}

// MARK: - Compact Moon Badge

struct MoonPhaseBadge: View {

    let lunarData: LunarData

    var body: some View {
        HStack(spacing: 6) {
            MoonVisual(
                illumination: lunarData.illumination,
                isWaxing: lunarData.isWaxing,
                size: 20
            )

            Text(lunarData.phase.rawValue)
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    Capsule()
                        .stroke(CosmicTheme.border, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Moon Phase Card

struct MoonPhaseCard: View {

    let lunarData: LunarData
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: 16) {
                // Moon visual with glow
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    lunarData.phase.color.opacity(0.3),
                                    lunarData.phase.color.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)

                    MoonVisual(
                        illumination: lunarData.illumination,
                        isWaxing: lunarData.isWaxing,
                        size: 80
                    )
                }

                // Phase info
                VStack(spacing: 6) {
                    Text(lunarData.phase.rawValue)
                        .font(TerminalFont.headline(18))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(lunarData.formattedIllumination + " illuminated")
                        .font(TerminalFont.data(12))
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                // Trading signal
                HStack(spacing: 6) {
                    Image(systemName: lunarData.phase.tradingSignal.type.icon)
                        .font(.system(size: 14))

                    Text(lunarData.phase.tradingSignal.headline)
                        .font(TerminalFont.data(12, weight: .semibold))
                }
                .foregroundColor(lunarData.phase.tradingSignal.type.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(lunarData.phase.tradingSignal.type.color.opacity(0.15))
                )

                // Moon sign
                HStack(spacing: 6) {
                    Text("Moon in")
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textMuted)

                    ZodiacSymbolView(sign: lunarData.moonSign, size: 16, color: elementColor)

                    Text(lunarData.moonSign.displayName)
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(elementColor)
                }

                // Next significant phase
                HStack(spacing: 12) {
                    nextPhaseIndicator(
                        label: "Full Moon",
                        days: lunarData.daysUntilFullMoon,
                        icon: "circle.fill"
                    )

                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(width: 0.5, height: 24)

                    nextPhaseIndicator(
                        label: "New Moon",
                        days: lunarData.daysUntilNewMoon,
                        icon: "circle"
                    )
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(CosmicTheme.border, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func nextPhaseIndicator(label: String, days: Int, icon: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 16))

            Text("\(days)d")
                .font(TerminalFont.price(14))
                .foregroundColor(CosmicTheme.textPrimary)

            Text(label)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
        }
    }

    private var elementColor: Color {
        switch lunarData.moonSign.element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }
}

// MARK: - Moon Phase Timeline

struct MoonPhaseTimeline: View {

    let entries: [MoonPhaseCalendarEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UPCOMING PHASES")
                .font(TerminalFont.data(11, weight: .semibold))
                .foregroundColor(CosmicTheme.textSecondary)

            HStack(spacing: 0) {
                ForEach(entries) { entry in
                    phaseEntry(entry)

                    if entry.id != entries.last?.id {
                        Rectangle()
                            .fill(CosmicTheme.border)
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CosmicTheme.secondaryBackground)
        )
    }

    private func phaseEntry(_ entry: MoonPhaseCalendarEntry) -> some View {
        VStack(spacing: 6) {
            entry.phase.sfImage
                .font(.system(size: 24))
                .foregroundColor(entry.phase.color)

            Text(entry.formattedDate)
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(entry.isToday ? CosmicTheme.gold : CosmicTheme.textPrimary)

            Text(entry.dayOfWeek)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Moon Phase Views") {
    let service = MoonPhaseService.shared
    let data = service.getCurrentLunarData()

    return ScrollView {
        VStack(spacing: 24) {
            Text("MOON PHASE COMPONENTS")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            // Badge
            MoonPhaseBadge(lunarData: data)

            // Small
            MoonPhaseView(lunarData: data, size: .small)
                .padding()
                .background(CosmicTheme.cardBackground)

            // Medium
            MoonPhaseView(lunarData: data, size: .medium)
                .padding()
                .background(CosmicTheme.cardBackground)

            // Large
            MoonPhaseView(lunarData: data, size: .large)
                .padding()
                .background(CosmicTheme.cardBackground)

            // Card
            MoonPhaseCard(lunarData: data)

            // Timeline
            MoonPhaseTimeline(entries: service.getUpcomingSignificantPhases())
        }
        .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("Moon Phases") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach([0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0], id: \.self) { illumination in
                VStack {
                    MoonVisual(
                        illumination: illumination,
                        isWaxing: illumination <= 0.5,
                        size: 60
                    )
                    Text("\(Int(illumination * 100))%")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
        .padding()
    }
    .background(CosmicTheme.background)
}
