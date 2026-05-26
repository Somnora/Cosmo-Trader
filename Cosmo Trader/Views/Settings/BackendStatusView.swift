import SwiftUI

struct BackendStatusView: View {
    private let client = CosmoAPIClient()
    private let config = CosmoBackendConfig.load()
    private let hasConfiguredBackendURL = CosmoConfig.string(["COSMO_BACKEND_BASE_URL", "BACKEND_BASE_URL"]) != nil
    private let hasFinnhubKey = APIConfig.isFinnhubConfigured
    private let expectedAPIVersion = "backend_v0"

    @State private var isRunning = false
    @State private var results: [BackendCheckResult] = []
    @State private var errorMessage: String?
    @State private var authMode = "none"
    @State private var buildInfo: BuildInfoResponse?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Base URL")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                    Text(config.baseURL.absoluteString)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textPrimary)
                }

                configStatusSection

                if let mismatchWarning {
                    Text(mismatchWarning)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.negative)
                }

                #if DEBUG
                Text(debugAuthBannerText)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
                #endif

                if !FirebaseConfigurator.isConfigured && (config.apiKey?.isEmpty != false) {
                    Text("Firebase not configured, protected endpoints will return unauthorized")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textMuted)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.negative)
                }

                Button(action: { Task { await runTests() } }) {
                    HStack {
                        if isRunning {
                            ProgressView()
                                .tint(CosmicTheme.gold)
                        }
                        Text(isRunning ? "Running..." : "Run Tests")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(CosmicTheme.gold.opacity(isRunning ? 0.6 : 1.0))
                    )
                    .foregroundColor(CosmicTheme.background)
                }
                .disabled(isRunning)
                .accessibilityIdentifier("backendStatus.runTestsButton")

                ForEach(results) { result in
                    BackendCheckCard(result: result)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Backend Status")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("backendStatus.screen")
        .onAppear {
            if results.isEmpty {
                Task { await runTests() }
            }
        }
    }

    private func runTests() async {
        #if DEBUG
        if CommandLine.arguments.contains("--backend-status-smoke") {
            isRunning = true
            errorMessage = nil
            buildInfo = nil
            results = [
                BackendCheckResult(
                    name: "UI Testing Fallback",
                    path: "local",
                    statusCode: nil,
                    responseText: "Backend smoke mode active. Live network checks skipped for CI.",
                    projectConfigured: nil,
                    authMode: FirebaseConfigurator.isConfigured ? "bearer" : "none",
                    uid: nil,
                    errorDescription: "Skipped live backend checks",
                    apiVersion: nil,
                    routeChecks: nil
                )
            ]
            isRunning = false
            return
        }
        #endif

        isRunning = true
        errorMessage = nil
        results = []
        buildInfo = nil
        await refreshAuthMode()

        await runBuildInfoCheck()
        await runCheck(name: "Public Health", path: "/health")
        await runCheck(name: "Protected Ping", path: "/v1/ping", requiresAuth: true)
        await runCheck(name: "Protected Healthz", path: "/v1/healthz", requiresAuth: true)
        await runCheck(name: "Protected WhoAmI", path: "/v1/whoami", requiresAuth: true)

        isRunning = false
    }

    private func runBuildInfoCheck() async {
        do {
            let info = try await client.buildInfo()
            buildInfo = info
            let responseText = truncateBuildInfoResponse(info)
            let result = BackendCheckResult(
                name: "Build Info",
                path: "/__build_info",
                statusCode: 200,
                responseText: responseText,
                projectConfigured: nil,
                authMode: nil,
                uid: nil,
                errorDescription: nil,
                apiVersion: info.apiVersion,
                routeChecks: info.routeChecks
            )
            results.append(result)
        } catch let error as CosmoAPIError {
            let statusCode: Int?
            switch error {
            case .unauthorized:
                statusCode = 401
            case .server(let code, _):
                statusCode = code
            default:
                statusCode = nil
            }
            let result = BackendCheckResult(
                name: "Build Info",
                path: "/__build_info",
                statusCode: statusCode,
                responseText: error.localizedDescription,
                projectConfigured: nil,
                authMode: nil,
                uid: nil,
                errorDescription: "Request failed",
                apiVersion: nil,
                routeChecks: nil
            )
            results.append(result)
            errorMessage = "Request failed while checking /__build_info."
        } catch {
            let result = BackendCheckResult(
                name: "Build Info",
                path: "/__build_info",
                statusCode: nil,
                responseText: error.localizedDescription,
                projectConfigured: nil,
                authMode: nil,
                uid: nil,
                errorDescription: "Request failed",
                apiVersion: nil,
                routeChecks: nil
            )
            results.append(result)
            errorMessage = "Request failed while checking /__build_info."
        }
    }

    private func runCheck(name: String, path: String, requiresAuth: Bool = false) async {
        do {
            let (statusCode, data) = try await client.raw(path: path, requiresAuth: requiresAuth)
            let responseText = truncateResponse(data)
            var projectConfigured: Bool?
            var whoAmIAuthMode: String?
            var whoAmIUID: String?
            if path == "/v1/healthz" {
                projectConfigured = (try? JSONDecoder().decode(V1HealthzResponse.self, from: data))?.projectConfigured
            }
            if path == "/v1/whoami", let whoAmI = try? JSONDecoder().decode(WhoAmIResponse.self, from: data) {
                projectConfigured = whoAmI.projectConfigured
                whoAmIAuthMode = whoAmI.authMode
                whoAmIUID = whoAmI.uid
            }

            let result = BackendCheckResult(
                name: name,
                path: path,
                statusCode: statusCode,
                responseText: responseText,
                projectConfigured: projectConfigured,
                authMode: whoAmIAuthMode,
                uid: whoAmIUID,
                errorDescription: statusCode == 401 ? "Unauthorized (API key missing or invalid)" : nil,
                apiVersion: nil,
                routeChecks: nil
            )
            results.append(result)
        } catch let error as CosmoAPIError {
            if case .unauthorized(let message) = error {
                let result = BackendCheckResult(
                    name: name,
                    path: path,
                    statusCode: 401,
                    responseText: message ?? "Unauthorized",
                    projectConfigured: nil,
                    authMode: nil,
                    uid: nil,
                    errorDescription: "Unauthorized (API key missing or invalid)",
                    apiVersion: nil,
                    routeChecks: nil
                )
                results.append(result)
                return
            }

            errorMessage = "Request failed while checking \(path)."
            let result = BackendCheckResult(
                name: name,
                path: path,
                statusCode: nil,
                responseText: error.localizedDescription,
                projectConfigured: nil,
                authMode: nil,
                uid: nil,
                errorDescription: "Request failed",
                apiVersion: nil,
                routeChecks: nil
            )
            results.append(result)
        } catch {
            errorMessage = "Network error while checking \(path)."
            let result = BackendCheckResult(
                name: name,
                path: path,
                statusCode: nil,
                responseText: error.localizedDescription,
                projectConfigured: nil,
                authMode: nil,
                uid: nil,
                errorDescription: "Network error",
                apiVersion: nil,
                routeChecks: nil
            )
            results.append(result)
        }
    }

    private func refreshAuthMode() async {
        if await AuthManager.shared.getIDTokenIfAvailable(forceRefresh: false) != nil {
            authMode = "bearer"
            return
        }
        if let apiKey = config.apiKey, !apiKey.isEmpty {
            authMode = "key"
            return
        }
        authMode = "none"
    }

    private func truncateResponse(_ data: Data) -> String {
        let maxLength = 500
        let text = String(data: data, encoding: .utf8) ?? "<non-utf8 response>"
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength)) + "..."
    }

    private func truncateBuildInfoResponse(_ info: BuildInfoResponse) -> String {
        guard let data = try? JSONEncoder().encode(info) else {
            return "<unable to encode build info>"
        }
        return truncateResponse(data)
    }

    private var mismatchWarning: String? {
        guard let apiVersion = buildInfo?.apiVersion, apiVersion != expectedAPIVersion else {
            return nil
        }
        return "Backend mismatch, deploy from backend_v0"
    }

    private var debugAuthBannerText: String {
        #if DEBUG
        if FirebaseConfigurator.isConfigured {
            return "Firebase enabled"
        }
        if let apiKey = config.apiKey, !apiKey.isEmpty {
            return "Firebase disabled, using key fallback"
        }
        return "Auth unavailable"
        #else
        return ""
        #endif
    }

    private var configStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Config Status")
                .font(.caption)
                .foregroundColor(CosmicTheme.textMuted)

            configStatusRow(label: "Backend URL", isConfigured: hasConfiguredBackendURL)
            configStatusRow(label: "Finnhub Key", isConfigured: hasFinnhubKey)
            configStatusRow(label: "Firebase", isConfigured: FirebaseConfigurator.isConfigured)
        }
        .padding(12)
        .accessibilityIdentifier("backendStatus.configStatus")
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    @ViewBuilder
    private func configStatusRow(label: String, isConfigured: Bool) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(CosmicTheme.textSecondary)
            Spacer()
            Text(isConfigured ? "Configured" : "Missing")
                .font(.caption2)
                .foregroundColor(isConfigured ? CosmicTheme.positive : CosmicTheme.negative)
        }
    }
}

private struct BackendCheckResult: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let statusCode: Int?
    let responseText: String
    let projectConfigured: Bool?
    let authMode: String?
    let uid: String?
    let errorDescription: String?
    let apiVersion: String?
    let routeChecks: BuildInfoRouteChecks?
}

private struct BackendCheckCard: View {
    let result: BackendCheckResult

    private var statusText: String {
        if let errorDescription = result.errorDescription {
            return errorDescription
        }
        guard let statusCode = result.statusCode else { return "No response" }
        if statusCode >= 200 && statusCode < 300 {
            return "OK"
        }
        return "HTTP \(statusCode)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CosmicTheme.textPrimary)
                    Text(result.path)
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                }
                Spacer()
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusText == "OK" ? CosmicTheme.positive : CosmicTheme.negative)
            }

            if let statusCode = result.statusCode {
                Text("Status: \(statusCode)")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            if let projectConfigured = result.projectConfigured {
                Text("project_configured: \(projectConfigured ? "true" : "false")")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            if let apiVersion = result.apiVersion {
                Text("api_version: \(apiVersion)")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            if let routeChecks = result.routeChecks {
                Text("route_checks: brief_today=\(boolText(routeChecks.hasBriefToday)), inbox=\(boolText(routeChecks.hasInbox)), rewards_status=\(boolText(routeChecks.hasRewardsStatus)), whoami=\(boolText(routeChecks.hasWhoami))")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            if let authMode = result.authMode {
                Text("auth_mode: \(authMode)")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            if let uid = result.uid {
                Text("uid: \(uid)")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Text(result.responseText)
                .font(.caption2)
                .foregroundColor(CosmicTheme.textSecondary)
                .lineLimit(6)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    private func boolText(_ value: Bool?) -> String {
        guard let value else { return "unknown" }
        return value ? "true" : "false"
    }
}
