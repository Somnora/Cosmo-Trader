import SwiftUI

struct AuthenticationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var email = ""
    @State private var password = ""
    @State private var isRegisterMode = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Title section
                    VStack(spacing: 8) {
                        Text("COSMIC CLOUD SECURE ACCESS")
                            .font(TerminalFont.ticker(18))
                            .foregroundColor(CosmicTheme.gold)

                        Text(isRegisterMode ? "LINK PROFILE TO EMAIL" : "SIGN IN TO SECURE ACCOUNT")
                            .font(TerminalFont.data(12))
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                    .padding(.top, 24)

                    // Form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EMAIL ADDRESS")
                                .font(TerminalFont.data(10, weight: .bold))
                                .foregroundColor(CosmicTheme.textMuted)

                            TextField("", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .font(TerminalFont.data(14))
                                .foregroundColor(CosmicTheme.textPrimary)
                                .padding(12)
                                .background(CosmicTheme.cardBackground)
                                .overlay(
                                    Rectangle()
                                        .stroke(CosmicTheme.border, lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("PASSWORD")
                                .font(TerminalFont.data(10, weight: .bold))
                                .foregroundColor(CosmicTheme.textMuted)

                            SecureField("", text: $password)
                                .font(TerminalFont.data(14))
                                .foregroundColor(CosmicTheme.textPrimary)
                                .padding(12)
                                .background(CosmicTheme.cardBackground)
                                .overlay(
                                    Rectangle()
                                        .stroke(CosmicTheme.border, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 24)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.negative)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }

                    if let successMessage {
                        Text(successMessage)
                            .font(TerminalFont.data(11))
                            .foregroundColor(CosmicTheme.positive)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: handleAuthAction) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(CosmicTheme.terminalBlack)
                                        .padding(.trailing, 8)
                                }
                                Text(isRegisterMode ? "LINK PROFILE" : "SIGN IN")
                                    .font(TerminalFont.data(14, weight: .bold))
                            }
                            .foregroundColor(CosmicTheme.terminalBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(CosmicTheme.gold)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)

                        Button(action: { isRegisterMode.toggle(); errorMessage = nil; successMessage = nil }) {
                            Text(isRegisterMode ? "ALREADY HAVE AN ACCOUNT? SIGN IN" : "NEW USER? LINK GUEST STATE TO EMAIL")
                                .font(TerminalFont.data(11, weight: .bold))
                                .foregroundColor(CosmicTheme.textSecondary)
                                .tracking(0.5)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Footer note
                    if isRegisterMode {
                        Text("Linking your account preserves all local portfolio holdings and watchlists on the cloud.")
                            .font(TerminalFont.data(10))
                            .foregroundColor(CosmicTheme.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("CLOSE") {
                        dismiss()
                    }
                    .font(TerminalFont.data(12, weight: .bold))
                    .foregroundColor(CosmicTheme.textMuted)
                }
            }
        }
    }

    private func handleAuthAction() {
        guard !email.isEmpty, !password.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                if isRegisterMode {
                    try await AuthManager.shared.signUpAndLink(email: email, password: password, appState: appState)
                    successMessage = "Account successfully linked!"
                } else {
                    try await AuthManager.shared.signIn(email: email, password: password, appState: appState)
                    successMessage = "Signed in successfully!"
                }
                
                // Let the user see the success message briefly, then dismiss
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
