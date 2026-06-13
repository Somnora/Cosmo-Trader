import Foundation

// MARK: - Astro Overlay Event
// ============================
// Historical cosmic context rendered against real OHLC price data.

struct AstroOverlayEvent: Identifiable, Codable, Equatable {
    let id: String
    let kind: AstroOverlayEventKind
    let title: String
    let subtitle: String?
    let startDate: Date
    let endDate: Date?
    let markerDate: Date
    let intensity: AstroOverlayIntensity
    let affectedElements: [ZodiacSign.Element]
    let affectedSectors: [MarketSector]
    let iconSystemName: String
    let source: AstroOverlaySource
    let isEstimated: Bool

    var isRange: Bool {
        guard let endDate else { return false }
        return !Calendar.current.isDate(endDate, inSameDayAs: startDate)
    }

    var dateInterval: DateInterval {
        DateInterval(start: startDate, end: endDate ?? startDate)
    }

    var accessibilityDescription: String {
        if isRange, let endDate {
            return "\(title), \(DateFormatter.astroOverlayShort.string(from: startDate)) to \(DateFormatter.astroOverlayShort.string(from: endDate))"
        }
        return "\(title), \(DateFormatter.astroOverlayShort.string(from: markerDate))"
    }
}

enum AstroOverlayEventKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case newMoon
    case fullMoon
    case firstQuarter
    case lastQuarter
    case moonInSign
    case mercuryRetrograde
    case companyBirthMonth
    case companyFoundingAnniversary
    case eclipse
    case planetaryIngress

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newMoon: return "New Moon"
        case .fullMoon: return "Full Moon"
        case .firstQuarter: return "First Quarter"
        case .lastQuarter: return "Last Quarter"
        case .moonInSign: return "Moon In Sign"
        case .mercuryRetrograde: return "Mercury Rx"
        case .companyBirthMonth: return "Birth Month"
        case .companyFoundingAnniversary: return "Founding Day"
        case .eclipse: return "Eclipse"
        case .planetaryIngress: return "Ingress"
        }
    }

    var shortLabel: String {
        switch self {
        case .newMoon, .fullMoon, .firstQuarter, .lastQuarter:
            return "Moon Phases"
        case .companyFoundingAnniversary:
            return "Founding Day"
        default:
            return displayName
        }
    }

    var iconSystemName: String {
        switch self {
        case .newMoon: return "moon"
        case .fullMoon: return "moon.circle.fill"
        case .firstQuarter, .lastQuarter: return "moonphase.first.quarter"
        case .moonInSign: return "moon.stars.fill"
        case .mercuryRetrograde: return "arrow.uturn.backward.circle.fill"
        case .companyBirthMonth: return "calendar"
        case .companyFoundingAnniversary: return "building.2.fill"
        case .eclipse: return "moon.haze.fill"
        case .planetaryIngress: return "arrow.right.circle.fill"
        }
    }
}

enum AstroOverlayIntensity: String, Codable, CaseIterable {
    case low
    case medium
    case high
}

enum AstroOverlaySource: String, Codable {
    case calculatedMoonPhase
    case calculatedMoonSign
    case verifiedEphemeris
    case companyFoundedDate
    case curatedDataset

    var displayLabel: String {
        switch self {
        case .calculatedMoonPhase:
            return "Calculated moon phase"
        case .calculatedMoonSign:
            return "Calculated moon sign"
        case .verifiedEphemeris:
            return "Verified ephemeris"
        case .companyFoundedDate:
            return "Company founding metadata"
        case .curatedDataset:
            return "Curated ephemeris"
        }
    }
}

struct AstroOverlayFilterState: Codable, Equatable {
    var enabledKinds: Set<AstroOverlayEventKind> = [
        .newMoon,
        .fullMoon,
        .mercuryRetrograde,
        .companyBirthMonth,
        .companyFoundingAnniversary
    ]

    var showEstimatedEvents: Bool = true
    var eventWindowDays: Int = 3

    static let defaultKinds: [AstroOverlayEventKind] = [
        .newMoon,
        .fullMoon,
        .mercuryRetrograde,
        .companyBirthMonth,
        .companyFoundingAnniversary
    ]

    static let optionalKinds: [AstroOverlayEventKind] = [
        .moonInSign,
        .firstQuarter,
        .lastQuarter
    ]

    static let stockCosmicCalendar = AstroOverlayFilterState(
        enabledKinds: [
            .newMoon,
            .fullMoon,
            .mercuryRetrograde,
            .moonInSign,
            .companyBirthMonth,
            .companyFoundingAnniversary
        ],
        showEstimatedEvents: true,
        eventWindowDays: 3
    )
}

extension DateFormatter {
    static let astroOverlayShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    static let astroOverlayMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}
