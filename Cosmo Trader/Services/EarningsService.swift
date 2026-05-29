import Foundation
import SwiftUI

// MARK: - Earnings Service
// =========================
// Manages earnings calendar data from Finnhub API and generates cosmic earnings horoscopes.
//
// FEATURE: Earnings Season Horoscopes
// Quarterly earnings are the most volatile periods. This service provides:
// - Earnings calendar with upcoming report dates (from real API)
// - Special horoscopes for stocks reporting that week
// - Cosmic commentary combining zodiac traits with Mercury retrograde, etc.
//
// "TSLA reports Thursday. As a Cancer with Mercury in retrograde, expect
//  emotional overreaction to guidance. The numbers matter less than the vibe."
//
// WHY IT WORKS: Earnings anxiety is real. This gives users a narrative frame.

@MainActor
@Observable
final class EarningsService {

    // MARK: - Singleton

    static let shared = EarningsService()

    // MARK: - Dependencies

    private let astroAlertService = AstroAlertService.shared
    private let moonService = MoonPhaseService.shared

    // MARK: - State

    /// All known earnings events
    private(set) var allEarningsEvents: [EarningsEvent] = []

    /// Is currently loading
    private(set) var isLoading: Bool = false

    /// Last fetch error
    private(set) var lastError: Error?

    /// Last refresh time
    private var lastRefresh: Date?

    /// Source state for the currently displayed earnings calendar.
    private(set) var dataProvenance: FinancialDataProvenance = .unavailable(reason: "Earnings calendar unavailable")

    /// Cache duration (5 minutes)
    private let cacheDuration: TimeInterval = 300

    /// UserDefaults keys for caching
    private let cacheKey = "com.cosmotrader.earningscache"
    private let cacheTimestampKey = "com.cosmotrader.earningscache.timestamp"

    // MARK: - Initialization

    private init(loadCache: Bool = true) {
        if loadCache {
            loadCachedEarnings()
        }
        // No production mock fallback: an empty earnings calendar is an
        // unavailable state until Finnhub or cached provider data exists.
    }

    static func testingInstance(loadCache: Bool = false) -> EarningsService {
        EarningsService(loadCache: loadCache)
    }

    // MARK: - Public Methods

    /// Get earnings events for stocks in a portfolio
    func getEarningsForPortfolio(stocks: [Stock]) -> [EarningsEvent] {
        let symbols = Set(stocks.map { $0.symbol })
        return allEarningsEvents
            .filter { symbols.contains($0.symbol) }
            .sorted { $0.reportDate < $1.reportDate }
    }

    /// Get earnings events happening this week
    func getEarningsThisWeek() -> [EarningsEvent] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: now) else {
            return []
        }

        return allEarningsEvents
            .filter { $0.reportDate >= now && $0.reportDate <= weekEnd }
            .sorted { $0.reportDate < $1.reportDate }
    }

    /// Get earnings events in the next N days
    func getEarningsWithin(days: Int) -> [EarningsEvent] {
        let calendar = Calendar.current
        let now = Date()
        guard let futureDate = calendar.date(byAdding: .day, value: days, to: now) else {
            return []
        }

        return allEarningsEvents
            .filter { $0.reportDate >= now && $0.reportDate <= futureDate }
            .sorted { $0.reportDate < $1.reportDate }
    }

    /// Get the next earnings event for a specific stock
    func getNextEarnings(for symbol: String) -> EarningsEvent? {
        let now = Date()
        return allEarningsEvents
            .filter { $0.symbol == symbol && $0.reportDate >= now }
            .sorted { $0.reportDate < $1.reportDate }
            .first
    }

    /// Check if a stock reports this week
    func reportsThisWeek(symbol: String) -> Bool {
        getEarningsThisWeek().contains { $0.symbol == symbol }
    }

    /// Get the cosmic earnings horoscope for a stock
    func getEarningsHoroscope(for stock: Stock, earningsDate: Date) -> EarningsHoroscope {
        generateHoroscope(stock: stock, earningsDate: earningsDate)
    }

    /// Refresh earnings data from API
    func refresh() async {
        // Check cache freshness
        if let lastFetch = lastRefresh,
           Date().timeIntervalSince(lastFetch) < cacheDuration {
            return
        }

        isLoading = true
        lastError = nil

        do {
            let today = Date()
            // Fetch earnings for the next 30 days
            guard let thirtyDaysOut = Calendar.current.date(byAdding: .day, value: 30, to: today) else {
                throw NetworkError.unknown("Failed to calculate date range")
            }

            let finnhubEarnings = try await StockAPIService.shared.fetchEarningsCalendar(from: today, to: thirtyDaysOut)

            // Convert to app's EarningsEvent model
            let convertedEvents = finnhubEarnings.compactMap { convertToEarningsEvent($0) }

            if !convertedEvents.isEmpty {
                let fetchedAt = Date()
                self.allEarningsEvents = convertedEvents
                self.lastRefresh = fetchedAt
                self.dataProvenance = .live(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: fetchedAt)

                // Cache results for offline use
                cacheEarnings(convertedEvents)

                log("✅ Loaded \(convertedEvents.count) earnings events from API")
            } else {
                // API returned empty - keep existing data
                log("⚠️ API returned no earnings, keeping existing data")
                if allEarningsEvents.isEmpty {
                    dataProvenance = .unavailable(reason: "Earnings calendar unavailable")
                }
            }

            lastError = nil

        } catch {
            log("❌ Earnings fetch error: \(error)")
            lastError = error

            // Fall back to cache if we have nothing. Do not show fake earnings.
            if allEarningsEvents.isEmpty {
                loadCachedEarnings()
                if allEarningsEvents.isEmpty {
                    dataProvenance = .unavailable(reason: "Earnings calendar unavailable")
                }
            }
        }

        isLoading = false
    }

    /// Force refresh, bypassing cache check
    func forceRefresh() async {
        lastRefresh = nil
        await refresh()
    }

    /// Synchronous refresh for legacy compatibility (triggers async refresh)
    func refreshSync() {
        Task {
            await refresh()
        }
    }

    // MARK: - API Conversion

    /// Convert Finnhub earnings to app EarningsEvent model
    private func convertToEarningsEvent(_ finnhub: FinnhubEarnings) -> EarningsEvent? {
        guard let date = parseDate(finnhub.date) else {
            log("⚠️ Failed to parse date: \(finnhub.date)")
            return nil
        }

        // Convert hour to timing
        let timing: EarningsEvent.ReportTiming
        switch finnhub.hour?.lowercased() {
        case "bmo":
            timing = .beforeMarket
        case "amc":
            timing = .afterMarket
        case "dmh":
            timing = .duringMarket
        default:
            timing = .afterMarket // Default to after market if unknown
        }

        // Set appropriate time based on timing
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = timing == .beforeMarket ? 7 : 16
        components.minute = 30
        let finalDate = calendar.date(from: components) ?? date

        // Get fiscal quarter string
        let fiscalQuarter = finnhub.quarter.map { "Q\($0)" } ?? getCurrentFiscalQuarter()
        let fiscalYear = finnhub.year ?? calendar.component(.year, from: Date())

        return EarningsEvent(
            symbol: finnhub.symbol,
            companyName: finnhub.symbol, // Finnhub doesn't provide company name, use symbol
            reportDate: finalDate,
            timing: timing,
            consensusEPS: finnhub.epsEstimate,
            previousEPS: finnhub.epsActual,
            fiscalQuarter: fiscalQuarter,
            fiscalYear: fiscalYear
        )
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    // MARK: - Caching

    private func cacheEarnings(_ events: [EarningsEvent]) {
        do {
            let data = try JSONEncoder().encode(events.map { CachedEarningsEvent(from: $0) })
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
            log("💾 Cached \(events.count) earnings events")
        } catch {
            log("⚠️ Failed to cache earnings: \(error)")
        }
    }

    private func loadCachedEarnings() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            log("📦 No cached earnings found")
            return
        }

        do {
            let cached = try JSONDecoder().decode([CachedEarningsEvent].self, from: data)
            allEarningsEvents = cached.map { $0.toEarningsEvent() }
            lastRefresh = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date
            if let lastRefresh {
                dataProvenance = .cached(provider: FinancialDataProvenance.finnhubProvider, fetchedAt: lastRefresh)
            }
            log("📦 Loaded \(allEarningsEvents.count) earnings from cache")
        } catch {
            log("⚠️ Failed to load cached earnings: \(error)")
        }
    }

    // MARK: - Logging

    private func log(_ message: String) {
        #if DEBUG
        print("[EarningsService] \(message)")
        #endif
    }

    /// Get current fiscal quarter
    private func getCurrentFiscalQuarter() -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())

        switch month {
        case 1...3: return "Q4" // Reporting Q4 of previous year
        case 4...6: return "Q1"
        case 7...9: return "Q2"
        default: return "Q3"
        }
    }

    // MARK: - Horoscope Generation

    /// Generate a cosmic earnings horoscope for a stock
    private func generateHoroscope(stock: Stock, earningsDate: Date) -> EarningsHoroscope {
        let sign = stock.foundedZodiacSign
        let isMercuryRetrograde = astroAlertService.isMercuryRetrograde
        let lunarData = moonService.getLunarData(for: earningsDate)
        let moonPhase = lunarData.phase
        let dayOfWeek = getDayOfWeek(earningsDate)

        // Generate cosmic factors affecting this earnings
        var cosmicFactors: [CosmicFactor] = []

        // 1. Zodiac sign influence
        if let sign {
            cosmicFactors.append(generateSignFactor(sign: sign))
        }

        // 2. Mercury retrograde (if active)
        if isMercuryRetrograde {
            cosmicFactors.append(CosmicFactor(
                name: "Mercury Retrograde",
                icon: "arrow.trianglehead.2.clockwise.rotate.90",
                influence: .cautionary,
                description: "Communication mishaps likely. Watch for guidance revisions, conference call gaffes, or misunderstood metrics."
            ))
        }

        // 3. Moon phase influence
        cosmicFactors.append(generateMoonFactor(phase: moonPhase))

        // 4. Day of week influence
        cosmicFactors.append(generateDayFactor(day: dayOfWeek))

        // Generate the main horoscope text
        let mainHoroscope = generateMainHoroscope(
            stock: stock,
            isMercuryRetrograde: isMercuryRetrograde,
            moonPhase: moonPhase,
            dayOfWeek: dayOfWeek
        )

        // Generate trading insight
        let tradingInsight = generateTradingInsight(
            stock: stock,
            isMercuryRetrograde: isMercuryRetrograde,
            cosmicFactors: cosmicFactors
        )

        // Calculate overall cosmic sentiment
        let sentiment = calculateSentiment(factors: cosmicFactors)

        return EarningsHoroscope(
            stock: stock,
            earningsDate: earningsDate,
            horoscopeText: mainHoroscope,
            tradingInsight: tradingInsight,
            cosmicFactors: cosmicFactors,
            sentiment: sentiment,
            isMercuryRetrograde: isMercuryRetrograde,
            moonPhase: moonPhase.rawValue
        )
    }

    // MARK: - Horoscope Text Generation

    private func generateMainHoroscope(stock: Stock, isMercuryRetrograde: Bool, moonPhase: MoonPhase, dayOfWeek: String) -> String {
        guard let sign = stock.foundedZodiacSign else {
            return "\(stock.symbol)'s founding or IPO date is unknown, so sign-based earnings context is unavailable. Use the lunar and Mercury context as market color only."
        }
        let element = sign.element

        var parts: [String] = []

        // Opening line based on sign
        parts.append(generateSignOpening(stock: stock))

        // Mercury retrograde warning if active
        if isMercuryRetrograde {
            parts.append(generateMercuryWarning(sign: sign))
        }

        // Moon phase influence
        parts.append(generateMoonInfluence(phase: moonPhase, element: element))

        // Closing advice
        parts.append(generateClosingAdvice(sign: sign))

        return parts.joined(separator: " ")
    }

    private func generateSignOpening(stock: Stock) -> String {
        guard let sign = stock.foundedZodiacSign else {
            return "\(stock.symbol)'s verified company sign is unknown, so this earnings read skips sign-specific framing."
        }

        switch sign {
        case .aries:
            return "\(stock.symbol) charges into earnings season with typical Aries boldness. Expect aggressive forward guidance and ambitious projections."

        case .taurus:
            return "\(stock.symbol), ever the steady Taurus, will focus on fundamentals. Look for consistent margins and cautious, methodical guidance."

        case .gemini:
            return "\(stock.symbol)'s Gemini nature means multiple narratives will emerge. The market will debate which version of the story to believe."

        case .cancer:
            return "\(stock.symbol) reports with Cancer's emotional sensitivity. The numbers matter less than the vibe — sentiment will drive reaction."

        case .leo:
            return "\(stock.symbol) takes the earnings stage like a true Leo. Expect theatrical presentation and bold claims about market leadership."

        case .virgo:
            return "\(stock.symbol)'s Virgo precision means every metric will be scrutinized. Details in the footnotes may move the stock more than headlines."

        case .libra:
            return "\(stock.symbol) seeks Libra's balance in its report. Watch for diplomatic guidance that tries to please both bulls and bears."

        case .scorpio:
            return "\(stock.symbol)'s Scorpio intensity suggests hidden currents. The real story may lie beneath the surface numbers."

        case .sagittarius:
            return "\(stock.symbol) shoots for the stars with Sagittarian optimism. Expect expansive vision, though execution details may be vague."

        case .capricorn:
            return "\(stock.symbol)'s Capricorn discipline will show in the numbers. Conservative guidance likely, with focus on long-term structural improvements."

        case .aquarius:
            return "\(stock.symbol)'s Aquarian innovation takes center stage. Unconventional metrics and future-focused commentary will dominate."

        case .pisces:
            return "\(stock.symbol) flows into earnings with Pisces intuition. The mood of the call may matter more than the spreadsheet."
        }
    }

    private func generateMercuryWarning(sign: ZodiacSign) -> String {
        switch sign.element {
        case .fire:
            return "With Mercury retrograde, this Fire sign's bold communications could backfire. Watch for guidance that's retracted or clarified later."

        case .earth:
            return "Mercury retrograde challenges even practical Earth signs. Financial projections may need revision. Double-check all numbers."

        case .air:
            return "Air signs feel Mercury retrograde most acutely. Expect communication misfires — the conference call could go off-script."

        case .water:
            return "Water signs' intuitive nature clashes with Mercury retrograde confusion. Emotional undertones may overwhelm the data."
        }
    }

    private func generateMoonInfluence(phase: MoonPhase, element: ZodiacSign.Element) -> String {
        switch phase {
        case .newMoon:
            return "The New Moon favors new beginnings — fresh guidance or strategic pivots may land well."

        case .waxingCrescent, .firstQuarter, .waxingGibbous:
            return "The waxing Moon builds momentum. Positive surprises could accelerate further."

        case .fullMoon:
            return "The Full Moon illuminates everything — both triumphs and troubles will be magnified."

        case .waningGibbous, .lastQuarter, .waningCrescent:
            return "The waning Moon suggests consolidation. Markets may temper extreme reactions."
        }
    }

    private func generateClosingAdvice(sign: ZodiacSign) -> String {
        switch sign.modality {
        case .cardinal:
            return "As a Cardinal sign, \(sign.displayName) companies often set the tone for their sector. Watch for ripple effects."

        case .fixed:
            return "Fixed signs like \(sign.displayName) rarely surprise. But when they do, the move is substantial."

        case .mutable:
            return "Mutable \(sign.displayName) adapts quickly. Post-earnings volatility may resolve faster than expected."
        }
    }

    private func generateTradingInsight(stock: Stock, isMercuryRetrograde: Bool, cosmicFactors: [CosmicFactor]) -> String {
        let cautionaryCount = cosmicFactors.filter { $0.influence == .cautionary }.count
        let favorableCount = cosmicFactors.filter { $0.influence == .favorable }.count

        if isMercuryRetrograde {
            return "Traditional cosmic wisdom suggests avoiding new positions during Mercury retrograde. If you must trade, keep size small and expectations modest."
        } else if cautionaryCount > favorableCount {
            return "The cosmic winds blow mixed signals. Consider waiting for post-earnings clarity before committing capital."
        } else if favorableCount > cautionaryCount {
            return "Celestial alignments favor bold moves, but remember: the stars incline, they don't compel. Let the numbers confirm the vibe."
        } else {
            return "Neutral cosmic conditions mean the fundamentals will speak loudest. Focus on the numbers, not the narrative."
        }
    }

    // MARK: - Factor Generation

    private func generateSignFactor(sign: ZodiacSign) -> CosmicFactor {
        let influence: CosmicFactor.Influence
        let description: String

        switch sign.element {
        case .fire:
            influence = .favorable
            description = "Fire signs bring bold energy to earnings. Expect confident guidance and aggressive growth targets."

        case .earth:
            influence = .neutral
            description = "Earth signs ground expectations in reality. Pragmatic outlook with focus on sustainable metrics."

        case .air:
            influence = .neutral
            description = "Air signs emphasize communication and ideas. Watch for narrative shifts in the investment thesis."

        case .water:
            influence = .cautionary
            description = "Water signs heighten emotional response. Market reaction may be more volatile than fundamentals warrant."
        }

        return CosmicFactor(
            name: "\(sign.displayName) Energy",
            icon: "sparkles",
            influence: influence,
            description: description
        )
    }

    private func generateMoonFactor(phase: MoonPhase) -> CosmicFactor {
        let influence: CosmicFactor.Influence
        let description: String

        switch phase {
        case .newMoon:
            influence = .favorable
            description = "New Moon favors fresh starts. New initiatives announced may be well-received."

        case .waxingCrescent, .firstQuarter:
            influence = .favorable
            description = "Growing Moon builds positive momentum. Good time for growth-oriented announcements."

        case .waxingGibbous:
            influence = .neutral
            description = "Moon approaching fullness. Anticipation builds but clarity is not yet complete."

        case .fullMoon:
            influence = .cautionary
            description = "Full Moon amplifies all emotions. Expect outsized reactions to any surprise."

        case .waningGibbous, .lastQuarter:
            influence = .neutral
            description = "Waning Moon suggests reflection. Markets may take time to fully price in results."

        case .waningCrescent:
            influence = .favorable
            description = "End of lunar cycle favors closure. Old concerns may finally be put to rest."
        }

        return CosmicFactor(
            name: "Moon Phase: \(phase.rawValue)",
            icon: phase.icon,
            influence: influence,
            description: description
        )
    }

    private func generateDayFactor(day: String) -> CosmicFactor {
        let influence: CosmicFactor.Influence
        let description: String

        switch day {
        case "Monday":
            influence = .neutral
            description = "Moon-day opens the week. Emotional Monday trading may exaggerate initial moves."

        case "Tuesday":
            influence = .favorable
            description = "Mars-day brings energy and decisive action. Markets tend to commit to a direction."

        case "Wednesday":
            influence = .favorable
            description = "Mercury-day favors communication. Conference calls likely to go smoothly."

        case "Thursday":
            influence = .favorable
            description = "Jupiter-day brings expansion and optimism. Positive surprises hit harder."

        case "Friday":
            influence = .cautionary
            description = "Venus-day meets weekend positioning. Traders may lock in gains rather than hold."

        default:
            influence = .neutral
            description = "Weekend earnings allow time for digestion before market reaction."
        }

        return CosmicFactor(
            name: "\(day) Report",
            icon: "calendar",
            influence: influence,
            description: description
        )
    }

    // MARK: - Helpers

    private func getDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func calculateSentiment(factors: [CosmicFactor]) -> EarningsHoroscope.Sentiment {
        var score = 0

        for factor in factors {
            switch factor.influence {
            case .favorable: score += 1
            case .neutral: score += 0
            case .cautionary: score -= 1
            }
        }

        if score >= 2 {
            return .bullish
        } else if score <= -2 {
            return .bearish
        } else if score > 0 {
            return .cautiously_optimistic
        } else if score < 0 {
            return .cautiously_pessimistic
        } else {
            return .neutral
        }
    }
}

// MARK: - Supporting Types

/// Represents an earnings report event
struct EarningsEvent: Identifiable {
    let id: UUID
    let symbol: String
    let companyName: String
    let reportDate: Date
    let timing: ReportTiming
    let consensusEPS: Double?
    let previousEPS: Double?
    let fiscalQuarter: String
    let fiscalYear: Int

    enum ReportTiming: String, Codable {
        case beforeMarket = "Before Market"
        case afterMarket = "After Market"
        case duringMarket = "During Market"

        var icon: String {
            switch self {
            case .beforeMarket: return "sunrise.fill"
            case .afterMarket: return "sunset.fill"
            case .duringMarket: return "sun.max.fill"
            }
        }
    }

    init(
        id: UUID = UUID(),
        symbol: String,
        companyName: String,
        reportDate: Date,
        timing: ReportTiming,
        consensusEPS: Double?,
        previousEPS: Double?,
        fiscalQuarter: String,
        fiscalYear: Int
    ) {
        self.id = id
        self.symbol = symbol
        self.companyName = companyName
        self.reportDate = reportDate
        self.timing = timing
        self.consensusEPS = consensusEPS
        self.previousEPS = previousEPS
        self.fiscalQuarter = fiscalQuarter
        self.fiscalYear = fiscalYear
    }

    /// Days until this earnings report
    var daysUntil: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: reportDate).day ?? 0
    }

    /// Is this report today?
    var isToday: Bool {
        Calendar.current.isDateInToday(reportDate)
    }

    /// Is this report this week?
    var isThisWeek: Bool {
        daysUntil <= 7 && daysUntil >= 0
    }

    /// Formatted report date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: reportDate)
    }

    /// Formatted time
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: reportDate)
    }

    /// Formatted consensus EPS
    var formattedConsensus: String? {
        guard let eps = consensusEPS else { return nil }
        return String(format: "$%.2f", eps)
    }
}

/// Cosmic earnings horoscope for a stock
struct EarningsHoroscope: Identifiable {
    let id = UUID()
    let stock: Stock
    let earningsDate: Date
    let horoscopeText: String
    let tradingInsight: String
    let cosmicFactors: [CosmicFactor]
    let sentiment: Sentiment
    let isMercuryRetrograde: Bool
    let moonPhase: String

    enum Sentiment: String {
        case bullish = "Bullish"
        case cautiously_optimistic = "Cautiously Optimistic"
        case neutral = "Neutral"
        case cautiously_pessimistic = "Cautiously Pessimistic"
        case bearish = "Bearish"

        var color: Color {
            switch self {
            case .bullish: return CosmicTheme.positive
            case .cautiously_optimistic: return CosmicTheme.accentBlue
            case .neutral: return CosmicTheme.textSecondary
            case .cautiously_pessimistic: return .orange
            case .bearish: return CosmicTheme.negative
            }
        }

        var icon: String {
            switch self {
            case .bullish: return "arrow.up.circle.fill"
            case .cautiously_optimistic: return "arrow.up.right.circle"
            case .neutral: return "minus.circle"
            case .cautiously_pessimistic: return "arrow.down.right.circle"
            case .bearish: return "arrow.down.circle.fill"
            }
        }
    }
}

/// A cosmic factor influencing earnings
struct CosmicFactor: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let influence: Influence
    let description: String

    enum Influence: String {
        case favorable = "Favorable"
        case neutral = "Neutral"
        case cautionary = "Cautionary"

        var color: Color {
            switch self {
            case .favorable: return CosmicTheme.positive
            case .neutral: return CosmicTheme.textSecondary
            case .cautionary: return .orange
            }
        }
    }
}

// MARK: - Cached Earnings Event
// =============================
// Codable wrapper for persisting EarningsEvent data to UserDefaults

private struct CachedEarningsEvent: Codable {
    let id: UUID
    let symbol: String
    let companyName: String
    let reportDate: Date
    let timing: EarningsEvent.ReportTiming
    let consensusEPS: Double?
    let previousEPS: Double?
    let fiscalQuarter: String
    let fiscalYear: Int

    init(from event: EarningsEvent) {
        self.id = event.id
        self.symbol = event.symbol
        self.companyName = event.companyName
        self.reportDate = event.reportDate
        self.timing = event.timing
        self.consensusEPS = event.consensusEPS
        self.previousEPS = event.previousEPS
        self.fiscalQuarter = event.fiscalQuarter
        self.fiscalYear = event.fiscalYear
    }

    func toEarningsEvent() -> EarningsEvent {
        EarningsEvent(
            id: id,
            symbol: symbol,
            companyName: companyName,
            reportDate: reportDate,
            timing: timing,
            consensusEPS: consensusEPS,
            previousEPS: previousEPS,
            fiscalQuarter: fiscalQuarter,
            fiscalYear: fiscalYear
        )
    }
}
