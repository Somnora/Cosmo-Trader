import SwiftUI

/// DataCellView
/// ------------
/// Single data point display like Bloomberg terminal cells.
///
/// Structure:
///   LABEL          (small, gray, uppercase)
///   VALUE          (large, white, monospace)
///   CHANGE         (small, green/red if applicable)
///
/// Design:
/// - Thin border, no background by default
/// - Fixed width for grid alignment
/// - Sharp corners (terminal aesthetic)
/// - Monospace numbers for alignment

// MARK: - Data Cell View

struct DataCellView: View {

    /// Cell label (displayed uppercase, small)
    let label: String

    /// Primary value (large, monospace)
    let value: String

    /// Optional change/delta value (small, colored)
    var change: String? = nil

    /// Change is positive (affects color)
    var isPositive: Bool = true

    /// Value color override
    var valueColor: Color = CosmicTheme.textPrimary

    /// Fixed width for grid alignment (nil for flexible)
    var fixedWidth: CGFloat? = nil

    /// Alignment within cell
    var alignment: HorizontalAlignment = .leading

    /// Show border
    var showBorder: Bool = true

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            // Label
            Text(label.uppercased())
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(0.5)

            // Value
            Text(value)
                .font(TerminalFont.price(14))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Change (optional)
            if let change = change {
                Text(change)
                    .font(TerminalFont.data(10))
                    .foregroundColor(isPositive ? CosmicTheme.positive : CosmicTheme.negative)
            }
        }
        .frame(width: fixedWidth, alignment: alignment == .leading ? .leading : (alignment == .trailing ? .trailing : .center))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(CosmicTheme.cardBackground)
        .overlay(
            Group {
                if showBorder {
                    Rectangle()
                        .stroke(CosmicTheme.border, lineWidth: 0.5)
                }
            }
        )
    }
}

// MARK: - Data Cell Variants

/// Minimal data cell without border
struct MinimalDataCell: View {

    let label: String
    let value: String
    var valueColor: Color = CosmicTheme.textPrimary
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label.uppercased())
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)

            Text(value)
                .font(TerminalFont.price(14))
                .foregroundColor(valueColor)
                .lineLimit(1)
        }
    }
}

/// Large hero data cell for prominent displays
struct HeroDataCell: View {

    let label: String
    let value: String
    var change: String? = nil
    var isPositive: Bool = true
    var valueColor: Color = CosmicTheme.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(1)

            Text(value)
                .font(TerminalFont.price(32))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let change = change {
                HStack(spacing: 4) {
                    Text(isPositive ? "▲" : "▼")
                        .font(.system(size: 10, weight: .bold))

                    Text(change)
                        .font(TerminalFont.data(13))
                }
                .foregroundColor(isPositive ? CosmicTheme.positive : CosmicTheme.negative)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }
}

/// Compact inline data cell for tight spaces
struct InlineDataCell: View {

    let label: String
    let value: String
    var valueColor: Color = CosmicTheme.textPrimary

    var body: some View {
        HStack(spacing: 8) {
            Text(label.uppercased())
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)

            Text(value)
                .font(TerminalFont.price(12))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Convenience Initializers

extension DataCellView {

    /// Price cell with automatic formatting
    static func price(label: String, value: Double, change: Double? = nil) -> DataCellView {
        let formattedValue = String(format: "$%.2f", value)
        var formattedChange: String? = nil
        var isPositive = true

        if let change = change {
            isPositive = change >= 0
            formattedChange = String(format: "%@$%.2f", isPositive ? "+" : "", change)
        }

        return DataCellView(
            label: label,
            value: formattedValue,
            change: formattedChange,
            isPositive: isPositive
        )
    }

    /// Percentage cell with automatic formatting and coloring
    static func percentage(label: String, value: Double) -> DataCellView {
        let isPositive = value >= 0
        let formatted = String(format: "%@%.2f%%", isPositive ? "+" : "", value)

        return DataCellView(
            label: label,
            value: formatted,
            valueColor: isPositive ? CosmicTheme.positive : CosmicTheme.negative
        )
    }

    /// Text cell with secondary coloring
    static func text(label: String, value: String) -> DataCellView {
        DataCellView(
            label: label,
            value: value,
            valueColor: CosmicTheme.textSecondary
        )
    }

    /// Gold-accented cell for cosmic/premium data
    static func gold(label: String, value: String) -> DataCellView {
        DataCellView(
            label: label,
            value: value,
            valueColor: CosmicTheme.gold
        )
    }

    /// Centered cell
    static func centered(label: String, value: String, color: Color = CosmicTheme.textPrimary) -> DataCellView {
        DataCellView(
            label: label,
            value: value,
            valueColor: color,
            alignment: .center
        )
    }
}

// MARK: - Data Cell Row (Multiple Cells)

struct DataCellRow: View {

    let cells: [DataCellView]
    var showDividers: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                cell
                    .frame(maxWidth: .infinity)

                if showDividers && index < cells.count - 1 {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(width: 0.5)
                }
            }
        }
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Responsive Grid

/// Adaptive grid that shows 2 columns on phone, 4 on iPad
struct ResponsiveDataGrid: View {

    let cells: [DataCellView]

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var columns: Int {
        horizontalSizeClass == .regular ? 4 : 2
    }

    var body: some View {
        let rows = stride(from: 0, to: cells.count, by: columns).map {
            Array(cells[$0..<min($0 + columns, cells.count)])
        }

        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowCells in
                HStack(spacing: 0) {
                    ForEach(Array(rowCells.enumerated()), id: \.offset) { index, cell in
                        cell
                            .showBorder(false)
                            .frame(maxWidth: .infinity)

                        if index < rowCells.count - 1 {
                            Rectangle()
                                .fill(CosmicTheme.border)
                                .frame(width: 0.5)
                        }
                    }

                    // Fill remaining columns
                    if rowCells.count < columns {
                        ForEach(rowCells.count..<columns, id: \.self) { _ in
                            Rectangle()
                                .fill(CosmicTheme.border)
                                .frame(width: 0.5)

                            Color.clear
                                .frame(maxWidth: .infinity)
                        }
                    }
                }

                if rowIndex < rows.count - 1 {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 0.5)
                }
            }
        }
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }
}

// MARK: - View Extension for Border Toggle

extension DataCellView {
    func showBorder(_ show: Bool) -> DataCellView {
        var copy = self
        copy.showBorder = show
        return copy
    }
}

// MARK: - Preview

#Preview("Data Cells") {
    ScrollView {
        VStack(spacing: 24) {
            Text("DATA CELLS")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            // Standard cells
            VStack(spacing: 0) {
                SectionHeaderView(title: "Standard Cells")

                HStack(spacing: 0) {
                    DataCellView(label: "Price", value: "$178.52")
                    DataCellView(label: "Volume", value: "52.3M", valueColor: CosmicTheme.textSecondary)
                    DataCellView(label: "Match", value: "87%", valueColor: CosmicTheme.gold)
                }
            }

            // With change values
            VStack(spacing: 0) {
                SectionHeaderView(title: "With Change")

                HStack(spacing: 0) {
                    DataCellView(label: "Today", value: "$178.52", change: "+$2.34", isPositive: true)
                    DataCellView(label: "Week", value: "$175.20", change: "-$3.32", isPositive: false)
                }
            }

            // Convenience initializers
            VStack(spacing: 0) {
                SectionHeaderView(title: "Factory Methods")

                HStack(spacing: 0) {
                    DataCellView.price(label: "Open", value: 176.15)
                    DataCellView.percentage(label: "Change", value: 1.33)
                    DataCellView.gold(label: "Cosmic", value: "92%")
                }
            }

            // Hero cell
            HeroDataCell(
                label: "Portfolio Value",
                value: "$45,230.89",
                change: "+$567.23 (+1.27%)",
                isPositive: true
            )

            // Minimal inline
            VStack(spacing: 0) {
                SectionHeaderView(title: "Inline Cells")

                VStack(spacing: 8) {
                    InlineDataCell(label: "Market Cap", value: "$2.8T")
                    InlineDataCell(label: "P/E Ratio", value: "28.4")
                    InlineDataCell(label: "Dividend", value: "0.65%", valueColor: CosmicTheme.gold)
                }
                .padding()
                .background(CosmicTheme.cardBackground)
            }

            // Responsive grid
            VStack(spacing: 0) {
                SectionHeaderView(title: "Responsive Grid")

                ResponsiveDataGrid(cells: [
                    DataCellView.price(label: "Price", value: 178.52),
                    DataCellView.percentage(label: "Day", value: 1.33),
                    DataCellView.text(label: "Volume", value: "52.3M"),
                    DataCellView.gold(label: "Match", value: "87%"),
                    DataCellView.price(label: "Open", value: 176.15),
                    DataCellView.percentage(label: "YTD", value: -5.2)
                ])
            }
        }
        .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("Hero Cell") {
    VStack(spacing: 16) {
        HeroDataCell(
            label: "Today's Gain",
            value: "$1,234.56",
            change: "+$234.56 (+23.4%)",
            isPositive: true
        )

        HeroDataCell(
            label: "Today's Loss",
            value: "$987.65",
            change: "-$123.45 (-11.1%)",
            isPositive: false,
            valueColor: CosmicTheme.negative
        )
    }
    .padding()
    .background(CosmicTheme.background)
}
