import Foundation

@MainActor
@Observable
final class AstroOverlayEventService {
    static let shared = AstroOverlayEventService()

    private let moonService = MoonPhaseService.shared
    private let retrogradeProvider = MercuryRetrogradeEphemerisProvider.shared
    private let calendar = Calendar.current

    private init() {}

    func upcomingEvents(
        for stock: Stock,
        from startDate: Date = Date(),
        days: Int = 30,
        filters: AstroOverlayFilterState? = nil
    ) -> [AstroOverlayEvent] {
        let clampedDays = max(1, min(days, 90))
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: clampedDays, to: start) ?? start
        let activeFilters = filters ?? .stockCosmicCalendar

        return events(
            for: stock,
            from: start,
            to: end,
            filters: activeFilters
        )
    }

    func events(
        for stock: Stock,
        from startDate: Date,
        to endDate: Date,
        filters: AstroOverlayFilterState
    ) -> [AstroOverlayEvent] {
        guard startDate <= endDate else { return [] }

        var events: [AstroOverlayEvent] = []

        if filters.enabledKinds.contains(.newMoon)
            || filters.enabledKinds.contains(.fullMoon)
            || filters.enabledKinds.contains(.firstQuarter)
            || filters.enabledKinds.contains(.lastQuarter) {
            events.append(contentsOf: moonPhaseEvents(from: startDate, to: endDate, filters: filters))
        }

        if filters.enabledKinds.contains(.moonInSign) {
            events.append(contentsOf: moonInCompanySignEvents(for: stock, from: startDate, to: endDate))
        }

        if filters.enabledKinds.contains(.mercuryRetrograde) {
            events.append(contentsOf: retrogradeProvider.events(from: startDate, to: endDate))
        }

        if filters.enabledKinds.contains(.companyBirthMonth) {
            events.append(contentsOf: companyBirthMonthEvents(for: stock, from: startDate, to: endDate))
        }

        if filters.enabledKinds.contains(.companyFoundingAnniversary) {
            events.append(contentsOf: companyFoundingAnniversaryEvents(for: stock, from: startDate, to: endDate))
        }

        return events
            .filter { filters.showEstimatedEvents || !$0.isEstimated }
            .sorted { $0.markerDate < $1.markerDate }
    }

    private func moonPhaseEvents(
        from startDate: Date,
        to endDate: Date,
        filters: AstroOverlayFilterState
    ) -> [AstroOverlayEvent] {
        var results: [AstroOverlayEvent] = []
        var date = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        var previousPhase: MoonPhase?

        while date <= end {
            let lunarData = moonService.getLunarData(for: date)
            let phase = lunarData.phase

            if phase != previousPhase,
               let kind = AstroOverlayEventKind(phase: phase),
               filters.enabledKinds.contains(kind) {
                results.append(AstroOverlayEvent(
                    id: "moon-\(kind.rawValue)-\(Self.idDateFormatter.string(from: date))",
                    kind: kind,
                    title: kind.displayName,
                    subtitle: "Illumination \(lunarData.formattedIllumination)",
                    startDate: date,
                    endDate: nil,
                    markerDate: date,
                    intensity: phase == .fullMoon || phase == .newMoon ? .high : .medium,
                    affectedElements: [lunarData.moonSign.element],
                    affectedSectors: [],
                    iconSystemName: kind.iconSystemName,
                    source: .calculatedMoonPhase,
                    isEstimated: false
                ))
            }

            previousPhase = phase
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? end.addingTimeInterval(86400)
        }

        return results
    }

    private func moonInCompanySignEvents(
        for stock: Stock,
        from startDate: Date,
        to endDate: Date
    ) -> [AstroOverlayEvent] {
        guard stock.supportsCompanyOverlayEvents,
              let targetSign = stock.foundedZodiacSign else { return [] }

        var results: [AstroOverlayEvent] = []
        var date = startDate
        var activeStart: Date?

        while date <= endDate {
            let isInTargetSign = moonService.getLunarData(for: date).moonSign == targetSign

            if isInTargetSign && activeStart == nil {
                activeStart = date
            } else if !isInTargetSign, let start = activeStart {
                results.append(moonInSignEvent(stock: stock, sign: targetSign, start: start, end: date))
                activeStart = nil
            }

            date = calendar.date(byAdding: .hour, value: 12, to: date) ?? endDate.addingTimeInterval(1)
        }

        if let start = activeStart {
            results.append(moonInSignEvent(stock: stock, sign: targetSign, start: start, end: endDate))
        }

        return results
    }

    private func moonInSignEvent(stock: Stock, sign: ZodiacSign, start: Date, end: Date) -> AstroOverlayEvent {
        return AstroOverlayEvent(
            id: "moon-in-\(sign.rawValue)-\(Self.idDateFormatter.string(from: start))",
            kind: .moonInSign,
            title: "Moon In \(sign.displayName)",
            subtitle: "\(stock.symbol) company sign",
            startDate: start,
            endDate: end,
            markerDate: start,
            intensity: .medium,
            affectedElements: [sign.element],
            affectedSectors: [marketSector(for: stock.sector)].compactMap { $0 },
            iconSystemName: AstroOverlayEventKind.moonInSign.iconSystemName,
            source: .calculatedMoonSign,
            isEstimated: false
        )
    }

    private func companyBirthMonthEvents(
        for stock: Stock,
        from startDate: Date,
        to endDate: Date
    ) -> [AstroOverlayEvent] {
        guard stock.supportsCompanyOverlayEvents,
              let foundedDate = stock.foundedDate,
              let sign = stock.foundedZodiacSign else { return [] }

        let foundingComponents = calendar.dateComponents([.month, .year], from: foundedDate)
        guard let foundedMonth = foundingComponents.month,
              let foundedYear = foundingComponents.year else { return [] }

        let range = yearRange(from: startDate, to: endDate)
        return range.compactMap { year in
            let monthStartComponents = DateComponents(year: year, month: foundedMonth, day: 1)
            guard let monthStart = calendar.date(from: monthStartComponents),
                  let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else {
                return nil
            }

            let monthEnd = monthInterval.end.addingTimeInterval(-1)
            guard monthEnd >= startDate && monthStart <= endDate else { return nil }

            return AstroOverlayEvent(
                id: "birth-month-\(stock.symbol)-\(year)",
                kind: .companyBirthMonth,
                title: "Birth Month",
                subtitle: "Founded \(monthName(foundedMonth)) \(foundedYear)",
                startDate: monthStart,
                endDate: monthEnd,
                markerDate: monthStart,
                intensity: .medium,
                affectedElements: [sign.element],
                affectedSectors: [marketSector(for: stock.sector)].compactMap { $0 },
                iconSystemName: AstroOverlayEventKind.companyBirthMonth.iconSystemName,
                source: .companyFoundedDate,
                isEstimated: false
            )
        }
    }

    private func companyFoundingAnniversaryEvents(
        for stock: Stock,
        from startDate: Date,
        to endDate: Date
    ) -> [AstroOverlayEvent] {
        guard stock.supportsCompanyOverlayEvents,
              let foundedDate = stock.foundedDate,
              let sign = stock.foundedZodiacSign else { return [] }

        let foundingComponents = calendar.dateComponents([.month, .day, .year], from: foundedDate)
        guard let month = foundingComponents.month,
              let day = foundingComponents.day,
              let foundedYear = foundingComponents.year else { return [] }

        return yearRange(from: startDate, to: endDate).compactMap { year in
            let components = DateComponents(year: year, month: month, day: day)
            guard let anniversary = calendar.date(from: components),
                  anniversary >= startDate,
                  anniversary <= endDate else {
                return nil
            }

            let age = max(0, year - foundedYear)
            return AstroOverlayEvent(
                id: "founding-day-\(stock.symbol)-\(year)",
                kind: .companyFoundingAnniversary,
                title: "Founding Day",
                subtitle: age > 0 ? "\(stock.name) turns \(age)" : "Founded \(year)",
                startDate: anniversary,
                endDate: nil,
                markerDate: anniversary,
                intensity: .high,
                affectedElements: [sign.element],
                affectedSectors: [marketSector(for: stock.sector)].compactMap { $0 },
                iconSystemName: AstroOverlayEventKind.companyFoundingAnniversary.iconSystemName,
                source: .companyFoundedDate,
                isEstimated: false
            )
        }
    }

    private func yearRange(from startDate: Date, to endDate: Date) -> ClosedRange<Int> {
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        return min(startYear, endYear)...max(startYear, endYear)
    }

    private func monthName(_ month: Int) -> String {
        DateFormatter().monthSymbols[max(0, min(month - 1, 11))]
    }

    private func marketSector(for sector: String) -> MarketSector? {
        let normalized = sector.lowercased()

        if normalized.contains("tech") { return .technology }
        if normalized.contains("finance") || normalized.contains("bank") { return .finance }
        if normalized.contains("health") { return .healthcare }
        if normalized.contains("energy") { return .energy }
        if normalized.contains("consumer") || normalized.contains("retail") { return .consumer }
        if normalized.contains("communication") || normalized.contains("media") { return .communications }
        if normalized.contains("industrial") { return .industrials }
        if normalized.contains("material") { return .materials }
        if normalized.contains("utilit") { return .utilities }
        if normalized.contains("real estate") { return .realEstate }
        if normalized.contains("crypto") { return .crypto }

        return nil
    }

    private static let idDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}

private extension AstroOverlayEventKind {
    init?(phase: MoonPhase) {
        switch phase {
        case .newMoon:
            self = .newMoon
        case .fullMoon:
            self = .fullMoon
        case .firstQuarter:
            self = .firstQuarter
        case .lastQuarter:
            self = .lastQuarter
        default:
            return nil
        }
    }
}
