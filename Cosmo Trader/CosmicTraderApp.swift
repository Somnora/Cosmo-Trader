import SwiftUI

/// CosmicTraderApp
/// ---------------
/// This is the ENTRY POINT of our app - where everything starts!
///
/// The @main attribute tells Swift "start here!"
/// The App protocol requires us to provide a `body` that returns a Scene.
/// WindowGroup is the standard scene type for iOS apps.
///
/// NAVIGATION FLOW:
/// 1. App launches
/// 2. Check if user has completed onboarding
/// 3. If not onboarded → Show OnboardingView
/// 4. If onboarded → Show main ContentView (TabView)

@main
struct CosmicTraderApp: App {

    // MARK: - State

    /// The shared app state - holds current user and all shared data
    @State private var appState = AppState()

    /// Initialize any app-wide settings when the app launches
    init() {
        configureAppAppearance()
        // Note: Deferred API diagnostic test to after app launch for better startup performance
        // The test will run after the launch screen completes
    }

    // MARK: - Body

    /// The main scene of our app
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }

    // MARK: - Appearance Configuration

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

// MARK: - Root View

/// Root view that handles the launch screen, onboarding, and main app flow
struct RootView: View {

    @Environment(AppState.self) private var appState
    @State private var showLaunchScreen = true

    var body: some View {
        ZStack {
            // Main content (behind launch screen)
            Group {
                if appState.hasCompletedOnboarding {
                    // Show main app
                    ContentView()
                        .transition(.opacity)
                } else {
                    // Show onboarding
                    OnboardingView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)

            // Launch screen overlay
            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Dismiss launch screen after animation completes (~4 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLaunchScreen = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Onboarded") {
    RootView()
        .environment(AppState.preview)
        .preferredColorScheme(.dark)
}

#Preview("App - New User") {
    RootView()
        .environment(AppState.previewEmpty)
        .preferredColorScheme(.dark)
}
