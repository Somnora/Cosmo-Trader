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
    // 2027-2030 source: TransitChart Mercury Retrograde 2010-2038, cross-checked
    // against Lunarium's Retrograde Mercury station-date table.
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
        .estimated(id: "2026-10", start: "2026-10-24", end: "2026-11-13", sign: "Scorpio"),
        .estimated(id: "2027-02", start: "2027-02-09", end: "2027-03-03", sign: "Pisces to Aquarius"),
        .estimated(id: "2027-06", start: "2027-06-10", end: "2027-07-04", sign: "Cancer to Gemini"),
        .estimated(id: "2027-10", start: "2027-10-07", end: "2027-10-28", sign: "Scorpio to Libra"),
        .estimated(id: "2028-01", start: "2028-01-24", end: "2028-02-14", sign: "Aquarius"),
        .estimated(id: "2028-05", start: "2028-05-21", end: "2028-06-14", sign: "Gemini"),
        .estimated(id: "2028-09", start: "2028-09-19", end: "2028-10-11", sign: "Libra"),
        .estimated(id: "2029-01", start: "2029-01-07", end: "2029-01-27", sign: "Aquarius to Capricorn"),
        .estimated(id: "2029-05", start: "2029-05-01", end: "2029-05-25", sign: "Taurus"),
        .estimated(id: "2029-09", start: "2029-09-02", end: "2029-09-25", sign: "Libra to Virgo"),
        .estimated(id: "2029-12", start: "2029-12-22", end: "2030-01-11", sign: "Capricorn"),
        .estimated(id: "2030-04", start: "2030-04-13", end: "2030-05-06", sign: "Taurus to Aries"),
        .estimated(id: "2030-08", start: "2030-08-16", end: "2030-09-08", sign: "Virgo"),
        .estimated(id: "2030-12", start: "2030-12-06", end: "2030-12-25", sign: "Capricorn to Sagittarius")
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
