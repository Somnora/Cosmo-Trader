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

    /// Which tab is currently selected
    @State private var selectedTab: Tab = .portfolio

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Portfolio Tab - Home/main view
            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: selectedTab == .portfolio ? "house.fill" : "house")
                }
                .tag(Tab.portfolio)

            // Discover Tab - Swipe on stocks
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: selectedTab == .discover ? "safari.fill" : "safari")
                }
                .tag(Tab.discover)

            // Cosmos Tab - Daily horoscope
            CosmosView()
                .tabItem {
                    Label("Cosmos", systemImage: selectedTab == .cosmos ? "moon.stars.fill" : "moon.stars")
                }
                .tag(Tab.cosmos)

            // Profile Tab - User settings
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == .profile ? "person.fill" : "person")
                }
                .tag(Tab.profile)
        }
        .tint(CosmicTheme.gold)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    // MARK: - Tab Bar Appearance

    /// Configure the UIKit tab bar appearance for our cosmic theme
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        // Background color - darker for cosmic feel
        appearance.backgroundColor = UIColor(CosmicTheme.background)

        // Add subtle top border
        appearance.shadowColor = UIColor(CosmicTheme.gold.opacity(0.1))

        // Unselected items
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(CosmicTheme.textMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(CosmicTheme.textMuted),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        // Selected items
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(CosmicTheme.gold)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(CosmicTheme.gold),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
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
    case cosmos
    case profile
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}
