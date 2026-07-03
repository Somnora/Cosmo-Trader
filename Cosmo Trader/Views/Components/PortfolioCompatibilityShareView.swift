import SwiftUI

struct PortfolioCompatibilityShareView: View {
    let user: UserProfile
    let result: PortfolioCompatibilityResult

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Text("COSMO TRADER TERMINAL v2.0")
                        .font(TerminalFont.data(18, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                    Spacer()
                    Text("SYSTEM: SECURE CLOUD SYNC")
                        .font(TerminalFont.data(14))
                        .foregroundColor(CosmicTheme.textMuted)
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)

                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(height: 2)
                    .padding(.horizontal, 40)

                Text("ZODIAC PORTFOLIO ALIGNMENT REPORT")
                    .font(TerminalFont.ticker(36))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
            }

            Spacer()

            // Main Content: Score & Badges
            HStack(spacing: 60) {
                // Large Score Circular Display
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(CosmicTheme.borderStrong, lineWidth: 8)
                            .frame(width: 320, height: 320)

                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [CosmicTheme.positive, CosmicTheme.gold, CosmicTheme.positive],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .frame(width: 320, height: 320)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("ALIGNMENT")
                                .font(TerminalFont.data(14, weight: .bold))
                                .foregroundColor(CosmicTheme.textMuted)
                                .tracking(2)

                            Text(String(format: "%.0f%%", result.overallScore))
                                .font(TerminalFont.price(96, weight: .bold))
                                .foregroundColor(CosmicTheme.positive)

                            Text(result.rating.displayName.uppercased())
                                .font(TerminalFont.data(16, weight: .bold))
                                .foregroundColor(CosmicTheme.gold)
                        }
                    }
                }

                // Dominant Sign / Element & Info
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("INVESTOR PROFILE")
                            .font(TerminalFont.data(14, weight: .bold))
                            .foregroundColor(CosmicTheme.textMuted)

                        Text(user.displayName.uppercased())
                            .font(TerminalFont.ticker(28))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }

                    HStack(spacing: 20) {
                        // Sign Badge
                        HStack(spacing: 8) {
                            ZodiacSymbolView(sign: user.sunSign, size: 24, color: user.element.color)
                            Text(user.sunSign.displayName.uppercased())
                                .font(TerminalFont.data(16, weight: .bold))
                                .foregroundColor(user.element.color)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(user.element.color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(user.element.color.opacity(0.5), lineWidth: 1.5)
                        )

                        // Element Badge
                        HStack(spacing: 8) {
                            ElementSymbolView(element: user.element, size: 20, color: user.element.color)
                            Text(user.element.displayName.uppercased())
                                .font(TerminalFont.data(16, weight: .bold))
                                .foregroundColor(user.element.color)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(user.element.color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(user.element.color.opacity(0.5), lineWidth: 1.5)
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("PORTFOLIO VALUE")
                            .font(TerminalFont.data(14, weight: .bold))
                            .foregroundColor(CosmicTheme.textMuted)
                        Text(user.formattedPortfolioValue)
                            .font(TerminalFont.price(24, weight: .bold))
                            .foregroundColor(CosmicTheme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 60)

            Spacer()

            // Element Breakdown Bars
            VStack(alignment: .leading, spacing: 20) {
                Text("PORTFOLIO ELEMENTAL COMPOSITION")
                    .font(TerminalFont.data(14, weight: .bold))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(1)

                VStack(spacing: 16) {
                    ForEach(ZodiacSign.Element.allCases, id: \.self) { element in
                        let pct = result.elementBreakdown[element] ?? 0
                        HStack(spacing: 20) {
                            HStack(spacing: 8) {
                                ElementSymbolView(element: element, size: 16, color: element.color)
                                Text(element.displayName.uppercased())
                                    .font(TerminalFont.data(14, weight: .bold))
                                    .foregroundColor(element.color)
                                    .frame(width: 80, alignment: .leading)
                            }

                            // Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(CosmicTheme.border)
                                        .frame(height: 12)

                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(element.color)
                                        .frame(width: geo.size.width * CGFloat(pct / 100.0), height: 12)
                                }
                            }
                            .frame(height: 12)

                            Text(String(format: "%.0f%%", pct))
                                .font(TerminalFont.price(14, weight: .bold))
                                .foregroundColor(CosmicTheme.textPrimary)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(.horizontal, 60)

            Spacer()

            // Cosmic Roast / Diagnosis
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(CosmicTheme.gold)
                    Text("COSMIC DIAGNOSIS")
                        .font(TerminalFont.data(14, weight: .bold))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(1)
                }

                Text(result.cosmicInsight)
                    .font(TerminalFont.body(20))
                    .foregroundColor(CosmicTheme.textPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CosmicTheme.cardBackground)
            .overlay(
                Rectangle()
                    .stroke(CosmicTheme.border, lineWidth: 1)
            )
            .padding(.horizontal, 60)

            Spacer()

            // Footer
            VStack(spacing: 12) {
                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(height: 1)
                    .padding(.horizontal, 40)

                HStack {
                    Text("Trade with the stars.")
                        .font(TerminalFont.data(14))
                        .foregroundColor(CosmicTheme.textMuted)

                    Spacer()

                    Text("cosmotrade.app")
                        .font(TerminalFont.ticker(16))
                        .foregroundColor(CosmicTheme.gold)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(width: 1080, height: 1080)
        .background(CosmicTheme.background)
    }
}
