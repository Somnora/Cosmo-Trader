import SwiftUI

/// PriceDisplayView
/// ----------------
/// Large, prominent price display with change indicators.
/// Bloomberg terminal style with proper formatting.
///
/// Features:
/// - Large monospace price with proper decimal formatting
/// - Change amount and percentage
/// - Arrow indicator (▲ or ▼)
/// - Color coded green/red
/// - Multiple size presets
/// - Optional flash animation on price updates

// MARK: - Price Display View

struct PriceDisplayView: View {

    /// Current price value
    let price: Double

    /// Price change amount
    let change: Double

    /// Price change percentage
    let changePercent: Double

    /// Display size preset
    var size: PriceDisplaySize = .large

    /// Show the change amount (not just percent)
    var showChangeAmount: Bool = true

    /// Enable flash animation on price change
    var enableFlash: Bool = false

    /// Flash state for animation
    @State private var isFlashing: Bool = false

    /// Previous price for detecting changes
    @State private var previousPrice: Double = 0

    /// Computed properties
    private var isPositive: Bool { change >= 0 }
    private var changeColor: Color { isPositive ? CosmicTheme.positive : CosmicTheme.negative }
    private var arrowSymbol: String { isPositive ? "▲" : "▼" }

    /// Flash color based on price movement direction
    private var flashColor: Color {
        guard previousPrice != 0 else { return .clear }
        return price > previousPrice ? CosmicTheme.positive : CosmicTheme.negative
    }

    var body: some View {
        VStack(alignment: .leading, spacing: size.verticalSpacing) {
            // Main price with flash effect
            Text(formattedPrice)
                .font(TerminalFont.price(size.priceSize))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .background(
                    Rectangle()
                        .fill(flashColor.opacity(isFlashing ? 0.3 : 0))
                        .animation(.easeOut(duration: 0.3), value: isFlashing)
                )
                .onChange(of: price) { oldValue, newValue in
                    if enableFlash && oldValue != newValue {
                        triggerFlash()
                    }
                    previousPrice = oldValue
                }
                .onAppear {
                    previousPrice = price
                }

            // Change row
            HStack(spacing: size.horizontalSpacing) {
                // Arrow
                Text(arrowSymbol)
                    .font(.system(size: size.arrowSize, weight: .bold))
                    .foregroundColor(changeColor)

                // Change amount
                if showChangeAmount {
                    Text(formattedChange)
                        .font(TerminalFont.price(size.changeSize))
                        .foregroundColor(changeColor)
                }

                // Percentage
                Text(formattedPercent)
                    .font(TerminalFont.data(size.changeSize))
                    .foregroundColor(changeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(changeColor.opacity(0.15))
                    )
            }
        }
    }

    /// Trigger the flash animation
    private func triggerFlash() {
        isFlashing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isFlashing = false
        }
    }

    // MARK: - Formatting

    private var formattedPrice: String {
        if price >= 1000 {
            return String(format: "$%,.2f", price)
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.4f", price)
        }
    }

    private var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        if abs(change) >= 1000 {
            return String(format: "%@$%,.2f", sign, change)
        } else {
            return String(format: "%@$%.2f", sign, change)
        }
    }

    private var formattedPercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, changePercent)
    }
}

// MARK: - Size Presets

enum PriceDisplaySize {
    case small
    case medium
    case large
    case hero

    var priceSize: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 28
        case .large: return 36
        case .hero: return 48
        }
    }

    var changeSize: CGFloat {
        switch self {
        case .small: return 11
        case .medium: return 13
        case .large: return 15
        case .hero: return 18
        }
    }

    var arrowSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        case .hero: return 18
        }
    }

    var verticalSpacing: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 6
        case .hero: return 8
        }
    }

    var horizontalSpacing: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        case .hero: return 10
        }
    }
}

// MARK: - Compact Price Display

/// Single-line price display for tight spaces
struct CompactPriceDisplay: View {

    let price: Double
    let changePercent: Double

    var body: some View {
        HStack(spacing: 8) {
            Text(String(format: "$%.2f", price))
                .font(TerminalFont.price(16))
                .foregroundColor(CosmicTheme.textPrimary)

            HStack(spacing: 2) {
                Image(systemName: changePercent >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 8))

                Text(String(format: "%@%.2f%%", changePercent >= 0 ? "+" : "", changePercent))
                    .font(TerminalFont.data(12))
            }
            .foregroundColor(changePercent >= 0 ? CosmicTheme.positive : CosmicTheme.negative)
        }
    }
}

// MARK: - Price Label

/// Minimal price with label above
struct PriceLabelView: View {

    let label: String
    let price: Double
    var showChange: Bool = false
    var changePercent: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)

            HStack(spacing: 6) {
                Text(String(format: "$%.2f", price))
                    .font(TerminalFont.price(18))
                    .foregroundColor(CosmicTheme.textPrimary)

                if showChange {
                    Text(String(format: "%@%.2f%%", changePercent >= 0 ? "+" : "", changePercent))
                        .font(TerminalFont.data(11))
                        .foregroundColor(changePercent >= 0 ? CosmicTheme.positive : CosmicTheme.negative)
                }
            }
        }
    }
}

// MARK: - Bid/Ask Display

/// Shows bid and ask prices side by side
struct BidAskDisplayView: View {

    let bid: Double
    let ask: Double
    var showSpread: Bool = true

    private var spread: Double { ask - bid }
    private var spreadPercent: Double {
        guard bid.isFinite, bid != 0, spread.isFinite else { return 0 }
        let percent = (spread / bid) * 100
        return percent.isFinite ? percent : 0
    }

    var body: some View {
        HStack(spacing: 0) {
            // Bid
            VStack(alignment: .leading, spacing: 4) {
                Text("BID")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)

                Text(String(format: "$%.2f", bid))
                    .font(TerminalFont.price(16))
                    .foregroundColor(CosmicTheme.positive)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Spread indicator
            if showSpread {
                VStack(spacing: 2) {
                    Text("SPREAD")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(String(format: "$%.2f", spread))
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)

                    Text(String(format: "%.3f%%", spreadPercent))
                        .font(TerminalFont.data(9))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .frame(width: 60)
            }

            // Ask
            VStack(alignment: .trailing, spacing: 4) {
                Text("ASK")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)

                Text(String(format: "$%.2f", ask))
                    .font(TerminalFont.price(16))
                    .foregroundColor(CosmicTheme.negative)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Day Range Display

/// Shows price range with current position indicator
struct DayRangeDisplayView: View {

    let low: Double
    let high: Double
    let current: Double
    var label: String = "Day Range"

    private var position: Double {
        guard high.isFinite, low.isFinite, current.isFinite, high > low else { return 0.5 }
        let normalized = (current - low) / (high - low)
        guard normalized.isFinite else { return 0.5 }
        return min(max(normalized, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(TerminalFont.data(10))
                .foregroundColor(CosmicTheme.textMuted)

            // Price labels
            HStack {
                Text(String(format: "$%.2f", low))
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.negative)

                Spacer()

                Text(String(format: "$%.2f", high))
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.positive)
            }

            // Range bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [CosmicTheme.negative.opacity(0.3), CosmicTheme.positive.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 4)

                    // Position indicator
                    Circle()
                        .fill(CosmicTheme.gold)
                        .frame(width: 10, height: 10)
                        .shadow(color: CosmicTheme.gold.opacity(0.5), radius: 4)
                        .offset(x: (CGFloat(position).sanitized * max(geometry.size.width - 10, 0).sanitized).sanitized)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - High/Low Display

/// Compact high/low with icons
struct HighLowDisplayView: View {

    let high: Double
    let low: Double

    var body: some View {
        HStack(spacing: 16) {
            // High
            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(CosmicTheme.positive)

                VStack(alignment: .leading, spacing: 0) {
                    Text("HIGH")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(String(format: "$%.2f", high))
                        .font(TerminalFont.price(13))
                        .foregroundColor(CosmicTheme.textPrimary)
                }
            }

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(width: 0.5, height: 24)

            // Low
            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(CosmicTheme.negative)

                VStack(alignment: .leading, spacing: 0) {
                    Text("LOW")
                        .font(TerminalFont.data(8))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(String(format: "$%.2f", low))
                        .font(TerminalFont.price(13))
                        .foregroundColor(CosmicTheme.textPrimary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Price Displays") {
    ScrollView {
        VStack(spacing: 32) {
            // Size variants
            Text("SIZE VARIANTS")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            VStack(alignment: .leading, spacing: 20) {
                PriceDisplayView(
                    price: 178.52,
                    change: 2.34,
                    changePercent: 1.33,
                    size: .hero
                )

                Divider().background(CosmicTheme.border)

                PriceDisplayView(
                    price: 178.52,
                    change: 2.34,
                    changePercent: 1.33,
                    size: .large
                )

                Divider().background(CosmicTheme.border)

                PriceDisplayView(
                    price: 178.52,
                    change: -3.21,
                    changePercent: -1.77,
                    size: .medium
                )

                Divider().background(CosmicTheme.border)

                PriceDisplayView(
                    price: 178.52,
                    change: 2.34,
                    changePercent: 1.33,
                    size: .small
                )
            }
            .padding()
            .background(CosmicTheme.cardBackground)

            // Compact display
            Text("COMPACT")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            CompactPriceDisplay(price: 178.52, changePercent: 1.33)
                .padding()
                .background(CosmicTheme.cardBackground)

            // Bid/Ask
            Text("BID/ASK")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            BidAskDisplayView(bid: 178.50, ask: 178.54)

            // Day Range
            Text("DAY RANGE")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            DayRangeDisplayView(low: 175.89, high: 179.23, current: 178.52)
                .padding()
                .background(CosmicTheme.cardBackground)

            // High/Low
            Text("HIGH/LOW")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            HighLowDisplayView(high: 179.23, low: 175.89)
                .padding()
                .background(CosmicTheme.cardBackground)
        }
        .padding()
    }
    .background(CosmicTheme.background)
}

#Preview("Negative Price") {
    VStack(spacing: 20) {
        PriceDisplayView(
            price: 145.23,
            change: -8.54,
            changePercent: -5.55,
            size: .hero
        )
    }
    .padding()
    .background(CosmicTheme.background)
}
