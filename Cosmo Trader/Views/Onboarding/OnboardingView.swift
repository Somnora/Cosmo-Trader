import SwiftUI

// MARK: - OnboardingView
// ======================
// A magical multi-step onboarding experience for first-time users.
//
// Steps:
// 1. Welcome - App intro with cosmic animation
// 2. Birth Date - Collect birth date, reveal zodiac sign
// 3. Name Entry - Personalized welcome
// 4. Element Explanation - Visual intro to their element
// 5. First Stock Match - Pick a compatible stock
// 6. Complete - Animated transition to main app
//
// Design: Mystical, welcoming, sets the cosmic tone

struct OnboardingView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var userName: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var birthTime: Date = Date()
    @State private var knowsBirthTime: Bool = false
    @State private var currentStep: OnboardingStep = .welcome
    @State private var isAnimating: Bool = false
    @State private var selectedStock: Stock? = nil
    @State private var showSignReveal: Bool = false
    @State private var pulseAnimation: Bool = false

    // Validation states
    @State private var nameValidationError: String? = nil
    @State private var dateValidationError: String? = nil
    @State private var showValidationError: Bool = false

    // MARK: - Computed Properties

    /// The zodiac sign based on current birth date
    private var previewSign: ZodiacSign {
        ZodiacSign.from(date: birthDate)
    }

    /// Top 3 compatible stocks for the user's sign
    private var compatibleStocks: [Stock] {
        let allStocks = Stock.samples + MockStockData.all
        let userSign = previewSign

        // Sort by compatibility and take top 3
        return allStocks
            .compactMap { (stock: Stock) -> (stock: Stock, score: Int)? in
                guard let stockSign = stock.zodiacSign else { return nil }
                let result = userSign.compatibility(with: stockSign)
                return (stock: stock, score: result.score)
            }
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0.stock }
    }

    /// Can the user proceed to the next step?
    private var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .birthDate:
            // Validate birth date
            return InputValidator.validateBirthDate(birthDate) == nil
        case .quote:
            // Quote step uses its own continue button
            return true
        case .disclaimer:
            // Disclaimer step uses its own "I understand" button
            return true
        case .birthTime:
            // Always can proceed (birth time is optional)
            return true
        case .name:
            // Validate name (at least 2 characters, valid format)
            return InputValidator.validateName(userName) == nil
        case .element:
            return true
        case .stockMatch:
            return selectedStock != nil
        case .complete:
            return true
        }
    }

    /// Get validation message for current step
    private var currentValidationMessage: String? {
        switch currentStep {
        case .birthDate:
            if let error = InputValidator.validateBirthDate(birthDate) {
                return error.cosmicMessage
            }
        case .name:
            if let error = InputValidator.validateName(userName) {
                return error.cosmicMessage
            }
        default:
            break
        }
        return nil
    }

    /// Progress value for page indicator
    private var progress: CGFloat {
        CGFloat(currentStep.rawValue + 1) / CGFloat(OnboardingStep.allCases.count)
    }

    /// Border color for name field based on validation
    private var nameFieldBorderColor: Color {
        if nameValidationError != nil {
            return .orange
        } else if userName.isEmpty {
            return CosmicTheme.textMuted.opacity(0.4)
        } else if InputValidator.validateName(userName) == nil {
            return CosmicTheme.gold.opacity(0.5)
        } else {
            return CosmicTheme.textMuted.opacity(0.4)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Cosmic background
            cosmicBackground

            // Content
            VStack(spacing: 0) {
                // Page indicator (hide on welcome, quote, disclaimer, and complete)
                if currentStep != .welcome && currentStep != .quote && currentStep != .disclaimer && currentStep != .complete {
                    pageIndicator
                        .padding(.top, 20)
                }

                Spacer()

                // Step content
                stepContent
                    .padding(.horizontal, 32)

                Spacer()

                // Bottom button (hide on quote and disclaimer steps - they have their own buttons)
                if currentStep != .complete && currentStep != .quote && currentStep != .disclaimer {
                    bottomButton
                        .padding(.horizontal, 32)
                        .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                isAnimating = true
            }
            startPulseAnimation()
            // Track onboarding started
            AnalyticsService.shared.trackOnboardingStarted()
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            // Exclude welcome, quote, disclaimer, and complete from the indicator
            ForEach(OnboardingStep.allCases.filter { $0 != .welcome && $0 != .quote && $0 != .disclaimer && $0 != .complete }, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? CosmicTheme.gold : CosmicTheme.textMuted.opacity(0.4))
                    .frame(width: step == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Cosmic Background

    private var cosmicBackground: some View {
        ZStack {
            // Base background - solid OLED black for terminal aesthetic
            CosmicTheme.background
                .ignoresSafeArea()

            // Subtle static stars - no animation, very dim
            // Only on welcome and complete screens for minimal cosmic hint
            if currentStep == .welcome || currentStep == .complete {
                StaticStarsBackground()
                    .opacity(0.4)
            }
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

        case .birthDate:
            birthDateContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))

        case .quote:
            quoteContent
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity
                ))

        case .disclaimer:
            disclaimerContent
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity
                ))

        case .birthTime:
            birthTimeContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))

        case .name:
            nameContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))

        case .element:
            elementContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))

        case .stockMatch:
            stockMatchContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))

        case .complete:
            completeContent
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)),
                    removal: .opacity
                ))
        }
    }

    // MARK: - Welcome Step

    private var welcomeContent: some View {
        VStack(spacing: 40) {
            // Clean terminal-style zodiac wheel - no glow, no pulse
            ZStack {
                // Simple outer ring - single, clean stroke
                Circle()
                    .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                    .frame(width: 200, height: 200)

                // Zodiac symbols in a ring - static positions, no animation
                ForEach(0..<12, id: \.self) { index in
                    let sign = ZodiacSign.allCases[index]
                    let angle = Double(index) * (360.0 / 12.0) - 90
                    let radians = angle * .pi / 180

                    ZodiacSymbolView(sign: sign, size: 16, color: CosmicTheme.gold.opacity(0.6))
                        .offset(
                            x: cos(radians) * 75,
                            y: sin(radians) * 75
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.03), value: isAnimating)
                }

                // Center icon - simple, no glow
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(CosmicTheme.gold)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: isAnimating)
            }

            // Title and tagline - terminal font style
            VStack(spacing: 12) {
                Text("COSMO TRADER")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: isAnimating)

                Text("Astrological Market Intelligence")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: isAnimating)
            }

            // Description - professional tone
            Text("Map your portfolio against market astrology cycles.\nGrounded context for playful market readers.")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: isAnimating)
        }
    }

    // MARK: - Birth Date Step

    private var birthDateContent: some View {
        VStack(spacing: 28) {
            // Animated sign preview
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                previewSign.element.color.opacity(showSignReveal ? 0.4 : 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .animation(.easeInOut(duration: 0.5), value: showSignReveal)

                // Circle background
                Circle()
                    .fill(CosmicTheme.cardBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(
                                showSignReveal ? previewSign.element.color : CosmicTheme.textMuted.opacity(0.4),
                                lineWidth: 2
                            )
                    )

                // Sign symbol (revealed as date changes) - custom glyph
                ZodiacSymbolView(sign: previewSign, size: 48, color: previewSign.element.color)
                    .scaleEffect(showSignReveal ? 1 : 0.5)
                    .opacity(showSignReveal ? 1 : 0.3)
                    .animation(.spring(response: 0.4), value: showSignReveal)
            }

            // Title
            VStack(spacing: 8) {
                Text("When were you born?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Your birth date reveals your cosmic investor identity")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Date picker with validation bounds
            DatePicker(
                "",
                selection: $birthDate,
                in: InputValidator.validBirthDateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .frame(maxHeight: 180)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(CosmicTheme.gold.opacity(0.2), lineWidth: 1)
                    )
            )
            .onChange(of: birthDate) { _, _ in
                withAnimation(.spring(response: 0.4)) {
                    showSignReveal = true
                    dateValidationError = nil
                }
                // Track birthdate entered and sign selected
                AnalyticsService.shared.trackBirthdateEntered(sunSign: previewSign.displayName)
                AnalyticsService.shared.trackOnboardingSignSelected(sign: previewSign.displayName, method: "birthday")
            }
            .accessibilityLabel("Birth date picker")
            .accessibilityHint("Select your birth date to determine your zodiac sign")
            .accessibilityIdentifier("onboarding.birthDatePicker")

            // Sign reveal text
            if showSignReveal {
                HStack(spacing: 8) {
                    ZodiacSymbolView(sign: previewSign, size: 18, color: previewSign.element.color)
                    Text("You're a \(previewSign.displayName)!")
                        .font(TerminalFont.headline(16))
                }
                .foregroundColor(previewSign.element.color)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onAppear {
            // Show sign reveal if date already selected
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showSignReveal = true
                }
            }
        }
    }

    // MARK: - Quote Step

    private var quoteContent: some View {
        OnboardingQuoteStepView {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = .disclaimer
            }
        }
    }

    // MARK: - Disclaimer Step

    private var disclaimerContent: some View {
        OnboardingDisclaimerStepView {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = .birthTime
            }
        }
    }

    // MARK: - Birth Time Step (Optional)

    private var birthTimeContent: some View {
        VStack(spacing: 28) {
            // Rising sign icon
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                CosmicTheme.gold.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Circle background
                Circle()
                    .fill(CosmicTheme.cardBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(CosmicTheme.gold.opacity(0.5), lineWidth: 2)
                    )

                // Rising sun icon
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(CosmicTheme.goldGradient)
            }

            // Title
            VStack(spacing: 8) {
                Text("Do you know your birth time?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Birth time enables rising sign calculation\nfor deeper cosmic insights")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Toggle for knowing birth time
            VStack(spacing: 16) {
                Toggle(isOn: $knowsBirthTime) {
                    HStack {
                        Image(systemName: knowsBirthTime ? "clock.fill" : "clock")
                            .foregroundColor(knowsBirthTime ? CosmicTheme.gold : CosmicTheme.textMuted)

                        Text(knowsBirthTime ? "I know my birth time" : "I don't know my birth time")
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: CosmicTheme.gold))
                .accessibilityIdentifier("onboarding.birthTimeToggle")
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(CosmicTheme.cardBackground)
                )

                // Time picker (only if they know their time)
                if knowsBirthTime {
                    DatePicker(
                        "",
                        selection: $birthTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(maxHeight: 150)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(CosmicTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.spring(response: 0.3), value: knowsBirthTime)

            // Helper text
            Text("You can always add or change this later in Profile settings")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Name Step

    private var nameContent: some View {
        VStack(spacing: 32) {
            // Preview avatar
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                previewSign.element.color.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(CosmicTheme.cardBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(previewSign.element.color, lineWidth: 1)
                    )

                ZodiacSymbolView(sign: previewSign, size: 48, color: previewSign.element.color)
            }

            // Title
            VStack(spacing: 8) {
                Text("What should we call you?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("This is how you'll appear in your investor profile")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Name input with validation
            VStack(spacing: 8) {
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
                                    .stroke(
                                        nameFieldBorderColor,
                                        lineWidth: 1
                                    )
                            )
                    )
                    .autocorrectionDisabled()
                    .onChange(of: userName) { _, newValue in
                        // Clear validation error when typing
                        nameValidationError = nil
                        // Limit to 50 characters
                        if newValue.count > 50 {
                            userName = String(newValue.prefix(50))
                        }
                    }
                    .accessibilityLabel("Name input field")
                    .accessibilityHint("Enter your display name")
                    .accessibilityIdentifier("onboarding.nameField")

                // Validation error message
                if let error = nameValidationError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }

            // Personalized preview
            if !userName.isEmpty {
                Text("Welcome, \(userName) the \(previewSign.displayName)")
                    .font(.headline)
                    .foregroundStyle(CosmicTheme.goldGradient)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.spring(response: 0.3), value: userName)
            }
        }
    }

    // MARK: - Element Step

    private var elementContent: some View {
        VStack(spacing: 28) {
            // Large element display
            ZStack {
                // Glow rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(previewSign.element.color.opacity(0.2 - Double(ring) * 0.05), lineWidth: 2)
                        .frame(width: 140 + CGFloat(ring) * 30, height: 140 + CGFloat(ring) * 30)
                        .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(ring) * 0.2),
                            value: pulseAnimation
                        )
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                previewSign.element.color.opacity(0.4),
                                previewSign.element.color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                ElementSymbolView(element: previewSign.element, size: 56)
            }

            // Element explanation
            VStack(spacing: 16) {
                Text("Your \(previewSign.element.displayName) Energy")
                    .font(TerminalFont.headline(22))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("As a \(previewSign.displayName), you're an \(previewSign.element.displayName) sign investor")
                    .font(TerminalFont.data(14, weight: .semibold))
                    .foregroundColor(previewSign.element.color)
            }

            // Element traits card
            VStack(alignment: .leading, spacing: 16) {
                Text(elementDescription)
                    .font(.body)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineSpacing(4)

                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.4))

                // Element traits
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Investing Style:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textMuted)

                    ForEach(elementTraits, id: \.self) { trait in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(previewSign.element.color)
                                .frame(width: 6, height: 6)
                            Text(trait)
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(CosmicTheme.cardBackground)
            )

            // Other elements teaser
            HStack(spacing: 20) {
                ForEach(ZodiacSign.Element.allCases.filter { $0 != previewSign.element }, id: \.self) { element in
                    VStack(spacing: 4) {
                        ElementSymbolView(element: element, size: 24, color: element.color.opacity(0.5))
                        Text(element.displayName)
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private var elementDescription: String {
        switch previewSign.element {
        case .fire:
            return "Fire signs are bold, action-oriented investors. You thrive on momentum, embrace calculated risks, and have a natural instinct for spotting opportunities before others."
        case .earth:
            return "Earth signs are patient, value-focused investors. You excel at building long-term wealth through steady accumulation and have a keen eye for undervalued assets."
        case .air:
            return "Air signs are analytical, diversified investors. You process information quickly, adapt to market changes, and excel at portfolio balancing."
        case .water:
            return "Water signs are intuitive, protective investors. You sense market shifts before they happen and prioritize preserving gains over chasing trends."
        }
    }

    private var elementTraits: [String] {
        switch previewSign.element {
        case .fire:
            return ["Bold entry and exit timing", "High growth stock affinity", "Momentum trading instincts"]
        case .earth:
            return ["Value investing strength", "Dividend stock appreciation", "Long-term holding patience"]
        case .air:
            return ["Multi-sector diversification", "Tech and innovation focus", "Quick market adaptation"]
        case .water:
            return ["Risk management priority", "Defensive positioning", "Contrarian opportunity sense"]
        }
    }

    // MARK: - Stock Match Step

    private var stockMatchContent: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.system(size: 36))
                    .foregroundStyle(CosmicTheme.goldGradient)

                Text("Your First Cosmic Matches")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("These stocks align with your \(previewSign.displayName) profile")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Stock cards
            VStack(spacing: 12) {
                ForEach(compatibleStocks, id: \.symbol) { stock in
                    StockMatchCard(
                        stock: stock,
                        userSign: previewSign,
                        isSelected: selectedStock?.symbol == stock.symbol,
                        onSelect: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedStock = stock
                            }
                        }
                    )
                }
            }

            // Selection prompt
            if selectedStock == nil {
                Text("Tap a stock to add it to your starter portfolio")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(CosmicTheme.positive)
                    Text("\(selectedStock?.symbol ?? "") selected!")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(CosmicTheme.positive)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Complete Step

    private var completeContent: some View {
        VStack(spacing: 36) {
            // Clean success display - terminal style
            ZStack {
                // Simple outer ring
                Circle()
                    .stroke(CosmicTheme.gold.opacity(0.4), lineWidth: 1)
                    .frame(width: 160, height: 160)

                // Inner ring with element color
                Circle()
                    .stroke(previewSign.element.color.opacity(0.3), lineWidth: 1)
                    .frame(width: 120, height: 120)

                // User sign - clean display
                VStack(spacing: 6) {
                    ZodiacSymbolView(sign: previewSign, size: 44, color: previewSign.element.color)
                    ElementSymbolView(element: previewSign.element, size: 18)
                }
            }

            // Completion message - terminal style
            VStack(spacing: 12) {
                Text("SETUP COMPLETE")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Welcome, \(userName)")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)

                if let stock = selectedStock {
                    Text("\(stock.symbol) added to portfolio")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }

            // Status message
            Text("Your \(previewSign.displayName) trading profile is ready.")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(CosmicTheme.textMuted)
                .multilineTextAlignment(.center)

            // Enter button - clean, no shadow glow
            Button(action: completeOnboarding) {
                HStack(spacing: 10) {
                    Text("Launch Terminal")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(CosmicTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(CosmicTheme.gold)
                .cornerRadius(8)
            }
            .padding(.top, 16)
            .accessibilityIdentifier("onboarding.launchTerminalButton")
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        Button(action: handleButtonTap) {
            HStack(spacing: 10) {
                Text(buttonTitle)
                    .font(.headline)
                    .fontWeight(.semibold)

                Image(systemName: "arrow.right")
                    .font(.headline)
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
        .accessibilityIdentifier("onboarding.primaryButton")
    }

    private var buttonTitle: String {
        switch currentStep {
        case .welcome: return "Begin Setup"
        case .birthDate: return "Continue"
        case .quote: return "Continue"  // Not shown - quote has its own button
        case .disclaimer: return "I Understand"  // Not shown - disclaimer has its own button
        case .birthTime: return "Continue"
        case .name: return "Continue"
        case .element: return "Find My First Match"
        case .stockMatch: return "Complete Setup"
        case .complete: return "Enter the Cosmos"
        }
    }

    // MARK: - Actions

    private func handleButtonTap() {
        // Validate current step before proceeding
        switch currentStep {
        case .birthDate:
            if let error = InputValidator.validateBirthDate(birthDate) {
                withAnimation(.spring(response: 0.3)) {
                    dateValidationError = error.cosmicMessage
                }
                return
            }
        case .name:
            if let error = InputValidator.validateName(userName) {
                withAnimation(.spring(response: 0.3)) {
                    nameValidationError = error.cosmicMessage
                }
                return
            }
        default:
            break
        }

        let nextStep: OnboardingStep? = {
            switch currentStep {
            case .welcome: return .birthDate
            case .birthDate: return .quote
            case .quote: return .disclaimer  // Quote step handles its own transition
            case .disclaimer: return .birthTime  // Disclaimer step handles its own transition
            case .birthTime: return .name
            case .name: return .element
            case .element: return .stockMatch
            case .stockMatch: return .complete
            case .complete: return nil
            }
        }()

        if let next = nextStep {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep = next
                // Clear validation errors when moving to next step
                nameValidationError = nil
                dateValidationError = nil
            }
        }
    }

    private func completeOnboarding() {
        // Track onboarding completed
        AnalyticsService.shared.trackOnboardingCompleted(sunSign: previewSign.displayName)

        // Determine time of birth (nil if user doesn't know)
        let timeOfBirth: Date? = knowsBirthTime ? birthTime : nil

        // Add selected stock to portfolio if chosen
        appState.completeOnboarding(
            name: userName.trimmingCharacters(in: .whitespaces),
            birthDate: birthDate,
            timeOfBirth: timeOfBirth
        )

        // Add the selected stock after user is created
        if let stock = selectedStock {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appState.addToPortfolio(stock, shares: 1)
                // Track first stock added
                AnalyticsService.shared.trackStockAddedToPortfolio(
                    symbol: stock.symbol,
                    zodiacSign: stock.zodiacSign?.displayName ?? "Unknown",
                    source: "onboarding"
                )
            }
        }

        // Update user properties
        AnalyticsService.shared.setUserProperties(
            sunSign: previewSign.displayName,
            portfolioSize: selectedStock != nil ? 1 : 0,
            accountAgeDays: 0,
            isPremium: false
        )
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
}

// MARK: - Onboarding Step Enum

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case birthDate = 1
    case quote = 2        // Premium positioning quote
    case disclaimer = 3   // Legal disclaimer - must acknowledge
    case birthTime = 4
    case name = 5
    case element = 6
    case stockMatch = 7
    case complete = 8
}

// MARK: - Stock Match Card

struct StockMatchCard: View {
    let stock: Stock
    let userSign: ZodiacSign
    let isSelected: Bool
    let onSelect: () -> Void

    private var compatibilityScore: Int? {
        guard let stockSign = stock.zodiacSign else { return nil }
        return userSign.compatibility(with: stockSign).score
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Stock zodiac symbol
                ZStack {
                    Circle()
                        .fill((stock.foundedElement?.color ?? CosmicTheme.textMuted).opacity(0.2))
                        .frame(width: 50, height: 50)

                    if let sign = stock.zodiacSign {
                        ZodiacSymbolView(sign: sign, size: 26, color: sign.element.color)
                    } else {
                        Text("?")
                            .font(TerminalFont.body(24, weight: .semibold))
                            .foregroundColor(CosmicTheme.textMuted)
                            .accessibilityLabel("unknown sign")
                    }
                }

                // Stock info
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.symbol)
                        .font(TerminalFont.data(15, weight: .bold))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(stock.name)
                        .font(TerminalFont.data(11))
                        .foregroundColor(CosmicTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Compatibility
                VStack(alignment: .trailing, spacing: 2) {
                    if let compatibilityScore {
                        Text("\(compatibilityScore)%")
                            .font(TerminalFont.price(16))
                            .foregroundColor(CosmicTheme.gold)
                    } else {
                        Text("Unknown")
                            .font(TerminalFont.data(12, weight: .semibold))
                            .foregroundColor(CosmicTheme.textMuted)
                    }

                    Text("match")
                        .font(TerminalFont.data(10))
                        .foregroundColor(CosmicTheme.textMuted)
                }

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? CosmicTheme.gold : CosmicTheme.textMuted.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(CosmicTheme.gold)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? CosmicTheme.gold : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.stockMatch.\(stock.symbol)")
    }
}

// MARK: - Static Stars Background
// Simplified, non-animated star field for subtle cosmic hint

struct StaticStarsBackground: View {
    var body: some View {
        Canvas { context, size in
            // Fewer stars, smaller, dimmer - subtle terminal aesthetic
            for i in 0..<40 {
                let x = pseudoRandom(seed: i * 3) * size.width
                let y = pseudoRandom(seed: i * 3 + 1) * size.height
                let starSize = 0.5 + pseudoRandom(seed: i * 3 + 2) * 1.0
                let brightness = 0.1 + pseudoRandom(seed: i * 3 + 3) * 0.2

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

// MARK: - Animated Stars Background (kept for compatibility)

struct AnimatedStarsBackground: View {
    let isAnimating: Bool

    var body: some View {
        StaticStarsBackground()
    }
}

// MARK: - Floating Particles (kept for compatibility, but simplified)

struct FloatingParticles: View {
    var body: some View {
        // Removed floating particles - too magical for terminal aesthetic
        EmptyView()
    }
}

// MARK: - Preview

#Preview("Onboarding - Welcome") {
    OnboardingView()
        .environment(AppState.previewEmpty)
}

#Preview("Onboarding Flow") {
    OnboardingView()
        .environment(AppState.previewEmpty)
}
