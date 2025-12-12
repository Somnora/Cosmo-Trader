import SwiftUI

/// ZodiacGlyphView (ZodiacSymbolView)
/// ----------------------------------
/// Technical, precise glyphs like those found on astronomical charts
/// or vintage stock certificates. Engineering diagram aesthetic.
///
/// Design Specifications:
/// - Single stroke weight: 1.5pt at standard size (24pt)
/// - Default color: accentGold (#FFD700)
/// - Scalable from 12pt to 64pt
/// - No fill, outline only
/// - Geometric and minimal
///
/// Display contexts:
/// - Next to stock tickers: small (16pt)
/// - In detail views: medium (32pt)
/// - In profile/headers: large (48pt)
///
/// These should feel like symbols on a nautical chart or observatory diagram.
/// Professional. Timeless. Not cute.

struct ZodiacSymbolView: View {

    let sign: ZodiacSign
    var size: CGFloat = 24
    var color: Color = Color(hex: "FFD700") // accentGold - astronomical chart standard
    var strokeWidth: CGFloat? = nil

    /// Computed stroke width based on size
    /// Standard: 1.5pt at 24pt size, scales proportionally
    private var effectiveStrokeWidth: CGFloat {
        strokeWidth ?? (size / 24.0) * 1.5
    }

    var body: some View {
        ZodiacSymbolShape(sign: sign)
            .stroke(color, style: StrokeStyle(
                lineWidth: effectiveStrokeWidth,
                lineCap: .round,
                lineJoin: .round
            ))
            .frame(width: size, height: size)
    }
}

// MARK: - ZodiacSymbolShape

/// The Shape that draws each zodiac symbol
struct ZodiacSymbolShape: Shape {
    let sign: ZodiacSign

    func path(in rect: CGRect) -> Path {
        switch sign {
        case .aries:       return ariesPath(in: rect)
        case .taurus:      return taurusPath(in: rect)
        case .gemini:      return geminiPath(in: rect)
        case .cancer:      return cancerPath(in: rect)
        case .leo:         return leoPath(in: rect)
        case .virgo:       return virgoPath(in: rect)
        case .libra:       return libraPath(in: rect)
        case .scorpio:     return scorpioPath(in: rect)
        case .sagittarius: return sagittariusPath(in: rect)
        case .capricorn:   return capricornPath(in: rect)
        case .aquarius:    return aquariusPath(in: rect)
        case .pisces:      return piscesPath(in: rect)
        }
    }

    // MARK: - Aries ♈
    // Two curved ram horns

    private func ariesPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Left horn - curved line going up and curling
        path.move(to: CGPoint(x: w * 0.25, y: h * 0.85))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.15),
            control: CGPoint(x: w * 0.05, y: h * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.4),
            control: CGPoint(x: w * 0.55, y: h * 0.15)
        )

        // Right horn - mirror of left
        path.move(to: CGPoint(x: w * 0.75, y: h * 0.85))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.15),
            control: CGPoint(x: w * 0.95, y: h * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.4),
            control: CGPoint(x: w * 0.45, y: h * 0.15)
        )

        return path
    }

    // MARK: - Taurus ♉
    // Circle with horns on top

    private func taurusPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Circle (bottom portion)
        let circleRadius = w * 0.3
        let circleCenter = CGPoint(x: w * 0.5, y: h * 0.65)
        path.addArc(
            center: circleCenter,
            radius: circleRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )

        // Left horn
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.35))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.1, y: h * 0.1),
            control: CGPoint(x: w * 0.05, y: h * 0.25)
        )

        // Connecting arc across top
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.35))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.8, y: h * 0.35),
            control: CGPoint(x: w * 0.5, y: h * 0.45)
        )

        // Right horn
        path.move(to: CGPoint(x: w * 0.8, y: h * 0.35))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.9, y: h * 0.1),
            control: CGPoint(x: w * 0.95, y: h * 0.25)
        )

        return path
    }

    // MARK: - Gemini ♊
    // Roman numeral II shape with connecting lines

    private func geminiPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Top horizontal line
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.15))

        // Bottom horizontal line
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.85))

        // Left vertical pillar
        path.move(to: CGPoint(x: w * 0.3, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.85))

        // Right vertical pillar
        path.move(to: CGPoint(x: w * 0.7, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.85))

        return path
    }

    // MARK: - Cancer ♋
    // Two curved shapes (like 69 rotated)

    private func cancerPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Top curl (like a 6)
        path.addArc(
            center: CGPoint(x: w * 0.35, y: h * 0.35),
            radius: w * 0.15,
            startAngle: .degrees(90),
            endAngle: .degrees(-180),
            clockwise: true
        )
        path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.8, y: h * 0.35),
            control: CGPoint(x: w * 0.5, y: h * 0.55)
        )

        // Bottom curl (like a 9, inverted)
        path.move(to: CGPoint(x: w * 0.8, y: h * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.2, y: h * 0.65),
            control: CGPoint(x: w * 0.5, y: h * 0.45)
        )
        path.addArc(
            center: CGPoint(x: w * 0.65, y: h * 0.65),
            radius: w * 0.15,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: true
        )
        path.addArc(
            center: CGPoint(x: w * 0.65, y: h * 0.65),
            radius: w * 0.15,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        return path
    }

    // MARK: - Leo ♌
    // Curved swoosh with circle

    private func leoPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Small circle at top left
        path.addArc(
            center: CGPoint(x: w * 0.25, y: h * 0.25),
            radius: w * 0.12,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )

        // Main swooping curve
        path.move(to: CGPoint(x: w * 0.37, y: h * 0.25))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.55),
            control: CGPoint(x: w * 0.7, y: h * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.3, y: h * 0.75),
            control: CGPoint(x: w * 0.2, y: h * 0.6)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.85),
            control: CGPoint(x: w * 0.5, y: h * 0.95)
        )

        return path
    }

    // MARK: - Virgo ♍
    // M with curved tail

    private func virgoPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // First vertical of M
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.8))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.2))

        // First hump
        path.addQuadCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.5),
            control: CGPoint(x: w * 0.25, y: h * 0.15)
        )

        // Second hump
        path.addQuadCurve(
            to: CGPoint(x: w * 0.6, y: h * 0.2),
            control: CGPoint(x: w * 0.35, y: h * 0.15)
        )

        // Third section going down with curved tail
        path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.7))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.9, y: h * 0.9),
            control: CGPoint(x: w * 0.6, y: h * 0.95)
        )

        // Cross stroke on tail
        path.move(to: CGPoint(x: w * 0.7, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.65))

        return path
    }

    // MARK: - Libra ♎
    // Omega/scale shape over horizontal line

    private func libraPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Top curve (omega-like)
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.15),
            control: CGPoint(x: w * 0.15, y: h * 0.15)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.5),
            control: CGPoint(x: w * 0.85, y: h * 0.15)
        )

        // Bottom horizontal line
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.7))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.7))

        // Base line
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.85))

        return path
    }

    // MARK: - Scorpio ♏
    // M with arrow tail

    private func scorpioPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // First vertical of M
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.8))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.2))

        // First hump
        path.addQuadCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.5),
            control: CGPoint(x: w * 0.25, y: h * 0.15)
        )

        // Second hump
        path.addQuadCurve(
            to: CGPoint(x: w * 0.6, y: h * 0.2),
            control: CGPoint(x: w * 0.35, y: h * 0.15)
        )

        // Third section going down with arrow tail
        path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.55))

        // Arrow head
        path.move(to: CGPoint(x: w * 0.9, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.5))
        path.move(to: CGPoint(x: w * 0.9, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.68))

        return path
    }

    // MARK: - Sagittarius ♐
    // Arrow pointing diagonal

    private func sagittariusPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Main arrow shaft (diagonal)
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.15))

        // Arrow head
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.15))
        path.move(to: CGPoint(x: w * 0.85, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.45))

        // Cross bar
        path.move(to: CGPoint(x: w * 0.3, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.5))

        return path
    }

    // MARK: - Capricorn ♑
    // V with curved tail

    private func capricornPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Top loop
        path.addArc(
            center: CGPoint(x: w * 0.3, y: h * 0.25),
            radius: w * 0.15,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        // V shape going down
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.7))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.5),
            control: CGPoint(x: w * 0.15, y: h * 0.85)
        )

        // Right side with curled tail
        path.move(to: CGPoint(x: w * 0.45, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.75),
            control: CGPoint(x: w * 0.65, y: h * 0.5)
        )
        path.addArc(
            center: CGPoint(x: w * 0.75, y: h * 0.75),
            radius: w * 0.1,
            startAngle: .degrees(0),
            endAngle: .degrees(270),
            clockwise: true
        )

        return path
    }

    // MARK: - Aquarius ♒
    // Two parallel wavy lines

    private func aquariusPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Top wavy line
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.35))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.3, y: h * 0.35),
            control: CGPoint(x: w * 0.2, y: h * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.35),
            control: CGPoint(x: w * 0.4, y: h * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.35),
            control: CGPoint(x: w * 0.6, y: h * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.9, y: h * 0.35),
            control: CGPoint(x: w * 0.8, y: h * 0.5)
        )

        // Bottom wavy line
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.65))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.3, y: h * 0.65),
            control: CGPoint(x: w * 0.2, y: h * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.65),
            control: CGPoint(x: w * 0.4, y: h * 0.8)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.65),
            control: CGPoint(x: w * 0.6, y: h * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.9, y: h * 0.65),
            control: CGPoint(x: w * 0.8, y: h * 0.8)
        )

        return path
    }

    // MARK: - Pisces ♓
    // Two curved lines with vertical bar

    private func piscesPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Left curved line (like a backwards C)
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.15))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.85),
            control: CGPoint(x: w * 0.05, y: h * 0.5)
        )

        // Right curved line (like a C)
        path.move(to: CGPoint(x: w * 0.65, y: h * 0.15))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.85),
            control: CGPoint(x: w * 0.95, y: h * 0.5)
        )

        // Horizontal connecting bar
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.5))

        return path
    }
}

// MARK: - Preview

#Preview("All Zodiac Symbols - Grid") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
            ForEach(ZodiacSign.allCases) { sign in
                VStack(spacing: 8) {
                    ZodiacSymbolView(sign: sign, size: 40)

                    Text(sign.displayName)
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .frame(width: 80, height: 80)
                .background(CosmicTheme.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(CosmicTheme.border, lineWidth: 0.5)
                )
            }
        }
        .padding()
    }
}

#Preview("Symbol Sizes") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        VStack(spacing: 24) {
            Text("SIZE COMPARISON")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            HStack(spacing: 32) {
                VStack {
                    ZodiacSymbolView(sign: .leo, size: 16)
                    Text("16pt")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                VStack {
                    ZodiacSymbolView(sign: .leo, size: 24)
                    Text("24pt")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                VStack {
                    ZodiacSymbolView(sign: .leo, size: 40)
                    Text("40pt")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                VStack {
                    ZodiacSymbolView(sign: .leo, size: 64)
                    Text("64pt")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            Divider()
                .background(CosmicTheme.border)

            Text("COLOR VARIANTS")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            HStack(spacing: 24) {
                ZodiacSymbolView(sign: .aries, size: 40, color: CosmicTheme.gold)
                ZodiacSymbolView(sign: .taurus, size: 40, color: CosmicTheme.earthElement)
                ZodiacSymbolView(sign: .gemini, size: 40, color: CosmicTheme.airElement)
                ZodiacSymbolView(sign: .cancer, size: 40, color: CosmicTheme.waterElement)
                ZodiacSymbolView(sign: .leo, size: 40, color: CosmicTheme.fireElement)
            }
        }
        .padding()
    }
}

#Preview("All Signs Large") {
    ScrollView {
        ZStack {
            CosmicTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                ForEach(ZodiacSign.allCases) { sign in
                    HStack(spacing: 16) {
                        ZodiacSymbolView(sign: sign, size: 48)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(sign.displayName)
                                .font(TerminalFont.headline(16))
                                .foregroundColor(CosmicTheme.textPrimary)

                            Text(sign.dateRangeDescription)
                                .font(TerminalFont.data(12))
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()

                        Text(sign.element.displayName)
                            .font(TerminalFont.data(11))
                            .foregroundColor(sign.element.color)
                    }
                    .padding(12)
                    .background(CosmicTheme.cardBackground)
                    .overlay(
                        Rectangle()
                            .stroke(CosmicTheme.border, lineWidth: 0.5)
                    )
                }
            }
            .padding()
        }
    }
    .background(CosmicTheme.background)
}
