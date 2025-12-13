import SwiftUI

// MARK: - VOC Moon Warning Banner
// =================================
// Prominent warning banner shown when Moon is Void of Course

struct VOCMoonWarningBanner: View {
    @State private var vocService = VoidOfCourseMoonService.shared
    @State private var showDetail = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?

    var onDismiss: (() -> Void)? = nil

    var body: some View {
        let status = vocService.getCurrentStatus()

        Group {
            switch status {
            case .inVOC(let period):
                activeVOCBanner(period: period)
            case .approaching(let period):
                approachingVOCBanner(period: period)
            case .clear, .unknown:
                EmptyView()
            }
        }
        .sheet(isPresented: $showDetail) {
            VOCMoonDetailSheet()
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Active VOC Banner

    private func activeVOCBanner(period: VOCPeriod) -> some View {
        Button(action: {
            showDetail = true
            AnalyticsService.shared.track(.vocWarningViewed)
        }) {
            HStack(spacing: 14) {
                // Warning icon with pulse
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 56, height: 56)
                        .scaleEffect(timeRemaining.truncatingRemainder(dividingBy: 2) < 1 ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: timeRemaining)

                    Image(systemName: "moon.haze.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("VOID OF COURSE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .tracking(1)

                        Text("ACTIVE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }

                    Text("Avoid initiating new positions")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textPrimary)

                    if let remaining = vocService.getTimeRemainingInVOC() {
                        Text("Ends in \(vocService.formatTimeRemaining(remaining))")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }

                Spacer()

                // Time and chevron
                VStack(alignment: .trailing, spacing: 2) {
                    Text(period.endTime, style: .time)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.orange)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Approaching VOC Banner

    private func approachingVOCBanner(period: VOCPeriod) -> some View {
        Button(action: {
            showDetail = true
            AnalyticsService.shared.track(.vocWarningViewed)
        }) {
            HStack(spacing: 12) {
                // Warning icon
                ZStack {
                    Circle()
                        .fill(CosmicTheme.gold.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "moon.haze")
                        .font(.headline)
                        .foregroundColor(CosmicTheme.gold)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text("VOC Moon Approaching")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("Starts at \(period.startTime, style: .time)")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.gold.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let remaining = vocService.getTimeRemainingInVOC() {
                timeRemaining = remaining
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - VOC Moon Detail Sheet
// ===============================
// Full detail view explaining VOC Moon

struct VOCMoonDetailSheet: View {
    @State private var vocService = VoidOfCourseMoonService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection

                    // Current status
                    currentStatusSection

                    // Upcoming VOC periods
                    upcomingPeriodsSection

                    // What is VOC section
                    educationalSection

                    // Trading wisdom section
                    tradingWisdomSection

                    // Disclaimer
                    disclaimerSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(CosmicTheme.background.ignoresSafeArea())
            .navigationTitle("Void of Course Moon")
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            AnalyticsService.shared.track(.vocDetailViewed)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Moon visualization
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(0.2),
                                Color.orange.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Moon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.4),
                                Color.gray.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                // Haze effect
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                // Question marks floating (void state)
                ForEach(0..<3, id: \.self) { i in
                    Text("?")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(Color.orange.opacity(0.5))
                        .offset(
                            x: CGFloat([-30, 35, 0][i]),
                            y: CGFloat([-25, -20, 30][i])
                        )
                }
            }

            // Title
            VStack(spacing: 8) {
                Text("Void of Course Moon")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("When the Moon goes quiet")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Current Status Section

    private var currentStatusSection: some View {
        let status = vocService.getCurrentStatus()

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Current Status", icon: "clock.fill")

            VStack(spacing: 16) {
                switch status {
                case .inVOC(let period):
                    activeStatusCard(period: period)
                case .approaching(let period):
                    approachingStatusCard(period: period)
                case .clear(let nextVOC):
                    clearStatusCard(nextVOC: nextVOC)
                case .unknown:
                    unknownStatusCard
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private func activeStatusCard(period: VOCPeriod) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Moon is Void of Course")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "Started", value: period.startTime, style: .time)
                infoRow(label: "Ends", value: period.endTime, style: .time)
                infoRow(label: "Duration", value: period.durationFormatted)
                infoRow(label: "Transition", value: period.signTransitionText)
                infoRow(label: "Last Aspect", value: period.lastAspect.description)
            }

            if let remaining = vocService.getTimeRemainingInVOC() {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text("\(vocService.formatTimeRemaining(remaining)) remaining")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
            }
        }
    }

    private func approachingStatusCard(period: VOCPeriod) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(CosmicTheme.gold)
                Text("VOC Approaching")
                    .font(.headline)
                    .foregroundColor(CosmicTheme.gold)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "Starts", value: period.startTime, style: .time)
                infoRow(label: "Duration", value: period.durationFormatted)
                infoRow(label: "Transition", value: period.signTransitionText)
            }
        }
    }

    private func clearStatusCard(nextVOC: VOCPeriod) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(CosmicTheme.positive)
                Text("Moon is Active")
                    .font(.headline)
                    .foregroundColor(CosmicTheme.positive)
                Spacer()
            }

            Text("The Moon is making aspects and actively influencing. Traditional timing suggests this is favorable for initiating actions.")
                .font(.caption)
                .foregroundColor(CosmicTheme.textSecondary)

            Divider()
                .background(CosmicTheme.borderDim)

            HStack {
                Text("Next VOC:")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
                Spacer()
                Text(nextVOC.startTime, style: .date)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                Text("at")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
                Text(nextVOC.startTime, style: .time)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
    }

    private var unknownStatusCard: some View {
        HStack {
            Image(systemName: "questionmark.circle")
                .foregroundColor(CosmicTheme.textMuted)
            Text("Status unknown")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textMuted)
            Spacer()
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(CosmicTheme.textPrimary)
        }
    }

    private func infoRow(label: String, value: Date, style: Text.DateStyle) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)
            Spacer()
            Text(value, style: style)
                .font(.caption)
                .foregroundColor(CosmicTheme.textPrimary)
        }
    }

    // MARK: - Upcoming Periods Section

    private var upcomingPeriodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Upcoming VOC Periods", icon: "calendar")

            VStack(spacing: 8) {
                let futurePeriods = vocService.upcomingVOCPeriods
                    .filter { $0.startTime > Date() }
                    .prefix(5)

                ForEach(Array(futurePeriods)) { period in
                    upcomingPeriodRow(period: period)
                }

                if futurePeriods.isEmpty {
                    Text("No upcoming VOC periods in the next few days")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                        .padding(.vertical, 8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private func upcomingPeriodRow(period: VOCPeriod) -> some View {
        HStack(spacing: 12) {
            // Date
            VStack(spacing: 2) {
                Text(period.startTime, format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)

                Text(period.startTime, format: .dateTime.day())
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textPrimary)
            }
            .frame(width: 40)

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(period.timeRangeFormatted)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("\(period.fromSign.symbol) → \(period.toSign.symbol) • \(period.durationFormatted)")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()

            // Duration badge
            Text(period.durationFormatted)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(CosmicTheme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(CosmicTheme.textMuted.opacity(0.15))
                )
        }
        .padding(.vertical, 6)
    }

    // MARK: - Educational Section

    private var educationalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "What is Void of Course?", icon: "book.fill")

            VStack(alignment: .leading, spacing: 16) {
                Text("The Moon is \"Void of Course\" during the period between making its last major aspect (conjunction, sextile, square, trine, or opposition) in one zodiac sign and entering the next sign.")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)

                Text("This happens every 2-3 days and can last from a few minutes to over 24 hours.")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)

                Divider()
                    .background(CosmicTheme.borderDim)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Traditional Interpretation")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.gold)

                    Text("Actions initiated during VOC periods are said to \"come to nothing\" or not manifest as expected. This includes:")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)

                    VStack(alignment: .leading, spacing: 4) {
                        bulletPoint("Starting new projects")
                        bulletPoint("Making important decisions")
                        bulletPoint("Signing contracts")
                        bulletPoint("Opening new positions")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Good For")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.positive)

                    VStack(alignment: .leading, spacing: 4) {
                        bulletPoint("Routine tasks and maintenance")
                        bulletPoint("Rest and meditation")
                        bulletPoint("Completing existing work")
                        bulletPoint("Research and analysis")
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Trading Wisdom Section

    private var tradingWisdomSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Trading Wisdom", icon: "chart.line.uptrend.xyaxis")

            VStack(alignment: .leading, spacing: 12) {
                Text("Some traders who follow financial astrology avoid initiating new positions during VOC periods. The theory suggests:")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)

                VStack(alignment: .leading, spacing: 8) {
                    wisdomPoint(
                        icon: "arrow.up.right",
                        title: "Entries",
                        text: "New positions opened during VOC may not develop as expected"
                    )

                    wisdomPoint(
                        icon: "arrow.down.right",
                        title: "Exits",
                        text: "Closing positions during VOC is considered acceptable"
                    )

                    wisdomPoint(
                        icon: "eye",
                        title: "Analysis",
                        text: "VOC is considered a good time for research and planning"
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private func wisdomPoint(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(text)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
    }

    // MARK: - Disclaimer Section

    private var disclaimerSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .foregroundColor(.orange)

            Text("This is for entertainment purposes only. There is no scientific evidence that Void of Course Moon periods affect trading outcomes. Always make investment decisions based on proper research and analysis, not astrological factors.")
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)
                .italic()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.08))
        )
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)

            Text(title)
                .font(TerminalFont.headline(14))
                .foregroundColor(CosmicTheme.textPrimary)
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)

            Text(text)
                .font(.caption)
                .foregroundColor(CosmicTheme.textSecondary)
        }
    }
}

// MARK: - VOC Settings Toggle
// ============================
// Settings row for enabling/disabling VOC warnings

struct VOCWarningsToggle: View {
    @State private var vocService = VoidOfCourseMoonService.shared

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: "moon.haze.fill")
                    .font(.body)
                    .foregroundColor(.orange)
            }

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text("Void of Course Warnings")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Alert when Moon is VOC")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $vocService.vocWarningsEnabled)
                .tint(CosmicTheme.gold)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Compact VOC Indicator
// ==============================
// Small indicator for headers/toolbars

struct VOCIndicator: View {
    @State private var vocService = VoidOfCourseMoonService.shared
    @State private var showDetail = false

    var body: some View {
        if vocService.vocWarningsEnabled && vocService.isCurrentlyVOC {
            Button(action: { showDetail = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "moon.haze.fill")
                        .font(.caption2)

                    Text("VOC")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.2))
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showDetail) {
                VOCMoonDetailSheet()
            }
        }
    }
}

// MARK: - Previews

#Preview("VOC Warning Banner") {
    VStack(spacing: 20) {
        VOCMoonWarningBanner()
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("VOC Detail Sheet") {
    VOCMoonDetailSheet()
        .preferredColorScheme(.dark)
}

#Preview("VOC Settings Toggle") {
    VStack {
        VOCWarningsToggle()
    }
    .background(CosmicTheme.cardBackground)
    .preferredColorScheme(.dark)
}
