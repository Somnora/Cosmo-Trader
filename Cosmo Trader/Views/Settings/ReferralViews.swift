import SwiftUI

struct ReferralCodeView: View {
    private let client = CosmoAPIClient()

    @State private var code = ""
    @State private var isSubmitting = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Enter your referral code to claim rewards.")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Referral Code")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                    TextField("ABC123", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(CosmicTheme.cardBackground)
                        )
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.negative)
                }

                if let successMessage {
                    Text(successMessage)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.positive)
                }

                Button(action: { Task { await applyCode() } }) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(CosmicTheme.gold)
                        }
                        Text(isSubmitting ? "Applying..." : "Apply")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(CosmicTheme.gold.opacity(isSubmitting ? 0.6 : 1.0))
                    )
                    .foregroundColor(CosmicTheme.background)
                }
                .disabled(isSubmitting)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Referral Code")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func applyCode() async {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        errorMessage = nil
        successMessage = nil

        guard normalized.count >= 6 && normalized.count <= 8 else {
            errorMessage = "Code must be 6 to 8 characters."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let request = ReferralApplyRequest(
                code: normalized,
                deviceId: DeviceIDProvider.shared.getOrCreateDeviceId()
            )
            let response = try await client.applyReferral(request)
            if let referralId = response.referralId {
                successMessage = "Applied. Referral ID: \(referralId)"
            } else {
                successMessage = response.message ?? "Referral applied."
            }
        } catch let error as CosmoAPIError {
            switch error {
            case .unauthorized:
                errorMessage = "Unauthorized (API key missing or invalid)"
            case .server(_, let message):
                errorMessage = message ?? "Request failed."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ReferralLeaderboardView: View {
    private let client = CosmoAPIClient()

    @State private var leaders: [ReferralLeaderboardEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.negative)
            }

            ForEach(Array(leaders.enumerated()), id: \.element.uid) { index, leader in
                HStack {
                    Text("#\(index + 1)")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                        .frame(width: 32, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(leader.anonymizedName)
                            .font(.subheadline)
                            .foregroundColor(CosmicTheme.textPrimary)
                        Text("Referrals: \(leader.referralRewardCount)")
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)
                    }

                    Spacer()
                }
                .listRowBackground(CosmicTheme.cardBackground)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Referral Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isLoading && leaders.isEmpty {
                ProgressView()
                    .tint(CosmicTheme.gold)
            }
        }
        .refreshable {
            await loadLeaderboard()
        }
        .task {
            if leaders.isEmpty {
                await loadLeaderboard()
            }
        }
    }

    private func loadLeaderboard() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await client.referralLeaderboard(limit: 50)
            leaders = response.leaders
        } catch let error as CosmoAPIError {
            switch error {
            case .unauthorized:
                errorMessage = "Unauthorized (API key missing or invalid)"
            case .server(_, let message):
                errorMessage = message ?? "Request failed."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
