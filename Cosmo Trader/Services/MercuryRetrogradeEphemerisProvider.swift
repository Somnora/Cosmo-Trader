import Foundation

struct MercuryRetrogradeWindow: Codable, Identifiable, Equatable {
    let id: String
    let startDate: Date
    let endDate: Date
    let shadowStartDate: Date?
    let shadowEndDate: Date?
    let signName: String?
    let isEstimated: Bool
}

final class MercuryRetrogradeEphemerisProvider {
    static let shared = MercuryRetrogradeEphemerisProvider()

    private init() {}

    func windows(from startDate: Date, to endDate: Date) -> [MercuryRetrogradeWindow] {
        allWindows.filter { window in
            window.startDate <= endDate && window.endDate >= startDate
        }
    }

    func events(from startDate: Date, to endDate: Date) -> [AstroOverlayEvent] {
        windows(from: startDate, to: endDate).map { window in
            AstroOverlayEvent(
                id: "mercury-rx-\(window.id)",
                kind: .mercuryRetrograde,
                title: "Mercury Retrograde",
                subtitle: window.isEstimated ? "\(window.signName ?? "Estimated window")" : window.signName,
                startDate: window.startDate,
                endDate: window.endDate,
                markerDate: window.startDate,
                intensity: .high,
                affectedElements: [],
                affectedSectors: [.technology, .communications, .finance],
                iconSystemName: AstroOverlayEventKind.mercuryRetrograde.iconSystemName,
                source: .curatedDataset,
                isEstimated: window.isEstimated
            )
        }
    }

    // MVP dataset. These ranges are curated constants and intentionally marked
    // estimated until a signed ephemeris resource is added to the app bundle.
    private let allWindows: [MercuryRetrogradeWindow] = [
        .estimated(id: "2021-01", start: "2021-01-30", end: "2021-02-20", sign: "Aquarius"),
        .estimated(id: "2021-05", start: "2021-05-29", end: "2021-06-22", sign: "Gemini"),
        .estimated(id: "2021-09", start: "2021-09-27", end: "2021-10-18", sign: "Libra"),
        .estimated(id: "2022-01", start: "2022-01-14", end: "2022-02-03", sign: "Aquarius to Capricorn"),
        .estimated(id: "2022-05", start: "2022-05-10", end: "2022-06-03", sign: "Gemini to Taurus"),
        .estimated(id: "2022-09", start: "2022-09-09", end: "2022-10-02", sign: "Libra to Virgo"),
        .estimated(id: "2022-12", start: "2022-12-29", end: "2023-01-18", sign: "Capricorn"),
        .estimated(id: "2023-04", start: "2023-04-21", end: "2023-05-14", sign: "Taurus"),
        .estimated(id: "2023-08", start: "2023-08-23", end: "2023-09-15", sign: "Virgo"),
        .estimated(id: "2023-12", start: "2023-12-13", end: "2024-01-01", sign: "Sagittarius to Capricorn"),
        .estimated(id: "2024-04", start: "2024-04-01", end: "2024-04-25", sign: "Aries"),
        .estimated(id: "2024-08", start: "2024-08-05", end: "2024-08-28", sign: "Virgo to Leo"),
        .estimated(id: "2024-11", start: "2024-11-25", end: "2024-12-15", sign: "Sagittarius"),
        .estimated(id: "2025-03", start: "2025-03-14", end: "2025-04-07", sign: "Aries to Pisces"),
        .estimated(id: "2025-07", start: "2025-07-17", end: "2025-08-11", sign: "Leo"),
        .estimated(id: "2025-11", start: "2025-11-09", end: "2025-11-29", sign: "Sagittarius to Scorpio"),
        .estimated(id: "2026-02", start: "2026-02-26", end: "2026-03-20", sign: "Pisces"),
        .estimated(id: "2026-06", start: "2026-06-29", end: "2026-07-23", sign: "Cancer"),
        .estimated(id: "2026-10", start: "2026-10-24", end: "2026-11-13", sign: "Scorpio")
    ]
}

private extension MercuryRetrogradeWindow {
    static func estimated(id: String, start: String, end: String, sign: String) -> MercuryRetrogradeWindow {
        MercuryRetrogradeWindow(
            id: id,
            startDate: Date.isoDate(start),
            endDate: Date.isoDate(end),
            shadowStartDate: nil,
            shadowEndDate: nil,
            signName: sign,
            isEstimated: true
        )
    }
}

private extension Date {
    static func isoDate(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
