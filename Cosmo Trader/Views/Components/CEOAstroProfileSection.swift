import SwiftUI

// MARK: - CEOAstroProfileSection
// ==============================
// The CEO astro profile block, lifted verbatim out of StockDetailView so that
// view could take the free-tier paywall without growing (view-size ratchet:
// views render state and forward intents).
//
// It reached for exactly three things from its old home -- the stock, the
// signed-in user, and whether the appear animation had run -- so those are the
// inputs, and the card background it used is reproduced here rather than
// threaded through as a closure.

struct CEOAstroProfileSection: View {

    let stock: Stock
    let user: UserProfile?
    let hasAppeared: Bool
    /// Passed in rather than re-derived: the framing level is the detail
    /// view's state, and a second copy of that lookup is a second thing to
    /// keep in step.
    let framedCEOInsight: String
    let userElementColor: Color

    var body: some View {
        section
    }

    private var section: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "person.fill.checkmark")
                    .foregroundColor(CosmicTheme.accentBlue)

                Text("CEO ASTRO PROFILE")
                    .font(TerminalFont.data(12, weight: .semibold))
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()
            }

            // CEO info card
            if let ceoName = stock.ceoName, let ceoSign = stock.ceoZodiacSign {
                VStack(spacing: 16) {
                    // CEO header with zodiac
                    HStack(spacing: 16) {
                        // CEO avatar
                        ZStack {
                            Circle()
                                .fill(ceoElementColor.opacity(0.2))
                                .frame(width: 56, height: 56)

                            Circle()
                                .stroke(ceoElementColor.opacity(0.5), lineWidth: 1)
                                .frame(width: 56, height: 56)

                            ZodiacSymbolView(sign: ceoSign, size: 28, color: ceoElementColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(ceoName)
                                .font(TerminalFont.headline(16))
                                .foregroundColor(CosmicTheme.textPrimary)

                            HStack(spacing: 8) {
                                Text(ceoSign.displayName)
                                    .font(TerminalFont.data(12, weight: .semibold))
                                    .foregroundColor(ceoElementColor)

                                Text("•")
                                    .foregroundColor(CosmicTheme.textMuted)

                                Text(ceoSign.element.displayName)
                                    .font(TerminalFont.data(12))
                                    .foregroundColor(CosmicTheme.textSecondary)
                            }

                            Text("Chief Executive Officer")
                                .font(TerminalFont.data(10))
                                .foregroundColor(CosmicTheme.textMuted)
                        }

                        Spacer()
                    }

                    Divider()
                        .background(CosmicTheme.textMuted.opacity(0.4))

                    // CEO-User compatibility
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Alignment with \(ceoName.components(separatedBy: " ").first ?? "CEO")")
                                .font(TerminalFont.data(11, weight: .semibold))
                                .foregroundColor(CosmicTheme.textMuted)

                            HStack(spacing: 12) {
                                // User's sign
                                ZodiacSymbolView(sign: user?.sunSign ?? .aries, size: 24, color: userElementColor)

                                // Connection indicator
                                HStack(spacing: 4) {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(ceoCompatibilityDots(index))
                                            .frame(width: 6, height: 6)
                                    }
                                }

                                // CEO's sign
                                ZodiacSymbolView(sign: ceoSign, size: 24, color: ceoElementColor)

                                Spacer()

                                // Compatibility score
                                Text("\(ceoCompatibilityScore)%")
                                    .font(TerminalFont.price(24))
                                    .foregroundColor(ceoCompatibilityColor)
                            }

                            Text(ceoCompatibilityDescription)
                                .font(TerminalFont.data(11))
                                .foregroundColor(CosmicTheme.textSecondary)
                                .lineSpacing(2)
                        }
                    }

                    // Leadership insight
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(CosmicTheme.accentBlue)

                        Text(framedCEOInsight)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .italic()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(CosmicTheme.accentBlue.opacity(0.1))
                    )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.25), value: hasAppeared)
    }

    // MARK: - CEO Compatibility Helpers

    private var ceoElementColor: Color {
        guard let element = stock.ceoElement else { return CosmicTheme.textSecondary }
        switch element {
        case .fire:  return CosmicTheme.fireElement
        case .earth: return CosmicTheme.earthElement
        case .air:   return CosmicTheme.airElement
        case .water: return CosmicTheme.waterElement
        }
    }

    private var ceoCompatibilityScore: Int {
        guard let ceoSign = stock.ceoZodiacSign else { return 50 }
        return (user?.sunSign ?? .aries).compatibilityScore(with: ceoSign)
    }

    private var ceoCompatibilityColor: Color {
        let score = ceoCompatibilityScore
        if score >= 85 { return CosmicTheme.gold }
        if score >= 70 { return CosmicTheme.accentBlue }
        if score >= 50 { return CosmicTheme.textPrimary }
        return .orange
    }

    private func ceoCompatibilityDots(_ index: Int) -> Color {
        let score = ceoCompatibilityScore
        let threshold = [50, 70, 85]
        return score >= threshold[index] ? ceoCompatibilityColor : CosmicTheme.textMuted.opacity(0.4)
    }

    private var ceoCompatibilityDescription: String {
        guard let ceoSign = stock.ceoZodiacSign else { return "" }
        let score = ceoCompatibilityScore

        if user?.sunSign ?? .aries == ceoSign {
            return "You share the same sign as the CEO - deep natural understanding and aligned vision."
        } else if (user?.sunSign ?? .aries).element == ceoSign.element {
            return "Same elemental energy creates intuitive trust in their leadership decisions."
        } else if score >= 85 {
            return "Excellent alignment - the CEO's profile fits your investment style."
        } else if score >= 70 {
            return "Good compatibility - their leadership approach complements your investor energy."
        } else if score >= 50 {
            return "Balanced dynamics - different perspectives can offer diversified opportunities."
        } else {
            return "Contrasting energies - exercise extra due diligence on leadership decisions."
        }
    }

    private var ceoLeadershipInsight: String {
        guard let ceoSign = stock.ceoZodiacSign, let ceoName = stock.ceoName else { return "" }
        let firstName = ceoName.components(separatedBy: " ").first ?? "The CEO"

        switch ceoSign {
        case .aries:
            return "\(firstName)'s Aries drive brings bold, pioneering leadership. Expect aggressive growth strategies and first-mover initiatives."
        case .taurus:
            return "\(firstName)'s Taurus energy emphasizes stability and long-term value creation. Methodical, patient approach to business."
        case .gemini:
            return "\(firstName)'s Gemini versatility enables quick pivots and excellent communication. Strong media presence and adaptability."
        case .cancer:
            return "\(firstName)'s Cancer intuition creates a nurturing corporate culture focused on employee and customer loyalty."
        case .leo:
            return "\(firstName)'s Leo charisma inspires teams and attracts attention. Bold vision with a flair for brand building."
        case .virgo:
            return "\(firstName)'s Virgo precision drives operational excellence. Detail-oriented approach to quality and efficiency."
        case .libra:
            return "\(firstName)'s Libra diplomacy excels at partnerships and creating balance. Strategic alliance-focused leadership."
        case .scorpio:
            return "\(firstName)'s Scorpio intensity brings transformative leadership. Deep strategic thinking and resilience through challenges."
        case .sagittarius:
            return "\(firstName)'s Sagittarius optimism fuels international expansion and big-picture thinking. Adventurous growth strategy."
        case .capricorn:
            return "\(firstName)'s Capricorn discipline builds sustainable long-term success. Conservative, structured approach to growth."
        case .aquarius:
            return "\(firstName)'s Aquarius innovation disrupts industries. Forward-thinking, technology-focused leadership."
        case .pisces:
            return "\(firstName)'s Pisces creativity brings imaginative solutions. Empathetic leadership with strong brand storytelling."
        }
    }

    private var cardBackground: some View {
        Rectangle()
            .fill(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 0.5)
            )
    }
}
