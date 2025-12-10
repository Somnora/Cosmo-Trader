import SwiftUI

// MARK: - OnboardingView
// ======================
// Simple onboarding flow for first-time users.
//
// Collects:
// 1. User's name
// 2. User's birth date (to determine zodiac sign)
//
// Design: Mystical, welcoming, emphasizes the cosmic theme

struct OnboardingView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var userName: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var currentStep: OnboardingStep = .welcome
    @State private var isAnimating: Bool = false

    // MARK: - Computed Properties

    /// The zodiac sign based on current birth date
    private var previewSign: ZodiacSign {
        ZodiacSign.from(date: birthDate)
    }

    /// Can the user proceed to the next step?
    private var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .name:
            return userName.trimmingCharacters(in: .whitespaces).count >= 2
        case .birthDate:
            return true
        case .reveal:
            return true
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Cosmic background
            cosmicBackground

            // Content based on current step
            VStack(spacing: 0) {
                Spacer()

                stepContent
                    .padding(.horizontal, 32)

                Spacer()

                // Bottom button
                bottomButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Cosmic Background

    private var cosmicBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.08),
                    Color(red: 0.05, green: 0.02, blue: 0.15),
                    Color(red: 0.08, green: 0.04, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Stars
            StarsBackground()
                .opacity(isAnimating ? 1 : 0)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            welcomeContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 1.05))
                ))

        case .name:
            nameContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))

        case .birthDate:
            birthDateContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))

        case .reveal:
            revealContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity
                ))
        }
    }

    // MARK: - Welcome Step

    private var welcomeContent: some View {
        VStack(spacing: 32) {
            // App icon / zodiac wheel
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                CosmicTheme.gold.opacity(0.3),
                                CosmicTheme.cosmicPurple.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                // Zodiac symbols in a circle
                ForEach(0..<12, id: \.self) { index in
                    let sign = ZodiacSign.allCases[index]
                    let angle = Double(index) * (360.0 / 12.0) - 90
                    let radians = angle * .pi / 180

                    Text(sign.symbol)
                        .font(.system(size: 24))
                        .offset(
                            x: cos(radians) * 70,
                            y: sin(radians) * 70
                        )
                        .opacity(isAnimating ? 0.8 : 0)
                        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.05), value: isAnimating)
                }

                // Center star
                Image(systemName: "sparkle")
                    .font(.system(size: 40))
                    .foregroundStyle(CosmicTheme.goldGradient)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .opacity(isAnimating ? 1 : 0)
            }

            // Title
            VStack(spacing: 12) {
                Text("Cosmo Trader")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Where the Stars Guide Your Portfolio")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Tagline
            Text("Discover stocks aligned with your cosmic energy. Trade with the wisdom of the universe.")
                .font(.body)
                .foregroundColor(CosmicTheme.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 8)
        }
    }

    // MARK: - Name Step

    private var nameContent: some View {
        VStack(spacing: 32) {
            // Icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(CosmicTheme.goldGradient)

            // Title
            VStack(spacing: 8) {
                Text("What should we call you?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("This is how you'll appear in your cosmic profile")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Name input
            TextField("Your name", text: $userName)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(CosmicTheme.textPrimary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(CosmicTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                        )
                )
                .autocorrectionDisabled()
        }
    }

    // MARK: - Birth Date Step

    private var birthDateContent: some View {
        VStack(spacing: 32) {
            // Icon
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(CosmicTheme.goldGradient)

            // Title
            VStack(spacing: 8) {
                Text("When were you born?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("We'll use this to calculate your sun sign and cosmic compatibility")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Date picker
            DatePicker(
                "",
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .frame(maxHeight: 200)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    // MARK: - Reveal Step

    private var revealContent: some View {
        VStack(spacing: 32) {
            // Zodiac symbol reveal
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                previewSign.element.color.opacity(0.4),
                                previewSign.element.color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)

                // Inner circle
                Circle()
                    .fill(CosmicTheme.cardBackground)
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(previewSign.element.color, lineWidth: 3)
                    )

                // Symbol
                Text(previewSign.symbol)
                    .font(.system(size: 80))
            }

            // Sign reveal
            VStack(spacing: 12) {
                Text("Welcome, \(userName)!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                HStack(spacing: 8) {
                    Text("You are a")
                        .font(.title3)
                        .foregroundColor(CosmicTheme.textSecondary)

                    Text(previewSign.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(previewSign.element.color)
                }

                // Element badge
                HStack(spacing: 8) {
                    Text(previewSign.element.emoji)
                    Text("\(previewSign.element.displayName) Sign")
                        .fontWeight(.medium)
                    Text("·")
                    Text(previewSign.modality.displayName)
                }
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)
            }

            // Personality snippet
            Text("\"\(previewSign.corporatePersonality)\"")
                .font(.subheadline)
                .italic()
                .foregroundColor(CosmicTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        Button(action: handleButtonTap) {
            HStack(spacing: 10) {
                Text(buttonTitle)
                    .font(.headline)
                    .fontWeight(.semibold)

                if currentStep != .reveal {
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
            }
            .foregroundColor(CosmicTheme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(canProceed ? CosmicTheme.goldGradient : LinearGradient(colors: [CosmicTheme.textMuted], startPoint: .leading, endPoint: .trailing))
            )
            .shadow(color: CosmicTheme.gold.opacity(canProceed ? 0.3 : 0), radius: 10, x: 0, y: 5)
        }
        .disabled(!canProceed)
        .animation(.easeInOut(duration: 0.2), value: canProceed)
    }

    private var buttonTitle: String {
        switch currentStep {
        case .welcome: return "Begin Your Journey"
        case .name: return "Continue"
        case .birthDate: return "Reveal My Sign"
        case .reveal: return "Enter the Cosmos"
        }
    }

    // MARK: - Actions

    private func handleButtonTap() {
        switch currentStep {
        case .welcome:
            withAnimation(.spring(response: 0.4)) {
                currentStep = .name
            }

        case .name:
            withAnimation(.spring(response: 0.4)) {
                currentStep = .birthDate
            }

        case .birthDate:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = .reveal
            }

        case .reveal:
            // Complete onboarding
            appState.completeOnboarding(
                name: userName.trimmingCharacters(in: .whitespaces),
                birthDate: birthDate
            )
        }
    }
}

// MARK: - Onboarding Step

enum OnboardingStep {
    case welcome
    case name
    case birthDate
    case reveal
}

// MARK: - Stars Background

struct StarsBackground: View {

    var body: some View {
        Canvas { context, size in
            for i in 0..<80 {
                let x = pseudoRandom(seed: i * 3) * size.width
                let y = pseudoRandom(seed: i * 3 + 1) * size.height
                let starSize = 1.0 + pseudoRandom(seed: i * 3 + 2) * 2.5
                let brightness = 0.2 + pseudoRandom(seed: i * 3 + 3) * 0.6

                let rect = CGRect(
                    x: x - starSize / 2,
                    y: y - starSize / 2,
                    width: starSize,
                    height: starSize
                )

                context.fill(
                    Circle().path(in: rect),
                    with: .color(Color.white.opacity(brightness))
                )
            }
        }
    }

    private func pseudoRandom(seed: Int) -> CGFloat {
        let x = sin(Double(seed) * 12.9898 + 78.233) * 43758.5453
        return CGFloat(x - floor(x))
    }
}

// MARK: - Preview

#Preview("Onboarding - Welcome") {
    OnboardingView()
        .environment(AppState.previewEmpty)
}

#Preview("Onboarding - Full Flow") {
    OnboardingView()
        .environment(AppState.previewEmpty)
}
