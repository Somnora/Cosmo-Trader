import SwiftUI

/// CosmicTraderApp
/// ---------------
/// This is the ENTRY POINT of our app - where everything starts!
///
/// The @main attribute tells Swift "start here!"
/// The App protocol requires us to provide a `body` that returns a Scene.
/// WindowGroup is the standard scene type for iOS apps.
///
/// Think of this as the "main()" function in other programming languages.

@main
struct CosmicTraderApp: App {

    /// Initialize any app-wide settings when the app launches
    init() {
        // Force dark mode for the entire app
        // Our cosmic theme looks best in dark mode!
        configureAppAppearance()
    }

    /// The main scene of our app
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Force dark mode
        }
    }

    /// Configure global appearance settings
    private func configureAppAppearance() {
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(CosmicTheme.background)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(CosmicTheme.textPrimary)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(CosmicTheme.textPrimary)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
}
