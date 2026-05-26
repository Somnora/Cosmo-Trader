import SwiftUI
import UIKit
import UserNotifications

// MARK: - App Delegate
// ====================
// Handles local notification foreground delivery and taps.

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set ourselves as the notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Register for memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }

        return true
    }

    // MARK: - Memory Warning Handler

    private func handleMemoryWarning() {
        #if DEBUG
        print("⚠️ Memory warning received - clearing caches")
        #endif

        // Clear API caches
        StockAPIService.shared.clearCache()
        VolumeService.shared.clearCache()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notification when app is in foreground - show it anyway
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, play sound, and update badge even when app is open
        completionHandler([.banner, .badge, .sound])
    }

    /// Handle notification tap - navigate to relevant screen
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle different notification types
        if let type = userInfo["type"] as? String {
            switch type {
            case "confluence":
                // Navigate to stock detail
                if let symbol = userInfo["symbol"] as? String {
                    NotificationCenter.default.post(
                        name: .openStockDetail,
                        object: nil,
                        userInfo: ["symbol": symbol]
                    )
                }

            case "ipo":
                // Navigate to IPO list
                if let ticker = userInfo["ticker"] as? String {
                    NotificationCenter.default.post(
                        name: .openIPODetail,
                        object: nil,
                        userInfo: ["ticker": ticker]
                    )
                }

            case "portfolio_move":
                // Navigate to portfolio
                NotificationCenter.default.post(name: .openPortfolio, object: nil)

            case "signSeason":
                // Navigate to cosmos tab
                NotificationCenter.default.post(name: .openCosmos, object: nil)

            default:
                // Default: open cosmos tab for horoscope-related notifications
                NotificationCenter.default.post(name: .openCosmos, object: nil)
            }
        } else {
            // No type specified - open cosmos tab
            NotificationCenter.default.post(name: .openCosmos, object: nil)
        }

        // Track notification opened
        AnalyticsService.shared.track(.notificationOpened)

        completionHandler()
    }
}

// MARK: - Notification Names for Navigation

extension Notification.Name {
    static let openStockDetail = Notification.Name("openStockDetail")
    static let openIPODetail = Notification.Name("openIPODetail")
    static let openPortfolio = Notification.Name("openPortfolio")
    static let openCosmos = Notification.Name("openCosmos")
}

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

    // MARK: - App Delegate

    /// Connect the AppDelegate for notification handling
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - State

    /// The shared app state - holds current user and all shared data
    @State private var appState = AppState()

    /// Initialize any app-wide settings when the app launches
    init() {
        #if DEBUG
        // For CoreGraphics NaN tracing, set scheme env var CG_NUMERICS_SHOW_BACKTRACE=1.
        #endif
        configureFirebaseIfAvailable()
        configureAppAppearance()
        configureAnalytics()
        // Note: Deferred API diagnostic test to after app launch for better startup performance
        // The test will run after the launch screen completes
    }

    /// Configure Firebase when plist is available.
    /// Add `GoogleService-Info_CT.plist` at the project root for device testing.
    private func configureFirebaseIfAvailable() {
        if AppState.shouldDisableFirebase {
            Log.debug("[Firebase] Disabled by launch argument.")
            return
        }

        guard FirebaseConfigurator.configureIfPossible() else {
            #if DEBUG
            Log.warning("[Firebase] GoogleService-Info plist missing in Debug. Firebase is disabled.")
            #else
            fatalError("Missing GoogleService-Info.plist required for Release build.")
            #endif
            return
        }
    }

    // MARK: - Analytics Configuration

    /// Configure and initialize analytics
    private func configureAnalytics() {
        // Initialize analytics from runtime configuration.
        Task { @MainActor in
            AnalyticsService.shared.initialize()

            // Track app opened
            AnalyticsService.shared.trackAppOpened()
        }
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
    @Environment(\.scenePhase) private var scenePhase
    @State private var showLaunchScreen = !(AppState.isUITesting || AppState.isScreenshotMode)
    @State private var hasAttemptedAuthBootstrap = false

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
            guard showLaunchScreen else { return }

            // Dismiss launch screen after animation completes (~4 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLaunchScreen = false
                }
            }
        }
        .task {
            guard !hasAttemptedAuthBootstrap else { return }
            hasAttemptedAuthBootstrap = true
            guard FirebaseConfigurator.isConfigured else { return }
            await AuthManager.shared.ensureSignedIn(appState: appState)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Start service timers
                CosmicTickerService.shared.startRefreshTimer()
                MercuryRetrogradeService.shared.startRefreshTimer()
            case .background, .inactive:
                // Stop service timers to save battery
                CosmicTickerService.shared.stopRefreshTimer()
                MercuryRetrogradeService.shared.stopRefreshTimer()
            @unknown default:
                break
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
