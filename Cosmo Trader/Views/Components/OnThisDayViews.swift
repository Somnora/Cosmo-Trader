import SwiftUI

// MARK: - On This Day Views
// ==========================
// UI components for displaying historical market tidbits.
// "On Dec 12, 1980, Apple went public (Sagittarius)..."

// MARK: - On This Day Card

struct OnThisDayCard: View {
    let event: HistoricalMarketEvent

    @State private var isExpanded: Bool = false
    @State private var showShareSheet: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                // Calendar icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(CosmicTheme.gold.opacity(0.15))
                        .frame(width: 44, height: 44)

                    VStack(spacing: 0) {
                        Text(monthAbbrev)
                            .font(TerminalFont.caption(9, weight: .bold))
                            .foregroundColor(CosmicTheme.gold)

                        Text("\(event.day)")
                            .font(TerminalFont.body(16, weight: .bold))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("On This Day")
                        .font(TerminalFont.caption(10, weight: .medium))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text("\(event.year)")
                        .font(TerminalFont.body(14, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)
                }

                Spacer()

                // Zodiac badge
                HStack(spacing: 4) {
                    Text(event.zodiacSign.symbol)
                        .font(.caption)

                    Text(event.zodiacSign.displayName)
                        .font(TerminalFont.caption(10, weight: .medium))
                        .foregroundColor(event.zodiacSign.element.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(event.zodiacSign.element.color.opacity(0.15))
                )
            }

            // Headline
            Text(event.headline.prefix(1).uppercased() + event.headline.dropFirst())
                .font(TerminalFont.body(14, weight: .medium))
                .foregroundColor(CosmicTheme.textPrimary)
                .lineLimit(isExpanded ? nil : 2)

            // Detail (expanded)
            if isExpanded {
                Text(event.detail)
                    .font(TerminalFont.caption(12))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Cosmic takeaway
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text(event.cosmicTakeaway)
                    .font(TerminalFont.caption(11))
                    .italic()
                    .foregroundColor(CosmicTheme.gold.opacity(0.9))
                    .lineLimit(isExpanded ? nil : 1)
            }

            // Category & actions
            HStack {
                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: event.category.icon)
                        .font(.caption2)

                    Text(event.category.rawValue)
                        .font(TerminalFont.caption(9, weight: .medium))
                }
                .foregroundColor(event.category.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(event.category.color.opacity(0.15))
                )

                Spacer()

                // Share button
                Button(action: {
                    showShareSheet = true
                    AnalyticsService.shared.track(.onThisDayShared)
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                // Expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CosmicTheme.gold.opacity(0.2), lineWidth: 0.5)
                )
        )
        .onAppear {
            AnalyticsService.shared.track(.onThisDayViewed)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: event.shareableText)
        }
    }

    private var monthAbbrev: String {
        let months = ["", "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        return months[event.month]
    }
}

// MARK: - Compact On This Day Banner

struct OnThisDayBanner: View {
    let event: HistoricalMarketEvent
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Date
                VStack(spacing: 0) {
                    Text(monthAbbrev)
                        .font(TerminalFont.caption(8, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)

                    Text("\(event.day)")
                        .font(TerminalFont.body(14, weight: .bold))
                        .foregroundColor(CosmicTheme.textPrimary)
                }
                .frame(width: 36)

                // Divider
                Rectangle()
                    .fill(CosmicTheme.textMuted.opacity(0.3))
                    .frame(width: 1, height: 28)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text("On This Day in \(event.year)")
                        .font(TerminalFont.caption(9, weight: .medium))
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(event.headline.prefix(1).uppercased() + event.headline.dropFirst())
                        .font(TerminalFont.caption(11))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                // Zodiac
                Text(event.zodiacSign.symbol)
                    .font(.body)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(CosmicTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private var monthAbbrev: String {
        let months = ["", "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        return months[event.month]
    }
}

// MARK: - On This Day Detail Sheet

struct OnThisDayDetailSheet: View {
    let event: HistoricalMarketEvent
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero section
                    VStack(spacing: 16) {
                        // Large date display
                        VStack(spacing: 4) {
                            Text(fullMonthName)
                                .font(TerminalFont.caption(12, weight: .medium))
                                .foregroundColor(CosmicTheme.textMuted)

                            Text("\(event.day)")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(CosmicTheme.gold)

                            Text("\(event.year)")
                                .font(TerminalFont.headline(24))
                                .foregroundColor(CosmicTheme.textPrimary)
                        }

                        // Zodiac badge
                        HStack(spacing: 8) {
                            Text(event.zodiacSign.symbol)
                                .font(.title2)

                            Text(event.zodiacSign.displayName)
                                .font(TerminalFont.body(16, weight: .semibold))
                                .foregroundColor(event.zodiacSign.element.color)

                            Text("Season")
                                .font(TerminalFont.caption(12))
                                .foregroundColor(CosmicTheme.textMuted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(event.zodiacSign.element.color.opacity(0.15))
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    Divider()
                        .background(CosmicTheme.textMuted.opacity(0.3))

                    // Event content
                    VStack(alignment: .leading, spacing: 16) {
                        // Headline
                        Text("On this day, \(event.headline).")
                            .font(TerminalFont.body(18, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)

                        // Detail
                        Text(event.detail)
                            .font(TerminalFont.body(14))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .lineSpacing(4)

                        // Category badge
                        HStack(spacing: 6) {
                            Image(systemName: event.category.icon)
                                .font(.subheadline)

                            Text(event.category.rawValue)
                                .font(TerminalFont.body(12, weight: .medium))
                        }
                        .foregroundColor(event.category.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(event.category.color.opacity(0.15))
                        )
                    }
                    .padding(.horizontal, 20)

                    // Cosmic takeaway card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.gold)

                            Text("Cosmic Takeaway")
                                .font(TerminalFont.body(14, weight: .semibold))
                                .foregroundColor(CosmicTheme.gold)
                        }

                        Text(event.cosmicTakeaway)
                            .font(TerminalFont.body(14))
                            .italic()
                            .foregroundColor(CosmicTheme.textPrimary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(CosmicTheme.gold.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)

                    // Share button
                    Button(action: { showShareSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share This Cosmic Moment")
                        }
                        .font(TerminalFont.body(14, weight: .semibold))
                        .foregroundColor(CosmicTheme.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(CosmicTheme.gold, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(CosmicTheme.background)
            .navigationTitle("On This Day")
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
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: event.shareableText)
        }
    }

    private var fullMonthName: String {
        let months = ["", "January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"]
        return months[event.month]
    }
}

// MARK: - On This Day Section (for PortfolioView)

struct OnThisDaySection: View {
    @State private var service = OnThisDayService.shared
    @State private var showDetail: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(CosmicTheme.gold)
                Text("Cosmic History")
                    .font(TerminalFont.body(14, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                Text("Today")
                    .font(TerminalFont.caption(10))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            // Card
            OnThisDayCard(event: service.getTodaysEvent())
        }
    }
}

// MARK: - Previews

#Preview("On This Day Card") {
    VStack {
        OnThisDayCard(event: HistoricalMarketEvent.allEvents.first(where: { $0.month == 12 && $0.day == 12 }) ?? .fallback)
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("On This Day Banner") {
    VStack {
        OnThisDayBanner(event: HistoricalMarketEvent.allEvents.first(where: { $0.month == 12 && $0.day == 12 }) ?? .fallback)
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("On This Day Detail") {
    OnThisDayDetailSheet(event: HistoricalMarketEvent.allEvents.first(where: { $0.month == 12 && $0.day == 12 }) ?? .fallback)
        .preferredColorScheme(.dark)
}
