import SwiftUI

/// DataGridView
/// ------------
/// Bloomberg-style data grid with labeled cells.
/// Each cell has a label on top and a value below.
///
/// Design:
/// - Monospace numbers for alignment
/// - Subtle borders between cells
/// - Compact, information-dense layout

// MARK: - Data Grid Cell

struct DataGridCell: View {

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
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : (alignment == .trailing ? .trailing : .center))
    }
}

// MARK: - Data Grid Row

struct DataGridRow: View {

    let cells: [DataGridCellData]
    var showDividers: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                DataGridCell(
                    label: cell.label,
                    value: cell.value,
                    valueColor: cell.color,
                    alignment: cell.alignment
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

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

// MARK: - Data Grid

struct DataGridView: View {

    let rows: [[DataGridCellData]]
    var showRowDividers: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                DataGridRow(cells: row)

                if showRowDividers && index < rows.count - 1 {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(height: 0.5)
                }
            }
        }
    }
}

// MARK: - Cell Data Model

struct DataGridCellData {
    let label: String
    let value: String
    var color: Color = CosmicTheme.textPrimary
    var alignment: HorizontalAlignment = .leading

    static func price(_ label: String, _ value: String, isPositive: Bool? = nil) -> DataGridCellData {
        let color: Color
        if let isPositive = isPositive {
            color = isPositive ? CosmicTheme.positive : CosmicTheme.negative
        } else {
            color = CosmicTheme.textPrimary
        }
        return DataGridCellData(label: label, value: value, color: color)
    }

    static func percentage(_ label: String, _ value: Double) -> DataGridCellData {
        let formatted = String(format: "%@%.2f%%", value >= 0 ? "+" : "", value)
        let color = value >= 0 ? CosmicTheme.positive : CosmicTheme.negative
        return DataGridCellData(label: label, value: formatted, color: color)
    }

    static func text(_ label: String, _ value: String) -> DataGridCellData {
        DataGridCellData(label: label, value: value, color: CosmicTheme.textSecondary)
    }

    static func gold(_ label: String, _ value: String) -> DataGridCellData {
        DataGridCellData(label: label, value: value, color: CosmicTheme.gold)
    }

    static func centered(_ label: String, _ value: String, color: Color = CosmicTheme.textPrimary) -> DataGridCellData {
        DataGridCellData(label: label, value: value, color: color, alignment: .center)
    }
}

// MARK: - Stats Grid (Pre-built configurations)

struct StatsGridView: View {

    let stats: [StatItem]
    var columns: Int = 3

    var body: some View {
        let rows = stride(from: 0, to: stats.count, by: columns).map {
            Array(stats[$0..<min($0 + columns, stats.count)])
        }

        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowStats in
                HStack(spacing: 0) {
                    ForEach(Array(rowStats.enumerated()), id: \.offset) { index, stat in
                        statCell(stat)
                            .frame(maxWidth: .infinity)

                        if index < rowStats.count - 1 {
                            Rectangle()
                                .fill(CosmicTheme.border)
                                .frame(width: 0.5)
                        }
                    }

                    // Fill remaining columns with empty cells
                    if rowStats.count < columns {
                        ForEach(rowStats.count..<columns, id: \.self) { _ in
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

    private func statCell(_ stat: StatItem) -> some View {
        VStack(spacing: 4) {
            Text(stat.label.uppercased())
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)

            Text(stat.value)
                .font(TerminalFont.price(14))
                .foregroundColor(stat.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
    }
}

struct StatItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    var color: Color = CosmicTheme.textPrimary

    static func price(_ label: String, _ value: String) -> StatItem {
        StatItem(label: label, value: value)
    }

    static func change(_ label: String, _ value: Double) -> StatItem {
        let formatted = String(format: "%@%.2f%%", value >= 0 ? "+" : "", value)
        let color = value >= 0 ? CosmicTheme.positive : CosmicTheme.negative
        return StatItem(label: label, value: formatted, color: color)
    }

    static func text(_ label: String, _ value: String) -> StatItem {
        StatItem(label: label, value: value, color: CosmicTheme.textSecondary)
    }

    static func gold(_ label: String, _ value: String) -> StatItem {
        StatItem(label: label, value: value, color: CosmicTheme.gold)
    }
}

// MARK: - Horizontal Stats Bar

struct HorizontalStatsBar: View {

    let stats: [StatItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                VStack(spacing: 2) {
                    Text(stat.value)
                        .font(TerminalFont.price(13))
                        .foregroundColor(stat.color)

                    Text(stat.label.uppercased())
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .frame(maxWidth: .infinity)

                if index < stats.count - 1 {
                    Rectangle()
                        .fill(CosmicTheme.border)
                        .frame(width: 0.5, height: 30)
                }
            }
        }
        .padding(.vertical, 8)
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview("Data Grid") {
    ScrollView {
        VStack(spacing: 24) {
            Text("DATA GRID")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            DataGridView(rows: [
                [
                    .price("Price", "$178.52"),
                    .percentage("Today", 1.33),
                    .text("Volume", "52.3M")
                ],
                [
                    .price("Open", "$176.15"),
                    .price("High", "$179.23"),
                    .price("Low", "$175.89")
                ]
            ])

            Text("STATS GRID")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            StatsGridView(stats: [
                .price("Market Cap", "$2.8T"),
                .change("YTD", 12.5),
                .gold("Match", "87%"),
                .text("Sector", "Tech"),
                .price("P/E", "28.4"),
                .change("52W", -5.2)
            ])

            Text("HORIZONTAL BAR")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            HorizontalStatsBar(stats: [
                .price("Total", "$45,230"),
                .change("Today", 2.34),
                .gold("Cosmic", "72%"),
                .text("Holdings", "8")
            ])
        }
        .padding()
    }
    .background(CosmicTheme.background)
}
