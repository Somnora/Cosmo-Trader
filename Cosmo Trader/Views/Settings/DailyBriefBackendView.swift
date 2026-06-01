import SwiftUI

struct DailyBriefBackendView: View {
    @Environment(AppState.self) private var appState

    private let client = CosmoAPIClient()
    private let backendConfig = CosmoBackendConfig.load()

    @State private var brief: DailyBriefResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isOffline = false
    @State private var isShowingLocalFallback = false
    @State private var lastUpdatedAt: Date?
    @State private var briefProvenance: FinancialDataProvenance = .unavailable(reason: "Daily Brief not loaded")
    @State private var diagnosticsURL: String?
    @State private var diagnosticsStatusCode: Int?
    @State private var todayViewModel = TodayMarketHoroscopeViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AppLayout.sectionSpacing) {
                TodayMarketHoroscopeView(viewModel: todayViewModel) {
                    appState.selectedTab = .portfolio
                }

                if shouldShowBriefStatus {
                    statusCard
                }

                if let errorMessage {
                    errorCard(errorMessage)
                }

                dailyBriefSupplement
            }
            .padding(.horizontal, AppLayout.screenHorizontalPadding)
            .padding(.top, 4)
            .iPadReadableContent(maxWidth: 980)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("DAILY BRIEF")
                    .font(TerminalFont.data(13, weight: .semibold))
                    .tracking(1.8)
                    .foregroundColor(CosmicTheme.textPrimary)
            }
        }
        .toolbarBackground(CosmicTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .accessibilityIdentifier("today.dailyBrief")
        .background(CosmicTheme.background)
        .tabBarSafeBottomPadding(extra: AppLayout.bottomTabBarExtraClearance)
        .refreshable {
            await todayViewModel.reload(user: appState.currentUser)
            await refreshBrief()
        }
        .task {
            await todayViewModel.load(user: appState.currentUser)
            if AppState.isScreenshotMode {
                showLocalFallbackIfNeeded()
                return
            }
            loadCachedBrief()
            await refreshBrief()
        }
    }

    private var statusCard: some View {
        briefStatusRow
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CosmicTheme.cardBackground.opacity(0.78))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
            )
    }

    private func errorCard(_ errorMessage: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(CosmicTheme.gold)

            Text(errorMessage)
                .font(.caption)
                .foregroundColor(CosmicTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground.opacity(0.78))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    @ViewBuilder
    private var dailyBriefSupplement: some View {
        if let brief, !AppState.isScreenshotMode {
            supportingBriefCard(brief)
        } else if isLoading && !AppState.isScreenshotMode {
            loadingBriefCard
        } else if errorMessage == nil && !AppState.isScreenshotMode {
            emptyBriefCard
        }
    }

    private func supportingBriefCard(_ brief: DailyBriefResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(CosmicTheme.border)
                    .frame(width: 18, height: 1)

                Text("SUPPORTING BRIEF")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .tracking(1.2)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            HStack(spacing: 8) {
                Rectangle()
                    .fill(CosmicTheme.gold.opacity(0.7))
                    .frame(width: 18, height: 1)

                Text(displayBriefDate(brief.date).uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .tracking(1.2)
                    .foregroundColor(CosmicTheme.gold)
            }

            Text(brief.briefText)
                .font(.body)
                .foregroundColor(CosmicTheme.textPrimary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            if let moodTag = brief.moodTag, !moodTag.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.gold)

                    Text("Mood")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)

                    Text(moodTag.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.gold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(CosmicTheme.gold.opacity(0.10))
                )
                .overlay(
                    Capsule()
                        .stroke(CosmicTheme.gold.opacity(0.25), lineWidth: 0.5)
                )
            }

            if let signals = brief.signals, !signals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(signals, id: \.self) { signal in
                            Text(signal)
                                .font(.caption2)
                                .foregroundColor(CosmicTheme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(CosmicTheme.cardBackground.opacity(0.65))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(CosmicTheme.gold.opacity(0.18), lineWidth: 0.5)
                                )
                        }
                    }
                    .padding(.trailing, 16)
                }
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.92),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
        .padding(AppLayout.cardHorizontalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CosmicTheme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private var loadingBriefCard: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(CosmicTheme.gold)
            Spacer()
        }
        .padding(AppLayout.cardHorizontalPadding)
        .frame(maxWidth: .infinity)
        .background(CosmicTheme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
        )
    }

    private var emptyBriefCard: some View {
        Text("No daily brief available yet.")
            .font(.subheadline)
            .foregroundColor(CosmicTheme.textMuted)
            .padding(AppLayout.cardHorizontalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CosmicTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(CosmicTheme.borderDim, lineWidth: 0.75)
            )
    }

    private var shouldShowBriefStatus: Bool {
        guard !AppState.isScreenshotMode else { return false }
        return brief != nil && (isOffline || lastUpdatedAt != nil)
    }

    private var briefStatusRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isOffline ? "wifi.slash" : "clock.arrow.circlepath")
                .font(.caption)
                .foregroundColor(CosmicTheme.gold)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(briefStatusTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)

                if let statusDetail = briefStatusDetail {
                    Text(statusDetail)
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                }
            }

            Spacer(minLength: 8)

            DataSourceIndicator(provenance: briefProvenance, size: .compact)
        }
    }

    private var briefStatusTitle: String {
        if isOffline {
            return isShowingLocalFallback ? "Today's brief is ready offline" : "Showing your saved brief"
        }

        return "Brief refreshed"
    }

    private var briefStatusDetail: String? {
        if let lastUpdatedAt {
            return "Updated \(formattedTimestamp(lastUpdatedAt))"
        }

        if isOffline {
            return "We'll refresh when your connection returns."
        }

        return nil
    }

    private func loadCachedBrief() {
        if let cachedPayload = DailyBriefBackendCache.load() {
            brief = cachedPayload.brief
            briefProvenance = .cached(provider: "Cosmo Backend", fetchedAt: cachedPayload.fetchedAt)
            lastUpdatedAt = lastUpdatedForDisplay(
                createdAt: cachedPayload.brief.createdAt,
                fallback: cachedPayload.fetchedAt
            )
        }
    }

    private func refreshBrief() async {
        isLoading = true
        errorMessage = nil
        isOffline = false
        isShowingLocalFallback = false
        diagnosticsURL = nil
        diagnosticsStatusCode = nil
        defer { isLoading = false }

        do {
            let latest = try await client.fetchDailyBriefToday()
            brief = latest
            isShowingLocalFallback = false
            let fetchedAt = Date()
            lastUpdatedAt = lastUpdatedForDisplay(createdAt: latest.createdAt, fallback: fetchedAt)
            briefProvenance = .live(provider: "Cosmo Backend", fetchedAt: fetchedAt)
            DailyBriefBackendCache.save(brief: latest, fetchedAt: fetchedAt)
        } catch let error as DailyBriefRequestError {
            switch error {
            case .unauthorized(let statusCode, let sanitizedURL, _):
                errorMessage = "Using your saved brief while your session reconnects."
                diagnosticsStatusCode = statusCode
                diagnosticsURL = sanitizedURL
                showLocalFallbackIfNeeded()
            case .server(let statusCode, let sanitizedURL, let message):
                if statusCode == 404 {
                    errorMessage = "Daily Brief is temporarily unavailable."
                } else {
                    errorMessage = userFacingServerMessage(message)
                }
                diagnosticsStatusCode = statusCode
                diagnosticsURL = sanitizedURL
                showLocalFallbackIfNeeded()
            }
        } catch let error as CosmoAPIError {
            switch error {
            case .unauthorized:
                errorMessage = "Using your saved brief while your session reconnects."
                diagnosticsStatusCode = 401
                diagnosticsURL = briefRequestSanitizedURL()
                showLocalFallbackIfNeeded()
            case .server(let statusCode, let message):
                if statusCode == 404 {
                    errorMessage = "Daily Brief is temporarily unavailable."
                } else {
                    errorMessage = userFacingServerMessage(message)
                }
                diagnosticsStatusCode = statusCode
                diagnosticsURL = briefRequestSanitizedURL()
                showLocalFallbackIfNeeded()
            case .transport(let transportError):
                if isOfflineError(transportError) {
                    isOffline = true
                }
                errorMessage = "We'll refresh your brief when the connection returns."
                diagnosticsURL = briefRequestSanitizedURL()
                showLocalFallbackIfNeeded()
            default:
                errorMessage = error.localizedDescription
                showLocalFallbackIfNeeded()
            }
        } catch {
            errorMessage = "We'll refresh your brief when the connection returns."
            diagnosticsURL = briefRequestSanitizedURL()
            showLocalFallbackIfNeeded()
        }
    }

    private func showLocalFallbackIfNeeded() {
        guard brief == nil, let user = appState.currentUser else { return }

        let localBrief = DailyBriefService.shared.generateBrief(for: user)
        brief = DailyBriefResponse(
            date: formattedBriefDate(localBrief.date),
            uid: appState.firebaseUID ?? "local",
            createdAt: ISO8601DateFormatter().string(from: localBrief.date),
            briefText: localBriefText(localBrief),
            moodTag: localBrief.cosmicConditions.overallEnergy.rawValue.lowercased(),
            signals: localBriefSignals(localBrief)
        )
        lastUpdatedAt = localBrief.date
        briefProvenance = .sample(reason: "Local fallback reading; backend unavailable")
        isOffline = true
        isShowingLocalFallback = true
        errorMessage = nil
    }

    private func localBriefText(_ brief: DailyBrief) -> String {
        let action = brief.framedSuggestedAction
        return "\(brief.cosmicHeadline)\n\n\(brief.framedConditionsSummary)\n\nToday's focus: \(action.title). \(action.description)"
    }

    private func localBriefSignals(_ brief: DailyBrief) -> [String] {
        [
            brief.cosmicConditions.overallEnergy.rawValue,
            brief.cosmicConditions.moonPhase.rawValue,
            "Mercury \(brief.cosmicConditions.mercuryStatus.rawValue)",
            brief.suggestedAction.title
        ]
    }

    private func formattedBriefDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func displayBriefDate(_ value: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")

        guard let date = parser.date(from: value) else {
            return value
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func lastUpdatedForDisplay(createdAt: String?, fallback: Date) -> Date {
        guard let createdAt else { return fallback }
        return parseBackendDate(createdAt) ?? fallback
    }

    private func parseBackendDate(_ value: String) -> Date? {
        if let iso = ISO8601DateFormatter().date(from: value) {
            return iso
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: value)
    }

    private func formattedTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func isOfflineError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .timedOut:
            return true
        default:
            return false
        }
    }

    private func briefRequestSanitizedURL() -> String {
        let url = backendConfig.baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("brief")
            .appendingPathComponent("today")
        let host = url.host ?? "unknown-host"
        let hostWithPort = url.port.map { "\(host):\($0)" } ?? host
        let path = url.path.isEmpty ? "/" : url.path
        return "\(hostWithPort)\(path)"
    }

    private func userFacingServerMessage(_ message: String?) -> String {
        guard let message, !message.isEmpty else {
            return "Unable to refresh Daily Brief."
        }

        let lowercasedMessage = message.lowercased()
        if lowercasedMessage.contains("http")
            || lowercasedMessage.contains("cloud run")
            || lowercasedMessage.contains("__build_info")
            || lowercasedMessage.contains("backend")
            || lowercasedMessage.contains("firebase") {
            return "Unable to refresh Daily Brief."
        }

        return message
    }

    private var diagnosticsFootnote: String? {
        var parts: [String] = []
        if let diagnosticsURL {
            parts.append(diagnosticsURL)
        }
        if let diagnosticsStatusCode {
            parts.append("HTTP \(diagnosticsStatusCode)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
}

private enum DailyBriefBackendCache {
    private static let key = "cosmo.backend.dailybrief.today.v1"

    private struct Payload: Codable {
        let brief: DailyBriefResponse
        let fetchedAt: Date
    }

    static func load() -> (brief: DailyBriefResponse, fetchedAt: Date)? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return nil
        }
        return (brief: payload.brief, fetchedAt: payload.fetchedAt)
    }

    static func save(brief: DailyBriefResponse, fetchedAt: Date) {
        let payload = Payload(brief: brief, fetchedAt: fetchedAt)
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
