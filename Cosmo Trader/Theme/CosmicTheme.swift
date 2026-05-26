import SwiftUI

/// CosmicTheme
/// -----------
/// Bloomberg Terminal aesthetic. No frills. Just data.
/// If it looks "designed" it's wrong. If it looks like banking software from 2008, it's right.

struct CosmicTheme {

    // MARK: - Backgrounds
    // True black. Nothing else.

    /// Primary background - TRUE BLACK
    static let background = Color(hex: "000000")

    /// Terminal black (alias)
    static let terminalBlack = Color(hex: "000000")

    /// Surface - barely visible lift for sections
    static let cardBackground = Color(hex: "0A0A0A")

    /// Secondary surfaces
    static let secondaryBackground = Color(hex: "0A0A0A")

    /// Tertiary - same as secondary, no hierarchy needed
    static let tertiaryBackground = Color(hex: "0A0A0A")

    /// Panel - slightly elevated dark surface for layering
    static let panelElevated = Color(hex: "0E0F11")

    /// Panel - dark navy emphasis (primary cockpit panels)
    static let panelNavy = Color(hex: "081627")

    /// Panel - brighter navy callout (secondary signal panels)
    static let panelSteel = Color(hex: "0C2238")

    /// Panel - muted gold callout backdrop
    static let panelGold = Color(hex: "151005")

    // MARK: - Borders
    // Thin 1px lines only. No shadows.

    /// Standard border - thin gray line
    static let border = Color(hex: "242629")

    /// Dim border (alias)
    static let borderDim = Color(hex: "1F2123")

    /// Slightly stronger border for emphasis
    static let borderStrong = Color(hex: "33363B")

    /// Navy hairline for emphasis panels
    static let borderNavy = Color(hex: "1F3957")

    /// Gold hairline for callouts
    static let borderGold = Color(hex: "3A2B0A")

    /// Divider lines
    static let divider = Color(hex: "1A1A1A")

    /// Grid lines
    static let gridLine = Color(hex: "1A1A1A")

    // MARK: - Market Colors
    // Classic terminal green/red. Nothing fancy.

    /// Gains - TERMINAL GREEN
    static let positive = Color(hex: "00FF00")

    /// Losses - RED
    static let negative = Color(hex: "FF3333")

    /// Alert red
    static let alertRed = Color(hex: "FF3333")

    /// Neutral/unchanged
    static let neutral = Color(hex: "666666")

    /// Terminal Green (alias)
    static let terminalGreen = Color(hex: "00FF00")

    // MARK: - Accent Colors

    /// Gold - MUTED, not bright
    static let gold = Color(hex: "AA8800")

    /// Soft gold (alias)
    static let softGold = Color(hex: "AA8800")

    /// Dim gold for backgrounds
    static let dimGold = Color(hex: "1A1500")

    /// Blue accents - dark terminal navy, not AI-purple space wash
    static let cosmicBlue = Color(hex: "071A2F")
    static let deepBlue = Color(hex: "04111F")
    static let accentBlue = Color(hex: "336699")
    static let terminalNavy = Color(hex: "071A2F")
    static let steelBlue = Color(hex: "5A7790")

    // MARK: - Text Colors
    // Tuned for practical readability on OLED dark panels while preserving
    // the muted terminal feel. Body and label tones lifted from the
    // earlier passes where they were too close to background grey.

    /// Primary text - bright but not pure white
    static let textPrimary = Color(hex: "E6E6E6")

    /// Secondary text - body copy on dark panels
    static let textSecondary = Color(hex: "9CA0A6")

    /// Muted text - hints, timestamps, captions
    static let textMuted = Color(hex: "6E737A")

    /// Disabled text
    static let textDisabled = Color(hex: "3A3D42")

    // MARK: - Tab Bar / Layout

    /// Clearance below scrollable content so it never sits beneath the
    /// floating system tab bar. Covers a 49pt tab bar + worst-case home
    /// indicator inset plus a small breathing room.
    static let tabBarClearance: CGFloat = 120

    // MARK: - Legacy Aliases

    static let cosmicPurple = Color(hex: "071A2F")  // Legacy alias: use dark navy, never purple.
    static let nebulaBlue = Color(hex: "0B223D")    // Legacy alias: deep terminal blue, not neon.

    // MARK: - Gradients (FLAT - no actual gradients)

    /// No gradient - flat color
    static let cosmicGradient = LinearGradient(
        colors: [background, background],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Gold "gradient" - flat
    static let goldGradient = LinearGradient(
        colors: [gold, gold],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Terminal gradient - flat black
    static let terminalGradient = LinearGradient(
        colors: [background, background],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Terminal green - flat
    static let terminalGreenGradient = LinearGradient(
        colors: [terminalGreen, terminalGreen],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Card gradient - flat
    static let cardGradient = LinearGradient(
        colors: [cardBackground, cardBackground],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Element Colors (Zodiac)
    // Muted. Not playful.

    static let fireElement = Color(hex: "AA4400")    // Muted orange
    static let earthElement = Color(hex: "558855")   // Muted green
    static let airElement = Color(hex: "AA8800")     // Same as gold
    static let waterElement = Color(hex: "446688")   // Steel blue

    // MARK: - Helpers

    static func withOpacity(_ color: Color, _ opacity: Double) -> Color {
        color.opacity(opacity)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography

struct TerminalFont {
    /// Monospace for ALL numbers and prices
    static func price(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Data display - monospaced
    static func data(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Labels - system, uppercase in usage
    static func label(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Headlines - no bold unless primary value
    static func headline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    /// Body text
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Ticker symbols - monospace
    static func ticker(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    /// Terminal readout
    static func readout(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }

    /// Timestamp
    static func timestamp(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }

    /// Caption
    static func caption(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Terminal Panel Styling
// Adds tasteful dimensionality to cards via tinted dark surfaces with
// hairline strokes. Keeps the OLED black background dominant; panels
// only lift slightly so the eye can read hierarchy without losing the
// terminal feel.

enum TerminalPanelEmphasis {
    /// Standard near-black card surface
    case standard
    /// Slightly lifted neutral surface for secondary blocks
    case elevated
    /// Dark navy emphasis - primary cockpit/control panels
    case navy
    /// Brighter navy/steel - secondary signal panels
    case steel
    /// Muted gold callout backdrop (use sparingly)
    case gold

    var fill: Color {
        switch self {
        case .standard: return CosmicTheme.cardBackground
        case .elevated: return CosmicTheme.panelElevated
        case .navy:     return CosmicTheme.panelNavy
        case .steel:    return CosmicTheme.panelSteel
        case .gold:     return CosmicTheme.panelGold
        }
    }

    var stroke: Color {
        switch self {
        case .standard: return CosmicTheme.border
        case .elevated: return CosmicTheme.borderStrong
        case .navy:     return CosmicTheme.borderNavy
        case .steel:    return CosmicTheme.borderNavy
        case .gold:     return CosmicTheme.borderGold
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Terminal panel with tinted background and hairline stroke. Sharp
    /// corners by default; pass a small cornerRadius for subtly rounded
    /// settings cards.
    func terminalPanel(
        _ emphasis: TerminalPanelEmphasis = .standard,
        cornerRadius: CGFloat = 0,
        strokeWidth: CGFloat = 1
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(emphasis.fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(emphasis.stroke, lineWidth: strokeWidth)
            )
    }

    /// Terminal style - NO rounded corners, 1px border
    func terminalCard() -> some View {
        self
            .background(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 1)
            )
    }

    /// Terminal button - sharp corners
    func terminalButton() -> some View {
        self
            .background(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 1)
            )
    }

    /// Price styling
    func priceStyle(size: CGFloat = 16, positive: Bool? = nil) -> some View {
        self
            .font(TerminalFont.price(size))
            .foregroundColor(
                positive == nil ? CosmicTheme.textPrimary :
                positive! ? CosmicTheme.positive : CosmicTheme.negative
            )
    }

    /// 1px border
    func subtleBorder(_ color: Color = CosmicTheme.border) -> some View {
        self.overlay(
            Rectangle()
                .stroke(color, lineWidth: 1)
        )
    }

    /// NO glow effect - just return self
    func terminalGlow(_ color: Color = CosmicTheme.terminalGreen) -> some View {
        self // No glow. Data doesn't glow.
    }

    /// Flat black background
    func voidBackground(gradient: Bool = false) -> some View {
        self.background(CosmicTheme.background)
    }

    /// Adds breathing room below scrollable tab content so it never
    /// sits flush against — or beneath — the system tab bar. Apply once
    /// at the ScrollView/List level. Use `extra` to fine-tune.
    func tabBarSafeBottomPadding(extra: CGFloat = 0) -> some View {
        self.safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: CosmicTheme.tabBarClearance + extra)
        }
    }

    /// NO scanlines - too decorative
    func scanlines(opacity: Double = 0.03) -> some View {
        self // No scanlines.
    }
}

// MARK: - Terminal Background (Flat Black)

struct VoidBackground: View {
    var showScanlines: Bool = false
    var scanlineOpacity: Double = 0.02

    var body: some View {
        CosmicTheme.background
            .ignoresSafeArea()
    }
}

/// NO scanlines
struct TerminalScanlines: View {
    var opacity: Double = 0.03

    var body: some View {
        Color.clear // Removed. Too decorative.
    }
}

/// NO vignette
struct VignetteOverlay: View {
    var intensity: Double = 0.5

    var body: some View {
        Color.clear // Removed. Too decorative.
    }
}

// MARK: - Preview

#Preview("Terminal Theme") {
    ScrollView {
        VStack(spacing: 0) {
            Text("──── TERMINAL THEME ────")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            // Colors
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("+2.45%")
                        .font(TerminalFont.price(16))
                        .foregroundColor(CosmicTheme.positive)
                    Text("GAIN")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 1)

                VStack(spacing: 4) {
                    Text("-1.23%")
                        .font(TerminalFont.price(16))
                        .foregroundColor(CosmicTheme.negative)
                    Text("LOSS")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 1)

                VStack(spacing: 4) {
                    Text("0.00%")
                        .font(TerminalFont.price(16))
                        .foregroundColor(CosmicTheme.neutral)
                    Text("FLAT")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            // Sample row
            HStack(spacing: 8) {
                Text("AAPL")
                    .font(TerminalFont.ticker(12))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .frame(width: 50, alignment: .leading)

                Text("Apple Inc.")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(1)

                Spacer()

                Text("$178.52")
                    .font(TerminalFont.price(12))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("+1.33%")
                    .font(TerminalFont.price(12))
                    .foregroundColor(CosmicTheme.positive)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)
        }
    }
    .background(CosmicTheme.background)
}
