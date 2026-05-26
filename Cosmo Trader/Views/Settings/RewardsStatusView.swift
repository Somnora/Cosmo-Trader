import SwiftUI

struct RewardsStatusView: View {
    private let client = CosmoAPIClient()

    @State private var rewardsStatus: RewardsStatusResponse?
    @State private var lastUpdatedAt: Date?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let errorMessage {
                    statusMessageCard(errorMessage, color: CosmicTheme.negative)
                }

                if let successMessage {
                    statusMessageCard(successMessage, color: CosmicTheme.positive)
                }

                if let lastUpdatedAt {
                    Text("Last updated \(lastUpdatedLabel(lastUpdatedAt))")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                creditsCard
                premiumCard
                referralCTASection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(CosmicTheme.background.ignoresSafeArea())
        .navigationTitle("Rewards")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isLoading && rewardsStatus == nil {
                ProgressView()
                    .tint(CosmicTheme.gold)
            }
        }
        .refreshable {
            await loadRewards(showSuccess: false)
        }
        .task {
            if rewardsStatus == nil {
                if let cached = RewardsStatusCache.load() {
                    rewardsStatus = cached.status
                    lastUpdatedAt = cached.cachedAt
                }
                await loadRewards(showSuccess: false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .rewardsStatusUpdated)) { _ in
            Task {
                await loadRewards(showSuccess: true)
            }
        }
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Credits Balance")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)

            Text("\(rewardsStatus?.creditsBalance ?? 0)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(CosmicTheme.gold)

            Text("Credits can be used for future premium perks and unlockables.")
                .font(.caption)
                .foregroundColor(CosmicTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Premium Status")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)

            if let premiumUntil = rewardsStatus?.premiumUntil,
               !premiumUntil.isEmpty {
                Text("Active until \(formatDate(premiumUntil))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.positive)
            } else {
                Text("Inactive")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private var referralCTASection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earn More Credits")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(CosmicTheme.textPrimary)

            Text("Use referral tools to invite friends and unlock more credits.")
                .font(.caption)
                .foregroundColor(CosmicTheme.textSecondary)

            NavigationLink(destination: ReferralCodeView()) {
                Text("Go to Referrals")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(CosmicTheme.gold)
                    )
            }
            .buttonStyle(.plain)

            NavigationLink(destination: ReferralLeaderboardView()) {
                Text("View Referral Leaderboard")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func loadRewards(showSuccess: Bool) async {
        isLoading = true
        errorMessage = nil
        if !showSuccess {
            successMessage = nil
        }
        defer { isLoading = false }

        do {
            let status = try await client.rewardsStatus()
            rewardsStatus = status
            let cacheTime = Date()
            lastUpdatedAt = cacheTime
            RewardsStatusCache.save(status: status, cachedAt: cacheTime)
            if showSuccess {
                successMessage = "Rewards status updated."
            }
        } catch let error as CosmoAPIError {
            successMessage = nil
            switch error {
            case .unauthorized:
                errorMessage = "Unauthorized right now. Reopen the app and try again."
            case .server(_, let message):
                errorMessage = message ?? "Unable to load rewards status."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            successMessage = nil
            errorMessage = error.localizedDescription
        }
    }

    private func lastUpdatedLabel(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatDate(_ value: String) -> String {
        if let date = ISO8601DateFormatter().date(from: value) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }

        let inFormatter = DateFormatter()
        inFormatter.dateFormat = "yyyy-MM-dd"
        if let date = inFormatter.date(from: value) {
            let outFormatter = DateFormatter()
            outFormatter.dateStyle = .medium
            outFormatter.timeStyle = .none
            return outFormatter.string(from: date)
        }
        return value
    }

    private func statusMessageCard(_ message: String, color: Color) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(CosmicTheme.cardBackground)
            )
    }
}

private enum RewardsStatusCache {
    private static let key = "com.cosmotrader.rewards.status.cache"

    struct CachedPayload: Codable {
        let status: RewardsStatus
        let cachedAt: Date
    }

    static func load() -> CachedPayload? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CachedPayload.self, from: data)
    }

    static func save(status: RewardsStatus, cachedAt: Date) {
        let payload = CachedPayload(status: status, cachedAt: cachedAt)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

extension Notification.Name {
    static let rewardsStatusUpdated = Notification.Name("com.cosmotrader.rewardsStatusUpdated")
}
