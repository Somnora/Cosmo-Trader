import Foundation
import SwiftUI

// MARK: - IPO Service
// ====================
// Service for fetching and managing IPO data.
// Currently uses mock data, but designed to integrate with real APIs (e.g., Finnhub IPO calendar).

@Observable
final class IPOService {

    // MARK: - Singleton

    static let shared = IPOService()

    // MARK: - State

    /// All IPOs
    private(set) var ipos: [IPO] = []

    /// Is currently loading
    private(set) var isLoading: Bool = false

    /// Last fetch error
    private(set) var lastError: Error?

    /// Last successful fetch time
    private(set) var lastFetchTime: Date?

    /// Cache duration (5 minutes for mock data)
    private let cacheDuration: TimeInterval = 300

    // MARK: - Init

    private init() {
        // Load initial data
        loadMockData()
    }

    // MARK: - Public Methods

    /// Get all upcoming IPOs (not yet launched)
    func getUpcomingIPOs() -> [IPO] {
        ipos.filter { !$0.hasLaunched }
            .sorted { $0.expectedDate < $1.expectedDate }
    }

    /// Get IPOs happening this month
    func getIPOsThisMonth() -> [IPO] {
        ipos.filter { $0.isThisMonth && !$0.hasLaunched }
            .sorted { $0.expectedDate < $1.expectedDate }
    }

    /// Get IPOs happening this week
    func getIPOsThisWeek() -> [IPO] {
        ipos.filter { $0.isThisWeek && !$0.hasLaunched }
            .sorted { $0.expectedDate < $1.expectedDate }
    }

    /// Get IPOs by sector
    func getIPOsBySector(_ sector: String) -> [IPO] {
        ipos.filter { $0.sector == sector && !$0.hasLaunched }
            .sorted { $0.expectedDate < $1.expectedDate }
    }

    /// Get IPOs by zodiac sign
    func getIPOsBySign(_ sign: ZodiacSign) -> [IPO] {
        ipos.filter { $0.zodiacSign == sign && !$0.hasLaunched }
    }

    /// Get highly compatible IPOs for user
    func getHighlyCompatibleIPOs(for user: UserProfile, minScore: Int = 80) -> [IPO] {
        ipos.filter { !$0.hasLaunched && $0.compatibility(with: user).score >= minScore }
            .sorted { $0.compatibility(with: user).score > $1.compatibility(with: user).score }
    }

    /// Get IPO alerts for user (highly compatible, coming soon)
    func getIPOAlerts(for user: UserProfile) -> [IPOAlert] {
        let compatibleIPOs = ipos.filter { ipo in
            ipo.isThisWeek &&
            !ipo.hasLaunched &&
            ipo.compatibility(with: user).score >= 80
        }

        return compatibleIPOs.map { ipo in
            let compat = ipo.compatibility(with: user)
            return IPOAlert(
                ipo: ipo,
                compatibilityScore: compat.score,
                message: generateAlertMessage(ipo: ipo, compatibility: compat)
            )
        }.sorted { $0.ipo.expectedDate < $1.ipo.expectedDate }
    }

    /// Get featured IPOs (highest valuations)
    func getFeaturedIPOs(limit: Int = 4) -> [IPO] {
        ipos.filter { !$0.hasLaunched }
            .sorted { ($0.estimatedValuation ?? 0) > ($1.estimatedValuation ?? 0) }
            .prefix(limit)
            .map { $0 }
    }

    /// Search IPOs by name or ticker
    func searchIPOs(query: String) -> [IPO] {
        guard !query.isEmpty else { return getUpcomingIPOs() }
        let lowercased = query.lowercased()
        return ipos.filter { ipo in
            ipo.companyName.lowercased().contains(lowercased) ||
            (ipo.ticker?.lowercased().contains(lowercased) ?? false) ||
            ipo.sector.lowercased().contains(lowercased)
        }
    }

    /// Sort IPOs by option
    func sortIPOs(_ ipos: [IPO], by option: IPOSortOption, user: UserProfile) -> [IPO] {
        switch option {
        case .date:
            return ipos.sorted { $0.expectedDate < $1.expectedDate }
        case .compatibility:
            return ipos.sorted { $0.compatibility(with: user).score > $1.compatibility(with: user).score }
        case .sector:
            return ipos.sorted { $0.sector < $1.sector }
        case .valuation:
            return ipos.sorted { ($0.estimatedValuation ?? 0) > ($1.estimatedValuation ?? 0) }
        }
    }

    /// Get IPO by ID
    func getIPO(id: UUID) -> IPO? {
        ipos.first { $0.id == id }
    }

    /// Refresh IPO data
    @MainActor
    func refresh() async {
        // Check cache
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheDuration {
            return
        }

        isLoading = true
        lastError = nil

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        // In the future, this would call Finnhub API:
        // let url = URL(string: "https://finnhub.io/api/v1/calendar/ipo?from=\(fromDate)&to=\(toDate)&token=\(apiKey)")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // let response = try JSONDecoder().decode(IPOResponse.self, from: data)

        // For now, use mock data
        loadMockData()

        lastFetchTime = Date()
        isLoading = false
    }

    // MARK: - Private Methods

    private func loadMockData() {
        ipos = MockIPOData.all
    }

    private func generateAlertMessage(ipo: IPO, compatibility: IPOCompatibilityResult) -> String {
        let dayText: String
        if ipo.isToday {
            dayText = "launches today"
        } else if ipo.daysUntilIPO == 1 {
            dayText = "launches tomorrow"
        } else {
            dayText = "enters the market \(ipo.weekdayName)"
        }

        if compatibility.userSign == ipo.zodiacSign {
            return "A fellow \(ipo.zodiacSign.displayName) \(dayText) — \(compatibility.score)% cosmic match"
        } else if compatibility.userSign.element == ipo.zodiacSign.element {
            return "This \(ipo.zodiacSign.displayName) IPO aligns with your \(compatibility.userSign.element.displayName.lowercased()) energy — \(compatibility.score)% compatible"
        } else {
            return "A \(ipo.zodiacSign.displayName) birth \(dayText) — \(compatibility.score)% compatibility with your \(compatibility.userSign.displayName)"
        }
    }
}

// MARK: - IPO Alert

struct IPOAlert: Identifiable {
    let id = UUID()
    let ipo: IPO
    let compatibilityScore: Int
    let message: String

    var isUrgent: Bool {
        ipo.daysUntilIPO <= 2
    }
}

// MARK: - IPO Statistics

extension IPOService {

    /// Get statistics about upcoming IPOs
    func getStatistics() -> IPOStatistics {
        let upcoming = getUpcomingIPOs()

        let totalValuation = upcoming.compactMap { $0.estimatedValuation }.reduce(0, +)
        let avgValuation = upcoming.isEmpty ? 0 : totalValuation / Double(upcoming.count)

        let sectorCounts = Dictionary(grouping: upcoming) { $0.sector }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        let signCounts = Dictionary(grouping: upcoming) { $0.zodiacSign }
            .mapValues { $0.count }

        return IPOStatistics(
            totalUpcoming: upcoming.count,
            thisWeekCount: getIPOsThisWeek().count,
            thisMonthCount: getIPOsThisMonth().count,
            totalEstimatedValuation: totalValuation,
            averageValuation: avgValuation,
            topSectors: sectorCounts.prefix(3).map { ($0.key, $0.value) },
            signDistribution: signCounts
        )
    }
}

struct IPOStatistics {
    let totalUpcoming: Int
    let thisWeekCount: Int
    let thisMonthCount: Int
    let totalEstimatedValuation: Double
    let averageValuation: Double
    let topSectors: [(String, Int)]
    let signDistribution: [ZodiacSign: Int]

    var formattedTotalValuation: String {
        if totalEstimatedValuation >= 1_000_000_000 {
            return String(format: "$%.1fB", totalEstimatedValuation / 1_000_000_000)
        } else {
            return String(format: "$%.0fM", totalEstimatedValuation / 1_000_000)
        }
    }
}

// MARK: - Finnhub API Response Models (for future integration)

/*
 When integrating with real Finnhub API, use these models:

 struct FinnhubIPOResponse: Codable {
     let ipoCalendar: [FinnhubIPO]
 }

 struct FinnhubIPO: Codable {
     let symbol: String?
     let date: String
     let exchange: String?
     let name: String?
     let numberOfShares: Int?
     let price: String?
     let status: String?
     let totalSharesValue: Int?
 }
 */
