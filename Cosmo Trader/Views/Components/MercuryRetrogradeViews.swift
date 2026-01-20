import SwiftUI

// MARK: - Mercury Retrograde Views
// =================================
// Always-visible countdown for Mercury Retrograde in CosmosView.
//
// "Next Mercury Retrograde: 23 days"
// or
// "MERCURY RETROGRADE ACTIVE — Day 12 of 21"

// MARK: - Mercury Retrograde Banner (Primary Display)

struct MercuryRetrogradeBanner: View {
    @State private var service = MercuryRetrogradeService.shared
    @State private var showDetail: Bool = false
    @State private var pulseAnimation: Bool = false

    var body: some View {
        Button(action: { showDetail = true }) {
            VStack(spacing: 0) {
                // Main content
                HStack(spacing: 12) {
                    // Status icon with animation
                    ZStack {
                        if service.isRetrograde {
                            Circle()
                                .fill(service.statusColor.opacity(0.3))
                                .frame(width: 48, height: 48)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .opacity(pulseAnimation ? 0.5 : 1.0)
                        }

                        Circle()
                            .fill(service.statusColor.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: service.statusIcon)
                            .font(.title2)
                            .foregroundColor(service.statusColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // Status message
                        HStack(spacing: 6) {
                            Text(service.statusMessage)
                                .font(TerminalFont.body(13, weight: .bold))
                                .foregroundColor(service.isRetrograde ? service.statusColor : CosmicTheme.textPrimary)

                            if service.isRetrograde {
                                Text("☿️")
                                    .font(.caption)
                            }
                        }

                        // Countdown/progress
                        Text(service.countdownText)
                            .font(TerminalFont.caption(11))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }

                    Spacer()

                    // Progress or countdown display
                    if service.isRetrograde {
                        // Progress ring
                        ZStack {
                            Circle()
                                .stroke(CosmicTheme.textMuted.opacity(0.3), lineWidth: 3)
                                .frame(width: 36, height: 36)

                            Circle()
                                .trim(from: 0, to: service.progressPercentage)
                                .stroke(service.statusColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 36, height: 36)
                                .rotationEffect(.degrees(-90))

                            Text("\(service.daysRemaining)")
                                .font(TerminalFont.caption(10, weight: .bold))
                                .foregroundColor(service.statusColor)
                        }
                    } else if service.daysUntilNext > 0 {
                        // Countdown number
                        VStack(spacing: 2) {
                            Text("\(service.daysUntilNext)")
                                .font(TerminalFont.body(18, weight: .bold))
                                .foregroundColor(service.statusColor)
                            Text("days")
                                .font(TerminalFont.caption(9))
                                .foregroundColor(CosmicTheme.textMuted)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(16)

                // Progress bar (for active retrograde)
                if service.isRetrograde {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(CosmicTheme.textMuted.opacity(0.2))
                                .frame(height: 3)

                            Rectangle()
                                .fill(service.statusColor)
                                .frame(width: geo.size.width * service.progressPercentage, height: 3)
                        }
                    }
                    .frame(height: 3)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(service.isRetrograde
                        ? service.statusColor.opacity(0.1)
                        : CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(service.statusColor.opacity(0.3), lineWidth: service.isRetrograde ? 1 : 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if service.isRetrograde {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
            if let event = AnalyticsEvent.mercuryRetrogradeViewed {
                AnalyticsService.shared.track(event)
            }
        }
        .sheet(isPresented: $showDetail) {
            MercuryRetrogradeDetailSheet()
        }
    }
}

// MARK: - Compact Banner (for smaller spaces)

struct MercuryRetrogradeCompactBanner: View {
    @State private var service = MercuryRetrogradeService.shared

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: service.statusIcon)
                .font(.caption)
                .foregroundColor(service.statusColor)

            // Text
            if service.isRetrograde {
                Text("☿️ RETROGRADE")
                    .font(TerminalFont.caption(10, weight: .bold))
                    .foregroundColor(service.statusColor)

                Text("Day \(service.currentDayOfRetrograde)/\(service.totalRetrogradeDays)")
                    .font(TerminalFont.caption(10))
                    .foregroundColor(CosmicTheme.textSecondary)
            } else {
                Text("☿️ Direct")
                    .font(TerminalFont.caption(10, weight: .medium))
                    .foregroundColor(CosmicTheme.textSecondary)

                if service.daysUntilNext > 0 && service.daysUntilNext <= 30 {
                    Text("(\(service.daysUntilNext)d)")
                        .font(TerminalFont.caption(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(service.isRetrograde
                    ? service.statusColor.opacity(0.15)
                    : CosmicTheme.cardBackground)
        )
    }
}

// MARK: - Detail Sheet

struct MercuryRetrogradeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service = MercuryRetrogradeService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection

                    // Status card
                    statusCard

                    // Advice sections
                    adviceSection

                    // 2025 retrograde schedule
                    scheduleSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(CosmicTheme.background)
            .navigationTitle("Mercury Retrograde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Large Mercury symbol
            ZStack {
                Circle()
                    .fill(service.statusColor.opacity(0.2))
                    .frame(width: 100, height: 100)

                if service.isRetrograde {
                    // Retrograde arrow animation
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(service.statusColor)
                } else {
                    Text("☿")
                        .font(.system(size: 56))
                        .foregroundColor(service.statusColor)
                }
            }

            // Status
            Text(service.statusMessage)
                .font(TerminalFont.headline(20))
                .foregroundColor(service.statusColor)

            // Countdown
            if service.isRetrograde {
                VStack(spacing: 4) {
                    Text("Day \(service.currentDayOfRetrograde) of \(service.totalRetrogradeDays)")
                        .font(TerminalFont.body(16, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("\(service.daysRemaining) days remaining")
                        .font(TerminalFont.caption(12))
                        .foregroundColor(CosmicTheme.textSecondary)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(CosmicTheme.textMuted.opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(service.statusColor)
                                .frame(width: geo.size.width * service.progressPercentage, height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                }
            } else if service.daysUntilNext > 0 {
                VStack(spacing: 4) {
                    Text("\(service.daysUntilNext)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(service.statusColor)

                    Text("days until next retrograde")
                        .font(TerminalFont.caption(12))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
        .padding(.top, 20)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(service.status.emoji)
                    .font(.title2)

                Text("Current Status")
                    .font(TerminalFont.body(14, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            Text(service.currentAdvice)
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(service.statusColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(service.statusColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var adviceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trading Advice")
                .font(TerminalFont.body(14, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)

            VStack(alignment: .leading, spacing: 12) {
                adviceRow(icon: "chart.line.uptrend.xyaxis", text: service.tradingAdvice)

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))

                adviceRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "Mercury Retrograde affects communication, technology, and contracts. Be extra careful with trading platforms and order confirmations.",
                    color: .orange
                )

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.3))

                adviceRow(
                    icon: "lightbulb.fill",
                    text: "This is actually a great time for reviewing past investments and reconsidering positions you've been unsure about.",
                    color: .yellow
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private func adviceRow(icon: String, text: String, color: Color = CosmicTheme.textSecondary) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(TerminalFont.caption(12))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("2025 Mercury Retrograde Schedule")
                .font(TerminalFont.body(14, weight: .semibold))
                .foregroundColor(CosmicTheme.gold)

            VStack(spacing: 12) {
                ForEach(MercuryRetrogradeService.retrograde2025Periods, id: \.start) { period in
                    retrogradeRow(start: period.start, end: period.end, sign: period.sign)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )

            // Disclaimer
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)

                Text("Mercury goes retrograde approximately 3-4 times per year, each lasting about 3 weeks. These are times to review, reflect, and revise — not necessarily to avoid trading entirely.")
                    .font(TerminalFont.caption(10))
                    .foregroundColor(CosmicTheme.textMuted)
                    .lineSpacing(3)
            }
        }
    }

    private func retrogradeRow(start: String, end: String, sign: String) -> some View {
        HStack {
            // Dates
            VStack(alignment: .leading, spacing: 2) {
                Text("\(start) — \(end)")
                    .font(TerminalFont.body(13, weight: .medium))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(sign)
                    .font(TerminalFont.caption(11))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()

            // Mercury symbol
            Text("☿️")
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Inline Status (for headers)

struct MercuryRetrogradeInlineStatus: View {
    @State private var service = MercuryRetrogradeService.shared

    var body: some View {
        HStack(spacing: 4) {
            if service.isRetrograde {
                Image(systemName: "arrow.uturn.backward")
                    .font(.caption2)
                    .foregroundColor(.orange)

                Text("Rx")
                    .font(TerminalFont.caption(9, weight: .bold))
                    .foregroundColor(.orange)
            } else {
                Text("☿")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Previews

#Preview("Mercury Retrograde Banner - Active") {
    VStack {
        MercuryRetrogradeBanner()
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Compact Banner") {
    VStack {
        MercuryRetrogradeCompactBanner()
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Detail Sheet") {
    MercuryRetrogradeDetailSheet()
        .preferredColorScheme(.dark)
}
