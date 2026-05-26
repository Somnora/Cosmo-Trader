import Foundation
import SwiftUI

// MARK: - IPO Service
// ====================
// Service for fetching and managing IPO data from the Finnhub API.
// Falls back to cached data when offline.

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

    /// Cache duration (5 minutes)
    private let cacheDuration: TimeInterval = 300

    /// UserDefaults key for IPO cache
    private let cacheKey = "com.cosmotrader.ipocache"
    private let cacheTimestampKey = "com.cosmotrader.ipocache.timestamp"

    // MARK: - Init

    private init() {
        // Load cached data first, then attempt API fetch
        loadCachedIPOs()

        // If no cached data, use mock data as initial fallback
        if ipos.isEmpty {
            loadMockData()
        }
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

    /// Refresh IPO data from API
    @MainActor
    func refresh() async {
        // Check cache freshness
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheDuration {
            return
        }

        isLoading = true
        lastError = nil

        do {
            let today = Date()
            // Fetch IPOs from today to 6 months out for better coverage
            guard let sixMonthsOut = Calendar.current.date(byAdding: .month, value: 6, to: today) else {
                throw NetworkError.unknown("Failed to calculate date range")
            }

            let finnhubIPOs = try await StockAPIService.shared.fetchIPOCalendar(from: today, to: sixMonthsOut)

            // Convert to app's IPO model
            let convertedIPOs = finnhubIPOs.compactMap { convertToIPO($0) }

            if !convertedIPOs.isEmpty {
                self.ipos = convertedIPOs
                self.lastFetchTime = Date()

                // Cache results for offline use
                cacheIPOs(convertedIPOs)

                log("✅ Loaded \(convertedIPOs.count) IPOs from API")
            } else {
                // API returned empty - keep existing data
                log("⚠️ API returned no IPOs, keeping existing data")
            }

            lastError = nil

        } catch {
            log("❌ IPO fetch error: \(error)")
            lastError = error

            // Fall back to cache or mock data if we have nothing
            if ipos.isEmpty {
                loadCachedIPOs()
                if ipos.isEmpty {
                    loadMockData()
                }
            }
        }

        isLoading = false
    }

    /// Force refresh, bypassing cache check
    @MainActor
    func forceRefresh() async {
        lastFetchTime = nil
        await refresh()
    }

    // MARK: - Private Methods

    private func loadMockData() {
        ipos = MockIPOData.all
        log("📦 Loaded mock IPO data")
    }

    /// Convert Finnhub IPO to app IPO model
    private func convertToIPO(_ finnhub: FinnhubIPO) -> IPO? {
        guard let date = parseDate(finnhub.date) else {
            log("⚠️ Failed to parse date: \(finnhub.date)")
            return nil
        }

        // Parse price range (e.g., "15-17" or "15.00")
        let (priceLow, priceHigh) = parsePriceRange(finnhub.price)

        // Determine sector from exchange or default
        let sector = determineSector(from: finnhub)

        return IPO(
            companyName: finnhub.name,
            ticker: finnhub.symbol.isEmpty ? nil : finnhub.symbol,
            expectedDate: date,
            priceRangeLow: priceLow,
            priceRangeHigh: priceHigh,
            sector: sector,
            industry: sector,
            description: "IPO on \(finnhub.exchange ?? "Unknown Exchange")",
            headquarters: "",
            foundedYear: nil,
            employeeCount: nil,
            estimatedValuation: calculateEstimatedValuation(shares: finnhub.shares, price: priceLow)
        )
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private func parsePriceRange(_ priceString: String?) -> (Double?, Double?) {
        guard let priceString = priceString, !priceString.isEmpty else {
            return (nil, nil)
        }

        // Handle range format "15-17" or "15.00-17.00"
        if priceString.contains("-") {
            let parts = priceString.split(separator: "-")
            if parts.count == 2 {
                let low = Double(parts[0].trimmingCharacters(in: .whitespaces))
                let high = Double(parts[1].trimmingCharacters(in: .whitespaces))
                return (low, high)
            }
        }

        // Single price
        if let price = Double(priceString) {
            return (price, price)
        }

        return (nil, nil)
    }

    private func determineSector(from finnhub: FinnhubIPO) -> String {
        // Map exchange to general sector (could be enhanced with more data)
        switch finnhub.exchange?.uppercased() {
        case "NASDAQ":
            return "Technology"
        case "NYSE":
            return "Financial Services"
        default:
            return "Other"
        }
    }

    private func calculateEstimatedValuation(shares: Int?, price: Double?) -> Double? {
        guard let shares = shares, let price = price else { return nil }
        return Double(shares) * price
    }

    // MARK: - Caching

    private func cacheIPOs(_ ipos: [IPO]) {
        do {
            let data = try JSONEncoder().encode(ipos.map { CachedIPO(from: $0) })
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
            log("💾 Cached \(ipos.count) IPOs")
        } catch {
            log("⚠️ Failed to cache IPOs: \(error)")
        }
    }

    private func loadCachedIPOs() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            log("📦 No cached IPOs found")
            return
        }

        do {
            let cached = try JSONDecoder().decode([CachedIPO].self, from: data)
            ipos = cached.map { $0.toIPO() }
            lastFetchTime = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date
            log("📦 Loaded \(ipos.count) IPOs from cache")
        } catch {
            log("⚠️ Failed to load cached IPOs: \(error)")
        }
    }

    // MARK: - Logging

    private func log(_ message: String) {
        #if DEBUG
        print("[IPOService] \(message)")
        #endif
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

// MARK: - Cached IPO Model
// =========================
// Codable wrapper for persisting IPO data to UserDefaults

private struct CachedIPO: Codable {
    let id: UUID
    let companyName: String
    let ticker: String?
    let expectedDate: Date
    let priceRangeLow: Double?
    let priceRangeHigh: Double?
    let sector: String
    let industry: String
    let description: String
    let headquarters: String
    let foundedYear: Int?
    let employeeCount: Int?
    let estimatedValuation: Double?

    init(from ipo: IPO) {
        self.id = ipo.id
        self.companyName = ipo.companyName
        self.ticker = ipo.ticker
        self.expectedDate = ipo.expectedDate
        self.priceRangeLow = ipo.priceRangeLow
        self.priceRangeHigh = ipo.priceRangeHigh
        self.sector = ipo.sector
        self.industry = ipo.industry
        self.description = ipo.description
        self.headquarters = ipo.headquarters
        self.foundedYear = ipo.foundedYear
        self.employeeCount = ipo.employeeCount
        self.estimatedValuation = ipo.estimatedValuation
    }

    func toIPO() -> IPO {
        IPO(
            id: id,
            companyName: companyName,
            ticker: ticker,
            expectedDate: expectedDate,
            priceRangeLow: priceRangeLow,
            priceRangeHigh: priceRangeHigh,
            sector: sector,
            industry: industry,
            description: description,
            headquarters: headquarters,
            foundedYear: foundedYear,
            employeeCount: employeeCount,
            estimatedValuation: estimatedValuation
        )
    }
}
