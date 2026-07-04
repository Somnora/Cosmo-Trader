import SwiftUI

// MARK: - ContentView (Main Tab View)
// ====================================
// The main container view that holds our tab navigation.
//
// This is shown AFTER onboarding is complete.
// Each tab receives the shared AppState via environment.

struct ContentView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - State

    /// Terminal audio service for ambient sounds
    @State private var audioService = TerminalAudioService.shared

    /// Binding to shared tab selection in AppState
    private var selectedTab: Binding<Tab> {
        Binding(
            get: { appState.selectedTab },
            set: { appState.selectedTab = $0 }
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Offline banner at top of screen
            OfflineBanner()

            TabView(selection: selectedTab) {
                // Today Tab - Daily Brief (Home)
                NavigationStack {
                    DailyBriefBackendView()
                }
                .accessibilityIdentifier("screen.today")
                .tabItem {
                    Label("Today", systemImage: appState.selectedTab == .today ? "sun.max.fill" : "sun.max")
                }
                .tag(Tab.today)

                // Portfolio Tab - Holdings view
                PortfolioView()
                .accessibilityIdentifier("screen.portfolio")
                .tabItem {
                    Label("Portfolio", systemImage: appState.selectedTab == .portfolio ? "chart.pie.fill" : "chart.pie")
                }
                .tag(Tab.portfolio)

                // Discover Tab - Swipe on stocks
                DiscoverView()
                .accessibilityIdentifier("screen.discover")
                .tabItem {
                    Label("Discover", systemImage: appState.selectedTab == .discover ? "safari.fill" : "safari")
                }
                .tag(Tab.discover)

                // Cosmos Tab - Daily horoscope
                CosmosView()
                .accessibilityIdentifier("screen.cosmos")
                .tabItem {
                    Label("Cosmos", systemImage: appState.selectedTab == .cosmos ? "moon.stars.fill" : "moon.stars")
                }
                .tag(Tab.cosmos)

                // Profile Tab - User settings
                ProfileView()
                .accessibilityIdentifier("screen.profile")
                .tabItem {
                    Label("Profile", systemImage: appState.selectedTab == .profile ? "person.fill" : "person")
                }
                .tag(Tab.profile)
            }
            .tint(CosmicTheme.gold)
            .toolbarBackground(CosmicTheme.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .onAppear {
                configureTabBarAppearance()
                // Track app opened and refresh user properties
                AnalyticsService.shared.trackAppOpened()
                AnalyticsService.shared.refreshUserProperties(from: appState)
                // Start ambient audio if enabled
                audioService.startAmbientLoop()
                // Sync widget data on app launch
                WidgetBridge.shared.syncAllWidgetData()
            }
            // MARK: - Notification Deep-Link Listeners
            .onReceive(NotificationCenter.default.publisher(for: .openToday)) { _ in
                appState.selectedTab = .today
            }
            .onReceive(NotificationCenter.default.publisher(for: .openPortfolio)) { _ in
                appState.selectedTab = .portfolio
            }
            .onReceive(NotificationCenter.default.publisher(for: .openDiscover)) { _ in
                appState.selectedTab = .discover
            }
            .onReceive(NotificationCenter.default.publisher(for: .openCosmos)) { _ in
                appState.selectedTab = .cosmos
            }
            .onReceive(NotificationCenter.default.publisher(for: .openProfile)) { _ in
                appState.selectedTab = .profile
            }
            .onReceive(NotificationCenter.default.publisher(for: .openStockDetail)) { _ in
                // Portfolio hosts the stock detail flow for tapped symbols
                appState.selectedTab = .portfolio
            }
            .onChange(of: appState.selectedTab) { oldTab, newTab in
                // Track tab switches
                AnalyticsService.shared.trackTabSwitch(newTab.analyticsName)
                // Play tab switch sound
                audioService.playTabSwitch()
            }
        }
    }

    // MARK: - Tab Bar Appearance

    /// Configure the UIKit tab bar appearance - Bloomberg Terminal style
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        // True black background
        appearance.backgroundColor = UIColor(CosmicTheme.background)

        // 1px top border line
        appearance.shadowColor = UIColor(CosmicTheme.border)

        // Unselected items - muted gray
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(CosmicTheme.textMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(CosmicTheme.textMuted),
            .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        ]

        // Selected items - muted gold (not bright)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(CosmicTheme.gold)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(CosmicTheme.gold),
            .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .medium)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Adaptive Layout Helpers

extension View {
    /// Constrains content to a readable max width on regular-width canvases
    /// (iPad), leaving compact (iPhone) layouts untouched. Defaults are tuned
    /// so that the 13" iPad portrait canvas (1032pt) shows a confident,
    /// centered column with restrained gutters rather than a stranded
    /// phone-width card.
    func iPadReadableContent(maxWidth: CGFloat = 980, alignment: Alignment = .top) -> some View {
        modifier(IPadReadableContentModifier(maxWidth: maxWidth, alignment: alignment))
    }
}

private struct IPadReadableContentModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let maxWidth: CGFloat
    let alignment: Alignment

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .frame(maxWidth: maxWidth, alignment: alignment)
                .frame(maxWidth: .infinity, alignment: alignment)
        } else {
            content
        }
    }
}

// MARK: - Tab Enum

/// Type-safe enum for our tabs
enum Tab: Hashable {
    case today
    case portfolio
    case discover
    case cosmos
    case profile

    /// Name for analytics tracking
    var analyticsName: String {
        switch self {
        case .today: return "Today"
        case .portfolio: return "Portfolio"
        case .discover: return "Discover"
        case .cosmos: return "Cosmos"
        case .profile: return "Profile"
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}
