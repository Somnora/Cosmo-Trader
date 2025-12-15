import SwiftUI

// MARK: - OptionExpiryView
// =========================
// Terminal-style display of option expiration compatibility.
// Shows upcoming monthly expirations with cosmic alignment scores.

struct OptionExpiryView: View {

    // MARK: - Properties

    let userSign: ZodiacSign
    @State private var expiries: [ExpiryCompatibility] = []
    @State private var selectedExpiry: ExpiryCompatibility?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection

            // Divider
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            // Table header
            tableHeader

            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            // Expiry rows
            ForEach(expiries) { expiry in
                expiryRow(expiry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedExpiry?.id == expiry.id {
                                selectedExpiry = nil
                            } else {
                                selectedExpiry = expiry
                            }
                        }
                    }

                // Expanded detail
                if selectedExpiry?.id == expiry.id {
                    expiryDetail(expiry)
                }

                Rectangle()
                    .fill(CosmicTheme.border.opacity(0.5))
                    .frame(height: 1)
            }

            // Legend
            legendSection
        }
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
        .onAppear {
            loadExpiries()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.gold)

                    Text("OPTION EXPIRY ALIGNMENT")
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .tracking(1)
                }

                Text("Monthly expirations aligned with your \(userSign.displayName) energy")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            // User sign badge
            VStack(spacing: 2) {
                ZodiacSymbolView(sign: userSign, size: 18, color: CosmicTheme.gold)
                Text(userSign.symbol)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(12)
    }

    // MARK: - Table Header

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("DATE")
                .frame(width: 60, alignment: .leading)
            Text("SIGN")
                .frame(width: 90, alignment: .leading)
            Text("SCORE")
                .frame(width: 50, alignment: .center)
            Text("MOON")
                .frame(width: 40, alignment: .center)
            Text("STATUS")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(TerminalFont.data(9))
        .foregroundColor(CosmicTheme.textMuted)
        .tracking(0.5)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CosmicTheme.background)
    }

    // MARK: - Expiry Row

    private func expiryRow(_ expiry: ExpiryCompatibility) -> some View {
        let isBest = expiries.first?.id == expiry.id
        let isSelected = selectedExpiry?.id == expiry.id

        return HStack(spacing: 0) {
            // Date
            Text(expiry.formattedDate)
                .font(TerminalFont.data(12, weight: .medium))
                .foregroundColor(CosmicTheme.textPrimary)
                .frame(width: 60, alignment: .leading)

            // Zodiac sign
            HStack(spacing: 6) {
                Text(expiry.zodiacSign.symbol)
                    .font(.caption)
                Text(expiry.zodiacSign.displayName)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
            .frame(width: 90, alignment: .leading)

            // Score
            Text("\(expiry.score)%")
                .font(TerminalFont.price(12))
                .foregroundColor(scoreColor(expiry.score))
                .frame(width: 50, alignment: .center)

            // Moon phase
            Text(expiry.moonPhase.emoji)
                .font(.caption)
                .frame(width: 40, alignment: .center)

            // Status indicators
            HStack(spacing: 4) {
                if isBest {
                    bestBadge
                }
                if expiry.hasWarnings {
                    warningBadge
                }

                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .font(.system(size: 8))
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            isSelected ? CosmicTheme.gold.opacity(0.05) :
            isBest ? CosmicTheme.positive.opacity(0.05) : Color.clear
        )
    }

    private var bestBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text("BEST")
                .font(TerminalFont.data(8, weight: .semibold))
        }
        .foregroundColor(CosmicTheme.gold)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(CosmicTheme.gold.opacity(0.15))
        )
    }

    private var warningBadge: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 10))
            .foregroundColor(.orange)
    }

    // MARK: - Expiry Detail

    private func expiryDetail(_ expiry: ExpiryCompatibility) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Insight
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold.opacity(0.7))

                Text(expiry.insight)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Warnings
            if !expiry.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(expiry.warnings) { warning in
                        HStack(spacing: 8) {
                            Image(systemName: warning.icon)
                                .font(.caption2)
                                .foregroundColor(.orange)

                            Text(warning.message)
                                .font(TerminalFont.data(10))
                                .foregroundColor(.orange.opacity(0.9))
                        }
                    }
                }
            }

            // Full date and days until
            HStack {
                Text(expiry.fullFormattedDate)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)

                Spacer()

                Text("\(expiry.daysUntil) days away")
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(12)
        .background(CosmicTheme.background.opacity(0.5))
    }

    // MARK: - Legend

    private var legendSection: some View {
        HStack(spacing: 16) {
            legendItem(color: CosmicTheme.positive, text: "80%+ Aligned")
            legendItem(color: CosmicTheme.textSecondary, text: "65-79% Neutral")
            legendItem(color: CosmicTheme.negative, text: "<65% Caution")
        }
        .padding(10)
        .background(CosmicTheme.background)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(text)
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
        }
    }

    // MARK: - Helpers

    private func loadExpiries() {
        expiries = OptionCompatibilityService.getCompatibleExpirations(
            userSign: userSign,
            expiryCount: 6
        )
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return CosmicTheme.positive
        case 65..<80: return CosmicTheme.textSecondary
        default: return CosmicTheme.negative
        }
    }
}

// MARK: - Compact Option Expiry Card
// ==================================
// A smaller card for embedding in other views.

struct OptionExpiryCard: View {

    let userSign: ZodiacSign
    @State private var bestExpiry: ExpiryCompatibility?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.gold)

                    Text("NEXT BEST EXPIRY")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                        .tracking(1)
                }

                Spacer()

                if let expiry = bestExpiry {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                        Text("\(expiry.score)%")
                            .font(TerminalFont.data(10, weight: .semibold))
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }

            if let expiry = bestExpiry {
                // Main content
                HStack(spacing: 12) {
                    // Date and sign
                    VStack(alignment: .leading, spacing: 2) {
                        Text(expiry.formattedDate)
                            .font(TerminalFont.price(18))
                            .foregroundColor(CosmicTheme.textPrimary)

                        HStack(spacing: 4) {
                            Text(expiry.zodiacSign.symbol)
                                .font(.caption)
                            Text(expiry.zodiacSign.displayName)
                                .font(TerminalFont.data(11))
                                .foregroundColor(CosmicTheme.textSecondary)
                        }
                    }

                    Spacer()

                    // Moon phase
                    VStack(spacing: 2) {
                        Text(expiry.moonPhase.emoji)
                            .font(.title3)

                        Text("\(expiry.daysUntil)d")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                // Insight
                Text(expiry.insight)
                    .font(TerminalFont.data(10))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Calculating cosmic alignment...")
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(12)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
        .onAppear {
            bestExpiry = OptionCompatibilityService.getBestExpiry(userSign: userSign)
        }
    }
}

// MARK: - Preview

#Preview("Option Expiry View") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                OptionExpiryView(userSign: .leo)
                    .padding(.horizontal)

                OptionExpiryCard(userSign: .leo)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    .preferredColorScheme(.dark)
}
