import SwiftUI

// MARK: - Feature Gate
// ====================
// Wraps premium features with graceful upgrade prompts.
// Philosophy: Informative, not aggressive. Show value, don't block.

struct FeatureGate<Content: View>: View {

    // MARK: - Properties

    let feature: PremiumFeature
    let content: Content
    var showLockIndicator: Bool = true
    var onUpgradeTapped: (() -> Void)?

    @State private var showUpgradePrompt = false

    private let subscriptionManager = SubscriptionManager.shared

    // MARK: - Init

    init(
        feature: PremiumFeature,
        showLockIndicator: Bool = true,
        onUpgradeTapped: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.feature = feature
        self.showLockIndicator = showLockIndicator
        self.onUpgradeTapped = onUpgradeTapped
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        if subscriptionManager.canAccess(feature) {
            content
        } else {
            lockedContent
        }
    }

    // MARK: - Locked Content

    private var lockedContent: some View {
        Button {
            showUpgradePrompt = true
        } label: {
            ZStack {
                content
                    .opacity(0.4)
                    .blur(radius: 1)

                if showLockIndicator {
                    lockOverlay
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showUpgradePrompt) {
            FeatureUpgradeSheet(
                feature: feature,
                onUpgrade: {
                    showUpgradePrompt = false
                    onUpgradeTapped?()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var lockOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(CosmicTheme.gold)

            Text("ORACLE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(CosmicTheme.gold)
                .tracking(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.terminalBlack.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(CosmicTheme.gold.opacity(0.5), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Feature Upgrade Sheet

struct FeatureUpgradeSheet: View {

    let feature: PremiumFeature
    var onUpgrade: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CosmicTheme.terminalBlack
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.top, 24)

                Spacer()

                // Feature info
                featureInfo
                    .padding(.horizontal, 24)

                Spacer()

                // Benefits preview
                benefitsPreview
                    .padding(.horizontal, 24)

                Spacer()

                // Actions
                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("[")
                    .foregroundColor(CosmicTheme.textSecondary)
                Text("ORACLE TIER")
                    .foregroundColor(CosmicTheme.gold)
                Text("]")
                    .foregroundColor(CosmicTheme.textSecondary)
            }
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .tracking(2)

            Rectangle()
                .fill(CosmicTheme.gold.opacity(0.3))
                .frame(width: 60, height: 1)
        }
    }

    // MARK: - Feature Info

    private var featureInfo: some View {
        VStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(CosmicTheme.gold)

            Text(feature.rawValue)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(CosmicTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(feature.upgradeMessage)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Benefits Preview

    private var benefitsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ORACLE INCLUDES:")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)
                .tracking(1)

            VStack(alignment: .leading, spacing: 6) {
                benefitRow("Real-time market data")
                benefitRow("Unlimited Discovery swipes")
                benefitRow("Advanced horoscopes")
                benefitRow("Lunar phase alerts")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.terminalBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            CosmicTheme.borderDim,
                            style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                        )
                )
        )
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Text("+")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CosmicTheme.gold)

            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(CosmicTheme.textPrimary)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onUpgrade?()
            } label: {
                HStack {
                    Text("UPGRADE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(2)
                    Text("·")
                        .foregroundColor(CosmicTheme.gold.opacity(0.5))
                    Text(SubscriptionManager.oracleTierPrice)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundColor(CosmicTheme.terminalBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(CosmicTheme.gold)
                )
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
            } label: {
                Text("Maybe later")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Oracle Badge

struct OracleBadge: View {

    enum Style {
        case compact
        case standard
        case inline
    }

    var style: Style = .compact

    var body: some View {
        switch style {
        case .compact:
            compactBadge
        case .standard:
            standardBadge
        case .inline:
            inlineBadge
        }
    }

    private var compactBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 8))
            Text("ORACLE")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .tracking(1)
        }
        .foregroundColor(CosmicTheme.gold)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(CosmicTheme.gold.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(CosmicTheme.gold.opacity(0.4), lineWidth: 0.5)
                )
        )
    }

    private var standardBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
            Text("ORACLE TIER")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2)
        }
        .foregroundColor(CosmicTheme.gold)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.gold.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(CosmicTheme.gold.opacity(0.5), lineWidth: 0.5)
                )
        )
    }

    private var inlineBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "sparkles")
                .font(.system(size: 10))
            Text("PRO")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .foregroundColor(CosmicTheme.gold)
    }
}

// MARK: - Premium Lock Icon

struct PremiumLockIcon: View {

    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .fill(CosmicTheme.gold.opacity(0.15))
                .frame(width: size, height: size)

            Image(systemName: "sparkles")
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundColor(CosmicTheme.gold)
        }
    }
}

// MARK: - Feature Locked Banner

struct FeatureLockedBanner: View {

    let feature: PremiumFeature
    var onUpgradeTapped: (() -> Void)?

    @State private var showUpgradeSheet = false

    var body: some View {
        Button {
            showUpgradeSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: feature.icon)
                    .font(.system(size: 16))
                    .foregroundColor(CosmicTheme.gold)

                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.upgradeMessage)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CosmicTheme.textPrimary)
                        .lineLimit(1)

                    Text("Tap to learn more")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(CosmicTheme.gold.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(CosmicTheme.gold.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showUpgradeSheet) {
            FeatureUpgradeSheet(
                feature: feature,
                onUpgrade: {
                    showUpgradeSheet = false
                    onUpgradeTapped?()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Swipe Limit Banner

struct SwipeLimitBanner: View {

    let swipesRemaining: Int
    let swipeLimit: Int
    var onUpgradeTapped: (() -> Void)?

    @State private var showUpgradeSheet = false

    var body: some View {
        Button {
            showUpgradeSheet = true
        } label: {
            HStack(spacing: 12) {
                // Swipe counter
                HStack(spacing: 4) {
                    Text("\(swipesRemaining)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(swipesRemaining > 0 ? CosmicTheme.gold : CosmicTheme.alertRed)

                    Text("/\(swipeLimit)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily swipes")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(swipesRemaining > 0 ? "Resets at midnight" : "Limit reached")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                Spacer()

                if swipesRemaining == 0 {
                    Text("UPGRADE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(CosmicTheme.terminalBlack)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(CosmicTheme.gold)
                        )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(
                                swipesRemaining > 0 ? CosmicTheme.borderDim : CosmicTheme.gold.opacity(0.5),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showUpgradeSheet) {
            FeatureUpgradeSheet(
                feature: .unlimitedSwipes,
                onUpgrade: {
                    showUpgradeSheet = false
                    onUpgradeTapped?()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Trial Banner

struct TrialBanner: View {

    let daysRemaining: Int
    var onUpgradeTapped: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 16))
                .foregroundColor(CosmicTheme.gold)

            VStack(alignment: .leading, spacing: 2) {
                Text("Oracle Trial Active")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("\(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)
            }

            Spacer()

            Button {
                onUpgradeTapped?()
            } label: {
                Text("SUBSCRIBE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(CosmicTheme.terminalBlack)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(CosmicTheme.gold)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.gold.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(CosmicTheme.gold.opacity(0.4), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Subscription Upgrade Card

struct SubscriptionUpgradeCard: View {

    @State private var showPaywall = false

    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(CosmicTheme.gold.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(CosmicTheme.gold)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Tier")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("Upgrade to Oracle for full access")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                Spacer()

                // Upgrade button
                Text("UPGRADE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(CosmicTheme.terminalBlack)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(CosmicTheme.gold)
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.borderDim, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Compact Upgrade Prompt

struct CompactUpgradePrompt: View {

    let message: String
    var onUpgrade: (() -> Void)?

    @State private var showPaywall = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundColor(CosmicTheme.gold)

            Text(message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary)

            Spacer()

            Button {
                showPaywall = true
                onUpgrade?()
            } label: {
                Text("UPGRADE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(CosmicTheme.gold)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CosmicTheme.gold.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(CosmicTheme.gold.opacity(0.2), lineWidth: 0.5)
                )
        )
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Preview

#Preview("Feature Gate - Locked") {
    ZStack {
        CosmicTheme.terminalBlack
            .ignoresSafeArea()

        VStack(spacing: 24) {
            FeatureGate(feature: .realTimeData) {
                VStack {
                    Text("REAL-TIME DATA")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                    Text("$145.23")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                }
                .foregroundColor(CosmicTheme.textPrimary)
                .padding(24)
                .background(CosmicTheme.cardBackground)
            }

            FeatureLockedBanner(feature: .unlimitedSwipes)

            SwipeLimitBanner(swipesRemaining: 2, swipeLimit: 5)

            SwipeLimitBanner(swipesRemaining: 0, swipeLimit: 5)

            TrialBanner(daysRemaining: 5)

            HStack(spacing: 16) {
                OracleBadge(style: .compact)
                OracleBadge(style: .standard)
                OracleBadge(style: .inline)
            }
        }
        .padding()
    }
}

#Preview("Upgrade Sheet") {
    FeatureUpgradeSheet(feature: .realTimeData)
}
