import SwiftUI

// MARK: - CosmicSignalCard
// =========================
// Displays a detected chart pattern with its cosmic interpretation.
// The "killer feature" that combines technical analysis with astrology.

struct CosmicSignalCard: View {

    // MARK: - Properties

    let insight: CosmicPatternInsight
    @State private var isExpanded: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection

            if isExpanded {
                // Expanded content
                expandedContent
            }
        }
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: Icon, headline, alignment badge
            HStack(alignment: .top, spacing: 10) {
                // Pattern icon
                Image(systemName: insight.pattern.pattern.icon)
                    .font(.title3)
                    .foregroundColor(insight.pattern.pattern.sentiment.color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(insight.pattern.pattern.sentiment.color.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    // Headline
                    Text(insight.headline)
                        .font(TerminalFont.data(13, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineLimit(isExpanded ? nil : 1)

                    // Pattern type and sentiment
                    HStack(spacing: 8) {
                        // Sentiment badge
                        HStack(spacing: 4) {
                            Image(systemName: insight.pattern.pattern.sentiment.icon)
                                .font(.caption2)
                            Text(insight.pattern.pattern.sentiment.rawValue)
                                .font(TerminalFont.data(10, weight: .medium))
                        }
                        .foregroundColor(insight.pattern.pattern.sentiment.color)

                        // Confidence
                        Text("\(insight.pattern.formattedConfidence) confidence")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                Spacer()

                // Cosmic alignment badge
                alignmentBadge
            }

            // Cosmic score bar
            cosmicScoreBar
        }
        .padding(14)
    }

    // MARK: - Alignment Badge

    private var alignmentBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: insight.cosmicAlignment.icon)
                .font(.caption2)

            Text(shortAlignment)
                .font(TerminalFont.data(9, weight: .semibold))
        }
        .foregroundColor(insight.cosmicAlignment.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(insight.cosmicAlignment.color.opacity(0.15))
        )
    }

    private var shortAlignment: String {
        switch insight.cosmicAlignment {
        case .stronglyAligned: return "ALIGNED"
        case .aligned: return "GOOD"
        case .neutral: return "NEUTRAL"
        case .conflicted: return "CAUTION"
        case .stronglyConflicted: return "AVOID"
        }
    }

    // MARK: - Cosmic Score Bar

    private var cosmicScoreBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("COSMIC SCORE")
                    .font(TerminalFont.data(9))
                    .foregroundColor(CosmicTheme.textMuted)
                    .tracking(0.5)

                Spacer()

                Text(insight.formattedCosmicScore)
                    .font(TerminalFont.price(12))
                    .foregroundColor(insight.cosmicAlignment.color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(CosmicTheme.border)
                        .frame(height: 4)

                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [insight.cosmicAlignment.color.opacity(0.7), insight.cosmicAlignment.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (insight.cosmicScore / 100), height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(CosmicTheme.border)
                .frame(height: 1)

            // Body text
            Text(insight.body)
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Retrograde warning (if active)
            if let retrogradeWarning = insight.retrogradeWarning {
                warningBox(
                    icon: "arrow.uturn.backward.circle.fill",
                    title: "Mercury Retrograde",
                    message: retrogradeWarning,
                    color: .orange
                )
            }

            // Moon phase note
            if let moonNote = insight.moonPhaseNote {
                infoBox(
                    icon: "moon.fill",
                    message: moonNote,
                    color: CosmicTheme.gold
                )
            }

            // Compatibility note
            if let compatNote = insight.compatibilityNote {
                infoBox(
                    icon: "sparkles",
                    message: compatNote,
                    color: CosmicTheme.accentBlue
                )
            }

            // Action advice
            actionAdviceSection

            // Premium badge if applicable
            if insight.isPremium {
                premiumBadge
            }

            // Detection details
            detailsSection
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    // MARK: - Warning Box

    private func warningBox(icon: String, title: String, message: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TerminalFont.data(10, weight: .semibold))
                    .foregroundColor(color)

                Text(message)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Info Box

    private func infoBox(icon: String, message: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(message)
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Action Advice

    private var actionAdviceSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)

            VStack(alignment: .leading, spacing: 2) {
                Text("COSMIC GUIDANCE")
                    .font(TerminalFont.data(9, weight: .semibold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(0.5)

                Text(insight.actionAdvice)
                    .font(TerminalFont.data(11))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.gold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(CosmicTheme.gold.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Premium Badge

    private var premiumBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption2)

            Text("ORACLE INSIGHT")
                .font(TerminalFont.data(9, weight: .bold))
                .tracking(1)
        }
        .foregroundColor(CosmicTheme.gold)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(CosmicTheme.gold.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        HStack {
            // Detection time
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(insight.pattern.formattedDate)
                    .font(TerminalFont.data(10))
            }
            .foregroundColor(CosmicTheme.textMuted)

            Spacer()

            // Price at detection
            HStack(spacing: 4) {
                Text("@")
                    .font(TerminalFont.data(10))
                Text(insight.pattern.formattedPrice)
                    .font(TerminalFont.data(10, weight: .medium))
            }
            .foregroundColor(CosmicTheme.textMuted)

            Spacer()

            // Expand/collapse indicator
            Image(systemName: "chevron.up")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)
                .rotationEffect(.degrees(isExpanded ? 0 : 180))
        }
    }

    // MARK: - Border Color

    private var borderColor: Color {
        if isExpanded {
            return insight.cosmicAlignment.color.opacity(0.3)
        }
        return CosmicTheme.border
    }
}

// MARK: - Cosmic Signals Section

/// A section displaying all cosmic signals for a stock
struct CosmicSignalsSection: View {

    let insights: [CosmicPatternInsight]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.gold)

                    Text("COSMIC NOTES")
                        .font(TerminalFont.data(11, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .tracking(1)
                }

                Spacer()

                if !insights.isEmpty {
                    Text("\(insights.count) DETECTED")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            if isLoading {
                loadingView
            } else if insights.isEmpty {
                emptyView
            } else {
                // Signal cards
                ForEach(insights) { insight in
                    CosmicSignalCard(insight: insight)
                }
            }

            // Disclaimer
            disclaimerText
        }
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(CosmicTheme.gold)

            Text("Analyzing cosmic patterns...")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textMuted)
                .italic()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(CosmicTheme.textMuted)

            Text("No significant patterns detected")
                .font(TerminalFont.data(12))
                .foregroundColor(CosmicTheme.textMuted)

            Text("The cosmos await the right moment")
                .font(TerminalFont.data(11))
                .foregroundColor(CosmicTheme.textMuted)
                .italic()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var disclaimerText: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle")
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)

            Text("Technical patterns and cosmic interpretations are for entertainment purposes only. Not financial advice.")
                .font(TerminalFont.data(9))
                .foregroundColor(CosmicTheme.textMuted)
        }
    }
}

// MARK: - Compact Signal Badge

/// A compact badge showing the most significant signal
struct CosmicSignalBadge: View {

    let insight: CosmicPatternInsight

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: insight.pattern.pattern.icon)
                .font(.caption2)
                .foregroundColor(insight.pattern.pattern.sentiment.color)

            Text(insight.pattern.pattern.rawValue)
                .font(TerminalFont.data(10, weight: .medium))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            // Alignment indicator
            Circle()
                .fill(insight.cosmicAlignment.color)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(CosmicTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CosmicTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Cosmic Note Card") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 16) {
                // Sample insights
                CosmicSignalCard(
                    insight: CosmicPatternInsight(
                        pattern: DetectedPattern(
                            pattern: .goldenCross,
                            confidence: 92,
                            detectedAt: Date(),
                            priceAtDetection: 178.52,
                            details: "50-day MA crossed above 200-day MA"
                        ),
                        headline: "GOLDEN CROSS - Major Pattern Note",
                        body: "The 50-day moving average has crossed above the 200-day. Historically, this pattern can accompany sustained upward momentum.",
                        cosmicAlignment: .stronglyAligned,
                        retrogradeWarning: nil,
                        moonPhaseNote: "Waxing Moon: Building energy favors bullish patterns.",
                        compatibilityNote: "Your Leo energy aligns well with this Aries stock.",
                        actionAdvice: "Use this as context alongside your own notes."
                    )
                )

                CosmicSignalCard(
                    insight: CosmicPatternInsight(
                        pattern: DetectedPattern(
                            pattern: .overbought,
                            confidence: 78,
                            detectedAt: Date(),
                            priceAtDetection: 505.75,
                            details: "RSI at 78.5 - above 70 threshold"
                        ),
                        headline: "Overbought Territory — Cool Down Expected",
                        body: "RSI has pushed above 70, indicating potentially unsustainable demand pressure.",
                        cosmicAlignment: .conflicted,
                        retrogradeWarning: "Mercury Retrograde Active: Exercise extra caution.",
                        moonPhaseNote: "Full Moon Energy: Volatility may spike.",
                        compatibilityNote: "Challenging alignment with your sign.",
                        actionAdvice: "Use this as context alongside your own notes."
                    )
                )
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Cosmic Notes Section - Empty") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        CosmicSignalsSection(insights: [], isLoading: false)
            .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Cosmic Notes Section - Loading") {
    ZStack {
        CosmicTheme.background.ignoresSafeArea()

        CosmicSignalsSection(insights: [], isLoading: true)
            .padding()
    }
    .preferredColorScheme(.dark)
}
