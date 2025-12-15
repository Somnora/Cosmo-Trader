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
        TabView(selection: selectedTab) {
            // Portfolio Tab - Home/main view
            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: appState.selectedTab == .portfolio ? "house.fill" : "house")
                }
                .tag(Tab.portfolio)

            // Discover Tab - Swipe on stocks
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: appState.selectedTab == .discover ? "safari.fill" : "safari")
                }
                .tag(Tab.discover)

            // IPO Tab - Upcoming cosmic births
            IPOListView()
                .tabItem {
                    Label("IPOs", systemImage: appState.selectedTab == .ipos ? "sparkle" : "sparkle")
                }
                .tag(Tab.ipos)

            // Cosmos Tab - Daily horoscope
            CosmosView()
                .tabItem {
                    Label("Cosmos", systemImage: appState.selectedTab == .cosmos ? "moon.stars.fill" : "moon.stars")
                }
                .tag(Tab.cosmos)

            // Profile Tab - User settings
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: appState.selectedTab == .profile ? "person.fill" : "person")
                }
                .tag(Tab.profile)
        }
        .tint(CosmicTheme.gold)
        .onAppear {
            configureTabBarAppearance()
            // Track app opened and refresh user properties
            AnalyticsService.shared.trackAppOpened()
            AnalyticsService.shared.refreshUserProperties(from: appState)
            // Start ambient audio if enabled
            audioService.startAmbientLoop()
        }
        .onChange(of: appState.selectedTab) { oldTab, newTab in
            // Track tab switches
            AnalyticsService.shared.trackTabSwitch(newTab.analyticsName)
            // Play tab switch sound
            audioService.playTabSwitch()
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

// MARK: - Tab Enum

/// Type-safe enum for our tabs
enum Tab: Hashable {
    case portfolio
    case discover
    case ipos
    case cosmos
    case profile

    /// Name for analytics tracking
    var analyticsName: String {
        switch self {
        case .portfolio: return "Portfolio"
        case .discover: return "Discover"
        case .ipos: return "IPOs"
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
