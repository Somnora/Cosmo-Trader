//
//  PortfolioWidget.swift
//  Cosmo Trader Widget
//
//  Portfolio widget showing value, daily change, and top holdings.
//  Supports small (2x2) and medium (4x2) sizes.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct PortfolioEntry: TimelineEntry {
    let date: Date
    let portfolio: WidgetPortfolioData
    let isPreview: Bool

    static let placeholder = PortfolioEntry(
        date: Date(),
        portfolio: .placeholder,
        isPreview: true
    )
}

// MARK: - Timeline Provider

struct PortfolioTimelineProvider: TimelineProvider {

    typealias Entry = PortfolioEntry

    func placeholder(in context: Context) -> PortfolioEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PortfolioEntry) -> Void) {
        let entry: PortfolioEntry

        if context.isPreview {
            entry = .placeholder
        } else if let data = WidgetDataProvider.readPortfolioData() {
            entry = PortfolioEntry(date: Date(), portfolio: data, isPreview: false)
        } else {
            entry = PortfolioEntry(date: Date(), portfolio: .placeholder, isPreview: false)
        }

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PortfolioEntry>) -> Void) {
        let currentDate = Date()
        let portfolio = WidgetDataProvider.readPortfolioData() ?? .placeholder

        let entry = PortfolioEntry(date: currentDate, portfolio: portfolio, isPreview: false)

        // Refresh every 15 minutes during market hours, hourly otherwise
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Portfolio Widget

struct PortfolioWidget: Widget {
    let kind: String = "PortfolioWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PortfolioTimelineProvider()) { entry in
            PortfolioWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Cosmic Portfolio")
        .description("Your portfolio at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Entry View

struct PortfolioWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PortfolioEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallPortfolioWidget(data: entry.portfolio)
        case .systemMedium:
            MediumPortfolioWidget(data: entry.portfolio)
        default:
            SmallPortfolioWidget(data: entry.portfolio)
        }
    }
}

// MARK: - Small Portfolio Widget (2x2)

struct SmallPortfolioWidget: View {
    let data: WidgetPortfolioData

    var body: some View {
        ZStack {
            WidgetTheme.background

            VStack(alignment: .leading, spacing: 6) {
                // Header
                Text("PORTFOLIO")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(WidgetTheme.textMuted)

                // Divider
                Rectangle()
                    .fill(WidgetTheme.gold.opacity(0.4))
                    .frame(height: 1)

                Spacer()

                // Change percentage - main focus
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(data.formattedChange)
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundColor(data.isPositive ? WidgetTheme.positive : WidgetTheme.negative)

                    Image(systemName: data.isPositive ? "arrow.up" : "arrow.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(data.isPositive ? WidgetTheme.positive : WidgetTheme.negative)
                }

                // Total value
                Text(data.formattedValue)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(WidgetTheme.textSecondary)

                Spacer()
            }
            .padding(12)
        }
    }
}

// MARK: - Medium Portfolio Widget (4x2)

struct MediumPortfolioWidget: View {
    let data: WidgetPortfolioData

    /// Whether to use mystical language (reads from shared framing level)
    private var useMysticalLanguage: Bool {
        WidgetDataProvider.isMysticalFraming()
    }

    var body: some View {
        ZStack {
            WidgetTheme.background

            VStack(spacing: 10) {
                // Header row
                HStack {
                    Text(useMysticalLanguage ? "COSMIC PORTFOLIO" : "PORTFOLIO")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(WidgetTheme.textMuted)

                    Spacer()

                    // Change badge
                    HStack(spacing: 4) {
                        Text(data.formattedChange)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(data.isPositive ? WidgetTheme.positive : WidgetTheme.negative)

                        Image(systemName: data.isPositive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(data.isPositive ? WidgetTheme.positive : WidgetTheme.negative)
                    }
                }

                // Divider
                Rectangle()
                    .fill(WidgetTheme.gold.opacity(0.4))
                    .frame(height: 1)

                // Portfolio value
                HStack {
                    Text(data.formattedValue)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(WidgetTheme.textPrimary)

                    Spacer()
                }

                Spacer()

                // Top holdings row
                if !data.topHoldings.isEmpty {
                    HStack(spacing: 16) {
                        ForEach(data.topHoldings.prefix(3), id: \.symbol) { holding in
                            HStack(spacing: 4) {
                                Text(holding.symbol)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(WidgetTheme.textPrimary)

                                Text(holding.formattedChange)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(holding.isPositive ? WidgetTheme.positive : WidgetTheme.negative)
                            }
                        }

                        Spacer()
                    }
                }

                // Compatibility footer (only show in mystical mode)
                if useMysticalLanguage {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                            .foregroundColor(WidgetTheme.gold)

                        Text("\(data.overallCompatibility)% compatible with your sign")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(WidgetTheme.textMuted)

                        Spacer()
                    }
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    PortfolioWidget()
} timeline: {
    PortfolioEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    PortfolioWidget()
} timeline: {
    PortfolioEntry.placeholder
}

#Preview("Small - Negative", as: .systemSmall) {
    PortfolioWidget()
} timeline: {
    PortfolioEntry(
        date: Date(),
        portfolio: WidgetPortfolioData(
            date: Date(),
            totalValue: 11200.00,
            dayChange: -340.00,
            dayChangePercent: -2.9,
            topHoldings: [
                WidgetHolding(symbol: "AAPL", changePercent: -1.5),
                WidgetHolding(symbol: "TSLA", changePercent: -5.2),
                WidgetHolding(symbol: "NVDA", changePercent: 0.8)
            ],
            overallCompatibility: 65
        ),
        isPreview: false
    )
}
