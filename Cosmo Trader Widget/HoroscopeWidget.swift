//
//  HoroscopeWidget.swift
//  Cosmo Trader Widget
//
//  Daily horoscope widget showing user's zodiac sign and cosmic forecast.
//  Supports small (2x2) and medium (4x2) sizes.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct HoroscopeEntry: TimelineEntry {
    let date: Date
    let horoscope: WidgetHoroscopeData
    let isPreview: Bool

    static let placeholder = HoroscopeEntry(
        date: Date(),
        horoscope: .placeholder,
        isPreview: true
    )
}

// MARK: - Timeline Provider

struct HoroscopeTimelineProvider: TimelineProvider {

    typealias Entry = HoroscopeEntry

    func placeholder(in context: Context) -> HoroscopeEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (HoroscopeEntry) -> Void) {
        let entry: HoroscopeEntry

        if context.isPreview {
            entry = .placeholder
        } else if let data = WidgetDataProvider.readHoroscopeData() {
            entry = HoroscopeEntry(date: Date(), horoscope: data, isPreview: false)
        } else {
            entry = HoroscopeEntry(date: Date(), horoscope: .placeholder, isPreview: false)
        }

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HoroscopeEntry>) -> Void) {
        let currentDate = Date()
        let horoscope = WidgetDataProvider.readHoroscopeData() ?? .placeholder

        let entry = HoroscopeEntry(date: currentDate, horoscope: horoscope, isPreview: false)

        // Refresh at midnight for new daily horoscope, or every 4 hours
        let calendar = Calendar.current
        var nextMidnight = calendar.startOfDay(for: currentDate)
        nextMidnight = calendar.date(byAdding: .day, value: 1, to: nextMidnight) ?? currentDate

        let fourHoursLater = calendar.date(byAdding: .hour, value: 4, to: currentDate) ?? currentDate
        let refreshDate = min(nextMidnight, fourHoursLater)

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Horoscope Widget

struct HoroscopeWidget: Widget {
    let kind: String = "HoroscopeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HoroscopeTimelineProvider()) { entry in
            HoroscopeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Horoscope")
        .description("Your cosmic forecast for the market.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Entry View

struct HoroscopeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HoroscopeEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallHoroscopeWidget(data: entry.horoscope)
        case .systemMedium:
            MediumHoroscopeWidget(data: entry.horoscope)
        default:
            SmallHoroscopeWidget(data: entry.horoscope)
        }
    }
}

// MARK: - Small Horoscope Widget (2x2)

struct SmallHoroscopeWidget: View {
    let data: WidgetHoroscopeData

    var body: some View {
        ZStack {
            WidgetTheme.background

            VStack(alignment: .leading, spacing: 6) {
                // Sign header
                HStack(spacing: 6) {
                    Text(data.signSymbol)
                        .font(.system(size: 24))

                    Text(data.signName.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(WidgetTheme.textPrimary)
                }

                // Divider
                Rectangle()
                    .fill(WidgetTheme.gold.opacity(0.4))
                    .frame(height: 1)

                // Horoscope text
                Text(data.horoscopeText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(WidgetTheme.textSecondary)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)

                Spacer()
            }
            .padding(12)
        }
    }
}

// MARK: - Medium Horoscope Widget (4x2)

struct MediumHoroscopeWidget: View {
    let data: WidgetHoroscopeData

    var body: some View {
        ZStack {
            WidgetTheme.background

            VStack(alignment: .leading, spacing: 10) {
                // Header row
                HStack {
                    HStack(spacing: 8) {
                        Text(data.signSymbol)
                            .font(.system(size: 28))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(data.signName.uppercased())
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(WidgetTheme.textPrimary)

                            Text(data.signElement.uppercased() + " SIGN")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(elementColor(data.signElement))
                        }
                    }

                    Spacer()

                    // Date
                    Text(data.date, style: .date)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(WidgetTheme.textMuted)
                }

                // Divider
                Rectangle()
                    .fill(WidgetTheme.gold.opacity(0.4))
                    .frame(height: 1)

                // Horoscope text
                Text(data.horoscopeText)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(WidgetTheme.textSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.9)

                Spacer()

                // Bottom row
                HStack {
                    // Lucky number
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundColor(WidgetTheme.gold)
                        Text("LUCKY: \(data.luckyNumber)")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(WidgetTheme.gold)
                    }

                    Spacer()

                    // Best match
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(WidgetTheme.positive)
                        Text(data.compatibility)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(WidgetTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
        }
    }

    private func elementColor(_ element: String) -> Color {
        switch element.lowercased() {
        case "fire": return .orange
        case "water": return .blue
        case "earth": return .brown
        case "air": return .cyan
        default: return WidgetTheme.textSecondary
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    HoroscopeWidget()
} timeline: {
    HoroscopeEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    HoroscopeWidget()
} timeline: {
    HoroscopeEntry.placeholder
}
