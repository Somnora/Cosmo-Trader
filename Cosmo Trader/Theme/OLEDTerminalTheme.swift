import SwiftUI

// MARK: - OLED Terminal Theme
// ===========================
// "TRON meets Wall Street meets The Alchemist"
//
// This file extends/overrides CosmicTheme with the new OLED Terminal aesthetic.
// The dryer and more serious the design, the funnier the horoscopes become.
// This should look like a Bloomberg terminal that happens to track planetary alignments.
//
// Design Rules:
// - Sharp corners on EVERYTHING (borderRadius: 0)
// - Thin 1px borders instead of shadows
// - Dense information — less padding, more data
// - NO gradients, NO glows, NO soft shadows
// - If it looks "designed," it's wrong. If it looks like a terminal, it's right.

// MARK: - OLED Color Palette

struct OLEDTerminal {

    // MARK: - Backgrounds
    // True black for OLED displays, maximum contrast

    /// Primary background - True OLED Black #000000
    static let terminalBlack = Color(hex: "000000")

    /// Card/surface background - Slight lift #0A0A0A
    static let surfaceDark = Color(hex: "0A0A0A")

    /// Border color - Subtle but visible #1C1C1C
    static let borderGray = Color(hex: "1C1C1C")

    // MARK: - Text Colors
    // High contrast for OLED readability

    /// Primary text - High contrast white #E0E0E0
    static let textPrimary = Color(hex: "E0E0E0")

    /// Secondary text - Dimmed labels #666666
    static let textSecondary = Color(hex: "666666")

    // MARK: - Market Colors
    // Electric, high-contrast trading colors

    /// Gains - Electric Spring Green #00FF7F
    static let marketGreen = Color(hex: "00FF7F")

    /// Losses - iOS Red #FF3B30
    static let marketRed = Color(hex: "FF3B30")

    // MARK: - Accent Colors
    // Use sparingly - only for important data

    /// Gold - highlights, zodiac elements #FFD700
    static let accentGold = Color(hex: "FFD700")

    /// Cyan - TRON-style accent, VERY sparingly #00FFFF
    static let accentCyan = Color(hex: "00FFFF")
}

// MARK: - Terminal Layout Constants

struct TerminalLayout {

    /// Standard cell padding (dense)
    static let cellPadding: CGFloat = 8

    /// Minimal spacing between rows
    static let rowSpacing: CGFloat = 0

    /// Border width - always 1px
    static let borderWidth: CGFloat = 1

    /// No corner radius - sharp corners only
    static let cornerRadius: CGFloat = 0

    /// Grid line opacity (barely visible)
    static let gridOpacity: Double = 0.05

    /// Starfield opacity (barely visible)
    static let starfieldOpacity: Double = 0.15
}

// MARK: - Faint Starfield Background
// Barely visible dots - like static on an old CRT
// Should be noticed subconsciously, not consciously

struct FaintStarfieldView: View {
    var density: Int = 80
    var opacity: Double = TerminalLayout.starfieldOpacity

    var body: some View {
        Canvas { context, size in
            for i in 0..<density {
                let x = pseudoRandom(seed: i * 2) * size.width
                let y = pseudoRandom(seed: i * 2 + 1) * size.height
                let starOpacity = 0.05 + pseudoRandom(seed: i * 3) * opacity

                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.fill(
                    Rectangle().path(in: rect),
                    with: .color(Color.white.opacity(starOpacity))
                )
            }
        }
    }

    private func pseudoRandom(seed: Int) -> CGFloat {
        let x = sin(Double(seed) * 12.9898) * 43758.5453
        return CGFloat(x - floor(x))
    }
}

// MARK: - Grid Lines Overlay
// Subtle graph paper effect - 5% opacity

struct GridLinesView: View {
    var spacing: CGFloat = 20
    var opacity: Double = TerminalLayout.gridOpacity

    var body: some View {
        Canvas { context, size in
            let color = Color.white.opacity(opacity)

            // Vertical lines
            var x: CGFloat = 0
            while x < size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(color), lineWidth: 0.5)
                x += spacing
            }

            // Horizontal lines
            var y: CGFloat = 0
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(color), lineWidth: 0.5)
                y += spacing
            }
        }
    }
}

// MARK: - OLED Terminal Background

struct OLEDTerminalBackground: View {
    var showStarfield: Bool = true
    var showGridLines: Bool = false

    var body: some View {
        ZStack {
            // True OLED black
            OLEDTerminal.terminalBlack
                .ignoresSafeArea()

            // Faint starfield (barely visible)
            if showStarfield {
                FaintStarfieldView()
                    .ignoresSafeArea()
            }

            // Optional grid lines
            if showGridLines {
                GridLinesView()
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Terminal View Modifiers

extension View {

    /// Sharp-cornered card with 1px border
    func oledCard() -> some View {
        self
            .background(OLEDTerminal.surfaceDark)
            .overlay(
                Rectangle()
                    .stroke(OLEDTerminal.borderGray, lineWidth: 1)
            )
    }

    /// Data row with bottom border only
    func oledRow() -> some View {
        self
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(OLEDTerminal.borderGray)
                        .frame(height: 1)
                }
            )
    }

    /// Dense cell padding
    func oledCellPadding() -> some View {
        self
            .padding(.horizontal, TerminalLayout.cellPadding)
            .padding(.vertical, 6)
    }

    /// Terminal button - no rounded corners
    func oledButton() -> some View {
        self
            .background(OLEDTerminal.surfaceDark)
            .overlay(
                Rectangle()
                    .stroke(OLEDTerminal.borderGray, lineWidth: 1)
            )
    }
}

// MARK: - Constellation Dividers
// Thin line patterns - structure, not decoration

struct ConstellationDividerView: View {
    enum Pattern {
        case solid
        case dashed
        case dotted
    }

    var pattern: Pattern = .solid
    var color: Color = OLEDTerminal.borderGray

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                var path = Path()
                path.move(to: CGPoint(x: 0, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width, y: size.height / 2))

                let style: StrokeStyle
                switch pattern {
                case .solid:
                    style = StrokeStyle(lineWidth: 1)
                case .dashed:
                    style = StrokeStyle(lineWidth: 1, dash: [4, 4])
                case .dotted:
                    style = StrokeStyle(lineWidth: 1, dash: [1, 3])
                }

                context.stroke(path, with: .color(color), style: style)
            }
        }
        .frame(height: 1)
    }
}

// MARK: - Data Table Components

struct OLEDTableHeader: View {
    let columns: [String]
    var columnWidths: [CGFloat?]? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                Text(column.uppercased())
                    .font(TerminalFont.data(10, weight: .medium))
                    .foregroundColor(OLEDTerminal.textSecondary)
                    .frame(maxWidth: columnWidths?[safe: index] ?? .infinity, alignment: .leading)
                    .oledCellPadding()
            }
        }
        .background(OLEDTerminal.surfaceDark)
        .oledRow()
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview("OLED Terminal Palette") {
    ScrollView {
        VStack(spacing: 0) {
            // Header
            Text("OLED TERMINAL THEME")
                .font(TerminalFont.ticker(16))
                .foregroundColor(OLEDTerminal.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(12)
                .oledCard()

            // Background Colors
            VStack(alignment: .leading, spacing: 0) {
                Text("BACKGROUNDS")
                    .font(TerminalFont.data(10))
                    .foregroundColor(OLEDTerminal.textSecondary)
                    .padding(8)

                HStack(spacing: 0) {
                    oledSwatch("#000000", OLEDTerminal.terminalBlack)
                    oledSwatch("#0A0A0A", OLEDTerminal.surfaceDark)
                    oledSwatch("#1C1C1C", OLEDTerminal.borderGray)
                }
            }
            .oledCard()

            // Market Colors
            VStack(alignment: .leading, spacing: 0) {
                Text("MARKET COLORS")
                    .font(TerminalFont.data(10))
                    .foregroundColor(OLEDTerminal.textSecondary)
                    .padding(8)

                HStack(spacing: 16) {
                    VStack {
                        Text("+5.23%")
                            .font(TerminalFont.price(20))
                            .foregroundColor(OLEDTerminal.marketGreen)
                        Text("GAINS")
                            .font(TerminalFont.data(9))
                            .foregroundColor(OLEDTerminal.textSecondary)
                    }

                    VStack {
                        Text("-2.14%")
                            .font(TerminalFont.price(20))
                            .foregroundColor(OLEDTerminal.marketRed)
                        Text("LOSSES")
                            .font(TerminalFont.data(9))
                            .foregroundColor(OLEDTerminal.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(12)
            }
            .oledCard()

            // Accent Colors
            VStack(alignment: .leading, spacing: 0) {
                Text("ACCENTS (USE SPARINGLY)")
                    .font(TerminalFont.data(10))
                    .foregroundColor(OLEDTerminal.textSecondary)
                    .padding(8)

                HStack(spacing: 0) {
                    oledSwatch("GOLD", OLEDTerminal.accentGold)
                    oledSwatch("CYAN", OLEDTerminal.accentCyan)
                }
            }
            .oledCard()

            // Sample Data Row
            VStack(alignment: .leading, spacing: 0) {
                Text("SAMPLE DATA")
                    .font(TerminalFont.data(10))
                    .foregroundColor(OLEDTerminal.textSecondary)
                    .padding(8)

                ConstellationDividerView()

                HStack {
                    Text("AAPL")
                        .font(TerminalFont.ticker(14))
                        .foregroundColor(OLEDTerminal.textPrimary)

                    Spacer()

                    Text("$178.52")
                        .font(TerminalFont.price(14))
                        .foregroundColor(OLEDTerminal.textPrimary)

                    Text("+2.34%")
                        .font(TerminalFont.data(12))
                        .foregroundColor(OLEDTerminal.marketGreen)
                        .frame(width: 70, alignment: .trailing)

                    ZodiacSymbolView(sign: .leo, size: 14, color: OLEDTerminal.accentGold)
                        .frame(width: 30)
                }
                .oledCellPadding()
                .oledRow()

                HStack {
                    Text("MERCURY")
                        .font(TerminalFont.data(12))
                        .foregroundColor(OLEDTerminal.textPrimary)

                    Spacer()

                    Text("RETROGRADE")
                        .font(TerminalFont.data(12, weight: .bold))
                        .foregroundColor(OLEDTerminal.marketRed)
                }
                .oledCellPadding()
            }
            .oledCard()
        }
        .padding(1)
    }
    .background(OLEDTerminalBackground(showStarfield: true))
}

private func oledSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 2) {
        Rectangle()
            .fill(color)
            .frame(height: 30)
            .overlay(
                Rectangle()
                    .stroke(OLEDTerminal.borderGray, lineWidth: 0.5)
            )
        Text(name)
            .font(TerminalFont.data(8))
            .foregroundColor(OLEDTerminal.textSecondary)
    }
    .frame(maxWidth: .infinity)
}
