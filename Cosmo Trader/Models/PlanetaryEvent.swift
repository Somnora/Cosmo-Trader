import Foundation

// MARK: - PlanetaryEvent
// =======================
// Represents cosmic events that affect the horoscope generator.
//
// Events include:
// - Retrogrades (Mercury, Venus, Mars, etc.)
// - Conjunctions (planetary alignments)
// - Moon phases
// - Planetary transits
//
// Each event affects certain signs or elements and contributes
// to the daily horoscope generation.

struct PlanetaryEvent: Identifiable {
    let id = UUID()
    let type: PlanetaryEventType
    let planet: String
    let title: String
    let description: String
    let icon: String
    let affectedSigns: [ZodiacSign]
    let affectedElements: [ZodiacSign.Element]
    let startDate: Date
    let endDate: Date?

    /// Is this event currently active?
    var isActive: Bool {
        let now = Date()
        if let end = endDate {
            return now >= startDate && now <= end
        }
        return now >= startDate
    }
}

// MARK: - Event Types

enum PlanetaryEventType: String, CaseIterable {
    case retrograde = "Retrograde"
    case conjunction = "Conjunction"
    case moonPhase = "Moon Phase"
    case transit = "Transit"

    var icon: String {
        switch self {
        case .retrograde: return "arrow.uturn.backward.circle"
        case .conjunction: return "circle.grid.cross"
        case .moonPhase: return "moon.stars"
        case .transit: return "arrow.right.circle"
        }
    }
}

// MARK: - Moon Phase
// MoonPhase enum is defined in MoonPhase.swift
// This file uses that definition for moon phase calculations

// MARK: - Mock Current Events

extension PlanetaryEvent {

    /// Current mock planetary events
    static var currentEvents: [PlanetaryEvent] {
        let calendar = Calendar.current
        let today = Date()

        return [
            // Mercury Retrograde (affects communication, tech, Air signs)
            PlanetaryEvent(
                type: .retrograde,
                planet: "Mercury",
                title: "Mercury Retrograde",
                description: "Communication and technology face cosmic turbulence. Double-check everything—especially your trades.",
                icon: "arrow.uturn.backward.circle",
                affectedSigns: [.gemini, .virgo],
                affectedElements: [.air],
                startDate: calendar.date(byAdding: .day, value: -10, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 10, to: today)
            ),

            // Venus-Jupiter Conjunction (prosperity, luck)
            PlanetaryEvent(
                type: .conjunction,
                planet: "Venus-Jupiter",
                title: "Venus-Jupiter Conjunction",
                description: "The planet of value meets the planet of expansion. Optimism runs high—guard against overconfidence.",
                icon: "circle.grid.cross",
                affectedSigns: [.taurus, .libra, .sagittarius, .pisces],
                affectedElements: [.earth, .fire],
                startDate: calendar.date(byAdding: .day, value: -3, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 3, to: today)
            ),

            // Current Moon Phase
            PlanetaryEvent(
                type: .moonPhase,
                planet: "Moon",
                title: MoonPhase.from(date: today).rawValue,
                description: MoonPhase.from(date: today).description,
                icon: MoonPhase.from(date: today).icon,
                affectedSigns: [.cancer],
                affectedElements: [.water],
                startDate: today,
                endDate: nil
            ),

            // Mars Transit (energy, action, Fire signs)
            PlanetaryEvent(
                type: .transit,
                planet: "Mars",
                title: "Mars in Aries",
                description: "The warrior planet returns home. Bold moves are favored, but aggression backfires.",
                icon: "arrow.right.circle",
                affectedSigns: [.aries, .scorpio],
                affectedElements: [.fire],
                startDate: calendar.date(byAdding: .day, value: -20, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 25, to: today)
            ),

            // Saturn Transit (discipline, Earth signs)
            PlanetaryEvent(
                type: .transit,
                planet: "Saturn",
                title: "Saturn in Pisces",
                description: "Structure meets dreams. Practical magic is possible if you put in the work.",
                icon: "clock.badge.checkmark",
                affectedSigns: [.pisces, .capricorn, .aquarius],
                affectedElements: [.water, .earth],
                startDate: calendar.date(byAdding: .month, value: -6, to: today)!,
                endDate: calendar.date(byAdding: .month, value: 18, to: today)
            )
        ]
    }

    /// Get today's moon phase
    static var currentMoonPhase: MoonPhase {
        MoonPhase.from(date: Date())
    }

    /// Featured events (first 3 most relevant)
    static var featuredEvents: [PlanetaryEvent] {
        Array(currentEvents.filter { $0.isActive }.prefix(3))
    }
}

// MARK: - Cosmic Weather Summary

/// A summary of current cosmic conditions
struct CosmicWeather {
    let moonPhase: MoonPhase
    let activeEvents: [PlanetaryEvent]
    let overallEnergy: CosmicEnergy
    let advice: String

    /// Overall cosmic energy level
    enum CosmicEnergy: String {
        case intense = "Intense"
        case active = "Active"
        case balanced = "Balanced"
        case calm = "Calm"
        case turbulent = "Turbulent"

        var color: String {
            switch self {
            case .intense: return "red"
            case .active: return "orange"
            case .balanced: return "green"
            case .calm: return "blue"
            case .turbulent: return "purple"
            }
        }

        var icon: String {
            switch self {
            case .intense: return "flame"
            case .active: return "bolt"
            case .balanced: return "equal.circle"
            case .calm: return "leaf"
            case .turbulent: return "tornado"
            }
        }
    }

    /// Generate current cosmic weather
    static var current: CosmicWeather {
        let events = PlanetaryEvent.featuredEvents
        let moonPhase = PlanetaryEvent.currentMoonPhase

        // Determine overall energy based on events
        let hasRetrograde = events.contains { $0.type == .retrograde }
        let hasConjunction = events.contains { $0.type == .conjunction }

        let energy: CosmicEnergy
        let advice: String

        if hasRetrograde && hasConjunction {
            energy = .turbulent
            advice = "Mixed signals from the cosmos. Proceed with awareness, not recklessness."
        } else if hasRetrograde {
            energy = .intense
            advice = "Review and reflect before acting. The stars reward patience today."
        } else if hasConjunction {
            energy = .active
            advice = "Cosmic amplification is in effect. Your actions carry extra weight."
        } else if moonPhase == .fullMoon {
            energy = .intense
            advice = "Full moon energy peaks. Emotions run high—in markets and in life."
        } else if moonPhase == .newMoon {
            energy = .calm
            advice = "A quiet cosmic moment. Plant seeds for future growth."
        } else {
            energy = .balanced
            advice = "Steady cosmic conditions. The stars neither push nor pull today."
        }

        return CosmicWeather(
            moonPhase: moonPhase,
            activeEvents: events,
            overallEnergy: energy,
            advice: advice
        )
    }
}
