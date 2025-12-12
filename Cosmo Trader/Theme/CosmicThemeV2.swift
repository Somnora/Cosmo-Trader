import SwiftUI

// MARK: - CosmicTheme V2
// ======================
// "TRON meets Wall Street meets The Alchemist"
//
// This is the updated theme following the OLED Terminal aesthetic.
// Import this to get the new color palette and view modifiers.
//
// Design Philosophy:
// - The dryer and more serious the design, the funnier the horoscopes become
// - This should look like a Bloomberg terminal that happens to track planetary alignments
// - Sharp corners on EVERYTHING (borderRadius: 0)
// - Thin 1px borders instead of shadows
// - Dense information — less padding, more data
// - NO gradients, NO glows, NO soft shadows
// - If it looks "designed," it's wrong. If it looks like a terminal, it's right.

// MARK: - Theme Extension
// This extends the existing CosmicTheme struct to add/override values

extension CosmicTheme {

    // MARK: - OLED Palette (New Values)
    // Use these new colors for the terminal aesthetic

    /// True OLED Black background
    static var oledBackground: Color { Color(hex: "000000") }

    /// Surface color for cards
    static var oledSurface: Color { Color(hex: "0A0A0A") }

    /// Border color
    static var oledBorder: Color { Color(hex: "1C1C1C") }

    /// Electric green for gains
    static var oledGreen: Color { Color(hex: "00FF7F") }

    /// Red for losses
    static var oledRed: Color { Color(hex: "FF3B30") }

    /// Bright gold accent
    static var oledGold: Color { Color(hex: "FFD700") }

    /// Cyan TRON accent (use sparingly)
    static var oledCyan: Color { Color(hex: "00FFFF") }

    /// High contrast white text
    static var oledTextPrimary: Color { Color(hex: "E0E0E0") }

    /// Dimmed secondary text
    static var oledTextSecondary: Color { Color(hex: "666666") }
}

// MARK: - Terminal View Modifiers V2
// Sharp corners, 1px borders, no decoration

extension View {

    /// Sharp-cornered terminal card with 1px border
    func terminalCardV2() -> some View {
        self
            .background(CosmicTheme.oledSurface)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.oledBorder, lineWidth: 1)
            )
    }

    /// Data row with bottom border separator
    func terminalRowV2() -> some View {
        self
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(CosmicTheme.oledBorder)
                        .frame(height: 1)
                }
            )
    }

    /// Dense cell padding for data tables
    func terminalCellPadding() -> some View {
        self
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
    }

    /// Sharp button style
    func terminalButtonV2() -> some View {
        self
            .background(CosmicTheme.oledSurface)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.oledBorder, lineWidth: 1)
            )
    }

    /// Apply OLED terminal background
    func oledTerminalBackground(showStarfield: Bool = true, showGrid: Bool = false) -> some View {
        self.background(
            ZStack {
                CosmicTheme.oledBackground
                    .ignoresSafeArea()

                if showStarfield {
                    TerminalStarfield()
                        .ignoresSafeArea()
                }

                if showGrid {
                    TerminalGrid()
                        .ignoresSafeArea()
                }
            }
        )
    }
}

// MARK: - Terminal Starfield
// Barely visible dots, like static

struct TerminalStarfield: View {
    var density: Int = 80
    var maxOpacity: Double = 0.15

    var body: some View {
        Canvas { context, size in
            for i in 0..<density {
                let x = seededRandom(seed: i * 2) * size.width
                let y = seededRandom(seed: i * 2 + 1) * size.height
                let opacity = 0.05 + seededRandom(seed: i * 3) * maxOpacity

                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.fill(
                    Rectangle().path(in: rect),
                    with: .color(Color.white.opacity(opacity))
                )
            }
        }
    }

    private func seededRandom(seed: Int) -> CGFloat {
        let x = sin(Double(seed) * 12.9898) * 43758.5453
        return CGFloat(x - floor(x))
    }
}

// MARK: - Terminal Grid
// Graph paper effect at 5% opacity

struct TerminalGrid: View {
    var spacing: CGFloat = 20
    var opacity: Double = 0.05

    var body: some View {
        Canvas { context, size in
            let lineColor = Color.white.opacity(opacity)

            // Vertical
            var x: CGFloat = 0
            while x < size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                x += spacing
            }

            // Horizontal
            var y: CGFloat = 0
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                y += spacing
            }
        }
    }
}

// MARK: - Terminal Dividers
// Thin structural lines

struct TerminalDivider: View {
    enum Style {
        case solid, dashed, dotted
    }

    var style: Style = .solid
    var color: Color = CosmicTheme.oledBorder

    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
            }
            .stroke(color, style: strokeStyle)
        }
        .frame(height: 1)
    }

    private var strokeStyle: StrokeStyle {
        switch style {
        case .solid:  return StrokeStyle(lineWidth: 1)
        case .dashed: return StrokeStyle(lineWidth: 1, dash: [4, 4])
        case .dotted: return StrokeStyle(lineWidth: 1, dash: [1, 3])
        }
    }
}

// MARK: - Data Table Header

struct TerminalTableHeader: View {
    let columns: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(columns, id: \.self) { col in
                Text(col.uppercased())
                    .font(TerminalFont.data(10, weight: .medium))
                    .foregroundColor(CosmicTheme.oledTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .terminalCellPadding()
            }
        }
        .background(CosmicTheme.oledSurface)
        .terminalRowV2()
    }
}

// MARK: - Data Table Row

struct TerminalTableRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            content
        }
        .terminalRowV2()
    }
}

// MARK: - Preview

#Preview("Theme V2 - OLED Terminal") {
    ScrollView {
        VStack(spacing: 0) {
            // Header
            Text("COSMO TRADER TERMINAL V2")
                .font(TerminalFont.ticker(16))
                .foregroundColor(CosmicTheme.oledTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(12)
                .terminalCardV2()

            // Color Samples
            VStack(alignment: .leading, spacing: 0) {
                Text("OLED PALETTE")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.oledTextSecondary)
                    .padding(8)

                TerminalDivider()

                HStack(spacing: 0) {
                    colorSampleV2("BG", CosmicTheme.oledBackground)
                    colorSampleV2("SURFACE", CosmicTheme.oledSurface)
                    colorSampleV2("BORDER", CosmicTheme.oledBorder)
                }

                HStack(spacing: 0) {
                    colorSampleV2("GREEN", CosmicTheme.oledGreen)
                    colorSampleV2("RED", CosmicTheme.oledRed)
                    colorSampleV2("GOLD", CosmicTheme.oledGold)
                    colorSampleV2("CYAN", CosmicTheme.oledCyan)
                }
            }
            .terminalCardV2()

            // Data Table Sample
            VStack(alignment: .leading, spacing: 0) {
                Text("MARKET DATA")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.oledTextSecondary)
                    .padding(8)

                TerminalTableHeader(columns: ["Symbol", "Price", "Change", "Sign"])

                ForEach(["AAPL", "GOOGL", "TSLA"], id: \.self) { sym in
                    TerminalTableRow {
                        Text(sym)
                            .font(TerminalFont.ticker(12))
                            .foregroundColor(CosmicTheme.oledTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .terminalCellPadding()

                        Text("$\(Int.random(in: 100...500)).00")
                            .font(TerminalFont.price(12))
                            .foregroundColor(CosmicTheme.oledTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .terminalCellPadding()

                        Text("+\(Double.random(in: 0.5...3.0), specifier: "%.2f")%")
                            .font(TerminalFont.data(12))
                            .foregroundColor(CosmicTheme.oledGreen)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .terminalCellPadding()

                        ZodiacSymbolView(sign: .leo, size: 12, color: CosmicTheme.oledGold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .terminalCellPadding()
                    }
                }
            }
            .terminalCardV2()

            // Planetary Status (The Test)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("PLANETARY STATUS")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.oledTextSecondary)

                    Spacer()

                    Text("LIVE")
                        .font(TerminalFont.data(9, weight: .bold))
                        .foregroundColor(CosmicTheme.oledGreen)
                }

                TerminalDivider()

                HStack {
                    Text("MERCURY")
                        .font(TerminalFont.data(12))
                        .foregroundColor(CosmicTheme.oledTextPrimary)

                    Spacer()

                    Text("RETROGRADE")
                        .font(TerminalFont.data(12, weight: .bold))
                        .foregroundColor(CosmicTheme.oledRed)
                }

                Text("Communication disruptions expected. Avoid signing contracts.")
                    .font(TerminalFont.caption(10))
                    .foregroundColor(CosmicTheme.oledTextSecondary)
            }
            .padding(12)
            .terminalCardV2()
        }
        .padding(1)
    }
    .oledTerminalBackground(showStarfield: true, showGrid: false)
}

#Preview("Dense Data Table") {
    VStack(spacing: 0) {
        TerminalTableHeader(columns: ["SYM", "PRICE", "CHG%", "VOL", "SIGN"])

        ForEach(["AAPL", "GOOGL", "TSLA", "NVDA", "AMZN", "META"], id: \.self) { sym in
            TerminalTableRow {
                Text(sym)
                    .font(TerminalFont.ticker(11))
                    .foregroundColor(CosmicTheme.oledTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .terminalCellPadding()

                Text("$\(Int.random(in: 100...500))")
                    .font(TerminalFont.price(11))
                    .foregroundColor(CosmicTheme.oledTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .terminalCellPadding()

                let positive = Bool.random()
                Text("\(positive ? "+" : "-")\(Double.random(in: 0.1...5.0), specifier: "%.2f")%")
                    .font(TerminalFont.data(11))
                    .foregroundColor(positive ? CosmicTheme.oledGreen : CosmicTheme.oledRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .terminalCellPadding()

                Text("\(Int.random(in: 1...99))M")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.oledTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .terminalCellPadding()

                ZodiacSymbolView(sign: [.aries, .taurus, .gemini, .cancer, .leo, .virgo].randomElement()!, size: 12, color: CosmicTheme.oledGold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .terminalCellPadding()
            }
        }
    }
    .terminalCardV2()
    .padding()
    .oledTerminalBackground()
}

private func colorSampleV2(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 2) {
        Rectangle()
            .fill(color)
            .frame(height: 24)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.oledBorder, lineWidth: 0.5)
            )
        Text(name)
            .font(TerminalFont.data(8))
            .foregroundColor(CosmicTheme.oledTextSecondary)
    }
    .frame(maxWidth: .infinity)
}
