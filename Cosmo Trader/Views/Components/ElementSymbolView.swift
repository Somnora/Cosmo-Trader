import SwiftUI

/// ElementSymbolView
/// -----------------
/// Classic alchemical element symbols as technical engineering diagrams.
/// Like symbols found on a vintage stock certificate or astronomical chart.
///
/// Design Specifications:
/// - Fire: Simple upward triangle (△)
/// - Earth: Downward triangle with horizontal line (▽̲)
/// - Air: Upward triangle with horizontal line (△̲)
/// - Water: Simple downward triangle (▽)
///
/// Design Philosophy:
/// - Single stroke weight: 1.5pt at standard size (20pt)
/// - Uses element-specific colors by default
/// - Scalable from 12pt to 48pt
/// - No fill, outline only
/// - Geometric and minimal - alchemical precision

struct ElementSymbolView: View {

    let element: ZodiacSign.Element
    var size: CGFloat = 20
    var color: Color? = nil
    var strokeWidth: CGFloat? = nil

    /// Default color based on element
    private var effectiveColor: Color {
        color ?? elementDefaultColor
    }

    private var elementDefaultColor: Color {
        switch element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    /// Computed stroke width based on size
    /// Standard: 1.5pt at 20pt size, scales proportionally
    private var effectiveStrokeWidth: CGFloat {
        strokeWidth ?? (size / 20.0) * 1.5
    }

    var body: some View {
        ElementSymbolShape(element: element)
            .stroke(effectiveColor, style: StrokeStyle(
                lineWidth: effectiveStrokeWidth,
                lineCap: .round,
                lineJoin: .round
            ))
            .frame(width: size, height: size)
    }
}

// MARK: - ElementSymbolShape

/// The Shape that draws each element symbol
struct ElementSymbolShape: Shape {
    let element: ZodiacSign.Element

    func path(in rect: CGRect) -> Path {
        switch element {
        case .fire:  return firePath(in: rect)
        case .earth: return earthPath(in: rect)
        case .air:   return airPath(in: rect)
        case .water: return waterPath(in: rect)
        }
    }

    // MARK: - Fire
    // Simple flame outline - upward pointing triangle

    private func firePath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Upward pointing triangle (alchemical fire symbol)
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.9))
        path.closeSubpath()

        return path
    }

    // MARK: - Earth
    // Downward triangle with horizontal line through it

    private func earthPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Downward pointing triangle
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.1))
        path.closeSubpath()

        // Horizontal line through the triangle
        path.move(to: CGPoint(x: w * 0.25, y: h * 0.4))
        path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.4))

        return path
    }

    // MARK: - Air
    // Upward triangle with horizontal line through it

    private func airPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Upward pointing triangle
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.9))
        path.closeSubpath()

        // Horizontal line through the triangle
        path.move(to: CGPoint(x: w * 0.25, y: h * 0.6))
        path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.6))

        return path
    }

    // MARK: - Water
    // Simple downward pointing triangle (▽) - alchemical water symbol

    private func waterPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Downward pointing triangle (same as Earth but without the line)
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.1))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview("All Element Symbols") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        VStack(spacing: 32) {
            Text("ELEMENT SYMBOLS")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            HStack(spacing: 40) {
                ForEach(ZodiacSign.Element.allCases) { element in
                    VStack(spacing: 12) {
                        ElementSymbolView(element: element, size: 40)

                        Text(element.displayName.uppercased())
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
            }

            Divider()
                .background(CosmicTheme.border)
                .padding(.horizontal, 40)

            Text("SIZE VARIANTS")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    ElementSymbolView(element: .fire, size: 16)
                    Text("16pt")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                VStack(spacing: 8) {
                    ElementSymbolView(element: .fire, size: 24)
                    Text("24pt")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                VStack(spacing: 8) {
                    ElementSymbolView(element: .fire, size: 32)
                    Text("32pt")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                VStack(spacing: 8) {
                    ElementSymbolView(element: .fire, size: 48)
                    Text("48pt")
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            Divider()
                .background(CosmicTheme.border)
                .padding(.horizontal, 40)

            Text("CUSTOM COLORS")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            HStack(spacing: 24) {
                ElementSymbolView(element: .water, size: 32, color: CosmicTheme.gold)
                ElementSymbolView(element: .fire, size: 32, color: CosmicTheme.accentBlue)
                ElementSymbolView(element: .earth, size: 32, color: CosmicTheme.textPrimary)
                ElementSymbolView(element: .air, size: 32, color: CosmicTheme.positive)
            }
        }
        .padding()
    }
}

#Preview("Elements with Signs") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        VStack(spacing: 20) {
            ForEach(ZodiacSign.Element.allCases) { element in
                HStack(spacing: 16) {
                    ElementSymbolView(element: element, size: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(element.displayName.uppercased())
                            .font(TerminalFont.data(12, weight: .semibold))
                            .foregroundColor(element.color)

                        HStack(spacing: 8) {
                            ForEach(element.signs) { sign in
                                ZodiacSymbolView(sign: sign, size: 20, color: CosmicTheme.textSecondary)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(16)
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
