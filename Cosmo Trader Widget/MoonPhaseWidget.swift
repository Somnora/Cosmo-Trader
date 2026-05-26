//
//  MoonPhaseWidget.swift
//  Cosmo Trader Widget
//
//  Home screen widget showing current moon phase and trading signal.
//  Supports small (2x2) and medium (4x2) sizes.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct MoonPhaseEntry: TimelineEntry {
    let date: Date
    let lunarData: WidgetLunarData
    let isPreview: Bool

    static let placeholder = MoonPhaseEntry(
        date: Date(),
        lunarData: .placeholder,
        isPreview: true
    )
}

// MARK: - Timeline Provider

struct MoonPhaseTimelineProvider: TimelineProvider {

    typealias Entry = MoonPhaseEntry

    /// Placeholder for widget gallery
    func placeholder(in context: Context) -> MoonPhaseEntry {
        .placeholder
    }

    /// Snapshot for widget preview
    func getSnapshot(in context: Context, completion: @escaping (MoonPhaseEntry) -> Void) {
        let entry: MoonPhaseEntry

        if context.isPreview {
            entry = .placeholder
        } else if let data = WidgetDataProvider.readWidgetData() {
            entry = MoonPhaseEntry(date: Date(), lunarData: data, isPreview: false)
        } else {
            // Fallback to calculated data if no shared data available
            entry = MoonPhaseEntry(date: Date(), lunarData: calculateFallbackData(), isPreview: false)
        }

        completion(entry)
    }

    /// Timeline for widget updates
    func getTimeline(in context: Context, completion: @escaping (Timeline<MoonPhaseEntry>) -> Void) {
        var entries: [MoonPhaseEntry] = []
        let currentDate = Date()

        // Read shared data or calculate fallback
        let lunarData = WidgetDataProvider.readWidgetData() ?? calculateFallbackData()

        // Create entries for the next 6 hours (1 per hour)
        for hourOffset in 0..<6 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = MoonPhaseEntry(date: entryDate, lunarData: lunarData, isPreview: false)
            entries.append(entry)
        }

        // Refresh every hour
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    /// Calculate fallback lunar data when shared data unavailable
    private func calculateFallbackData() -> WidgetLunarData {
        let date = Date()
        let phase = calculateMoonPhase(for: date)
        let age = calculateMoonAge(for: date)
        let illumination = calculateIllumination(age: age)

        return WidgetLunarData(
            date: date,
            phaseName: phase.name,
            phaseEmoji: phase.sfSymbol,
            illumination: illumination,
            isWaxing: age < 14.76,
            daysUntilFullMoon: calculateDaysUntilFull(age: age),
            daysUntilNewMoon: calculateDaysUntilNew(age: age),
            moonSignName: "Unknown",
            moonSignElement: "Unknown",
            tradingSignalHeadline: phase.signalHeadline,
            tradingSignalType: phase.signalType,
            tradingSignalSentiment: phase.sentiment
        )
    }

    // MARK: - Moon Calculations (Fallback)

    private let synodicMonth: Double = 29.530588853
    private let referenceNewMoon: Date = {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 6
        components.hour = 18
        components.minute = 14
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: components)!
    }()

    private func calculateMoonAge(for date: Date) -> Double {
        let secondsSinceReference = date.timeIntervalSince(referenceNewMoon)
        let daysSinceReference = secondsSinceReference / 86400
        return daysSinceReference.truncatingRemainder(dividingBy: synodicMonth)
    }

    private func calculateIllumination(age: Double) -> Double {
        let radians = (age / synodicMonth) * 2 * .pi
        return (1 - cos(radians)) / 2
    }

    private func calculateDaysUntilFull(age: Double) -> Int {
        let fullMoonAge = synodicMonth / 2
        if age < fullMoonAge {
            return Int(fullMoonAge - age)
        } else {
            return Int(synodicMonth - age + fullMoonAge)
        }
    }

    private func calculateDaysUntilNew(age: Double) -> Int {
        return Int(synodicMonth - age)
    }

    private func calculateMoonPhase(for date: Date) -> (name: String, emoji: String, signalHeadline: String, signalType: String, sentiment: String) {
        let age = calculateMoonAge(for: date)

        switch age {
        case 0..<1.85:
            return ("New Moon", "🌑", "Accumulation Phase", "Accumulate", "Bullish")
        case 1.85..<7.38:
            return ("Waxing Crescent", "🌒", "Building Momentum", "Build Position", "Bullish")
        case 7.38..<9.23:
            return ("First Quarter", "🌓", "Decision Point", "Hold", "Neutral")
        case 9.23..<14.76:
            return ("Waxing Gibbous", "🌔", "Pre-Peak Energy", "Build Position", "Bullish")
        case 14.76..<16.61:
            return ("Full Moon", "🌕", "Peak Volatility", "Caution", "Volatile")
        case 16.61..<22.14:
            return ("Waning Gibbous", "🌖", "Distribution Phase", "Take Profit", "Bearish")
        case 22.14..<24.00:
            return ("Last Quarter", "🌗", "Review & Reduce", "Reduce", "Bearish")
        default:
            return ("Waning Crescent", "🌘", "Rest Period", "Wait", "Neutral")
        }
    }
}

// MARK: - Moon Phase Widget

struct MoonPhaseWidget: Widget {
    let kind: String = "MoonPhaseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoonPhaseTimelineProvider()) { entry in
            MoonPhaseWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Moon Phase")
        .description("Track lunar cycles and market timing signals.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Entry View

struct MoonPhaseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MoonPhaseEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallMoonWidget(data: entry.lunarData)
        case .systemMedium:
            MediumMoonWidget(data: entry.lunarData)
        default:
            SmallMoonWidget(data: entry.lunarData)
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    MoonPhaseWidget()
} timeline: {
    MoonPhaseEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    MoonPhaseWidget()
} timeline: {
    MoonPhaseEntry.placeholder
}
