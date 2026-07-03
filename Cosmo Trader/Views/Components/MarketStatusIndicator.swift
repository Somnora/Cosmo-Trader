import SwiftUI

/// MarketStatusIndicator
/// --------------------
/// Shows current market status with visual indicator.
/// NYSE/NASDAQ trading hours: 9:30 AM - 4:00 PM ET
///
/// Features:
/// - Color-coded status dot (green = open, red = closed, yellow = extended)
/// - Current time in Eastern Time
/// - Countdown to next open/close
/// - Pulsing animation when market is open

// MARK: - Market Status

enum MarketStatus: Equatable {
    case open
    case closed
    case preMarket
    case afterHours

    var displayName: String {
        switch self {
        case .open: return "OPEN"
        case .closed: return "CLOSED"
        case .preMarket: return "PRE-MKT"
        case .afterHours: return "AFTER-HRS"
        }
    }

    var color: Color {
        switch self {
        case .open: return CosmicTheme.positive
        case .closed: return CosmicTheme.negative
        case .preMarket: return CosmicTheme.gold
        case .afterHours: return CosmicTheme.gold
        }
    }

    var description: String {
        switch self {
        case .open: return "Market is trading"
        case .closed: return "Market is closed"
        case .preMarket: return "Pre-market session"
        case .afterHours: return "After-hours session"
        }
    }
}

// MARK: - Market Status Indicator

struct MarketStatusIndicator: View {

    /// Injected time for testing, or nil to use real time
    var currentDate: Date?

    /// Show detailed info (time and countdown)
    var showDetails: Bool = true

    /// Size preset
    var size: MarketIndicatorSize = .medium

    /// Pulsing animation for open status
    @State private var isPulsing = false

    var body: some View {
        // Re-evaluates once per wall-clock minute while visible and pauses
        // off screen; the per-instance Timer publisher it replaces fired for
        // as long as the view existed anywhere in the hierarchy.
        TimelineView(.everyMinute) { context in
            content(for: currentDate ?? context.date)
        }
    }

    private func content(for date: Date) -> some View {
        let status = MarketTimeHelper.status(for: date)

        return HStack(spacing: size.spacing) {
            // Status dot
            statusDot(status: status)

            // Status text
            VStack(alignment: .leading, spacing: 2) {
                Text(status.displayName)
                    .font(TerminalFont.data(size.labelSize, weight: .semibold))
                    .foregroundColor(status.color)

                if showDetails {
                    Text(MarketTimeHelper.easternTimeString(for: date) + " ET")
                        .font(TerminalFont.data(size.timeSize))
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            if showDetails, let countdown = countdownText(for: date, status: status) {
                Spacer()

                Text(countdown)
                    .font(TerminalFont.data(size.timeSize))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .onAppear {
            if status == .open {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: status) { _, newStatus in
            if newStatus == .open {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }

    // MARK: - Status Dot

    private func statusDot(status: MarketStatus) -> some View {
        ZStack {
            // Outer glow for open status
            if status == .open {
                Circle()
                    .fill(status.color.opacity(0.3))
                    .frame(width: size.dotSize + 6, height: size.dotSize + 6)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
            }

            // Main dot
            Circle()
                .fill(status.color)
                .frame(width: size.dotSize, height: size.dotSize)

            // Inner highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.4), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size.dotSize / 2
                    )
                )
                .frame(width: size.dotSize, height: size.dotSize)
        }
    }

    // MARK: - Countdown

    private func countdownText(for date: Date, status: MarketStatus) -> String? {
        switch status {
        case .open:
            if let closeTime = MarketTimeHelper.nextClose(from: date) {
                let remaining = closeTime.timeIntervalSince(date)
                return "Closes in \(formatDuration(remaining))"
            }
        case .closed, .preMarket, .afterHours:
            if let openTime = MarketTimeHelper.nextOpen(from: date) {
                let remaining = openTime.timeIntervalSince(date)
                return "Opens in \(formatDuration(remaining))"
            }
        }
        return nil
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Size Presets

enum MarketIndicatorSize {
    case small
    case medium
    case large

    var dotSize: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        }
    }

    var labelSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }

    var timeSize: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }

    var spacing: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        }
    }
}

// MARK: - Compact Badge

/// Tiny status badge for tight spaces
struct MarketStatusBadge: View {

    var currentDate: Date?

    var body: some View {
        TimelineView(.everyMinute) { context in
            let status = MarketTimeHelper.status(for: currentDate ?? context.date)

            HStack(spacing: 4) {
                Circle()
                    .fill(status.color)
                    .frame(width: 6, height: 6)

                Text(status.displayName)
                    .font(TerminalFont.data(9, weight: .semibold))
                    .foregroundColor(status.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status.color.opacity(0.15))
            )
        }
    }
}

// MARK: - Market Time Helper

struct MarketTimeHelper {

    /// NYSE/NASDAQ regular trading hours (Eastern Time)
    static let marketOpenHour = 9
    static let marketOpenMinute = 30
    static let marketCloseHour = 16
    static let marketCloseMinute = 0

    /// Extended hours
    static let preMarketOpenHour = 4
    static let afterHoursCloseHour = 20

    /// Eastern timezone
    static var easternTimeZone: TimeZone {
        TimeZone(identifier: "America/New_York") ?? .current
    }

    /// Get current market status
    static func status(for date: Date) -> MarketStatus {
        let calendar = Calendar.current
        var easternCalendar = calendar
        easternCalendar.timeZone = easternTimeZone

        let components = easternCalendar.dateComponents([.hour, .minute, .weekday], from: date)
        guard let hour = components.hour,
              let minute = components.minute,
              let weekday = components.weekday else {
            return .closed
        }

        // Weekend check (1 = Sunday, 7 = Saturday)
        if weekday == 1 || weekday == 7 {
            return .closed
        }

        let timeInMinutes = hour * 60 + minute
        let marketOpen = marketOpenHour * 60 + marketOpenMinute  // 9:30 = 570
        let marketClose = marketCloseHour * 60 + marketCloseMinute  // 16:00 = 960
        let preMarketOpen = preMarketOpenHour * 60  // 4:00 = 240
        let afterHoursClose = afterHoursCloseHour * 60  // 20:00 = 1200

        if timeInMinutes >= marketOpen && timeInMinutes < marketClose {
            return .open
        } else if timeInMinutes >= preMarketOpen && timeInMinutes < marketOpen {
            return .preMarket
        } else if timeInMinutes >= marketClose && timeInMinutes < afterHoursClose {
            return .afterHours
        } else {
            return .closed
        }
    }

    /// Get Eastern time string
    static func easternTimeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = easternTimeZone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Get next market open time
    static func nextOpen(from date: Date) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = easternTimeZone

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .weekday], from: date)

        // Set to market open time
        components.hour = marketOpenHour
        components.minute = marketOpenMinute
        components.second = 0

        guard var openTime = calendar.date(from: components) else { return nil }

        // If we're past today's open, move to next day
        if date >= openTime {
            openTime = calendar.date(byAdding: .day, value: 1, to: openTime) ?? openTime
        }

        // Skip weekends
        var weekday = calendar.component(.weekday, from: openTime)
        while weekday == 1 || weekday == 7 {
            openTime = calendar.date(byAdding: .day, value: 1, to: openTime) ?? openTime
            weekday = calendar.component(.weekday, from: openTime)
        }

        return openTime
    }

    /// Get next market close time
    static func nextClose(from date: Date) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = easternTimeZone

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = marketCloseHour
        components.minute = marketCloseMinute
        components.second = 0

        guard let closeTime = calendar.date(from: components) else { return nil }

        // Only return if we haven't passed it yet
        if date < closeTime {
            return closeTime
        }

        return nil
    }
}

// MARK: - Full Status Panel

/// Detailed market status with all sessions
struct MarketStatusPanel: View {

    var currentDate: Date?

    var body: some View {
        TimelineView(.everyMinute) { context in
            content(for: currentDate ?? context.date)
        }
    }

    private func content(for date: Date) -> some View {
        let status = MarketTimeHelper.status(for: date)

        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("MARKET STATUS")
                    .font(TerminalFont.headline(14))
                    .foregroundColor(CosmicTheme.textSecondary)

                Spacer()

                Text(MarketTimeHelper.easternTimeString(for: date) + " ET")
                    .font(TerminalFont.data(12))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            // Current status
            HStack(spacing: 10) {
                Circle()
                    .fill(status.color)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.displayName)
                        .font(TerminalFont.headline(18))
                        .foregroundColor(status.color)

                    Text(status.description)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }

            Divider()
                .background(CosmicTheme.border)

            // Session timeline
            HStack(spacing: 0) {
                sessionBlock(
                    label: "PRE",
                    time: "4:00a - 9:30a",
                    isActive: status == .preMarket
                )

                sessionBlock(
                    label: "OPEN",
                    time: "9:30a - 4:00p",
                    isActive: status == .open
                )

                sessionBlock(
                    label: "AFTER",
                    time: "4:00p - 8:00p",
                    isActive: status == .afterHours
                )
            }
        }
        .padding(16)
        .background(CosmicTheme.cardBackground)
        .overlay(
            Rectangle()
                .stroke(CosmicTheme.border, lineWidth: 0.5)
        )
    }

    private func sessionBlock(label: String, time: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(TerminalFont.data(10, weight: .semibold))
                .foregroundColor(isActive ? CosmicTheme.gold : CosmicTheme.textMuted)

            Text(time)
                .font(TerminalFont.data(9))
                .foregroundColor(isActive ? CosmicTheme.textSecondary : CosmicTheme.textMuted)

            RoundedRectangle(cornerRadius: 2)
                .fill(isActive ? CosmicTheme.gold : CosmicTheme.border)
                .frame(height: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isActive ? CosmicTheme.gold.opacity(0.1) : Color.clear)
    }
}

// MARK: - Preview

#Preview("Market Status") {
    ScrollView {
        VStack(spacing: 24) {
            Text("MARKET STATUS INDICATOR")
                .font(TerminalFont.headline(16))
                .foregroundColor(CosmicTheme.textPrimary)

            // Different statuses (mock times)
            Group {
                // Market Open (10:30 AM ET on a Monday)
                let openDate = createDate(hour: 10, minute: 30, weekday: 2)
                MarketStatusIndicator(currentDate: openDate)

                Divider().background(CosmicTheme.border)

                // Pre-market (7:00 AM ET)
                let preMarketDate = createDate(hour: 7, minute: 0, weekday: 2)
                MarketStatusIndicator(currentDate: preMarketDate)

                Divider().background(CosmicTheme.border)

                // After hours (5:30 PM ET)
                let afterHoursDate = createDate(hour: 17, minute: 30, weekday: 2)
                MarketStatusIndicator(currentDate: afterHoursDate)

                Divider().background(CosmicTheme.border)

                // Closed (weekend)
                let closedDate = createDate(hour: 12, minute: 0, weekday: 1) // Sunday
                MarketStatusIndicator(currentDate: closedDate)
            }
            .padding()
            .background(CosmicTheme.cardBackground)

            Text("BADGE STYLE")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            HStack(spacing: 12) {
                MarketStatusBadge(currentDate: createDate(hour: 10, minute: 30, weekday: 2))
                MarketStatusBadge(currentDate: createDate(hour: 7, minute: 0, weekday: 2))
                MarketStatusBadge(currentDate: createDate(hour: 22, minute: 0, weekday: 2))
            }

            Text("FULL PANEL")
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textSecondary)

            MarketStatusPanel(currentDate: createDate(hour: 10, minute: 30, weekday: 2))

            MarketStatusPanel(currentDate: createDate(hour: 7, minute: 0, weekday: 2))
        }
        .padding()
    }
    .background(CosmicTheme.background)
}

// Helper for preview dates
private func createDate(hour: Int, minute: Int, weekday: Int) -> Date {
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(identifier: "America/New_York")!

    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = hour
    components.minute = minute

    // Adjust to get correct weekday
    var date = calendar.date(from: components) ?? Date()
    let currentWeekday = calendar.component(.weekday, from: date)
    let daysToAdd = (weekday - currentWeekday + 7) % 7
    date = calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date

    return date
}
