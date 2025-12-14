//
//  WidgetViews.swift
//  Cosmo Trader Widget
//
//  Widget views for small (2x2) and medium (4x2) sizes.
//  OLED terminal aesthetic matching the main app.
//

import SwiftUI
import WidgetKit

// MARK: - Widget Colors (OLED Terminal Theme)

enum WidgetTheme {
    static let background = Color.black
    static let cardBackground = Color(red: 0.06, green: 0.06, blue: 0.08)
    static let gold = Color(red: 0.85, green: 0.75, blue: 0.45)
    static let textPrimary = Color(red: 0.93, green: 0.93, blue: 0.91)
    static let textSecondary = Color(red: 0.65, green: 0.65, blue: 0.63)
    static let textMuted = Color(red: 0.45, green: 0.45, blue: 0.43)
    static let positive = Color(red: 0.30, green: 0.78, blue: 0.40)
    static let negative = Color(red: 0.90, green: 0.35, blue: 0.35)
    static let border = Color(red: 0.25, green: 0.25, blue: 0.27)

    static func sentimentColor(_ sentiment: String) -> Color {
        switch sentiment {
        case "Bullish": return positive
        case "Bearish": return negative
        case "Volatile": return .orange
        default: return textSecondary
        }
    }

    static func signalColor(_ type: String) -> Color {
        switch type {
        case "Accumulate", "Build Position":
            return positive
        case "Caution":
            return .orange
        case "Take Profit", "Reduce":
            return gold
        default:
            return textSecondary
        }
    }
}

// MARK: - Small Moon Widget (2x2)

struct SmallMoonWidget: View {
    let data: WidgetLunarData

    var body: some View {
        ZStack {
            // OLED black background
            WidgetTheme.background

            VStack(spacing: 8) {
                // Moon emoji and phase
                HStack(spacing: 6) {
                    Text(data.phaseEmoji)
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.phaseName.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(WidgetTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(data.formattedIllumination)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(WidgetTheme.textSecondary)
                    }
                }

                // Countdown to significant phases
                HStack(spacing: 12) {
                    countdownPill(emoji: "🌕", days: data.daysUntilFullMoon)
                    countdownPill(emoji: "🌑", days: data.daysUntilNewMoon)
                }

                // Trading signal
                HStack(spacing: 4) {
                    Circle()
                        .fill(WidgetTheme.signalColor(data.tradingSignalType))
                        .frame(width: 6, height: 6)

                    Text(data.shortTradingInsight.uppercased())
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(WidgetTheme.signalColor(data.tradingSignalType))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(WidgetTheme.signalColor(data.tradingSignalType).opacity(0.15))
                )
            }
            .padding(12)
        }
    }

    private func countdownPill(emoji: String, days: Int) -> some View {
        HStack(spacing: 3) {
            Text(emoji)
                .font(.system(size: 10))
            Text("\(days)d")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(days <= 2 ? WidgetTheme.gold : WidgetTheme.textSecondary)
        }
    }
}

// MARK: - Medium Moon Widget (4x2)

struct MediumMoonWidget: View {
    let data: WidgetLunarData

    var body: some View {
        ZStack {
            // OLED black background
            WidgetTheme.background

            HStack(spacing: 16) {
                // Left side: Moon visual
                VStack(spacing: 8) {
                    // Large moon emoji
                    Text(data.phaseEmoji)
                        .font(.system(size: 44))

                    // Phase name
                    Text(data.phaseName.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(WidgetTheme.textPrimary)

                    // Illumination
                    Text(data.formattedIllumination + " LIT")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(WidgetTheme.textSecondary)

                    // Waxing/Waning indicator
                    HStack(spacing: 3) {
                        Image(systemName: data.isWaxing ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8))
                        Text(data.isWaxing ? "WAXING" : "WANING")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(data.isWaxing ? WidgetTheme.positive : WidgetTheme.textMuted)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(WidgetTheme.border)
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Right side: Trading info
                VStack(alignment: .leading, spacing: 10) {
                    // Trading signal headline
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SIGNAL")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(WidgetTheme.textMuted)

                        Text(data.tradingSignalHeadline.uppercased())
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(WidgetTheme.signalColor(data.tradingSignalType))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    // Trading insight
                    Text(data.shortTradingInsight)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(WidgetTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    // Countdown row
                    HStack(spacing: 16) {
                        countdownItem(label: "FULL", emoji: "🌕", days: data.daysUntilFullMoon)
                        countdownItem(label: "NEW", emoji: "🌑", days: data.daysUntilNewMoon)
                    }

                    // Sentiment badge
                    HStack(spacing: 4) {
                        Image(systemName: sentimentIcon(data.tradingSignalSentiment))
                            .font(.system(size: 9))
                        Text(data.tradingSignalSentiment.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(WidgetTheme.sentimentColor(data.tradingSignalSentiment))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(WidgetTheme.sentimentColor(data.tradingSignalSentiment).opacity(0.15))
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
    }

    private func countdownItem(label: String, emoji: String, days: Int) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Text(emoji)
                    .font(.system(size: 10))
                Text("\(days)d")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(days <= 2 ? WidgetTheme.gold : WidgetTheme.textPrimary)
            }
            Text(label)
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundColor(WidgetTheme.textMuted)
        }
    }

    private func sentimentIcon(_ sentiment: String) -> String {
        switch sentiment {
        case "Bullish": return "arrow.up.right"
        case "Bearish": return "arrow.down.right"
        case "Volatile": return "arrow.up.arrow.down"
        default: return "arrow.right"
        }
    }
}

// MARK: - Preview

#Preview("Small Widget") {
    SmallMoonWidget(data: .placeholder)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
}

#Preview("Medium Widget") {
    MediumMoonWidget(data: .placeholder)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
}

#Preview("Small - Full Moon") {
    SmallMoonWidget(data: WidgetLunarData(
        date: Date(),
        phaseName: "Full Moon",
        phaseEmoji: "🌕",
        illumination: 0.99,
        isWaxing: false,
        daysUntilFullMoon: 0,
        daysUntilNewMoon: 15,
        moonSignName: "Leo",
        moonSignElement: "Fire",
        tradingSignalHeadline: "Peak Volatility",
        tradingSignalType: "Caution",
        tradingSignalSentiment: "Volatile"
    ))
    .previewContext(WidgetPreviewContext(family: .systemSmall))
}

#Preview("Medium - New Moon") {
    MediumMoonWidget(data: WidgetLunarData(
        date: Date(),
        phaseName: "New Moon",
        phaseEmoji: "🌑",
        illumination: 0.01,
        isWaxing: true,
        daysUntilFullMoon: 15,
        daysUntilNewMoon: 0,
        moonSignName: "Capricorn",
        moonSignElement: "Earth",
        tradingSignalHeadline: "Accumulation Phase",
        tradingSignalType: "Accumulate",
        tradingSignalSentiment: "Bullish"
    ))
    .previewContext(WidgetPreviewContext(family: .systemMedium))
}
