import SwiftUI

// MARK: - Legal Views
// ====================
// Privacy Policy, Terms of Service, and NFA Disclaimer views.
// Terminal-style aesthetic consistent with the app theme.

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    LegalHeaderView(
                        title: "PRIVACY POLICY",
                        subtitle: "Last updated: December 2024"
                    )

                    // Sections
                    LegalSection(
                        title: "DATA WE COLLECT",
                        content: """
                        Cosmo Trader collects minimal data necessary to provide our services:

                        • Birth Date: Used solely to calculate your zodiac sign for personalized cosmic insights. Stored locally on your device.

                        • Portfolio Data: Stock symbols, quantities, and purchase information you choose to enter. Stored locally on your device.

                        • App Usage: Anonymous analytics to improve the app experience. No personally identifiable information is collected.
                        """
                    )

                    LegalSection(
                        title: "DATA STORAGE",
                        content: """
                        All personal data is stored locally on your device using secure iOS storage mechanisms. We do not transmit your personal information to external servers.

                        Your zodiac profile, portfolio holdings, and preferences remain on your device unless you explicitly choose to share them.
                        """
                    )

                    LegalSection(
                        title: "THIRD-PARTY SERVICES",
                        content: """
                        We use the following third-party services:

                        • Stock Market APIs: To fetch real-time and historical stock price data. Only stock symbols are transmitted, no personal information.

                        • Apple App Store: For subscription management and payment processing.

                        We do not sell, trade, or transfer your personal information to third parties.
                        """
                    )

                    LegalSection(
                        title: "YOUR RIGHTS",
                        content: """
                        You have the right to:

                        • Access your data at any time within the app
                        • Delete all your data by uninstalling the app
                        • Opt out of analytics in device settings
                        • Request information about data processing

                        For data requests, contact: privacy@cosmotrader.app
                        """
                    )

                    LegalSection(
                        title: "SECURITY",
                        content: """
                        We implement industry-standard security measures:

                        • Local data encryption via iOS Keychain
                        • Secure HTTPS connections for all API calls
                        • No storage of sensitive financial credentials

                        Cosmo Trader does not have access to your brokerage accounts or execute trades on your behalf.
                        """
                    )

                    LegalSection(
                        title: "CHILDREN'S PRIVACY",
                        content: "Cosmo Trader is not intended for users under 18 years of age. We do not knowingly collect personal information from children."
                    )

                    LegalSection(
                        title: "CHANGES TO POLICY",
                        content: "We may update this Privacy Policy periodically. Continued use of the app after changes constitutes acceptance of the updated policy."
                    )

                    LegalSection(
                        title: "CONTACT",
                        content: """
                        Questions about this Privacy Policy?

                        Email: privacy@cosmotrader.app
                        """
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(CosmicTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
        }
    }
}

// MARK: - NFA Disclaimer View

struct NFADisclaimerView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with warning
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(CosmicTheme.gold)

                        Text("NOT FINANCIAL ADVICE")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text("Please read this disclaimer carefully")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

                    // Main disclaimer
                    LegalSection(
                        title: "DISCLAIMER",
                        content: """
                        COSMO TRADER IS FOR ENTERTAINMENT AND EDUCATIONAL PURPOSES ONLY.

                        The astrological insights, zodiac compatibility scores, cosmic signals, and all other content provided by this application DO NOT constitute financial advice, investment advice, trading advice, or any other sort of professional advice.

                        Nothing in this app should be construed as a recommendation to buy, sell, or hold any security, cryptocurrency, or other financial instrument.
                        """
                    )

                    LegalSection(
                        title: "NO PROFESSIONAL RELATIONSHIP",
                        content: """
                        Use of Cosmo Trader does not create any professional relationship between you and the developers, including but not limited to:

                        • Financial advisor relationship
                        • Investment advisor relationship
                        • Broker-dealer relationship
                        • Any fiduciary relationship

                        We are not registered investment advisors, broker-dealers, or financial planners.
                        """
                    )

                    LegalSection(
                        title: "ASTROLOGICAL CONTENT",
                        content: """
                        The zodiac signs, horoscopes, compatibility scores, moon phases, planetary alignments, and all astrological content in this app are based on traditional astrology and are provided purely for entertainment.

                        There is no scientific evidence that astronomical phenomena influence stock market performance or investment outcomes.

                        ANY INVESTMENT DECISION SHOULD BE BASED ON YOUR OWN RESEARCH AND CONSULTATION WITH QUALIFIED FINANCIAL PROFESSIONALS.
                        """
                    )

                    LegalSection(
                        title: "RISK WARNING",
                        content: """
                        Investing in stocks, securities, and financial instruments involves substantial risk of loss and is not suitable for every investor.

                        • Past performance does not guarantee future results
                        • You could lose some or all of your investment
                        • Stock prices can be volatile and unpredictable
                        • IPO investments carry additional risks

                        Never invest money you cannot afford to lose.
                        """
                    )

                    LegalSection(
                        title: "DATA ACCURACY",
                        content: """
                        While we strive to provide accurate stock market data:

                        • Data may be delayed or inaccurate
                        • We do not guarantee data accuracy or completeness
                        • Always verify information with official sources
                        • Use real-time data from your broker for trading decisions

                        Cosmo Trader is not responsible for any losses resulting from reliance on app data.
                        """
                    )

                    LegalSection(
                        title: "SEEK PROFESSIONAL ADVICE",
                        content: """
                        Before making any investment decision, you should:

                        • Consult with a qualified financial advisor
                        • Conduct your own due diligence
                        • Consider your financial situation and goals
                        • Understand the risks involved
                        • Review official company filings and disclosures
                        """
                    )

                    LegalSection(
                        title: "LIMITATION OF LIABILITY",
                        content: """
                        TO THE MAXIMUM EXTENT PERMITTED BY LAW:

                        Cosmo Trader, its developers, affiliates, and partners shall not be liable for any direct, indirect, incidental, special, consequential, or punitive damages arising from:

                        • Your use of or reliance on any information in the app
                        • Investment decisions made based on app content
                        • Trading losses or missed opportunities
                        • Data inaccuracies or service interruptions
                        """
                    )

                    // Acknowledgment
                    VStack(spacing: 12) {
                        Rectangle()
                            .fill(CosmicTheme.borderDim)
                            .frame(height: 1)

                        Text("By using Cosmo Trader, you acknowledge that you have read, understood, and agree to this disclaimer.")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(CosmicTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)

                        Rectangle()
                            .fill(CosmicTheme.borderDim)
                            .frame(height: 1)
                    }
                    .padding(.top, 16)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(CosmicTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
        }
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    LegalHeaderView(
                        title: "TERMS OF SERVICE",
                        subtitle: "Last updated: December 2024"
                    )

                    LegalSection(
                        title: "ACCEPTANCE OF TERMS",
                        content: "By downloading, installing, or using Cosmo Trader, you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the application."
                    )

                    LegalSection(
                        title: "DESCRIPTION OF SERVICE",
                        content: """
                        Cosmo Trader is a mobile application that combines stock market information with astrological entertainment content. The app provides:

                        • Stock market data display
                        • Portfolio tracking tools
                        • Astrological insights and zodiac compatibility
                        • IPO calendar and information
                        • Entertainment features (Cosmic Roasts, etc.)

                        The app does not execute trades or connect to brokerage accounts.
                        """
                    )

                    LegalSection(
                        title: "USER RESPONSIBILITIES",
                        content: """
                        You agree to:

                        • Provide accurate information when using the app
                        • Not use the app for any unlawful purpose
                        • Not attempt to reverse engineer or modify the app
                        • Not misrepresent app content as financial advice
                        • Comply with all applicable laws and regulations
                        """
                    )

                    LegalSection(
                        title: "SUBSCRIPTIONS",
                        content: """
                        Cosmo Trader offers optional subscription services ("Oracle Tier"):

                        • Subscriptions are billed through Apple App Store
                        • Prices are displayed in the app before purchase
                        • Subscriptions auto-renew unless cancelled
                        • Cancel anytime through App Store settings
                        • Refunds are handled by Apple per their policies
                        """
                    )

                    LegalSection(
                        title: "INTELLECTUAL PROPERTY",
                        content: """
                        All content, features, and functionality of Cosmo Trader, including but not limited to text, graphics, logos, and software, are owned by Cosmo Trader and protected by intellectual property laws.

                        You may not reproduce, distribute, or create derivative works without express written permission.
                        """
                    )

                    LegalSection(
                        title: "DISCLAIMER OF WARRANTIES",
                        content: """
                        THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED.

                        We do not warrant that:
                        • The app will be error-free or uninterrupted
                        • Data will be accurate or complete
                        • The app will meet your requirements
                        • Results will be achieved from using the app
                        """
                    )

                    LegalSection(
                        title: "TERMINATION",
                        content: "We reserve the right to terminate or suspend access to the app at any time, without notice, for conduct that we believe violates these Terms or is harmful to other users or the app."
                    )

                    LegalSection(
                        title: "GOVERNING LAW",
                        content: "These Terms shall be governed by and construed in accordance with the laws of the State of California, United States, without regard to conflict of law provisions."
                    )

                    LegalSection(
                        title: "CONTACT",
                        content: """
                        Questions about these Terms of Service?

                        Email: legal@cosmotrader.app
                        """
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(CosmicTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct LegalHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(CosmicTheme.textPrimary)

            Text(subtitle)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
    }
}

struct LegalSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Rectangle()
                    .fill(CosmicTheme.gold)
                    .frame(width: 3, height: 16)

                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)
            }

            // Content
            Text(content)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "0A0A0A"))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CosmicTheme.borderDim, lineWidth: 1)
                )
        )
    }
}

// MARK: - Quick Disclaimer Banner

struct DisclaimerBanner: View {

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundColor(CosmicTheme.textMuted)

            Text("Not financial advice. For entertainment only.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(CosmicTheme.textMuted)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(hex: "0A0A0A"))
    }
}

// MARK: - About View

struct AboutView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App info header
                    VStack(spacing: 16) {
                        // App icon placeholder
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(CosmicTheme.gold, lineWidth: 2)
                                )

                            Image(systemName: "sparkles")
                                .font(.system(size: 32))
                                .foregroundColor(CosmicTheme.gold)
                        }

                        Text("COSMO TRADER")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text("Version \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(CosmicTheme.textSecondary)

                        Text("Where the stars meet the market")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(CosmicTheme.textMuted)
                            .italic()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

                    // Data Attribution
                    LegalSection(
                        title: "DATA ATTRIBUTION",
                        content: """
                        Stock market data provided by Finnhub.io

                        Finnhub provides real-time market data, company information, and financial metrics used throughout this application.

                        Data may be delayed up to 15 minutes for free tier users.

                        Visit finnhub.io for more information.
                        """
                    )

                    // Entertainment disclaimer
                    LegalSection(
                        title: "ENTERTAINMENT PURPOSE",
                        content: """
                        Cosmo Trader is designed for entertainment and educational purposes only.

                        The astrological content, zodiac compatibility scores, and cosmic insights are based on traditional astrology and should not be used as the basis for any financial decisions.

                        Always consult with qualified financial professionals before making investment decisions.
                        """
                    )

                    // Open source acknowledgments
                    LegalSection(
                        title: "ACKNOWLEDGMENTS",
                        content: """
                        Built with SwiftUI for iOS

                        Special thanks to:
                        • Finnhub.io for market data API
                        • The astrology community for zodiac wisdom
                        • Our beta testers for invaluable feedback

                        Made with cosmic energy in California.
                        """
                    )

                    // Copyright
                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(CosmicTheme.borderDim)
                            .frame(height: 1)

                        Text("© 2024 Somnora. All rights reserved.")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CosmicTheme.textMuted)

                        Text("Cosmo Trader is a trademark of Somnora.")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(CosmicTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(CosmicTheme.gold)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Privacy Policy") {
    PrivacyPolicyView()
        .preferredColorScheme(.dark)
}

#Preview("NFA Disclaimer") {
    NFADisclaimerView()
        .preferredColorScheme(.dark)
}

#Preview("Terms of Service") {
    TermsOfServiceView()
        .preferredColorScheme(.dark)
}

#Preview("Disclaimer Banner") {
    VStack {
        Spacer()
        DisclaimerBanner()
    }
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("About View") {
    AboutView()
        .preferredColorScheme(.dark)
}
