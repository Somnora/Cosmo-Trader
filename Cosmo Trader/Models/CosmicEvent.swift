import Foundation
import SwiftUI

// MARK: - CosmicEvent
// ===================
// Represents significant astrological events that "affect" the market.
//
// Events include:
// - Mercury Retrograde (communication/tech chaos)
// - Full Moons (emotional peaks, volatility)
// - New Moons (fresh starts, new opportunities)
// - Eclipses (major shifts, surprises)
// - Planetary Ingress (planets changing signs)
//
// Each event has witty, Co-Star style advice for traders.

struct CosmicEvent: Identifiable, Equatable {
    let id: UUID
    let type: CosmicEventType
    let title: String
    let subtitle: String
    let description: String
    let advice: String
    let warningMessage: String?
    let startDate: Date
    let endDate: Date
    let intensity: EventIntensity
    let affectedElements: [ZodiacSign.Element]
    let affectedSectors: [MarketSector]
    let icon: String

    init(
        id: UUID = UUID(),
        type: CosmicEventType,
        title: String,
        subtitle: String,
        description: String,
        advice: String,
        warningMessage: String? = nil,
        startDate: Date,
        endDate: Date,
        intensity: EventIntensity,
        affectedElements: [ZodiacSign.Element],
        affectedSectors: [MarketSector],
        icon: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.advice = advice
        self.warningMessage = warningMessage
        self.startDate = startDate
        self.endDate = endDate
        self.intensity = intensity
        self.affectedElements = affectedElements
        self.affectedSectors = affectedSectors
        self.icon = icon ?? type.defaultIcon
    }

    // MARK: - Computed Properties

    /// Is this event currently active?
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    /// Days until event starts (negative if already started)
    var daysUntilStart: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: startDate).day ?? 0
    }

    /// Days remaining in event (0 if not active)
    var daysRemaining: Int {
        guard isActive else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }

    /// Formatted date range string
    var dateRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        return "\(start) - \(end)"
    }

    /// Short status text
    var statusText: String {
        if isActive {
            if daysRemaining == 0 {
                return "Ends today"
            } else if daysRemaining == 1 {
                return "1 day left"
            } else {
                return "\(daysRemaining) days left"
            }
        } else if daysUntilStart > 0 {
            if daysUntilStart == 1 {
                return "Starts tomorrow"
            } else {
                return "In \(daysUntilStart) days"
            }
        } else {
            return "Ended"
        }
    }

    /// Color for the event based on type and intensity
    var themeColor: Color {
        switch type {
        case .mercuryRetrograde:
            return .orange
        case .fullMoon:
            return Color(red: 0.9, green: 0.9, blue: 0.7)
        case .newMoon:
            return Color(red: 0.3, green: 0.3, blue: 0.5)
        case .lunarEclipse:
            return .red
        case .solarEclipse:
            return Color(red: 1.0, green: 0.8, blue: 0.3)
        case .planetaryIngress:
            return .purple
        case .venusRetrograde:
            return .pink
        case .marsRetrograde:
            return .red
        case .jupiterRetrograde:
            return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .saturnRetrograde:
            return Color(red: 0.5, green: 0.5, blue: 0.6)
        }
    }

    static func == (lhs: CosmicEvent, rhs: CosmicEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Cosmic Event Type

enum CosmicEventType: String, CaseIterable {
    case mercuryRetrograde = "Mercury Retrograde"
    case fullMoon = "Full Moon"
    case newMoon = "New Moon"
    case lunarEclipse = "Lunar Eclipse"
    case solarEclipse = "Solar Eclipse"
    case planetaryIngress = "Planetary Ingress"
    case venusRetrograde = "Venus Retrograde"
    case marsRetrograde = "Mars Retrograde"
    case jupiterRetrograde = "Jupiter Retrograde"
    case saturnRetrograde = "Saturn Retrograde"

    var defaultIcon: String {
        switch self {
        case .mercuryRetrograde: return "arrow.uturn.backward.circle.fill"
        case .fullMoon: return "moon.circle.fill"
        case .newMoon: return "moon"
        case .lunarEclipse: return "moon.haze.fill"
        case .solarEclipse: return "sun.haze.fill"
        case .planetaryIngress: return "arrow.right.circle.fill"
        case .venusRetrograde: return "heart.circle.fill"
        case .marsRetrograde: return "flame.circle.fill"
        case .jupiterRetrograde: return "sparkles"
        case .saturnRetrograde: return "clock.badge.exclamationmark"
        }
    }

    var sfSymbol: String {
        defaultIcon  // Use the existing SF Symbol icons
    }

    /// Whether this event type typically causes market "turbulence"
    var isCautionEvent: Bool {
        switch self {
        case .mercuryRetrograde, .lunarEclipse, .solarEclipse, .marsRetrograde:
            return true
        default:
            return false
        }
    }
}

// MARK: - Event Intensity

enum EventIntensity: String, CaseIterable {
    case mild = "Mild"
    case moderate = "Moderate"
    case intense = "Intense"

    var icon: String {
        switch self {
        case .mild: return "circle"
        case .moderate: return "circle.circle"
        case .intense: return "circle.circle.fill"
        }
    }

    var glowRadius: CGFloat {
        switch self {
        case .mild: return 5
        case .moderate: return 10
        case .intense: return 20
        }
    }

    var pulseScale: CGFloat {
        switch self {
        case .mild: return 1.02
        case .moderate: return 1.05
        case .intense: return 1.1
        }
    }
}

// MARK: - Market Sector

enum MarketSector: String, CaseIterable, Codable {
    case technology = "Technology"
    case finance = "Finance"
    case healthcare = "Healthcare"
    case energy = "Energy"
    case consumer = "Consumer"
    case communications = "Communications"
    case industrials = "Industrials"
    case materials = "Materials"
    case utilities = "Utilities"
    case realEstate = "Real Estate"
    case crypto = "Crypto"

    var icon: String {
        switch self {
        case .technology: return "desktopcomputer"
        case .finance: return "dollarsign.circle"
        case .healthcare: return "cross.case"
        case .energy: return "bolt.fill"
        case .consumer: return "cart.fill"
        case .communications: return "antenna.radiowaves.left.and.right"
        case .industrials: return "gearshape.2"
        case .materials: return "cube.box"
        case .utilities: return "lightbulb"
        case .realEstate: return "house"
        case .crypto: return "bitcoinsign.circle"
        }
    }
}

// MARK: - Mock Cosmic Events

struct MockCosmicEvents {

    /// All mock cosmic events spread across the coming months
    static var all: [CosmicEvent] {
        let calendar = Calendar.current
        let today = Date()

        return [
            // 1. Mercury Retrograde (current/active)
            CosmicEvent(
                type: .mercuryRetrograde,
                title: "Mercury Retrograde",
                subtitle: "in Sagittarius",
                description: "Mercury stations retrograde in truth-seeking Sagittarius, raising communication and execution risk. Expect confusing headlines, tech friction, and delayed confirmations.",
                advice: "Mercury retrograde is good for re-reading your notes, not for rushing them. Slow down before you act on anything.",
                warningMessage: "Crypto headlines may read more chaotic than usual; treat with patience.",
                startDate: calendar.date(byAdding: .day, value: -5, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 16, to: today)!,
                intensity: .intense,
                affectedElements: [.air, .fire],
                affectedSectors: [.technology, .communications, .crypto]
            ),

            // 2. Full Moon in Cancer
            CosmicEvent(
                type: .fullMoon,
                title: "Full Moon",
                subtitle: "in Cancer",
                description: "Full moon conditions can heighten volatility around security, home, and rate-sensitive assets. Real estate, consumer, and healthcare exposure may deserve a closer read.",
                advice: "Emotion-led reactions can distort the read. If the thesis still checks out after a cooling-off period, re-read your criteria before acting.",
                warningMessage: nil,
                startDate: calendar.date(byAdding: .day, value: 3, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 4, to: today)!,
                intensity: .moderate,
                affectedElements: [.water],
                affectedSectors: [.realEstate, .consumer, .healthcare]
            ),

            // 3. New Moon in Capricorn
            CosmicEvent(
                type: .newMoon,
                title: "New Moon",
                subtitle: "in Capricorn",
                description: "Capricorn's long-range discipline meets a new moon reset. This favors portfolio planning, risk budgets, and durable balance-sheet stories.",
                advice: "Research quality names and define what would make the thesis worth a closer look.",
                warningMessage: nil,
                startDate: calendar.date(byAdding: .day, value: 18, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 19, to: today)!,
                intensity: .mild,
                affectedElements: [.earth],
                affectedSectors: [.finance, .industrials]
            ),

            // 4. Venus enters Aquarius
            CosmicEvent(
                type: .planetaryIngress,
                title: "Venus Enters Aquarius",
                subtitle: "Innovation meets value",
                description: "The planet of value enters innovation-minded Aquarius. Unconventional and technology-led assets may screen better, but valuation discipline still matters.",
                advice: "Explore innovative sectors, then separate narrative from profitability.",
                warningMessage: nil,
                startDate: calendar.date(byAdding: .day, value: 8, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 32, to: today)!,
                intensity: .mild,
                affectedElements: [.air],
                affectedSectors: [.technology, .communications]
            ),

            // 5. Lunar Eclipse in Leo
            CosmicEvent(
                type: .lunarEclipse,
                title: "Lunar Eclipse",
                subtitle: "in Leo",
                description: "A dramatic eclipse window in Leo can surface leadership, branding, and creative-sector surprises. Watch companies where executive narrative drives valuation.",
                advice: "Watch for surprising earnings reports and unexpected executive announcements. Stay nimble.",
                warningMessage: "High-variance context. Review concentration and risk rules independently.",
                startDate: calendar.date(byAdding: .day, value: 25, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 26, to: today)!,
                intensity: .intense,
                affectedElements: [.fire],
                affectedSectors: [.consumer, .communications, .technology]
            ),

            // 6. Mars Retrograde
            CosmicEvent(
                type: .marsRetrograde,
                title: "Mars Retrograde",
                subtitle: "in Virgo",
                description: "The planet of action turns retrograde in detail-oriented Virgo. Aggressive strategies may lose momentum while operational issues get harder to ignore.",
                advice: "Review and refine rather than initiate. Slower analysis is useful if it improves execution quality.",
                warningMessage: "Cosmic context flag: risk themes may feel amplified. Not a trading instruction.",
                startDate: calendar.date(byAdding: .day, value: 35, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 95, to: today)!,
                intensity: .moderate,
                affectedElements: [.earth, .fire],
                affectedSectors: [.energy, .industrials, .materials]
            ),

            // 7. Jupiter enters Gemini
            CosmicEvent(
                type: .planetaryIngress,
                title: "Jupiter Enters Gemini",
                subtitle: "Expansion meets curiosity",
                description: "The planet of expansion enters communication-driven Gemini. Information velocity, AI infrastructure, and multi-channel distribution may command attention.",
                advice: "Jupiter in Gemini highlights multiple narratives at once; compare them instead of chasing the loudest story.",
                warningMessage: nil,
                startDate: calendar.date(byAdding: .day, value: 45, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 410, to: today)!,
                intensity: .moderate,
                affectedElements: [.air],
                affectedSectors: [.technology, .communications, .finance]
            ),

            // 8. Solar Eclipse in Aries
            CosmicEvent(
                type: .solarEclipse,
                title: "Solar Eclipse",
                subtitle: "in Aries",
                description: "A solar eclipse in Aries marks a reset window for risk appetite, identity, and first-mover narratives. Sudden shifts can change which strategies still fit.",
                advice: "Be ready to pivot if the thesis changes. Watch for genuine breakouts, not just adrenaline.",
                warningMessage: "Major market-moving context. Review liquidity assumptions independently.",
                startDate: calendar.date(byAdding: .day, value: 52, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 53, to: today)!,
                intensity: .intense,
                affectedElements: [.fire],
                affectedSectors: [.technology, .energy, .finance]
            ),

            // 9. Venus Retrograde
            CosmicEvent(
                type: .venusRetrograde,
                title: "Venus Retrograde",
                subtitle: "in Scorpio",
                description: "The planet of value turns inward in Scorpio. This is a reassessment window for conviction, liquidity, and emotional attachment to losing positions.",
                advice: "Review holdings you defend out of habit. Separate long-term thesis from sunk cost.",
                warningMessage: "Luxury and discretionary themes may feel noisy; use fresh validation before treating the context as meaningful.",
                startDate: calendar.date(byAdding: .day, value: 60, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 102, to: today)!,
                intensity: .moderate,
                affectedElements: [.water, .earth],
                affectedSectors: [.consumer, .realEstate, .finance]
            ),

            // 10. Full Moon in Scorpio
            CosmicEvent(
                type: .fullMoon,
                title: "Full Moon",
                subtitle: "in Scorpio",
                description: "A high-intensity full moon in Scorpio can bring hidden leverage, power dynamics, and concentrated financial fears to the surface.",
                advice: "Use the window for portfolio cleanup. Identify which positions are dragging return or distorting risk.",
                warningMessage: nil,
                startDate: calendar.date(byAdding: .day, value: 70, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 71, to: today)!,
                intensity: .intense,
                affectedElements: [.water],
                affectedSectors: [.finance, .healthcare, .energy]
            ),

            // 11. Saturn Retrograde
            CosmicEvent(
                type: .saturnRetrograde,
                title: "Saturn Retrograde",
                subtitle: "in Pisces",
                description: "Saturn retrograde turns the discipline lens inward. Structures that looked stable may need proof: cash flow, risk controls, and position rules.",
                advice: "Review your risk management. Are your guardrails actually written down?",
                warningMessage: nil,
                startDate: calendar.date(byAdding: .day, value: 80, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 220, to: today)!,
                intensity: .mild,
                affectedElements: [.water, .earth],
                affectedSectors: [.finance, .utilities, .realEstate]
            ),

            // 12. New Moon in Pisces
            CosmicEvent(
                type: .newMoon,
                title: "New Moon",
                subtitle: "in Pisces",
                description: "A Pisces new moon supports imagination and thematic thinking, but it needs guardrails. Intuition can help source ideas; validation keeps the read grounded.",
                advice: "Set portfolio intentions, then translate them into criteria, watchlist names, and risk limits.",
                warningMessage: nil,
                startDate: calendar.date(byAdding: .day, value: 90, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 91, to: today)!,
                intensity: .mild,
                affectedElements: [.water],
                affectedSectors: [.healthcare, .consumer]
            ),

            // 13. Mercury enters Aries
            CosmicEvent(
                type: .planetaryIngress,
                title: "Mercury Enters Aries",
                subtitle: "Speed thinking activated",
                description: "Thoughts come fast and furious. The planet of communication enters the sign of impulse. Quick decisions abound—for better or worse.",
                advice: "Fast doesn't mean smart. Let ideas simmer before executing.",
                warningMessage: nil,
                startDate: calendar.date(byAdding: .day, value: 100, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 118, to: today)!,
                intensity: .mild,
                affectedElements: [.fire, .air],
                affectedSectors: [.technology, .communications]
            ),

            // 14. Jupiter Retrograde
            CosmicEvent(
                type: .jupiterRetrograde,
                title: "Jupiter Retrograde",
                subtitle: "in Gemini",
                description: "The planet of growth goes reflective. Expansion pauses for quality control. Those moonshot bets? Time to check if they're still launching.",
                advice: "Consolidate gains. Growth for growth's sake isn't always wise.",
                warningMessage: nil,
                startDate: calendar.date(byAdding: .day, value: 120, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 240, to: today)!,
                intensity: .mild,
                affectedElements: [.air, .fire],
                affectedSectors: [.finance, .technology]
            ),

            // 15. Full Moon in Sagittarius
            CosmicEvent(
                type: .fullMoon,
                title: "Full Moon",
                subtitle: "in Sagittarius",
                description: "The archer's moon illuminates the bigger picture. Where is your portfolio journey taking you? Time to zoom out from the daily charts.",
                advice: "Assess your long-term strategy. Are you still on course?",
                warningMessage: nil,
                startDate: calendar.date(byAdding: .day, value: 130, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 131, to: today)!,
                intensity: .moderate,
                affectedElements: [.fire],
                affectedSectors: [.finance, .consumer, .communications]
            )
        ]
    }
}
