import SwiftUI

/// CosmicTheme
/// -----------
/// NYSE trading floor meets planetarium.
/// Bloomberg Terminal sophistication with subtle cosmic elements.
///
/// Design Philosophy:
/// - Data-dense, grid-based layouts
/// - Monospace numbers like a trading terminal
/// - Sharp corners for data, rounded for interactive elements
/// - Subtle borders instead of heavy shadows
/// - The cosmos as data, not decoration

struct CosmicTheme {

    // MARK: - Terminal Backgrounds
    // Deep Void Black - Bloomberg Terminal meets Planetarium

    /// Primary background - Deep Void Black
    static let background = Color(hex: "050505")

    /// Card/surface background - Dark Gray
    static let cardBackground = Color(hex: "1A1A1A")

    /// Secondary surfaces - for nested elements
    static let secondaryBackground = Color(hex: "111111")

    /// Tertiary - hover states, highlights
    static let tertiaryBackground = Color(hex: "1F1F1F")

    // MARK: - Border & Divider Colors

    /// Standard border color
    static let border = Color(hex: "2D2D2D")

    /// Subtle divider lines
    static let divider = Color(hex: "252525")

    /// Grid lines (very subtle)
    static let gridLine = Color(hex: "1F1F1F")

    // MARK: - Market Colors
    // Classic trading terminal green/red

    /// Gains, bullish, positive - Terminal Green
    static let positive = Color(hex: "00FF41")

    /// Losses, bearish, negative - Bearish Red
    static let negative = Color(hex: "FF3B30")

    /// Neutral/unchanged
    static let neutral = Color(hex: "888888")

    /// Terminal Green accent for data highlights
    static let terminalGreen = Color(hex: "00FF41")

    // MARK: - Accent Colors

    /// Starlight Gold - premium feel, highlights, zodiac elements
    static let gold = Color(hex: "D4AF37")

    /// Soft gold for secondary accents
    static let softGold = Color(hex: "B8962E")

    /// Dim gold for subtle backgrounds
    static let dimGold = Color(hex: "3D3220")

    /// Deep space blue - subtle accent for cosmic elements
    static let cosmicBlue = Color(hex: "0A1628")

    /// Deep blue for gradients
    static let deepBlue = Color(hex: "0A1220")

    /// Steel blue for interactive highlights (no purple)
    static let accentBlue = Color(hex: "2D5A8A")

    // MARK: - Text Colors

    /// Primary text - bright but not harsh white
    static let textPrimary = Color(hex: "E8E8E8")

    /// Secondary text - dimmed
    static let textSecondary = Color(hex: "A0A0A0")

    /// Muted text - hints, timestamps
    static let textMuted = Color(hex: "666666")

    /// Disabled text
    static let textDisabled = Color(hex: "444444")

    // MARK: - Legacy Aliases (for compatibility)

    static let cosmicPurple = cosmicBlue  // Redirect purple to blue
    static let nebulaBlue = deepBlue

    // MARK: - Gradients

    /// Subtle blue gradient for special headers
    static let cosmicGradient = LinearGradient(
        colors: [cosmicBlue, deepBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gold gradient for premium elements
    static let goldGradient = LinearGradient(
        colors: [gold, softGold],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Terminal gradient - subtle fade for backgrounds
    static let terminalGradient = LinearGradient(
        colors: [background, Color(hex: "020202")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Terminal green glow gradient
    static let terminalGreenGradient = LinearGradient(
        colors: [terminalGreen.opacity(0.8), terminalGreen.opacity(0.4)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Data card gradient - very subtle
    static let cardGradient = LinearGradient(
        colors: [cardBackground, Color(hex: "151515")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Element Colors (Zodiac)
    // Muted, sophisticated versions

    static let fireElement = Color(hex: "C94D38")    // Muted red-orange
    static let earthElement = Color(hex: "4A7C4E")   // Forest green
    static let airElement = Color(hex: "C4A84B")     // Muted gold
    static let waterElement = Color(hex: "3A6B8C")   // Steel blue

    // MARK: - Opacity Helpers

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
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
    /// Monospace font for prices and numbers - Bloomberg Terminal style
    static func price(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Data display font - monospaced for alignment
    static func data(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Label font (default system for readability)
    static func label(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Headline with slight tracking
    static func headline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    /// Body text for longer content
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Ticker symbol font - bold monospace for stock symbols
    static func ticker(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }

    /// Terminal readout - like green phosphor display
    static func readout(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    /// Timestamp font - subtle monospace
    static func timestamp(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply terminal card style with sharp corners
    func terminalCard() -> some View {
        self
            .background(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
    }

    /// Apply terminal card with subtle rounded corners (for buttons)
    func terminalButton() -> some View {
        self
            .background(CosmicTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
    }

    /// Price text styling
    func priceStyle(size: CGFloat = 16, positive: Bool? = nil) -> some View {
        self
            .font(TerminalFont.price(size))
            .foregroundColor(
                positive == nil ? CosmicTheme.textPrimary :
                positive! ? CosmicTheme.positive : CosmicTheme.negative
            )
    }

    /// Subtle border
    func subtleBorder(_ color: Color = CosmicTheme.border) -> some View {
        self.overlay(
            Rectangle()
                .stroke(color, lineWidth: 0.5)
        )
    }

    /// Terminal glow effect for highlighted data
    func terminalGlow(_ color: Color = CosmicTheme.terminalGreen) -> some View {
        self.shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 0)
    }

    /// Deep void background with optional subtle gradient
    func voidBackground(gradient: Bool = false) -> some View {
        self.background(
            gradient ? AnyView(CosmicTheme.terminalGradient) : AnyView(CosmicTheme.background)
        )
    }

    /// Scanline effect for extra terminal authenticity
    func scanlines(opacity: Double = 0.03) -> some View {
        self.overlay(
            TerminalScanlines(opacity: opacity)
        )
    }
}

// MARK: - Terminal Background Components

/// Deep void black background view
struct TerminalBackground: View {
    var showScanlines: Bool = false
    var scanlineOpacity: Double = 0.02

    var body: some View {
        ZStack {
            // Deep void black
            CosmicTheme.background
                .ignoresSafeArea()

            // Optional subtle gradient
            LinearGradient(
                colors: [
                    Color(hex: "080808"),
                    CosmicTheme.background,
                    Color(hex: "030303")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Optional scanlines
            if showScanlines {
                TerminalScanlines(opacity: scanlineOpacity)
                    .ignoresSafeArea()
            }
        }
    }
}

/// Subtle scanline overlay for CRT terminal effect
struct TerminalScanlines: View {
    var opacity: Double = 0.03

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let spacing: CGFloat = 3
                var y: CGFloat = 0
                while y < geometry.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    y += spacing
                }
            }
            .stroke(Color.white.opacity(opacity), lineWidth: 0.5)
        }
    }
}

/// Vignette effect for planetarium feel
struct VignetteOverlay: View {
    var intensity: Double = 0.5

    var body: some View {
        RadialGradient(
            colors: [
                Color.clear,
                Color.black.opacity(intensity * 0.3),
                Color.black.opacity(intensity)
            ],
            center: .center,
            startRadius: 100,
            endRadius: 500
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview("Terminal Theme") {
    ScrollView {
        VStack(spacing: 24) {
            // Header
            Text("BLOOMBERG TERMINAL × PLANETARIUM")
                .font(TerminalFont.headline(20))
                .foregroundColor(CosmicTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .terminalCard()

            // Backgrounds - Deep Void Black
            VStack(alignment: .leading, spacing: 8) {
                Text("VOID BACKGROUNDS")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 2) {
                    colorBlock("Void #050505", CosmicTheme.background)
                    colorBlock("Surface", CosmicTheme.cardBackground)
                    colorBlock("Secondary", CosmicTheme.secondaryBackground)
                    colorBlock("Tertiary", CosmicTheme.tertiaryBackground)
                }
            }
            .padding()
            .terminalCard()

            // Market Colors with Terminal Green
            VStack(alignment: .leading, spacing: 8) {
                Text("MARKET COLORS")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 16) {
                    VStack {
                        Text("+2.45%")
                            .font(TerminalFont.price(24))
                            .foregroundColor(CosmicTheme.positive)
                            .terminalGlow(CosmicTheme.terminalGreen)
                        Text("Terminal Green")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }

                    VStack {
                        Text("-1.23%")
                            .font(TerminalFont.price(24))
                            .foregroundColor(CosmicTheme.negative)
                        Text("Bearish Red")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }

                    VStack {
                        Text("0.00%")
                            .font(TerminalFont.price(24))
                            .foregroundColor(CosmicTheme.neutral)
                        Text("Neutral")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .terminalCard()

            // Accents
            VStack(alignment: .leading, spacing: 8) {
                Text("ACCENTS")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 2) {
                    colorBlock("Starlight Gold", CosmicTheme.gold)
                    colorBlock("Terminal Green", CosmicTheme.terminalGreen)
                    colorBlock("Deep Blue", CosmicTheme.deepBlue)
                    colorBlock("Accent Blue", CosmicTheme.accentBlue)
                }
            }
            .padding()
            .terminalCard()

            // Elements
            VStack(alignment: .leading, spacing: 8) {
                Text("ZODIAC ELEMENTS")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textMuted)

                HStack(spacing: 2) {
                    colorBlock("Fire", CosmicTheme.fireElement)
                    colorBlock("Earth", CosmicTheme.earthElement)
                    colorBlock("Air", CosmicTheme.airElement)
                    colorBlock("Water", CosmicTheme.waterElement)
                }
            }
            .padding()
            .terminalCard()

            // Sample Price Display
            VStack(alignment: .leading, spacing: 8) {
                Text("PRICE DISPLAY")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textMuted)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AAPL")
                            .font(TerminalFont.ticker(14))
                            .foregroundColor(CosmicTheme.textPrimary)
                        Text("Apple Inc.")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$178.52")
                            .font(TerminalFont.price(20))
                            .foregroundColor(CosmicTheme.textPrimary)
                        Text("+2.34 (+1.33%)")
                            .font(TerminalFont.data(12))
                            .foregroundColor(CosmicTheme.positive)
                            .terminalGlow()
                    }
                }
                .padding(12)
                .background(CosmicTheme.secondaryBackground)
                .subtleBorder()
            }
            .padding()
            .terminalCard()
        }
        .padding()
    }
    .background(TerminalBackground())
}

#Preview("Terminal Green Glow") {
    VStack(spacing: 20) {
        Text("MARKET OPEN")
            .font(TerminalFont.readout(32))
            .foregroundColor(CosmicTheme.terminalGreen)
            .terminalGlow()

        Text("$1,247.89")
            .font(TerminalFont.price(48))
            .foregroundColor(CosmicTheme.terminalGreen)
            .terminalGlow()

        Text("+$47.23 (+3.94%)")
            .font(TerminalFont.data(18))
            .foregroundColor(CosmicTheme.positive)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TerminalBackground(showScanlines: true))
}

private func colorBlock(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 4) {
        Rectangle()
            .fill(color)
            .frame(height: 40)
        Text(name)
            .font(.system(size: 8, design: .monospaced))
            .foregroundColor(CosmicTheme.textMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity)
}
