import SwiftUI

// MARK: - DashedDataRow
// =====================
// Terminal-style key-value display with dashed line connector.
// Perfect for displaying stock metadata like P/E Ratio, Element, Planet.
//
// Design Philosophy:
// - Clean label on left, value on right
// - Dashed line fills the space between
// - Monospace fonts for alignment
// - Subtle, professional appearance

struct DashedDataRow: View {

    // MARK: - Properties

    let label: String
    let value: String
    var valueColor: Color = CosmicTheme.textPrimary
    var labelColor: Color = CosmicTheme.textMuted
    var dashColor: Color = CosmicTheme.textMuted.opacity(0.4)
    var dashLength: CGFloat = 4
    var gapLength: CGFloat = 3

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            // Label
            Text(label)
                .font(TerminalFont.data(12))
                .foregroundColor(labelColor)
                .fixedSize()

            // Dashed line
            DashedLine(dashLength: dashLength, gapLength: gapLength)
                .stroke(dashColor, style: StrokeStyle(lineWidth: 1, dash: [dashLength, gapLength]))
                .frame(height: 1)

            // Value
            Text(value)
                .font(TerminalFont.data(12, weight: .medium))
                .foregroundColor(valueColor)
                .fixedSize()
        }
    }
}

// MARK: - Dashed Line Shape

struct DashedLine: Shape {
    var dashLength: CGFloat = 4
    var gapLength: CGFloat = 3

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// MARK: - Data Row Item

struct DataRowItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    var color: Color = CosmicTheme.textPrimary

    static func text(_ label: String, _ value: String) -> DataRowItem {
        DataRowItem(label: label, value: value, color: CosmicTheme.textSecondary)
    }

    static func primary(_ label: String, _ value: String) -> DataRowItem {
        DataRowItem(label: label, value: value, color: CosmicTheme.textPrimary)
    }

    static func gold(_ label: String, _ value: String) -> DataRowItem {
        DataRowItem(label: label, value: value, color: CosmicTheme.gold)
    }

    static func positive(_ label: String, _ value: String) -> DataRowItem {
        DataRowItem(label: label, value: value, color: CosmicTheme.positive)
    }

    static func negative(_ label: String, _ value: String) -> DataRowItem {
        DataRowItem(label: label, value: value, color: CosmicTheme.negative)
    }

    static func element(_ label: String, _ element: ZodiacSign.Element) -> DataRowItem {
        DataRowItem(label: label, value: element.displayName, color: element.color)
    }
}

// MARK: - Data Row Stack

/// Vertically stacked dashed data rows
struct DashedDataStack: View {

    let items: [DataRowItem]
    var spacing: CGFloat = 12

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(items) { item in
                DashedDataRow(
                    label: item.label,
                    value: item.value,
                    valueColor: item.color
                )
            }
        }
    }
}

// MARK: - Two Column Data Grid

/// Two-column layout of dashed data rows
struct DashedDataGrid: View {

    let leftItems: [DataRowItem]
    let rightItems: [DataRowItem]
    var spacing: CGFloat = 12
    var columnSpacing: CGFloat = 24

    var body: some View {
        HStack(alignment: .top, spacing: columnSpacing) {
            DashedDataStack(items: leftItems, spacing: spacing)
            DashedDataStack(items: rightItems, spacing: spacing)
        }
    }
}

// MARK: - Sectioned Data View

/// Data rows with section headers
struct SectionedDataView: View {

    let sections: [(title: String, items: [DataRowItem])]
    var sectionSpacing: CGFloat = 20
    var itemSpacing: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title.uppercased())
                        .font(TerminalFont.data(10, weight: .semibold))
                        .foregroundColor(CosmicTheme.gold)

                    DashedDataStack(items: section.items, spacing: itemSpacing)
                }
            }
        }
    }
}

// MARK: - Compact Data Row

/// More compact version for tight spaces
struct CompactDataRow: View {

    let label: String
    let value: String
    var valueColor: Color = CosmicTheme.textPrimary

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)
                .fixedSize()

            DashedLine()
                .stroke(CosmicTheme.textMuted.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                .frame(height: 1)

            Text(value)
                .font(TerminalFont.data(10, weight: .medium))
                .foregroundColor(valueColor)
                .fixedSize()
        }
    }
}

// MARK: - Preview

#Preview("Dashed Data Rows") {
    ScrollView {
        VStack(spacing: 32) {
            // Basic rows
            VStack(alignment: .leading, spacing: 16) {
                Text("BASIC ROWS")
                    .font(TerminalFont.headline(14))
                    .foregroundColor(CosmicTheme.textPrimary)

                VStack(spacing: 12) {
                    DashedDataRow(label: "P/E Ratio", value: "28.4")
                    DashedDataRow(label: "Market Cap", value: "$2.8T")
                    DashedDataRow(label: "Volume", value: "52.3M")
                    DashedDataRow(label: "Element", value: "Fire", valueColor: CosmicTheme.fireElement)
                    DashedDataRow(label: "Ruling Planet", value: "Sun", valueColor: CosmicTheme.gold)
                }
            }
            .padding()
            .background(CosmicTheme.cardBackground)

            // Stacked
            VStack(alignment: .leading, spacing: 16) {
                Text("DATA STACK")
                    .font(TerminalFont.headline(14))
                    .foregroundColor(CosmicTheme.textPrimary)

                DashedDataStack(items: [
                    .primary("Open", "$176.15"),
                    .primary("High", "$179.23"),
                    .primary("Low", "$175.89"),
                    .positive("Change", "+$2.37"),
                    .gold("Compatibility", "87%")
                ])
            }
            .padding()
            .background(CosmicTheme.cardBackground)

            // Two column grid
            VStack(alignment: .leading, spacing: 16) {
                Text("TWO COLUMN GRID")
                    .font(TerminalFont.headline(14))
                    .foregroundColor(CosmicTheme.textPrimary)

                DashedDataGrid(
                    leftItems: [
                        .primary("Price", "$178.52"),
                        .positive("Today", "+1.33%"),
                        .text("52W High", "$198.23")
                    ],
                    rightItems: [
                        .text("P/E", "28.4"),
                        .text("Div Yield", "0.52%"),
                        .text("52W Low", "$124.17")
                    ]
                )
            }
            .padding()
            .background(CosmicTheme.cardBackground)

            // Sectioned
            VStack(alignment: .leading, spacing: 16) {
                Text("SECTIONED DATA")
                    .font(TerminalFont.headline(14))
                    .foregroundColor(CosmicTheme.textPrimary)

                SectionedDataView(sections: [
                    ("Market Data", [
                        .primary("Price", "$178.52"),
                        .positive("Change", "+$2.37 (+1.33%)"),
                        .text("Volume", "52.3M")
                    ]),
                    ("Cosmic Profile", [
                        .gold("Zodiac Sign", "Leo"),
                        .element("Element", .fire),
                        .gold("Ruling Planet", "Sun")
                    ])
                ])
            }
            .padding()
            .background(CosmicTheme.cardBackground)

            // Compact
            VStack(alignment: .leading, spacing: 16) {
                Text("COMPACT ROWS")
                    .font(TerminalFont.headline(14))
                    .foregroundColor(CosmicTheme.textPrimary)

                VStack(spacing: 8) {
                    CompactDataRow(label: "Open", value: "$176.15")
                    CompactDataRow(label: "High", value: "$179.23")
                    CompactDataRow(label: "Low", value: "$175.89")
                    CompactDataRow(label: "Close", value: "$178.52", valueColor: CosmicTheme.positive)
                }
            }
            .padding()
            .background(CosmicTheme.cardBackground)
        }
        .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("Stock Detail Context") {
    VStack(spacing: 0) {
        // Header
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AAPL")
                    .font(TerminalFont.ticker(20))
                    .foregroundColor(CosmicTheme.textPrimary)
                Text("Apple Inc.")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$178.52")
                    .font(TerminalFont.price(24))
                    .foregroundColor(CosmicTheme.textPrimary)
                Text("+$2.37 (+1.33%)")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.positive)
            }
        }
        .padding()
        .background(CosmicTheme.cardBackground)

        // Data section
        VStack(alignment: .leading, spacing: 16) {
            DashedDataGrid(
                leftItems: [
                    .text("Open", "$176.15"),
                    .text("High", "$179.23"),
                    .text("Low", "$175.89"),
                    .text("Volume", "52.3M")
                ],
                rightItems: [
                    .text("P/E Ratio", "28.4"),
                    .text("Market Cap", "$2.8T"),
                    .text("Div Yield", "0.52%"),
                    .text("Beta", "1.25")
                ]
            )

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 0.5)

            DashedDataStack(items: [
                .gold("Zodiac Sign", "Leo"),
                .element("Element", .fire),
                .gold("Ruling Planet", "Sun"),
                .gold("Compatibility", "87%")
            ])
        }
        .padding()
        .background(CosmicTheme.secondaryBackground)
    }
    .background(CosmicTheme.background)
}
