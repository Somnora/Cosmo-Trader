import SwiftUI

/// HoroscopeView
/// -------------
/// The Horoscope tab - our unique astrological trading insights!
///
/// This is what makes our app special - combining zodiac wisdom
/// with stock market themes (for entertainment purposes!)

struct HoroscopeView: View {

    @State private var viewModel = HoroscopeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Today's horoscope card
                        if let horoscope = viewModel.dailyHoroscope {
                            dailyHoroscopeCard(horoscope)
                        } else if viewModel.isLoading {
                            loadingCard
                        }

                        // Browse all signs
                        allSignsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Horoscope")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(CosmicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            await viewModel.loadDailyHoroscope()
        }
    }

    // MARK: - Subviews

    /// Loading placeholder card
    private var loadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(CosmicTheme.gold)
            Text("Reading the stars...")
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
        )
    }

    /// Main daily horoscope card
    private func dailyHoroscopeCard(_ horoscope: Horoscope) -> some View {
        VStack(spacing: 20) {
            // Header with sign
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Daily Reading")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textSecondary)

                    Text(horoscope.sign.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(CosmicTheme.gold)
                }

                Spacer()

                // Large zodiac symbol
                Text(horoscope.sign.symbol)
                    .font(.system(size: 60))
            }

            Divider()
                .background(CosmicTheme.textMuted)

            // General reading
            VStack(alignment: .leading, spacing: 8) {
                Label("General", systemImage: "sparkles")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.gold)

                Text(horoscope.generalReading)
                    .font(.body)
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineSpacing(4)
            }

            // Trading insight
            VStack(alignment: .leading, spacing: 8) {
                Label("Trading Insight", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.cosmicPurple)

                Text(horoscope.tradingInsight)
                    .font(.body)
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineSpacing(4)
            }

            // Lucky info row
            HStack(spacing: 20) {
                luckyItem(title: "Lucky Number", value: "\(horoscope.luckyNumber)")
                luckyItem(title: "Lucky Stock", value: horoscope.luckyStock)
                luckyItem(title: "Mood", value: String(repeating: "★", count: horoscope.moodRating))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [CosmicTheme.gold.opacity(0.5), CosmicTheme.cosmicPurple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    /// Small lucky info item
    private func luckyItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)

            Text(value)
                .font(.headline)
                .foregroundColor(CosmicTheme.gold)
        }
        .frame(maxWidth: .infinity)
    }

    /// Browse all zodiac signs section
    private var allSignsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Signs")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.allSigns) { sign in
                    ZodiacSignButton(sign: sign, isSelected: sign == viewModel.userSign)
                }
            }
        }
    }
}

// MARK: - Zodiac Sign Button Component

struct ZodiacSignButton: View {
    let sign: ZodiacSign
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(sign.symbol)
                .font(.system(size: 32))

            Text(sign.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? CosmicTheme.gold : CosmicTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? CosmicTheme.cardBackground : CosmicTheme.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? CosmicTheme.gold : Color.clear, lineWidth: 2)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    HoroscopeView()
        .preferredColorScheme(.dark)
}
