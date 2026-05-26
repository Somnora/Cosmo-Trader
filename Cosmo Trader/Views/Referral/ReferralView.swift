import SwiftUI

// MARK: - Referral View
// ======================
// Main referral hub showing user's code, stats, and share options.

struct ReferralView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var referralService = ReferralService.shared
    @State private var showingShareSheet = false
    @State private var copiedCode = false
    @State private var showRewardAlert = false
    @State private var rewardAlertMessage = "Rewards redeemed."
    @State private var redeemError: String?
    @State private var isRedeeming = false
    @State private var showingLeaderboard = false
    private let apiClient = CosmoAPIClient()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Your Referral Code
                    referralCodeCard

                    // Stats
                    statsSection

                    // Rewards
                    rewardsSection

                    // Share Button
                    shareButton

                    // Leaderboard Preview
                    leaderboardPreview

                    // How It Works
                    howItWorksSection
                }
                .padding()
            }
            .background(CosmicTheme.background)
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(text: referralService.generateShareText())
            }
            .sheet(isPresented: $showingLeaderboard) {
                LegacyReferralLeaderboardView()
            }
            .alert("Rewards Claimed!", isPresented: $showRewardAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(rewardAlertMessage)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(CosmicTheme.gold.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 32))
                    .foregroundColor(CosmicTheme.gold)
            }

            Text("Spread the Cosmic Word")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)

            Text("Invite friends and both get free Oracle Tier")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Referral Code Card

    private var referralCodeCard: some View {
        VStack(spacing: 16) {
            Text("YOUR REFERRAL CODE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(CosmicTheme.textMuted)
                .tracking(2)

            // Code display
            HStack(spacing: 12) {
                Text(referralService.myReferralCode)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(CosmicTheme.gold)

                Button(action: copyCode) {
                    Image(systemName: copiedCode ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.title3)
                        .foregroundColor(copiedCode ? .green : CosmicTheme.gold)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1A1A1A"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.gold.opacity(0.5), lineWidth: 2)
                    )
            )

            if copiedCode {
                Text("Copied!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: copiedCode)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(
                icon: "person.badge.plus",
                value: "\(referralService.referralCount)",
                label: "Referrals"
            )

            Divider()
                .frame(height: 50)
                .background(CosmicTheme.borderDim)

            statItem(
                icon: "gift.fill",
                value: "\(referralService.earnedRewardDays)",
                label: "Days Earned"
            )

            Divider()
                .frame(height: 50)
                .background(CosmicTheme.borderDim)

            statItem(
                icon: "clock.fill",
                value: "\(referralService.availableRewardDays)",
                label: "Available"
            )
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(CosmicTheme.gold)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CosmicTheme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rewards Section

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(CosmicTheme.gold)
                Text("Referral Rewards")
                    .font(.headline)
                    .foregroundColor(CosmicTheme.textPrimary)
            }

            // Reward tiers
            VStack(spacing: 12) {
                rewardTier(
                    referrals: 1,
                    reward: "1 week Oracle Tier",
                    achieved: referralService.referralCount >= 1
                )
                rewardTier(
                    referrals: 5,
                    reward: "1 month Oracle Tier",
                    achieved: referralService.referralCount >= 5
                )
                rewardTier(
                    referrals: 12,
                    reward: "3 months Oracle Tier",
                    achieved: referralService.referralCount >= 12
                )
                rewardTier(
                    referrals: 52,
                    reward: "1 year Oracle Tier",
                    achieved: referralService.referralCount >= 52,
                    isUltimate: true
                )
            }

            // Claim button if rewards available
            if referralService.hasPendingRewards {
                VStack(spacing: 8) {
                    Button(action: claimRewards) {
                        HStack {
                            if isRedeeming {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "gift.fill")
                            }
                            Text("Claim \(referralService.availableRewardDays) Days")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(CosmicTheme.gold)
                        .cornerRadius(12)
                    }
                    .disabled(isRedeeming)

                    if let redeemError {
                        Text(redeemError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func rewardTier(referrals: Int, reward: String, achieved: Bool, isUltimate: Bool = false) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(achieved ? CosmicTheme.gold : CosmicTheme.borderDim)
                    .frame(width: 32, height: 32)

                if achieved {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                } else {
                    Text("\(referrals)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(referrals) referral\(referrals == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(achieved ? CosmicTheme.textPrimary : CosmicTheme.textMuted)

                Text(reward)
                    .font(.caption)
                    .foregroundColor(achieved ? CosmicTheme.gold : CosmicTheme.textMuted)
            }

            Spacer()

            if isUltimate {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(CosmicTheme.gold)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button(action: { showingShareSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Invite Friends")
                        .font(.headline)
                    Text("Share your code via text, social, or email")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .foregroundColor(CosmicTheme.textPrimary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.gold.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Leaderboard Preview
    private var leaderboardPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(CosmicTheme.gold)
                Text("Top Cosmic Recruiters")
                    .font(.headline)
                    .foregroundColor(CosmicTheme.textPrimary)

                Spacer()

                Button("See All") {
                    showingLeaderboard = true
                }
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)
            }

            if referralService.isLeaderboardLoading {
                HStack {
                    ProgressView()
                        .tint(CosmicTheme.gold)
                    Text("Loading leaderboard…")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            } else if let error = referralService.leaderboardError {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Couldn't load leaderboard.")
                        .font(.caption)
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task { await referralService.loadLeaderboard(limit: 50) }
                    }
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
                }
            } else if referralService.leaderboardEntries.isEmpty {
                Text("No leaderboard data yet.")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            } else {
                ForEach(referralService.leaderboardEntries.prefix(3)) { entry in
                    HStack(spacing: 12) {
                        Text(entry.badge)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.anonymizedName)
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.textPrimary)

                            HStack(spacing: 4) {
                                Text(entry.zodiacSign.symbol)
                                Text("\(entry.referralCount) referrals")
                                    .font(.caption)
                                    .foregroundColor(CosmicTheme.textMuted)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
        .task {
            if referralService.leaderboardEntries.isEmpty && referralService.leaderboardError == nil {
                await referralService.loadLeaderboard(limit: 50)
            }
        }
    }

    // MARK: - How It Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.headline)
                .foregroundColor(CosmicTheme.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                howItWorksStep(
                    number: 1,
                    title: "Share your code",
                    description: "Send your unique code to friends"
                )
                howItWorksStep(
                    number: 2,
                    title: "They sign up",
                    description: "Friend enters your code during onboarding"
                )
                howItWorksStep(
                    number: 3,
                    title: "Both get rewarded",
                    description: "You both get 7 days of Oracle Tier free"
                )
            }

            Text("Rewards stack up to 1 year. Keep inviting!")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)
                .italic()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func howItWorksStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(CosmicTheme.gold.opacity(0.2))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
    }

    // MARK: - Actions

    private func copyCode() {
        UIPasteboard.general.string = referralService.myReferralCode
        withAnimation {
            copiedCode = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedCode = false
            }
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func claimRewards() {
        let days = referralService.availableRewardDays
        redeemError = nil
        isRedeeming = true
        Task {
            let result = await referralService.redeemRewardDays(days)
            isRedeeming = false
            if result.isSuccess {
                await refreshRewardsStatusSummary(daysClaimed: days)
                NotificationCenter.default.post(name: .rewardsStatusUpdated, object: nil)
                showRewardAlert = true

                // Haptic feedback for success
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } else {
                redeemError = result.message
            }
        }
    }

    private func refreshRewardsStatusSummary(daysClaimed: Int) async {
        do {
            let status = try await apiClient.fetchRewardsStatus()
            if let premiumUntil = status.premiumUntil, !premiumUntil.isEmpty {
                rewardAlertMessage = "Redeemed \(daysClaimed) days. Premium is active until \(premiumUntil)."
            } else {
                rewardAlertMessage = "Redeemed \(daysClaimed) days. Credits balance is now \(status.creditsBalance)."
            }
        } catch {
            rewardAlertMessage = "Redeemed \(daysClaimed) days. Rewards status will refresh shortly."
        }
    }
}

// MARK: - Referral Leaderboard View

struct LegacyReferralLeaderboardView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var referralService = ReferralService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 48))
                            .foregroundColor(CosmicTheme.gold)

                        Text("Top Cosmic Recruiters")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text("The most stellar referrers in the cosmos")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    .padding(.vertical)

                    // Leaderboard
                    if referralService.isLeaderboardLoading {
                        ProgressView()
                            .tint(CosmicTheme.gold)
                            .padding(.top, 20)
                    } else if let error = referralService.leaderboardError {
                        VStack(spacing: 8) {
                            Text("Couldn't load leaderboard.")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textMuted)
                            Button("Retry") {
                                Task { await referralService.loadLeaderboard(limit: 50) }
                            }
                            .font(.caption)
                            .foregroundColor(CosmicTheme.gold)
                        }
                        .padding(.top, 12)
                    } else if referralService.leaderboardEntries.isEmpty {
                        Text("No leaderboard data yet.")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                            .padding(.top, 12)
                    } else {
                        ForEach(referralService.leaderboardEntries) { entry in
                            leaderboardRow(entry)
                        }
                    }
                }
                .padding()
            }
            .background(CosmicTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CosmicTheme.gold)
                }
            }
            .task {
                if referralService.leaderboardEntries.isEmpty && referralService.leaderboardError == nil {
                    await referralService.loadLeaderboard(limit: 50)
                }
            }
        }
    }

    private func leaderboardRow(_ entry: ReferralLeaderboard.LeaderboardEntry) -> some View {
        HStack(spacing: 16) {
            // Rank
            Text(entry.badge)
                .font(.title)
                .frame(width: 40)

            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.anonymizedName)
                    .font(.headline)
                    .foregroundColor(CosmicTheme.textPrimary)

                HStack(spacing: 8) {
                    ZodiacMark(sign: entry.zodiacSign, size: .tiny, style: .element)
                    Text(entry.zodiacSign.displayName)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            Spacer()

            // Count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.referralCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.gold)

                Text("referrals")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(entry.rank <= 3 ?
                      CosmicTheme.gold.opacity(0.1) :
                      CosmicTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(entry.rank <= 3 ?
                                CosmicTheme.gold.opacity(0.3) :
                                Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Referral Code Input View (For Onboarding)

struct ReferralCodeInputView: View {

    @Binding var referralCode: String
    @State private var result: ReferralResult?
    @State private var isValidating = false

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "ticket.fill")
                .font(.system(size: 48))
                .foregroundColor(CosmicTheme.gold)

            // Title
            VStack(spacing: 8) {
                Text("Have a Referral Code?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text("Enter it below for 7 days of free Oracle Tier")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textMuted)
                    .multilineTextAlignment(.center)
            }

            // Input
            VStack(spacing: 8) {
                TextField("Enter code (e.g., CT-ABC123)", text: $referralCode)
                    .font(.system(size: 18, design: .monospaced))
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "1A1A1A"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(resultBorderColor, lineWidth: 2)
                            )
                    )
                    .autocorrectionDisabled()

                // Result message
                if let result = result {
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(result.isSuccess ? .green : .red)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: result?.message)

            // Buttons
            VStack(spacing: 12) {
                Button(action: applyCode) {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Apply Code")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        referralCode.isEmpty ?
                        CosmicTheme.gold.opacity(0.5) :
                        CosmicTheme.gold
                    )
                    .cornerRadius(12)
                }
                .disabled(referralCode.isEmpty || isValidating)

                Button("Skip for Now") {
                    onComplete()
                }
                .font(.subheadline)
                .foregroundColor(CosmicTheme.textMuted)
            }
        }
        .padding()
    }

    private var resultBorderColor: Color {
        guard let result = result else {
            return CosmicTheme.borderDim
        }
        return result.isSuccess ? .green : .red
    }

    private func applyCode() {
        isValidating = true
        Task {
            let applyResult = await ReferralService.shared.applyReferralCode(referralCode)
            result = applyResult
            isValidating = false

            if applyResult.isSuccess {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Compact Referral Card (For ProfileView)

struct ReferralCard: View {

    @State private var showingReferralView = false
    private let referralService = ReferralService.shared

    var body: some View {
        Button(action: { showingReferralView = true }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(CosmicTheme.gold.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundColor(CosmicTheme.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Invite Friends")
                        .font(.headline)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(referralService.referralCountText)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Earn 7 days")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.gold)
                    Text("per referral")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.gold.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingReferralView) {
            ReferralView()
        }
    }
}

// MARK: - Previews

#Preview("Referral View") {
    ReferralView()
        .preferredColorScheme(.dark)
}

#Preview("Leaderboard") {
    LegacyReferralLeaderboardView()
        .preferredColorScheme(.dark)
}

#Preview("Referral Card") {
    VStack {
        ReferralCard()
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Code Input") {
    ReferralCodeInputView(
        referralCode: .constant(""),
        onComplete: {}
    )
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}
