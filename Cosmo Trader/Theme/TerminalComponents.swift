import SwiftUI

// MARK: - Terminal Components
// ===========================
// Bloomberg-style UI components for data-dense layouts.
// Sharp corners, thin borders, no decoration.
//
// Components:
// - TerminalDataCell: Individual data cell
// - TerminalDataRow: Row of data cells
// - TerminalDataTable: Full data table with header
// - TerminalSection: Section container with header
// - TerminalStatusBadge: Status indicator
// - TerminalPriceDisplay: Price with change
// - TerminalAlertBanner: Alert/warning banner

// MARK: - Terminal Data Cell

struct TerminalDataCell: View {
    let label: String
    let value: String
    var valueColor: Color = CosmicTheme.oledTextPrimary
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label.uppercased())
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.oledTextSecondary)

            Text(value)
                .font(TerminalFont.price(14))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Terminal Data Row

struct TerminalDataRowView: View {
    let cells: [(label: String, value: String, color: Color?)]

    init(_ cells: [(String, String, Color?)]) {
        self.cells = cells.map { (label: $0.0, value: $0.1, color: $0.2) }
    }

    init(_ cells: [(String, String)]) {
        self.cells = cells.map { (label: $0.0, value: $0.1, color: nil) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                TerminalDataCell(
                    label: cell.label,
                    value: cell.value,
                    valueColor: cell.color ?? CosmicTheme.oledTextPrimary
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .terminalCellPadding()
            }
        }
        .terminalRowV2()
    }
}

// MARK: - Terminal Section

struct TerminalSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var showBorder: Bool = true
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(title.uppercased())
                    .font(TerminalFont.data(10, weight: .medium))
                    .foregroundColor(CosmicTheme.oledTextSecondary)

                if let sub = subtitle {
                    Spacer()
                    Text(sub.uppercased())
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.oledGold)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            TerminalDivider()

            // Content
            content
        }
        .background(CosmicTheme.oledSurface)
        .overlay(
            Group {
                if showBorder {
                    Rectangle()
                        .stroke(CosmicTheme.oledBorder, lineWidth: 1)
                }
            }
        )
    }
}

// MARK: - Terminal Status Badge

struct TerminalStatusBadge: View {
    let text: String
    var status: Status = .neutral

    enum Status {
        case positive, negative, warning, neutral, live

        var color: Color {
            switch self {
            case .positive: return CosmicTheme.oledGreen
            case .negative: return CosmicTheme.oledRed
            case .warning:  return CosmicTheme.oledGold
            case .neutral:  return CosmicTheme.oledTextSecondary
            case .live:     return CosmicTheme.oledGreen
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if status == .live {
                Circle()
                    .fill(status.color)
                    .frame(width: 6, height: 6)
            }

            Text(text.uppercased())
                .font(TerminalFont.data(9, weight: .bold))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Rectangle()
                .fill(status.color.opacity(0.1))
        )
        .overlay(
            Rectangle()
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Terminal Price Display

struct TerminalPriceDisplay: View {
    let price: String
    let change: String
    let changePercent: String
    var isPositive: Bool = true
    var size: Size = .medium

    enum Size {
        case small, medium, large

        var priceSize: CGFloat {
            switch self {
            case .small:  return 16
            case .medium: return 24
            case .large:  return 32
            }
        }

        var changeSize: CGFloat {
            switch self {
            case .small:  return 10
            case .medium: return 12
            case .large:  return 14
            }
        }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(price)
                .font(TerminalFont.price(size.priceSize))
                .foregroundColor(CosmicTheme.oledTextPrimary)

            HStack(spacing: 4) {
                Text(change)
                    .font(TerminalFont.data(size.changeSize))

                Text("(\(changePercent))")
                    .font(TerminalFont.data(size.changeSize))
            }
            .foregroundColor(isPositive ? CosmicTheme.oledGreen : CosmicTheme.oledRed)
        }
    }
}

// MARK: - Terminal Alert Banner

struct TerminalAlertBanner: View {
    let title: String
    let message: String
    var severity: Severity = .info
    var onDismiss: (() -> Void)? = nil

    enum Severity {
        case info, warning, critical

        var color: Color {
            switch self {
            case .info:     return CosmicTheme.oledCyan
            case .warning:  return CosmicTheme.oledGold
            case .critical: return CosmicTheme.oledRed
            }
        }

        var icon: String {
            switch self {
            case .info:     return "info.circle"
            case .warning:  return "exclamationmark.triangle"
            case .critical: return "xmark.octagon"
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: severity.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(severity.color)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(TerminalFont.data(11, weight: .bold))
                    .foregroundColor(severity.color)

                Text(message)
                    .font(TerminalFont.caption(10))
                    .foregroundColor(CosmicTheme.oledTextSecondary)
            }

            Spacer()

            // Dismiss
            if let dismiss = onDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(CosmicTheme.oledTextSecondary)
                }
            }
        }
        .padding(12)
        .background(severity.color.opacity(0.1))
        .overlay(
            Rectangle()
                .stroke(severity.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Terminal Stock Row

struct TerminalStockRow: View {
    let symbol: String
    let name: String
    let price: String
    let change: String
    let changePercent: String
    var zodiacSign: ZodiacSign? = nil
    var isPositive: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            // Symbol and Name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(symbol)
                        .font(TerminalFont.ticker(13))
                        .foregroundColor(CosmicTheme.oledTextPrimary)

                    if let sign = zodiacSign {
                        ZodiacSymbolView(sign: sign, size: 12, color: CosmicTheme.oledGold)
                    }
                }

                Text(name)
                    .font(TerminalFont.caption(10))
                    .foregroundColor(CosmicTheme.oledTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Price
            VStack(alignment: .trailing, spacing: 2) {
                Text(price)
                    .font(TerminalFont.price(14))
                    .foregroundColor(CosmicTheme.oledTextPrimary)

                HStack(spacing: 4) {
                    Text(change)
                    Text(changePercent)
                }
                .font(TerminalFont.data(10))
                .foregroundColor(isPositive ? CosmicTheme.oledGreen : CosmicTheme.oledRed)
            }
        }
        .terminalCellPadding()
        .terminalRowV2()
    }
}

// MARK: - Terminal Ticker Strip

struct TerminalTickerStrip: View {
    let items: [(symbol: String, price: String, change: String, isPositive: Bool)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 8) {
                        Text(item.symbol)
                            .font(TerminalFont.ticker(11))
                            .foregroundColor(CosmicTheme.oledTextPrimary)

                        Text(item.price)
                            .font(TerminalFont.price(11))
                            .foregroundColor(CosmicTheme.oledTextPrimary)

                        Text(item.change)
                            .font(TerminalFont.data(10))
                            .foregroundColor(item.isPositive ? CosmicTheme.oledGreen : CosmicTheme.oledRed)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)

                    // Separator
                    Rectangle()
                        .fill(CosmicTheme.oledBorder)
                        .frame(width: 1)
                }
            }
        }
        .background(CosmicTheme.oledSurface)
        .overlay(
            VStack {
                Rectangle()
                    .fill(CosmicTheme.oledBorder)
                    .frame(height: 1)
                Spacer()
                Rectangle()
                    .fill(CosmicTheme.oledBorder)
                    .frame(height: 1)
            }
        )
    }
}

// MARK: - Terminal Key-Value Row

struct TerminalKeyValueRow: View {
    let key: String
    let value: String
    var valueColor: Color = CosmicTheme.oledTextPrimary
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(key)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.oledTextSecondary)

                Spacer()

                Text(value)
                    .font(TerminalFont.data(11, weight: .medium))
                    .foregroundColor(valueColor)
            }
            .terminalCellPadding()

            if showDivider {
                TerminalDivider(style: .dotted, color: CosmicTheme.oledBorder.opacity(0.5))
            }
        }
    }
}

// MARK: - Preview

#Preview("Terminal Components") {
    ScrollView {
        VStack(spacing: 16) {
            // Status Badges
            TerminalSection(title: "Status Badges") {
                HStack(spacing: 8) {
                    TerminalStatusBadge(text: "Bullish", status: .positive)
                    TerminalStatusBadge(text: "Bearish", status: .negative)
                    TerminalStatusBadge(text: "Caution", status: .warning)
                    TerminalStatusBadge(text: "Live", status: .live)
                }
                .padding(8)
            }

            // Price Display
            TerminalSection(title: "Price Display") {
                HStack {
                    TerminalPriceDisplay(
                        price: "$178.52",
                        change: "+$2.34",
                        changePercent: "+1.33%",
                        isPositive: true,
                        size: .large
                    )

                    Spacer()

                    TerminalPriceDisplay(
                        price: "$245.67",
                        change: "-$5.23",
                        changePercent: "-2.08%",
                        isPositive: false,
                        size: .large
                    )
                }
                .padding(12)
            }

            // Alert Banners
            VStack(spacing: 8) {
                TerminalAlertBanner(
                    title: "Mercury Retrograde",
                    message: "Communication disruptions expected through Dec 28",
                    severity: .warning
                )

                TerminalAlertBanner(
                    title: "Market Closed",
                    message: "Trading resumes Monday 9:30 AM EST",
                    severity: .info
                )
            }
            .padding(.horizontal, 1)

            // Stock Rows
            TerminalSection(title: "Holdings", subtitle: "8 Positions") {
                TerminalStockRow(
                    symbol: "AAPL",
                    name: "Apple Inc.",
                    price: "$178.52",
                    change: "+$2.34",
                    changePercent: "(+1.33%)",
                    zodiacSign: .leo,
                    isPositive: true
                )

                TerminalStockRow(
                    symbol: "TSLA",
                    name: "Tesla Inc.",
                    price: "$245.67",
                    change: "-$5.23",
                    changePercent: "(-2.08%)",
                    zodiacSign: .scorpio,
                    isPositive: false
                )

                TerminalStockRow(
                    symbol: "NVDA",
                    name: "NVIDIA Corp.",
                    price: "$456.78",
                    change: "+$12.34",
                    changePercent: "(+2.78%)",
                    zodiacSign: .aquarius,
                    isPositive: true
                )
            }

            // Key-Value Rows
            TerminalSection(title: "Portfolio Stats") {
                TerminalKeyValueRow(key: "Total Value", value: "$24,567.89", valueColor: CosmicTheme.oledTextPrimary)
                TerminalKeyValueRow(key: "Today's Change", value: "+$234.56 (+0.96%)", valueColor: CosmicTheme.oledGreen)
                TerminalKeyValueRow(key: "Dominant Element", value: "Fire", valueColor: CosmicTheme.fireElement)
                TerminalKeyValueRow(key: "Compatibility", value: "87%", valueColor: CosmicTheme.oledGold, showDivider: false)
            }
        }
        .padding(1)
    }
    .oledTerminalBackground()
}

#Preview("Ticker Strip") {
    VStack {
        Spacer()

        TerminalTickerStrip(items: [
            ("AAPL", "$178.52", "+1.33%", true),
            ("GOOGL", "$142.34", "-0.45%", false),
            ("TSLA", "$245.67", "+2.15%", true),
            ("NVDA", "$456.78", "+3.21%", true),
            ("AMZN", "$156.89", "-1.02%", false)
        ])

        Spacer()
    }
    .oledTerminalBackground()
}
