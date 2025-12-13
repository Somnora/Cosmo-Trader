import Foundation
import SwiftUI

// MARK: - Saturn Return Service
// ==============================
// Tracks company "Saturn Returns" - the astrological concept that occurs
// every ~29.5 years when Saturn returns to its natal position.
//
// In astrology, Saturn Returns represent:
// - Major life transitions and maturity tests
// - Restructuring, reinvention, or crisis points
// - "Growing up" and facing hard truths
//
// For companies, this often correlates with:
// - Leadership transitions
// - Business model pivots
// - Market position challenges
// - The need to reinvent or face decline
//
// Historical examples:
// - Apple (founded 1976): Saturn Return ~2005 → iPhone pivot
// - Microsoft (founded 1975): Saturn Return ~2004 → Cloud transformation began
// - Amazon (founded 1994): Saturn Return ~2023 → AWS/AI focus intensifies

@MainActor
@Observable
final class SaturnReturnService {

    // MARK: - Singleton

    static let shared = SaturnReturnService()

    // MARK: - Constants

    /// Saturn's orbital period in years (time to complete one orbit around the Sun)
    static let saturnOrbitalPeriod: Double = 29.457 // ~29.5 years

    /// Alert window: months before Saturn Return to start alerting
    static let alertWindowMonths: Int = 6

    /// "Exact" window: months around exact Saturn Return date
    static let exactWindowMonths: Int = 3

    // MARK: - State

    /// Cached Saturn Return data for stocks
    private var saturnReturnCache: [String: SaturnReturnData] = [:]

    /// Known company founding dates (would come from API in production)
    private var companyFoundingDates: [String: Date] = [:]

    // MARK: - Initialization

    private init() {
        loadKnownFoundingDates()
    }

    // MARK: - Public Methods

    /// Get Saturn Return data for a stock
    func getSaturnReturn(for stock: Stock) -> SaturnReturnData? {
        // Check cache first
        if let cached = saturnReturnCache[stock.symbol] {
            return cached
        }

        // Get founding date
        guard let foundingDate = getFoundingDate(for: stock) else {
            return nil
        }

        // Calculate Saturn Return data
        let data = calculateSaturnReturn(foundingDate: foundingDate, symbol: stock.symbol)
        saturnReturnCache[stock.symbol] = data
        return data
    }

    /// Get all stocks approaching Saturn Return from a portfolio
    func getApproachingSaturnReturns(from stocks: [Stock]) -> [SaturnReturnAlert] {
        var alerts: [SaturnReturnAlert] = []

        for stock in stocks {
            if let data = getSaturnReturn(for: stock),
               let alert = createAlertIfApproaching(data: data, stock: stock) {
                alerts.append(alert)
            }
        }

        // Sort by proximity to Saturn Return
        return alerts.sorted { $0.daysUntil < $1.daysUntil }
    }

    /// Check if a stock is currently in Saturn Return
    func isInSaturnReturn(_ stock: Stock) -> Bool {
        guard let data = getSaturnReturn(for: stock) else { return false }
        return data.isInSaturnReturn
    }

    /// Get company age in years
    func getCompanyAge(for stock: Stock) -> Double? {
        guard let foundingDate = getFoundingDate(for: stock) else { return nil }
        let now = Date()
        let years = now.timeIntervalSince(foundingDate) / (365.25 * 24 * 60 * 60)
        return years
    }

    /// Get historical Saturn Return insight
    func getHistoricalInsight(for stock: Stock) -> SaturnReturnHistoricalInsight? {
        guard let data = getSaturnReturn(for: stock) else { return nil }

        // Check if we have historical data for this company
        if let insight = historicalInsights[stock.symbol] {
            return insight
        }

        // Generate generic insight based on Saturn Return status
        return generateGenericInsight(for: stock, data: data)
    }

    // MARK: - Private Methods

    private func getFoundingDate(for stock: Stock) -> Date? {
        // First check our known dates
        if let date = companyFoundingDates[stock.symbol] {
            return date
        }

        // Fall back to stock's founded date
        return stock.foundedDate
    }

    private func calculateSaturnReturn(foundingDate: Date, symbol: String) -> SaturnReturnData {
        let now = Date()
        let calendar = Calendar.current

        // Calculate company age
        let ageInYears = now.timeIntervalSince(foundingDate) / (365.25 * 24 * 60 * 60)

        // Determine which Saturn Return we're approaching/in
        let saturnReturnNumber = Int(ageInYears / Self.saturnOrbitalPeriod) + 1
        let nextSaturnReturnAge = Double(saturnReturnNumber) * Self.saturnOrbitalPeriod

        // Calculate next Saturn Return date
        let nextSaturnReturnDate = calendar.date(
            byAdding: .day,
            value: Int((nextSaturnReturnAge - ageInYears) * 365.25),
            to: now
        ) ?? now

        // Calculate previous Saturn Return (if applicable)
        var previousSaturnReturnDate: Date? = nil
        if saturnReturnNumber > 1 {
            let previousAge = Double(saturnReturnNumber - 1) * Self.saturnOrbitalPeriod
            previousSaturnReturnDate = calendar.date(
                byAdding: .year,
                value: Int(previousAge),
                to: foundingDate
            )
        }

        // Determine status
        let monthsUntilNext = calendar.dateComponents([.month], from: now, to: nextSaturnReturnDate).month ?? 0
        let status: SaturnReturnStatus

        if monthsUntilNext <= Self.exactWindowMonths && monthsUntilNext >= -Self.exactWindowMonths {
            status = .inSaturnReturn
        } else if monthsUntilNext <= Self.alertWindowMonths && monthsUntilNext > Self.exactWindowMonths {
            status = .approaching
        } else if monthsUntilNext < -Self.exactWindowMonths && monthsUntilNext >= -(Self.alertWindowMonths) {
            status = .recentlyCompleted
        } else {
            status = .distant
        }

        return SaturnReturnData(
            symbol: symbol,
            foundingDate: foundingDate,
            companyAgeYears: ageInYears,
            currentSaturnReturnNumber: saturnReturnNumber,
            nextSaturnReturnDate: nextSaturnReturnDate,
            previousSaturnReturnDate: previousSaturnReturnDate,
            status: status
        )
    }

    private func createAlertIfApproaching(data: SaturnReturnData, stock: Stock) -> SaturnReturnAlert? {
        guard data.status == .approaching || data.status == .inSaturnReturn else {
            return nil
        }

        let calendar = Calendar.current
        let daysUntil = calendar.dateComponents([.day], from: Date(), to: data.nextSaturnReturnDate).day ?? 0

        let headline: String
        let message: String
        let urgency: SaturnReturnAlert.Urgency

        switch data.status {
        case .inSaturnReturn:
            headline = "\(stock.symbol) is in Saturn Return"
            message = "At \(Int(data.companyAgeYears)) years old, \(stock.name) is experiencing its Saturn Return — a period of transformation and maturity testing."
            urgency = .high
        case .approaching:
            let monthsUntil = daysUntil / 30
            headline = "\(stock.symbol) approaches Saturn Return"
            message = "\(stock.name) will hit its Saturn Return in ~\(monthsUntil) months. Watch for signs of strategic pivots or leadership changes."
            urgency = monthsUntil <= 3 ? .medium : .low
        default:
            return nil
        }

        return SaturnReturnAlert(
            stock: stock,
            data: data,
            headline: headline,
            message: message,
            daysUntil: daysUntil,
            urgency: urgency
        )
    }

    private func generateGenericInsight(for stock: Stock, data: SaturnReturnData) -> SaturnReturnHistoricalInsight {
        let ordinal = data.currentSaturnReturnNumber == 1 ? "first" :
                      data.currentSaturnReturnNumber == 2 ? "second" : "\(data.currentSaturnReturnNumber)th"

        let insight: String
        switch data.status {
        case .approaching:
            insight = "\(stock.name) is approaching its \(ordinal) Saturn Return. Companies at this stage often face pressure to evolve their core business model or risk stagnation."
        case .inSaturnReturn:
            insight = "\(stock.name) is currently in its \(ordinal) Saturn Return — a critical period for corporate maturity. Watch for strategic announcements, leadership changes, or market repositioning."
        case .recentlyCompleted:
            insight = "\(stock.name) recently completed its \(ordinal) Saturn Return. The dust is settling — observe whether transformation efforts are taking hold."
        case .distant:
            let yearsUntil = Int(Self.saturnOrbitalPeriod * Double(data.currentSaturnReturnNumber) - data.companyAgeYears)
            insight = "\(stock.name)'s next Saturn Return is ~\(yearsUntil) years away. Current phase: steady growth and execution."
        }

        return SaturnReturnHistoricalInsight(
            symbol: stock.symbol,
            insight: insight,
            historicalEvent: nil,
            outcome: nil
        )
    }

    // MARK: - Known Founding Dates

    private func loadKnownFoundingDates() {
        let calendar = Calendar.current

        func date(year: Int, month: Int, day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
        }

        companyFoundingDates = [
            // Tech Giants
            "AAPL": date(year: 1976, month: 4, day: 1),      // Apple
            "MSFT": date(year: 1975, month: 4, day: 4),      // Microsoft
            "GOOGL": date(year: 1998, month: 9, day: 4),     // Google/Alphabet
            "AMZN": date(year: 1994, month: 7, day: 5),      // Amazon
            "META": date(year: 2004, month: 2, day: 4),      // Meta (Facebook)
            "NVDA": date(year: 1993, month: 1, day: 1),      // NVIDIA
            "TSLA": date(year: 2003, month: 7, day: 1),      // Tesla
            "NFLX": date(year: 1997, month: 8, day: 29),     // Netflix
            "AMD": date(year: 1969, month: 5, day: 1),       // AMD
            "INTC": date(year: 1968, month: 7, day: 18),     // Intel
            "CRM": date(year: 1999, month: 3, day: 8),       // Salesforce
            "ORCL": date(year: 1977, month: 6, day: 16),     // Oracle
            "IBM": date(year: 1911, month: 6, day: 16),      // IBM
            "CSCO": date(year: 1984, month: 12, day: 10),    // Cisco
            "ADBE": date(year: 1982, month: 12, day: 1),     // Adobe

            // Finance
            "JPM": date(year: 1799, month: 1, day: 1),       // JPMorgan (Bank of Manhattan)
            "BAC": date(year: 1904, month: 10, day: 17),     // Bank of America
            "WFC": date(year: 1852, month: 3, day: 18),      // Wells Fargo
            "GS": date(year: 1869, month: 1, day: 1),        // Goldman Sachs
            "V": date(year: 1958, month: 9, day: 18),        // Visa
            "MA": date(year: 1966, month: 1, day: 1),        // Mastercard

            // Healthcare
            "JNJ": date(year: 1886, month: 1, day: 1),       // Johnson & Johnson
            "PFE": date(year: 1849, month: 1, day: 1),       // Pfizer
            "UNH": date(year: 1977, month: 1, day: 1),       // UnitedHealth
            "ABBV": date(year: 2013, month: 1, day: 1),      // AbbVie (spun off)
            "MRK": date(year: 1891, month: 1, day: 1),       // Merck

            // Consumer
            "KO": date(year: 1892, month: 1, day: 29),       // Coca-Cola
            "PEP": date(year: 1965, month: 1, day: 1),       // PepsiCo
            "WMT": date(year: 1962, month: 7, day: 2),       // Walmart
            "HD": date(year: 1978, month: 6, day: 22),       // Home Depot
            "NKE": date(year: 1964, month: 1, day: 25),      // Nike
            "MCD": date(year: 1955, month: 4, day: 15),      // McDonald's
            "SBUX": date(year: 1971, month: 3, day: 30),     // Starbucks
            "DIS": date(year: 1923, month: 10, day: 16),     // Disney

            // Industrial
            "BA": date(year: 1916, month: 7, day: 15),       // Boeing
            "CAT": date(year: 1925, month: 4, day: 15),      // Caterpillar
            "GE": date(year: 1892, month: 4, day: 15),       // General Electric
            "MMM": date(year: 1902, month: 1, day: 1),       // 3M
            "HON": date(year: 1906, month: 1, day: 1),       // Honeywell

            // Energy
            "XOM": date(year: 1870, month: 1, day: 10),      // ExxonMobil (Standard Oil)
            "CVX": date(year: 1879, month: 9, day: 10),      // Chevron

            // Telecom
            "T": date(year: 1983, month: 1, day: 1),         // AT&T (post-breakup)
            "VZ": date(year: 1983, month: 10, day: 7),       // Verizon (Bell Atlantic)
        ]
    }

    // MARK: - Historical Insights Database

    private var historicalInsights: [String: SaturnReturnHistoricalInsight] {
        [
            "AAPL": SaturnReturnHistoricalInsight(
                symbol: "AAPL",
                insight: "Apple's first Saturn Return (~2005) preceded one of the greatest corporate pivots in history.",
                historicalEvent: "Steve Jobs announced Apple would transition Macs to Intel processors, and the iPhone was secretly in development.",
                outcome: "Apple transformed from a computer company to the world's most valuable consumer electronics company."
            ),
            "MSFT": SaturnReturnHistoricalInsight(
                symbol: "MSFT",
                insight: "Microsoft's first Saturn Return (~2004) marked the beginning of its identity crisis before cloud transformation.",
                historicalEvent: "Windows XP security issues, antitrust battles, and the missed mobile revolution created existential pressure.",
                outcome: "Eventually led to Satya Nadella's appointment and the Azure-first strategy that revitalized the company."
            ),
            "AMZN": SaturnReturnHistoricalInsight(
                symbol: "AMZN",
                insight: "Amazon approached its first Saturn Return (~2023-2024) amid AI transformation pressure.",
                historicalEvent: "AWS growth slowing, retail competition intensifying, and the generative AI revolution requiring massive investment.",
                outcome: "Amazon doubled down on AI integration across all services and cost optimization measures."
            ),
            "NVDA": SaturnReturnHistoricalInsight(
                symbol: "NVDA",
                insight: "NVIDIA's Saturn Return (~2022-2023) coincided with its emergence as the AI infrastructure leader.",
                historicalEvent: "The ChatGPT moment created unprecedented demand for NVIDIA's GPUs, transforming the company's trajectory.",
                outcome: "NVIDIA became one of the most valuable companies in the world, validating years of AI investment."
            ),
            "DIS": SaturnReturnHistoricalInsight(
                symbol: "DIS",
                insight: "Disney has experienced multiple Saturn Returns across its century-long history.",
                historicalEvent: "Its ~1952 Saturn Return preceded Disneyland. Its ~1981 return saw EPCOT and leadership turmoil.",
                outcome: "Each Saturn Return brought major theme park expansion or strategic pivots."
            ),
            "NFLX": SaturnReturnHistoricalInsight(
                symbol: "NFLX",
                insight: "Netflix approaches its first Saturn Return (~2026-2027).",
                historicalEvent: "Password sharing crackdown, ad-tier launch, and live events signal the maturation phase.",
                outcome: "TBD — Watch for major strategic shifts as Saturn Return approaches."
            )
        ]
    }
}

// MARK: - Supporting Types

struct SaturnReturnData: Identifiable {
    let id = UUID()
    let symbol: String
    let foundingDate: Date
    let companyAgeYears: Double
    let currentSaturnReturnNumber: Int
    let nextSaturnReturnDate: Date
    let previousSaturnReturnDate: Date?
    let status: SaturnReturnStatus

    var isInSaturnReturn: Bool {
        status == .inSaturnReturn
    }

    var isApproaching: Bool {
        status == .approaching
    }

    var formattedAge: String {
        let years = Int(companyAgeYears)
        let months = Int((companyAgeYears - Double(years)) * 12)
        if months > 0 {
            return "\(years) years, \(months) months"
        }
        return "\(years) years"
    }

    var formattedNextDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: nextSaturnReturnDate)
    }

    var progressToNextReturn: Double {
        let periodYears = SaturnReturnService.saturnOrbitalPeriod
        let yearsIntoCurrentCycle = companyAgeYears.truncatingRemainder(dividingBy: periodYears)
        return yearsIntoCurrentCycle / periodYears
    }
}

enum SaturnReturnStatus: String {
    case approaching = "Approaching"
    case inSaturnReturn = "In Saturn Return"
    case recentlyCompleted = "Recently Completed"
    case distant = "Distant"

    var color: Color {
        switch self {
        case .inSaturnReturn: return .orange
        case .approaching: return CosmicTheme.gold
        case .recentlyCompleted: return CosmicTheme.positive
        case .distant: return CosmicTheme.textMuted
        }
    }

    var icon: String {
        switch self {
        case .inSaturnReturn: return "exclamationmark.triangle.fill"
        case .approaching: return "clock.fill"
        case .recentlyCompleted: return "checkmark.circle.fill"
        case .distant: return "moon.zzz.fill"
        }
    }
}

struct SaturnReturnAlert: Identifiable {
    let id = UUID()
    let stock: Stock
    let data: SaturnReturnData
    let headline: String
    let message: String
    let daysUntil: Int
    let urgency: Urgency

    enum Urgency {
        case low, medium, high

        var color: Color {
            switch self {
            case .low: return CosmicTheme.textSecondary
            case .medium: return CosmicTheme.gold
            case .high: return .orange
            }
        }
    }
}

struct SaturnReturnHistoricalInsight: Identifiable {
    let id = UUID()
    let symbol: String
    let insight: String
    let historicalEvent: String?
    let outcome: String?
}

// MARK: - Analytics Events

extension AnalyticsEvent {
    static let saturnReturnViewed = AnalyticsEvent(rawValue: "saturn_return_viewed")!
    static let saturnReturnAlertTapped = AnalyticsEvent(rawValue: "saturn_return_alert_tapped")!
}
