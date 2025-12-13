import SwiftUI

// MARK: - HoldingRow
// ===================
// Dense table row. No decoration. Data only.
// Bloomberg Terminal aesthetic.

struct HoldingRow: View {

    // MARK: - Properties

    let stock: Stock
    let compatibility: CompatibilityResult
    var onTap: (() -> Void)? = nil

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 0) {
                // Symbol with zodiac glyph
                HStack(spacing: 4) {
                    ZodiacSymbolView(
                        sign: stock.zodiacSign,
                        size: 10,
                        color: CosmicTheme.gold.opacity(0.7)
                    )
                    Text(stock.symbol)
                        .font(TerminalFont.ticker(11))
                        .foregroundColor(CosmicTheme.textPrimary)
                }
                .frame(width: 60, alignment: .leading)

                // Name
                Text(stock.name)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Shares
                Text("\(stock.formattedSharesOwned)")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .frame(width: 40, alignment: .trailing)

                // Price
                Text(stock.formattedPrice)
                    .font(TerminalFont.price(11))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .frame(width: 70, alignment: .trailing)

                // Change %
                Text(stock.formattedPercentage)
                    .font(TerminalFont.price(11))
                    .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                    .frame(width: 55, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Holding Row

struct CompactHoldingRow: View {

    let stock: Stock
    let compatibility: CompatibilityResult

    var body: some View {
        HStack(spacing: 8) {
            // Symbol with glyph
            HStack(spacing: 4) {
                ZodiacSymbolView(
                    sign: stock.zodiacSign,
                    size: 10,
                    color: CosmicTheme.gold.opacity(0.7)
                )
                Text(stock.symbol)
                    .font(TerminalFont.ticker(11))
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            Spacer()

            // Price
            Text(stock.formattedPrice)
                .font(TerminalFont.price(11))
                .foregroundColor(CosmicTheme.textPrimary)

            // Change
            Text(stock.formattedPercentage)
                .font(TerminalFont.price(11))
                .foregroundColor(stock.isPositive ? CosmicTheme.positive : CosmicTheme.negative)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

#Preview("Holding Row") {
    VStack(spacing: 0) {
        // Header
        HStack(spacing: 0) {
            Text("SYM")
                .frame(width: 60, alignment: .leading)
            Text("NAME")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("QTY")
                .frame(width: 40, alignment: .trailing)
            Text("PRICE")
                .frame(width: 70, alignment: .trailing)
            Text("CHG%")
                .frame(width: 55, alignment: .trailing)
        }
        .font(TerminalFont.data(9))
        .foregroundColor(CosmicTheme.textMuted)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(CosmicTheme.cardBackground)

        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)

        // Sample rows
        let stock: Stock = {
            var s = MockStockData.all.first { $0.symbol == "AAPL" }!
            s.sharesOwned = 15
            return s
        }()

        HoldingRow(
            stock: stock,
            compatibility: CompatibilityResult(
                userSign: .leo,
                stockSign: .aries,
                score: 92,
                description: "",
                advice: "",
                elementDynamic: ""
            )
        )

        Rectangle()
            .fill(CosmicTheme.border)
            .frame(height: 1)
    }
    .background(CosmicTheme.background)
}
