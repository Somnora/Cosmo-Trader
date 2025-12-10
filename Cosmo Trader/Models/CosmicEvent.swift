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

    var emoji: String {
        switch self {
        case .mercuryRetrograde: return "☿️"
        case .fullMoon: return "🌕"
        case .newMoon: return "🌑"
        case .lunarEclipse: return "🌒"
        case .solarEclipse: return "🌘"
        case .planetaryIngress: return "➡️"
        case .venusRetrograde: return "♀️"
        case .marsRetrograde: return "♂️"
        case .jupiterRetrograde: return "♃"
        case .saturnRetrograde: return "♄"
        }
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

enum MarketSector: String, CaseIterable {
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
                description: "The cosmic trickster is at it again. Mercury stations retrograde in truth-seeking Sagittarius, turning our grand plans into cosmic comedy. Expect miscommunications, tech glitches, and your ex to mysteriously resurface.",
                advice: "Triple-check every trade confirmation. Read the fine print twice. Maybe three times. Actually, just screenshot everything.",
                warningMessage: "Maybe don't YOLO into crypto this week. Just a thought.",
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
                description: "Emotions are running high and your portfolio might feel the cosmic tide. This nurturing lunar peak illuminates matters of security, home, and what truly makes you feel safe. Including your savings account.",
                advice: "Avoid making impulsive trades based on feelings. That gut instinct? It might just be anxiety. Sleep on it.",
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
                description: "The ambitious goat energy meets lunar new beginnings. A powerful time to set long-term financial goals and get serious about your portfolio strategy. The stars favor discipline over dreams.",
                advice: "Perfect time to research that blue-chip stock you've been eyeing. Plant seeds now for Q2 harvest.",
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
                description: "The planet of value and attraction enters the sign of innovation and rebellion. Suddenly, those unconventional investments look a lot more appealing. Tech stocks get a cosmic glow-up.",
                advice: "Good time to explore innovative sectors. Just remember: disruptive doesn't always mean profitable.",
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
                description: "A dramatic cosmic curtain call in the sign of the spotlight. Hidden truths emerge, especially around leadership and creative ventures. Some CEOs might be sweating right now.",
                advice: "Watch for surprising earnings reports and unexpected executive announcements. Stay nimble.",
                warningMessage: "High volatility window. Consider reducing position sizes.",
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
                description: "The planet of action and aggression takes a cosmic nap in detail-oriented Virgo. Projects stall, energy dips, and that aggressive trading strategy suddenly feels exhausting.",
                advice: "Review and refine rather than initiate. Your analysis paralysis might actually be cosmic wisdom for once.",
                warningMessage: "Avoid starting new high-risk positions. Patience, warrior.",
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
                description: "The planet of luck and expansion enters the sign of communication and duality. Information is currency, and those who can process data fastest win. Hello, AI stocks.",
                advice: "Diversification is your friend. Jupiter in Gemini rewards spreading your bets across multiple opportunities.",
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
                description: "A blazing reset in the sign of new beginnings. Solar eclipses bring sudden shifts and fresh starts. The universe is hitting refresh on your financial identity.",
                advice: "Be ready to pivot. Old strategies may suddenly become obsolete. Watch for breakthrough opportunities.",
                warningMessage: "Major market-moving potential. Keep cash reserves ready.",
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
                description: "The planet of value goes inward in intense Scorpio. Time to reassess what you truly value in your portfolio. Those emotional attachments to losing stocks? Yeah, we need to talk.",
                advice: "Review holdings you've been sentimental about. Is it love or denial?",
                warningMessage: "Avoid major luxury purchases. That Tesla might look different in 6 weeks.",
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
                description: "The most intense full moon of the year. Secrets surface, power dynamics shift, and your deepest financial fears might come up for air. Transformation is non-negotiable.",
                advice: "Great time for portfolio deep-cleaning. What's really dragging you down?",
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
                description: "The cosmic taskmaster goes introspective. Structures you thought were solid might wobble. Time to reinforce your portfolio foundation—or admit some strategies were built on vibes.",
                advice: "Review your risk management. Are your stop-losses actually set?",
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
                description: "The dreamiest new moon invites you to invest with intuition. Imagination meets manifestation. What do you really want your portfolio to become?",
                advice: "Set intentions for your investment journey. Vision boards allowed.",
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
