import SwiftUI

// MARK: - Daily Ritual Views
// ===========================
// UI components for the 30-second morning ritual experience.
// A guided sequence: Cosmic Weather → Portfolio → Horoscope → Intention

// MARK: - Daily Ritual Card (Entry Point)

struct DailyRitualCard: View {
    let holdings: [Stock]
    let userSign: ZodiacSign

    @State private var ritualService = DailyRitualService.shared
    @State private var showingRitual = false

    var body: some View {
        Button(action: { showingRitual = true }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(ritualService.hasCompletedTodaysRitual ? Color.green.opacity(0.2) : CosmicTheme.gold.opacity(0.2))
                        .frame(width: 48, height: 48)

                    if ritualService.hasCompletedTodaysRitual {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "sun.horizon.fill")
                            .font(.title2)
                            .foregroundColor(CosmicTheme.gold)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(ritualService.hasCompletedTodaysRitual ? "Ritual Complete" : "Daily Ritual")
                            .font(TerminalFont.body(14, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)

                        if !ritualService.hasCompletedTodaysRitual && ritualService.isRitualTime {
                            Text("NOW")
                                .font(TerminalFont.caption(9, weight: .bold))
                                .foregroundColor(CosmicTheme.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(CosmicTheme.gold)
                                )
                        }
                    }

                    if ritualService.hasCompletedTodaysRitual {
                        if let intention = ritualService.todaysIntention {
                            HStack(spacing: 4) {
                                Image(systemName: intention.icon)
                                    .font(.caption2)
                                Text("Intention: \(intention.rawValue)")
                                    .font(TerminalFont.caption(11))
                            }
                            .foregroundColor(intention.color)
                        }
                    } else {
                        Text("30-second morning alignment")
                            .font(TerminalFont.caption(11))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }

                Spacer()

                // Streak badge
                if ritualService.currentStreak > 0 {
                    VStack(spacing: 2) {
                        Text("\(ritualService.currentStreak)")
                            .font(TerminalFont.body(16, weight: .bold))
                            .foregroundColor(CosmicTheme.gold)
                        Text("streak")
                            .font(TerminalFont.caption(9))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                ritualService.hasCompletedTodaysRitual
                                    ? Color.green.opacity(0.3)
                                    : CosmicTheme.gold.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingRitual) {
            DailyRitualFlow(
                holdings: holdings,
                userSign: userSign
            )
        }
    }
}

// MARK: - Daily Ritual Flow (Full Screen Experience)

struct DailyRitualFlow: View {
    let holdings: [Stock]
    let userSign: ZodiacSign

    @Environment(\.dismiss) private var dismiss
    @State private var ritualService = DailyRitualService.shared

    @State private var currentStep: RitualStep = .cosmicWeather
    @State private var stepProgress: Double = 0
    @State private var selectedIntention: DailyIntention?
    @State private var isTransitioning = false

    private let stepDuration: TimeInterval = 5.0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.02, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.25),
                    CosmicTheme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ritualHeader

                // Progress indicator
                progressIndicator
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                // Content
                Spacer()

                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                Spacer()

                // Action button
                if currentStep != .intention {
                    continueButton
                } else if selectedIntention == nil {
                    intentionPicker
                } else {
                    completeButton
                }
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            AnalyticsService.shared.track(.dailyRitualStarted)
            startStepTimer()
        }
    }

    // MARK: - Header

    private var ritualHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Daily Ritual")
                    .font(TerminalFont.body(14, weight: .medium))
                    .foregroundColor(CosmicTheme.textPrimary)

                if let timeUntil = ritualService.timeUntilMarketOpen {
                    Text(timeUntil)
                        .font(TerminalFont.caption(10))
                        .foregroundColor(CosmicTheme.gold)
                }
            }

            Spacer()

            // Streak badge
            if ritualService.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                    Text("\(ritualService.currentStreak)")
                        .font(TerminalFont.caption(12, weight: .bold))
                }
                .foregroundColor(.orange)
            } else {
                Color.clear
                    .frame(width: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(RitualStep.allCases, id: \.self) { step in
                VStack(spacing: 4) {
                    // Step dot/icon
                    ZStack {
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue
                                ? CosmicTheme.gold
                                : CosmicTheme.textMuted.opacity(0.3))
                            .frame(width: step == currentStep ? 12 : 8, height: step == currentStep ? 12 : 8)

                        if step.rawValue < currentStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(CosmicTheme.background)
                        }
                    }

                    // Step label
                    Text(step.shortName)
                        .font(TerminalFont.caption(9))
                        .foregroundColor(step == currentStep ? CosmicTheme.gold : CosmicTheme.textMuted)
                }
                .frame(maxWidth: .infinity)

                if step != .intention {
                    // Connecting line
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue
                            ? CosmicTheme.gold
                            : CosmicTheme.textMuted.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .cosmicWeather:
            cosmicWeatherStep
        case .portfolio:
            portfolioStep
        case .horoscope:
            horoscopeStep
        case .intention:
            intentionStep
        }
    }

    // MARK: - Step 1: Cosmic Weather

    private var cosmicWeatherStep: some View {
        let weather = ritualService.getCosmicWeather()

        return VStack(spacing: 24) {
            // Moon phase visual
            Text(weather.moonPhase.icon)
                .font(.system(size: 80))

            VStack(spacing: 8) {
                Text("\(weather.moonPhase.rawValue)")
                    .font(TerminalFont.body(20, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Moon in \(weather.moonSign.displayName)")
                    .font(TerminalFont.body(16))
                    .foregroundColor(weather.moonSign.element.color)
            }

            // Energy level
            HStack(spacing: 8) {
                Image(systemName: weather.overallEnergy.icon)
                    .foregroundColor(weather.overallEnergy.color)

                Text("\(weather.overallEnergy.displayName) Energy Today")
                    .font(TerminalFont.body(14))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(weather.overallEnergy.color.opacity(0.15))
            )

            // Alerts
            if !weather.alerts.isEmpty {
                VStack(spacing: 8) {
                    ForEach(weather.alerts.prefix(2), id: \.self) { alert in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)

                            Text(alert)
                                .font(TerminalFont.caption(12))
                                .foregroundColor(CosmicTheme.textSecondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 2: Portfolio Overnight

    private var portfolioStep: some View {
        let summary = ritualService.getOvernightSummary(holdings: holdings)

        return VStack(spacing: 24) {
            // Sentiment emoji
            Text(summary.sentiment.emoji)
                .font(.system(size: 72))

            // Change amount
            VStack(spacing: 8) {
                Text(summary.formattedChange)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(summary.totalChange >= 0 ? CosmicTheme.positive : CosmicTheme.negative)

                Text(summary.formattedPercent)
                    .font(TerminalFont.body(18))
                    .foregroundColor(summary.percentChange >= 0 ? CosmicTheme.positive : CosmicTheme.negative)

                Text("Overnight Change")
                    .font(TerminalFont.caption(12))
                    .foregroundColor(CosmicTheme.textMuted)
            }

            // Top mover
            if let topMover = summary.topMover {
                VStack(spacing: 4) {
                    Text("Top Mover")
                        .font(TerminalFont.caption(10))
                        .foregroundColor(CosmicTheme.textMuted)

                    HStack(spacing: 8) {
                        Text(topMover.zodiacSign.symbol)
                            .font(.title2)

                        Text(topMover.symbol)
                            .font(TerminalFont.body(14, weight: .semibold))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text("\(topMover.percentageChange >= 0 ? "+" : "")\(String(format: "%.1f", topMover.percentageChange))%")
                            .font(TerminalFont.body(14))
                            .foregroundColor(topMover.percentageChange >= 0 ? CosmicTheme.positive : CosmicTheme.negative)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(CosmicTheme.cardBackground)
                )
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 3: Horoscope

    private var horoscopeStep: some View {
        let horoscope = ritualService.getDailyHoroscope(for: userSign)

        return VStack(spacing: 24) {
            // Sign symbol
            Text(userSign.symbol)
                .font(.system(size: 72))

            Text(userSign.displayName)
                .font(TerminalFont.body(20, weight: .semibold))
                .foregroundColor(userSign.element.color)

            // Horoscope text
            Text("\"\(horoscope)\"")
                .font(TerminalFont.body(16))
                .italic()
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 4: Intention

    private var intentionStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "target")
                .font(.system(size: 56))
                .foregroundColor(CosmicTheme.gold)

            Text("Set Your Intention")
                .font(TerminalFont.body(20, weight: .semibold))
                .foregroundColor(CosmicTheme.textPrimary)

            Text("What energy will guide your trading today?")
                .font(TerminalFont.body(14))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)

            if let intention = selectedIntention {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: intention.icon)
                            .font(.title2)
                        Text(intention.rawValue)
                            .font(TerminalFont.body(18, weight: .semibold))
                    }
                    .foregroundColor(intention.color)

                    Text(intention.affirmation)
                        .font(TerminalFont.caption(12))
                        .italic()
                        .foregroundColor(CosmicTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(intention.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(intention.color.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Intention Picker

    private var intentionPicker: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(DailyIntention.allCases, id: \.self) { intention in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedIntention = intention
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: intention.icon)
                                .font(.title2)

                            Text(intention.rawValue)
                                .font(TerminalFont.body(14, weight: .medium))

                            Text(intention.description)
                                .font(TerminalFont.caption(10))
                                .foregroundColor(CosmicTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .foregroundColor(intention.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(intention.color.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(intention.color.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: {
            advanceToNextStep()
        }) {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(TerminalFont.body(16, weight: .semibold))

                Image(systemName: "arrow.right")
            }
            .foregroundColor(CosmicTheme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.gold)
            )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button(action: {
            completeRitual()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Complete Ritual")
                    .font(TerminalFont.body(16, weight: .semibold))
            }
            .foregroundColor(CosmicTheme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green)
            )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func startStepTimer() {
        // Auto-advance timer (optional - can tap to continue)
        // For now, just manual advancement
    }

    private func advanceToNextStep() {
        guard !isTransitioning else { return }
        isTransitioning = true

        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .cosmicWeather:
                currentStep = .portfolio
            case .portfolio:
                currentStep = .horoscope
            case .horoscope:
                currentStep = .intention
            case .intention:
                break
            }
        }

        AnalyticsService.shared.track(.dailyRitualStepViewed)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isTransitioning = false
        }
    }

    private func completeRitual() {
        guard let intention = selectedIntention else { return }
        ritualService.completeRitual(intention: intention)
        dismiss()
    }
}

// MARK: - Ritual Step

enum RitualStep: Int, CaseIterable {
    case cosmicWeather = 0
    case portfolio = 1
    case horoscope = 2
    case intention = 3

    var shortName: String {
        switch self {
        case .cosmicWeather: return "Cosmos"
        case .portfolio: return "Portfolio"
        case .horoscope: return "Horoscope"
        case .intention: return "Intention"
        }
    }
}

// MARK: - Streak Banner (for Profile)

struct RitualStreakBanner: View {
    @State private var ritualService = DailyRitualService.shared

    var body: some View {
        if ritualService.currentStreak > 0 || ritualService.totalRituals > 0 {
            HStack(spacing: 16) {
                // Streak flame
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(ritualService.streakMessage)
                        .font(TerminalFont.body(14, weight: .semibold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    HStack(spacing: 12) {
                        Label("\(ritualService.totalRituals) total", systemImage: "sun.horizon.fill")
                        Label("Best: \(ritualService.longestStreak)", systemImage: "trophy.fill")
                    }
                    .font(TerminalFont.caption(10))
                    .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Previews

#Preview("Daily Ritual Card") {
    VStack {
        DailyRitualCard(
            holdings: Stock.ownedSamples,
            userSign: .leo
        )
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Daily Ritual Flow") {
    DailyRitualFlow(
        holdings: Stock.ownedSamples,
        userSign: .leo
    )
    .preferredColorScheme(.dark)
}
