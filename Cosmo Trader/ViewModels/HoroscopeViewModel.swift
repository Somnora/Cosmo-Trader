import Foundation
import SwiftUI

// MARK: - HoroscopeViewModel
// ===========================
// The brain behind the Cosmos tab.
//
// Responsibilities:
// - Generate daily horoscopes using HoroscopeGenerator
// - Provide current cosmic weather data
// - Handle refresh/regenerate actions
// - Format dates and manage animation states
//
// Now works with AppState for shared user data.

@Observable
class HoroscopeViewModel {

    // MARK: - Properties

    /// Reference to shared app state
    private var appState: AppState

    /// The generated daily horoscope
    var horoscope: DailyHoroscope?

    /// Current cosmic weather conditions
    var cosmicWeather: CosmicWeather

    /// Active planetary events
    var planetaryEvents: [PlanetaryEvent]

    /// Loading state
    var isLoading: Bool = false

    /// Animation trigger for refresh
    var refreshTrigger: Bool = false

    // MARK: - Initialization

    init(appState: AppState = AppState.shared) {
        self.appState = appState
        self.cosmicWeather = CosmicWeather.current
        self.planetaryEvents = PlanetaryEvent.featuredEvents

        // Generate initial horoscope only if user exists
        if let currentUser = appState.currentUser {
            self.horoscope = HoroscopeGenerator.generate(for: currentUser)
        }
    }

    // MARK: - Computed Properties

    /// Current user from app state (nil if not logged in)
    var user: UserProfile? {
        appState.currentUser
    }

    /// Today's date formatted nicely
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    /// Current moon phase
    var moonPhase: MoonPhase {
        cosmicWeather.moonPhase
    }

    /// Moon phase icon (SF Symbol name)
    var moonPhaseIcon: String {
        switch moonPhase {
        case .newMoon: return "moon"
        case .waxingCrescent: return "moon.fill"
        case .firstQuarter: return "moonphase.first.quarter"
        case .waxingGibbous: return "moonphase.waxing.gibbous"
        case .fullMoon: return "moonphase.full.moon"
        case .waningGibbous: return "moonphase.waning.gibbous"
        case .lastQuarter: return "moonphase.last.quarter"
        case .waningCrescent: return "moonphase.waning.crescent"
        }
    }

    /// User's sun sign display
    var userSignDisplay: String {
        guard let user = user else { return "" }
        return "\(user.sunSign.textSymbol) \(user.sunSign.displayName)"
    }

    /// Greeting based on time of day
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    /// Horoscope reading text
    var readingText: String {
        horoscope?.reading ?? "Preparing your market astrology reading..."
    }

    /// Dominant element in portfolio (for display)
    var dominantElement: ZodiacSign.Element? {
        horoscope?.dominantElement
    }

    /// Performance sentiment text
    var performanceSentiment: String {
        guard let performance = horoscope?.performance else {
            return "Analyzing..."
        }

        switch performance.sentiment {
        case .veryPositive: return "Thriving"
        case .positive: return "Growing"
        case .flat: return "Steady"
        case .negative: return "Challenged"
        case .veryNegative: return "Tested"
        }
    }

    /// Performance color
    var performanceColor: Color {
        guard let performance = horoscope?.performance else {
            return CosmicTheme.textMuted
        }

        switch performance.sentiment {
        case .veryPositive, .positive:
            return CosmicTheme.positive
        case .flat:
            return CosmicTheme.textSecondary
        case .negative, .veryNegative:
            return CosmicTheme.negative
        }
    }

    /// Overall change percentage
    var overallChangePercent: String {
        guard let change = horoscope?.performance.overallChange else {
            return "0.0%"
        }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change))%"
    }

    // MARK: - Actions

    /// Regenerate the horoscope
    func regenerateHoroscope() {
        guard let user = user else { return }
        isLoading = true
        refreshTrigger.toggle()

        // Simulate brief delay for mystical effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            self.horoscope = HoroscopeGenerator.generate(for: user)
            self.cosmicWeather = CosmicWeather.current
            self.planetaryEvents = PlanetaryEvent.featuredEvents
            self.isLoading = false

            // Sync new reading to home screen widget
            if let reading = self.horoscope?.reading {
                WidgetBridge.shared.syncHoroscopeSnapshot(
                    signName: user.sunSign.displayName,
                    signSymbol: user.sunSign.textSymbol,
                    signElement: user.sunSign.element.displayName,
                    horoscopeText: reading
                )
            }
        }
    }

    /// Refresh cosmic weather
    func refreshCosmicWeather() {
        cosmicWeather = CosmicWeather.current
        planetaryEvents = PlanetaryEvent.featuredEvents
    }
}
