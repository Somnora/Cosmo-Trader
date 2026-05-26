import SwiftUI
import StoreKit

// MARK: - Paywall View
// ====================
// Full-screen Oracle Tier upgrade experience.
// Terminal aesthetic with persuasive but not aggressive messaging.
// Philosophy: Show the value, let them decide.

struct PaywallView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showTerms = false
    @State private var showPrivacy = false

    private let subscriptionManager = SubscriptionManager.shared
    private let storeKitManager = StoreKitManager.shared

    // MARK: - Pricing Helpers

    private var selectedProduct: Product? {
        switch selectedPlan {
        case .monthly:
            return storeKitManager.monthlyProduct
        case .yearly:
            return storeKitManager.yearlyProduct
        case .lifetime:
            return storeKitManager.lifetimeProduct
        }
    }

    private var selectedSubscriptionHasIntroOffer: Bool {
        guard selectedPlan != .lifetime,
              let product = selectedProduct,
              let subscription = product.subscription else {
            return false
        }
        return subscription.introductoryOffer != nil
    }

    private var purchaseButtonTitle: String {
        if selectedPlan == .lifetime { return "UNLOCK LIFETIME" }
        return selectedSubscriptionHasIntroOffer ? "START FREE TRIAL" : "SUBSCRIBE"
    }

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

                    // Premium positioning quote
                    JPMorganQuoteView(size: .compact)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)

                    // Plans
                    plansSection
                        .padding(.top, 24)

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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .task {
            // Load products when view appears
            if storeKitManager.products.isEmpty {
                await storeKitManager.loadProducts()
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

                Text("The full curated reading - without limits")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Divider
            HStack(spacing: 8) {
                Rectangle()
                    .fill(CosmicTheme.gold.opacity(0.3))
                    .frame(height: 0.5)
                Text("★")
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
                let benefits = OracleTierBenefits.all
                ForEach(Array(benefits.enumerated()), id: \.element.id) { index, benefit in
                    benefitRow(benefit, isLast: index == benefits.count - 1)
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

            // Plan options - show real prices from StoreKit or fallback
            VStack(spacing: 12) {
                if let yearly = storeKitManager.yearlyProduct {
                    let savingsText = storeKitManager.yearlySavingsPercentage().map { "SAVE \($0)%" }
                    planOption(
                        plan: .yearly,
                        title: "YEARLY",
                        price: yearly.displayPrice,
                        period: "/year",
                        savings: savingsText
                    )
                } else {
                    planOption(
                        plan: .yearly,
                        title: "YEARLY",
                        price: SubscriptionManager.oracleTierYearlyPrice,
                        period: "/year",
                        savings: "SAVE 33%"
                    )
                }

                // Lifetime plan option
                if let lifetime = storeKitManager.lifetimeProduct {
                    planOption(
                        plan: .lifetime,
                        title: "LIFETIME",
                        price: lifetime.displayPrice,
                        period: "once",
                        savings: "BEST VALUE"
                    )
                } else {
                    planOption(
                        plan: .lifetime,
                        title: "LIFETIME",
                        price: SubscriptionManager.oracleTierLifetimePrice,
                        period: "once",
                        savings: "BEST VALUE"
                    )
                }

                if let monthly = storeKitManager.monthlyProduct {
                    planOption(
                        plan: .monthly,
                        title: "MONTHLY",
                        price: monthly.displayPrice,
                        period: "/month",
                        savings: nil
                    )
                } else {
                    planOption(
                        plan: .monthly,
                        title: "MONTHLY",
                        price: SubscriptionManager.oracleTierPrice,
                        period: "/month",
                        savings: nil
                    )
                }
            }

            // Loading indicator
            if storeKitManager.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: CosmicTheme.textSecondary))
                        .scaleEffect(0.7)
                    Text("Loading prices...")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
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
                        Text(purchaseButtonTitle)
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
            .disabled(isProcessing || selectedProduct == nil)

            // Restore purchases + manage subscription
            HStack(spacing: 16) {
                Button {
                    restorePurchases()
                } label: {
                    Text("Restore Purchases")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
                .buttonStyle(.plain)

                Text("·")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CosmicTheme.borderDim)

                Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                    Text("Manage Subscription")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 12) {
            // Legal links
            HStack(spacing: 16) {
                Button {
                    showTerms = true
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
                    showPrivacy = true
                } label: {
                    Text("Privacy")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            // Disclaimer
            Text(footerDisclaimerText)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(CosmicTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 16)
        }
    }

    private var footerDisclaimerText: String {
        if selectedPlan == .lifetime {
            return "Payment will be charged to your Apple ID account. This is a one-time purchase and does not auto-renew."
        }

        let renewalText = "Payment will be charged to your Apple ID account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period."
        if selectedSubscriptionHasIntroOffer {
            return "\(renewalText) Introductory offer availability is determined by Apple and may vary by account."
        }
        return renewalText
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            AnalyticsService.shared.trackPaywallDismissed(source: "close_button")
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

    // MARK: - Actions

    private func processSubscription() {
        isProcessing = true

        Task {
            do {
                // Get the selected product
                guard let selectedProduct else {
                    await MainActor.run {
                        isProcessing = false
                        errorMessage = "Product not available. Please try again."
                        showError = true
                    }
                    return
                }

                // Perform the purchase
                try await subscriptionManager.purchase(product: selectedProduct)

                await MainActor.run {
                    isProcessing = false

                    // Track subscription started
                    AnalyticsService.shared.trackSubscriptionStarted(
                        tier: "oracle",
                        source: "paywall",
                        trialEnabled: selectedSubscriptionHasIntroOffer
                    )

                    dismiss()
                }
            } catch let error as StoreKitError {
                await MainActor.run {
                    isProcessing = false

                    // Don't show error for user cancellation
                    if !error.isUserCancellation {
                        if error.isPending {
                            errorMessage = "Your purchase is pending approval. You'll get access once approved."
                        } else {
                            errorMessage = error.errorDescription ?? "Purchase failed. Please try again."
                        }
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "An unexpected error occurred. Please try again."
                    showError = true
                }
            }
        }
    }

    private func restorePurchases() {
        isProcessing = true

        Task {
            let restored = await subscriptionManager.restorePurchases()
            await MainActor.run {
                isProcessing = false
                if restored {
                    // Track restore
                    AnalyticsService.shared.trackSubscriptionRestored()
                    dismiss()
                } else {
                    // No purchases restored or restore error
                    if let error = subscriptionManager.purchaseError {
                        errorMessage = error.errorDescription ?? "Restore failed. Please try again."
                    } else {
                        errorMessage = "No previous purchases found to restore."
                    }
                    showError = true
                }
            }
        }
    }
}

// MARK: - Paywall Plan

enum PaywallPlan {
    case monthly
    case yearly
    case lifetime
}

// MARK: - Compact Paywall

struct CompactPaywallView: View {

    var onDismiss: (() -> Void)?
    var onUpgrade: (() -> Void)?

    private let storeKitManager = StoreKitManager.shared

    /// Display price - uses StoreKit product if available, falls back to constant
    private var displayPrice: String {
        storeKitManager.monthlyProduct?.displayPrice ?? SubscriptionManager.oracleTierPrice
    }

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
                quickBenefit("Unlimited Discover swipes")
                quickBenefit("Refresh your reading anytime")
                quickBenefit("Track more portfolio holdings")
                quickBenefit("Generate more Cosmic Roasts")
                quickBenefit("Moon-in-sign local alert")
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
            VStack(spacing: 6) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(displayPrice)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(CosmicTheme.gold)
                }

                // Optionally show "Lifetime available"
                if storeKitManager.lifetimeProduct != nil {
                    Text("Lifetime available")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(CosmicTheme.textSecondary)
                }
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
        .task {
            // Ensure products are loaded
            if storeKitManager.products.isEmpty {
                await storeKitManager.loadProducts()
            }
        }
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
