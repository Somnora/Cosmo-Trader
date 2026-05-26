import SwiftUI

struct ProfileSyncView: View {
    private let client = CosmoAPIClient()
    private let zodiacSigns = [
        "aries", "taurus", "gemini", "cancer", "leo", "virgo",
        "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"
    ]

    @State private var selectedZodiacSign: String = ""
    @State private var riskLevel: Double = 50
    @State private var notificationsEnabled: Bool = false
    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        Form {
            Section("Profile") {
                Picker("Zodiac Sign", selection: $selectedZodiacSign) {
                    Text("Not Set").tag("")
                    ForEach(zodiacSigns, id: \.self) { sign in
                        Text(sign.capitalized).tag(sign)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Risk Level")
                        Spacer()
                        Text("\(Int(riskLevel.rounded()))")
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                    Slider(value: $riskLevel, in: 0...100, step: 1)
                }

                Toggle("Notifications Enabled", isOn: $notificationsEnabled)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.negative)
                }
            }

            if let successMessage {
                Section {
                    Text(successMessage)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.positive)
                }
            }

            Section {
                Button(action: { Task { await save() } }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(CosmicTheme.gold)
                        }
                        Text(isSaving ? "Saving..." : "Save")
                    }
                }
                .disabled(isSaving || isLoading)
            }
        }
        .scrollContentBackground(.hidden)
        .background(CosmicTheme.background.ignoresSafeArea())
        .navigationTitle("Profile Sync")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !isLoading {
                await loadProfile()
            }
        }
    }

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let profile = try await client.fetchMe()
            selectedZodiacSign = profile.zodiacSign ?? ""
            riskLevel = Double(profile.riskLevel ?? 50)
            notificationsEnabled = profile.notificationsEnabled ?? false
        } catch let error as CosmoAPIError {
            switch error {
            case .unauthorized:
                errorMessage = "Session unavailable. Please sign in and try again."
            case .server(_, let message):
                errorMessage = message ?? "Unable to load profile from backend."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        let request = UpdateUserProfileRequest(
            zodiacSign: selectedZodiacSign.isEmpty ? nil : selectedZodiacSign,
            riskLevel: Int(riskLevel.rounded()),
            notificationsEnabled: notificationsEnabled
        )

        do {
            let updated = try await client.updateMe(request: request)
            selectedZodiacSign = updated.zodiacSign ?? ""
            riskLevel = Double(updated.riskLevel ?? Int(riskLevel.rounded()))
            notificationsEnabled = updated.notificationsEnabled ?? notificationsEnabled
            successMessage = "Profile synced successfully."
        } catch let error as CosmoAPIError {
            switch error {
            case .unauthorized:
                errorMessage = "Session unavailable. Please sign in and try again."
            case .server(_, let message):
                errorMessage = message ?? "Unable to save profile."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

