import SwiftUI

// MARK: - Paywall View
// ====================
// Full-screen Oracle Tier upgrade experience.
// Terminal aesthetic with persuasive but not aggressive messaging.
// Philosophy: Show the value, let them decide.

struct PaywallView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPlan = .monthly
    @State private var isProcessing = false
    @State private var showTrialStarted = false

    private let subscriptionManager = SubscriptionManager.shared

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            CosmicTheme.terminalBlack
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    paywallHeader
                        .padding(.top, 20)

                    // Benefits
                    benefitsSection
                        .padding(.top, 32)

                    // Plans
                    plansSection
                        .padding(.top, 32)

                    // Action
                    actionSection
                        .padding(.top, 32)

                    // Footer
                    footerSection
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    closeButton
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                }
                Spacer()
            }
        }
        .overlay {
            if showTrialStarted {
                trialStartedOverlay
            }
        }
    }

    // MARK: - Header

    private var paywallHeader: some View {
        VStack(spacing: 16) {
            // Oracle symbol
            ZStack {
                Circle()
                    .strokeBorder(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                    .frame(width: 80, height: 80)

                Circle()
                    .strokeBorder(CosmicTheme.gold.opacity(0.2), lineWidth: 0.5)
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(CosmicTheme.gold)
            }

            // Title
            VStack(spacing: 8) {
                Text("ORACLE TIER")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(4)

                Text("Unlock the full cosmic experience")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Divider
            HStack(spacing: 8) {
                Rectangle()
                    .fill(CosmicTheme.gold.opacity(0.3))
                    .frame(height: 0.5)
                Text("*")
                    .font(.system(size: 10))
                    .foregroundColor(CosmicTheme.gold.opacity(0.5))
                Rectangle()
                    .fill(CosmicTheme.gold.opacity(0.3))
                    .frame(height: 0.5)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("[ FEATURES ]")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .tracking(2)
                Spacer()
            }

            // Benefits grid
            VStack(spacing: 0) {
                ForEach(Array(OracleTierBenefits.all.prefix(6).enumerated()), id: \.element.id) { index, benefit in
                    benefitRow(benefit, isLast: index == 5)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(CosmicTheme.borderDim, lineWidth: 0.5)
            )
        }
    }

    private func benefitRow(_ benefit: OracleBenefit, isLast: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: benefit.feature.icon)
                .font(.system(size: 14))
                .foregroundColor(CosmicTheme.gold)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(benefit.title)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(benefit.description)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("+")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(CosmicTheme.gold.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CosmicTheme.cardBackground)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(CosmicTheme.borderDim)
                    .frame(height: 0.5)
            }
        }
    }

    // MARK: - Plans Section

    private var plansSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("[ SELECT PLAN ]")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.textSecondary)
                    .tracking(2)
                Spacer()
            }

            // Plan options
            VStack(spacing: 12) {
                planOption(
                    plan: .yearly,
                    title: "YEARLY",
                    price: "$39.99",
                    period: "/year",
                    savings: "SAVE 33%"
                )

                planOption(
                    plan: .monthly,
                    title: "MONTHLY",
                    price: "$4.99",
                    period: "/month",
                    savings: nil
                )
            }
        }
    }

    private func planOption(
        plan: PaywallPlan,
        title: String,
        price: String,
        period: String,
        savings: String?
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPlan = plan
            }
        } label: {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            selectedPlan == plan ? CosmicTheme.gold : CosmicTheme.borderDim,
                            lineWidth: 1
                        )
                        .frame(width: 20, height: 20)

                    if selectedPlan == plan {
                        Circle()
                            .fill(CosmicTheme.gold)
                            .frame(width: 10, height: 10)
                    }
                }

                // Plan info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(CosmicTheme.textPrimary)

                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(CosmicTheme.terminalBlack)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(CosmicTheme.gold)
                                )
                        }
                    }
                }

                Spacer()

                // Price
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(selectedPlan == plan ? CosmicTheme.gold : CosmicTheme.textPrimary)

                    Text(period)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(selectedPlan == plan ? CosmicTheme.gold.opacity(0.08) : CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(
                                selectedPlan == plan ? CosmicTheme.gold : CosmicTheme.borderDim,
                                lineWidth: selectedPlan == plan ? 1 : 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 16) {
            // Subscribe button
            Button {
                processSubscription()
            } label: {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: CosmicTheme.terminalBlack))
                            .scaleEffect(0.8)
                    } else {
                        Text("SUBSCRIBE")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .tracking(2)
                    }
                }
                .foregroundColor(CosmicTheme.terminalBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(CosmicTheme.gold)
                )
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)

            // Trial button (if not used)
            if !subscriptionManager.hasUsedTrial() {
                Button {
                    startTrial()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "gift")
                            .font(.system(size: 12))
                        Text("Start \(SubscriptionManager.trialDuration)-Day Free Trial")
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .foregroundColor(CosmicTheme.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(CosmicTheme.gold.opacity(0.5), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }

            // Restore purchases
            Button {
                restorePurchases()
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CosmicTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 12) {
            // Legal links
            HStack(spacing: 16) {
                Button {
                    // Open terms
                } label: {
                    Text("Terms")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
                .buttonStyle(.plain)

                Text("|")
                    .font(.system(size: 10))
                    .foregroundColor(CosmicTheme.borderDim)

                Button {
                    // Open privacy
                } label: {
                    Text("Privacy")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            // Disclaimer
            Text("Payment will be charged to your Apple ID account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(CosmicTheme.textSecondary)
                .padding(10)
                .background(
                    Circle()
                        .fill(CosmicTheme.cardBackground)
                        .overlay(
                            Circle()
                                .strokeBorder(CosmicTheme.borderDim, lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trial Started Overlay

    private var trialStartedOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(CosmicTheme.gold)

                VStack(spacing: 8) {
                    Text("TRIAL ACTIVATED")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(CosmicTheme.gold)
                        .tracking(2)

                    Text("\(SubscriptionManager.trialDuration) days of Oracle Tier access")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                Button {
                    dismiss()
                } label: {
                    Text("LET'S GO")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(CosmicTheme.terminalBlack)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(CosmicTheme.gold)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func processSubscription() {
        isProcessing = true

        // TODO: Integrate StoreKit
        // For now, simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            subscriptionManager.upgradeToOracle()
            isProcessing = false
            dismiss()
        }
    }

    private func startTrial() {
        subscriptionManager.startFreeTrial()
        withAnimation {
            showTrialStarted = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }

    private func restorePurchases() {
        isProcessing = true

        Task {
            let restored = await subscriptionManager.restorePurchases()
            await MainActor.run {
                isProcessing = false
                if restored {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Paywall Plan

enum PaywallPlan {
    case monthly
    case yearly
}

// MARK: - Compact Paywall

struct CompactPaywallView: View {

    var onDismiss: (() -> Void)?
    var onUpgrade: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(CosmicTheme.gold)

                Text("ORACLE TIER")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)
                    .tracking(2)
            }

            // Quick benefits
            VStack(alignment: .leading, spacing: 8) {
                quickBenefit("Real-time market data")
                quickBenefit("Unlimited swipes & stocks")
                quickBenefit("Advanced horoscopes")
                quickBenefit("Lunar phase alerts")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(
                        CosmicTheme.borderDim,
                        style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                    )
            )

            // Price
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(SubscriptionManager.oracleTierPrice)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)
            }

            // Actions
            VStack(spacing: 12) {
                Button {
                    onUpgrade?()
                } label: {
                    Text("UPGRADE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(2)
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
                    onDismiss?()
                } label: {
                    Text("Maybe later")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(CosmicTheme.terminalBlack)
    }

    private func quickBenefit(_ text: String) -> some View {
        HStack(spacing: 8) {
            Text("+")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CosmicTheme.gold)

            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(CosmicTheme.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview("Paywall") {
    PaywallView()
}

#Preview("Compact Paywall") {
    ZStack {
        CosmicTheme.terminalBlack
            .ignoresSafeArea()

        CompactPaywallView()
            .padding()
    }
}
