import SwiftUI

/// ContentView
/// -----------
/// The main container view that holds our tab navigation.
///
/// TabView is SwiftUI's built-in way to create a tab bar at the bottom
/// of the screen. Each tab shows a different View when selected.

struct ContentView: View {

    /// Which tab is currently selected (stored so we can track it)
    @State private var selectedTab: Tab = .portfolio

    var body: some View {
        TabView(selection: $selectedTab) {
            // Portfolio Tab
            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }
                .tag(Tab.portfolio)

            // Discover Tab
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(Tab.discover)

            // Horoscope Tab
            HoroscopeView()
                .tabItem {
                    Label("Horoscope", systemImage: "sparkles")
                }
                .tag(Tab.horoscope)

            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(CosmicTheme.gold) // Tab bar accent color
        .onAppear {
            // Customize tab bar appearance
            configureTabBarAppearance()
        }
    }

    /// Configure the UIKit tab bar appearance for our cosmic theme
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        // Background color
        appearance.backgroundColor = UIColor(CosmicTheme.background)

        // Unselected items
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(CosmicTheme.textMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(CosmicTheme.textMuted)
        ]

        // Selected items
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(CosmicTheme.gold)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(CosmicTheme.gold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Tab Enum

/// Enum for our tabs - makes it type-safe and easy to track
enum Tab: Hashable {
    case portfolio
    case discover
    case horoscope
    case profile
}

// MARK: - Preview

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
