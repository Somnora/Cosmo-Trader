import Foundation
import SwiftUI

// MARK: - On This Day Service
// ============================
// Historical market tidbits for each day of the year.
// "On Dec 12, 1980, Apple went public (Sagittarius). Initial investors
// saw 50,000% returns. The archer aimed high."
//
// WHY IT WORKS: Daily content. Educational. Shareable. Cosmic tie-in.

@MainActor
@Observable
final class OnThisDayService {

    // MARK: - Singleton

    static let shared = OnThisDayService()

    // MARK: - State

    /// Today's historical event
    private(set) var todaysEvent: HistoricalMarketEvent?

    /// Cache of events by month-day key
    private var eventCache: [String: HistoricalMarketEvent] = [:]

    // MARK: - Initialization

    private init() {
        loadTodaysEvent()
    }

    // MARK: - Public Methods

    /// Get the event for today
    func getTodaysEvent() -> HistoricalMarketEvent {
        if let cached = todaysEvent {
            return cached
        }
        loadTodaysEvent()
        return todaysEvent ?? HistoricalMarketEvent.fallback
    }

    /// Get event for a specific date
    func getEvent(for date: Date) -> HistoricalMarketEvent {
        let key = dateKey(for: date)
        if let cached = eventCache[key] {
            return cached
        }

        let event = findEvent(for: date)
        eventCache[key] = event
        return event
    }

    /// Refresh today's event (call at midnight or app foreground)
    func refresh() {
        loadTodaysEvent()
    }

    // MARK: - Private Methods

    private func loadTodaysEvent() {
        todaysEvent = findEvent(for: Date())
    }

    private func dateKey(for date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(month)-\(day)"
    }

    private func findEvent(for date: Date) -> HistoricalMarketEvent {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // Find exact match first
        if let exact = HistoricalMarketEvent.allEvents.first(where: {
            $0.month == month && $0.day == day
        }) {
            return exact
        }

        // Fall back to same month, closest day
        let sameMonth = HistoricalMarketEvent.allEvents.filter { $0.month == month }
        if let closest = sameMonth.min(by: { abs($0.day - day) < abs($1.day - day) }) {
            return closest
        }

        // Ultimate fallback - use day of year to pick deterministically
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = dayOfYear % HistoricalMarketEvent.allEvents.count
        return HistoricalMarketEvent.allEvents[index]
    }
}

// MARK: - Historical Market Event

struct HistoricalMarketEvent: Identifiable {
    let id = UUID()
    let month: Int
    let day: Int
    let year: Int
    let headline: String
    let detail: String
    let cosmicTakeaway: String
    let zodiacSign: ZodiacSign
    let category: EventCategory

    enum EventCategory: String {
        case ipo = "IPO"
        case crash = "Crash"
        case milestone = "Milestone"
        case merger = "M&A"
        case innovation = "Innovation"
        case regulation = "Regulation"
        case bubble = "Bubble"
        case recovery = "Recovery"

        var icon: String {
            switch self {
            case .ipo: return "star.fill"
            case .crash: return "chart.line.downtrend.xyaxis"
            case .milestone: return "flag.fill"
            case .merger: return "arrow.triangle.merge"
            case .innovation: return "lightbulb.fill"
            case .regulation: return "building.columns.fill"
            case .bubble: return "bubble.fill"
            case .recovery: return "arrow.up.heart.fill"
            }
        }

        var color: Color {
            switch self {
            case .ipo: return .green
            case .crash: return .red
            case .milestone: return .blue
            case .merger: return .purple
            case .innovation: return .orange
            case .regulation: return .gray
            case .bubble: return .pink
            case .recovery: return .teal
            }
        }
    }

    /// Formatted date string
    var formattedDate: String {
        let monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return "\(monthNames[month]) \(day), \(year)"
    }

    /// Full display text
    var fullText: String {
        "On \(formattedDate), \(headline) (\(zodiacSign.displayName)). \(detail) \(cosmicTakeaway)"
    }

    /// Shareable text
    var shareableText: String {
        "📅 On This Day in Cosmic Markets\n\n\(zodiacSign.symbol) \(formattedDate)\n\n\(headline)\n\n\(detail)\n\n✨ \(cosmicTakeaway)\n\n— Cosmo Trader"
    }

    /// Fallback event
    static let fallback = HistoricalMarketEvent(
        month: 1,
        day: 1,
        year: 1792,
        headline: "the Buttonwood Agreement was signed",
        detail: "24 stockbrokers gathered under a buttonwood tree on Wall Street, founding what would become the NYSE.",
        cosmicTakeaway: "Capricorn energy built institutions that last centuries.",
        zodiacSign: .capricorn,
        category: .milestone
    )
}

// MARK: - Historical Events Database

extension HistoricalMarketEvent {

    /// All historical market events
    static let allEvents: [HistoricalMarketEvent] = [
        // JANUARY
        HistoricalMarketEvent(
            month: 1, day: 3, year: 1977,
            headline: "Apple Computer was incorporated",
            detail: "Steve Jobs, Steve Wozniak, and Ronald Wayne filed the paperwork in California.",
            cosmicTakeaway: "Capricorn's discipline met Aquarian innovation.",
            zodiacSign: .capricorn,
            category: .milestone
        ),
        HistoricalMarketEvent(
            month: 1, day: 8, year: 1889,
            headline: "Herman Hollerith patented the electric tabulating machine",
            detail: "This invention would eventually lead to the founding of IBM.",
            cosmicTakeaway: "Capricorn builds the foundations of future empires.",
            zodiacSign: .capricorn,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 1, day: 14, year: 2000,
            headline: "the Dow hit its dot-com peak of 11,722",
            detail: "The bubble was about to burst. Two months later, the crash began.",
            cosmicTakeaway: "Capricorn warns: what goes up must come down.",
            zodiacSign: .capricorn,
            category: .bubble
        ),
        HistoricalMarketEvent(
            month: 1, day: 22, year: 1984,
            headline: "Apple aired the '1984' Super Bowl commercial",
            detail: "The Macintosh was introduced. The ad only ran once but changed advertising forever.",
            cosmicTakeaway: "Aquarius disrupts the status quo with style.",
            zodiacSign: .aquarius,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 1, day: 28, year: 1986,
            headline: "the Space Shuttle Challenger disaster occurred",
            detail: "Markets dropped as the nation mourned. Aerospace stocks plummeted.",
            cosmicTakeaway: "Aquarius reminds us that innovation carries risk.",
            zodiacSign: .aquarius,
            category: .crash
        ),

        // FEBRUARY
        HistoricalMarketEvent(
            month: 2, day: 4, year: 2004,
            headline: "Facebook was launched from a Harvard dorm room",
            detail: "Mark Zuckerberg's 'TheFacebook' would become a $1 trillion company.",
            cosmicTakeaway: "Aquarius connects humanity, for better or worse.",
            zodiacSign: .aquarius,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 2, day: 8, year: 1971,
            headline: "NASDAQ began trading",
            detail: "The first electronic stock exchange revolutionized how markets operate.",
            cosmicTakeaway: "Aquarius brings the future into the present.",
            zodiacSign: .aquarius,
            category: .milestone
        ),
        HistoricalMarketEvent(
            month: 2, day: 19, year: 2002,
            headline: "Hewlett-Packard acquired Compaq",
            detail: "The controversial $25 billion merger reshaped the PC industry.",
            cosmicTakeaway: "Pisces merges two into one, sometimes messily.",
            zodiacSign: .pisces,
            category: .merger
        ),
        HistoricalMarketEvent(
            month: 2, day: 27, year: 1991,
            headline: "the Gulf War ended",
            detail: "Markets rallied on peace. Oil prices stabilized.",
            cosmicTakeaway: "Pisces seeks peace, and markets reward it.",
            zodiacSign: .pisces,
            category: .recovery
        ),

        // MARCH
        HistoricalMarketEvent(
            month: 3, day: 9, year: 2009,
            headline: "the S&P 500 hit its Great Recession low of 676",
            detail: "Those who bought at the bottom saw 600%+ returns over the next decade.",
            cosmicTakeaway: "Pisces intuition saw opportunity in despair.",
            zodiacSign: .pisces,
            category: .recovery
        ),
        HistoricalMarketEvent(
            month: 3, day: 10, year: 2000,
            headline: "the NASDAQ peaked at 5,048",
            detail: "The dot-com bubble burst the next day. It took 15 years to recover.",
            cosmicTakeaway: "Pisces dreams can become delusions.",
            zodiacSign: .pisces,
            category: .bubble
        ),
        HistoricalMarketEvent(
            month: 3, day: 14, year: 2012,
            headline: "Apple's market cap exceeded $500 billion",
            detail: "The first company to reach this milestone under Tim Cook's leadership.",
            cosmicTakeaway: "Pisces creativity builds lasting value.",
            zodiacSign: .pisces,
            category: .milestone
        ),
        HistoricalMarketEvent(
            month: 3, day: 23, year: 2020,
            headline: "the Fed announced unlimited QE",
            detail: "Markets bottomed and began a historic recovery during the pandemic.",
            cosmicTakeaway: "Aries charges forward when others freeze.",
            zodiacSign: .aries,
            category: .recovery
        ),

        // APRIL
        HistoricalMarketEvent(
            month: 4, day: 1, year: 1976,
            headline: "Apple Computer Company was founded",
            detail: "Jobs and Wozniak started building computers in a garage.",
            cosmicTakeaway: "Aries has the courage to start from nothing.",
            zodiacSign: .aries,
            category: .milestone
        ),
        HistoricalMarketEvent(
            month: 4, day: 3, year: 2010,
            headline: "the first iPad went on sale",
            detail: "Apple sold 300,000 units on day one. A new category was born.",
            cosmicTakeaway: "Aries pioneers new territory.",
            zodiacSign: .aries,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 4, day: 14, year: 2003,
            headline: "the Human Genome Project was completed",
            detail: "Biotech stocks surged on hopes of personalized medicine.",
            cosmicTakeaway: "Aries conquers the final frontier: ourselves.",
            zodiacSign: .aries,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 4, day: 18, year: 2019,
            headline: "Disney+ was announced",
            detail: "Disney stock jumped 12% as streaming wars began in earnest.",
            cosmicTakeaway: "Aries disrupts even its own business model.",
            zodiacSign: .aries,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 4, day: 28, year: 2020,
            headline: "oil futures went negative for the first time",
            detail: "Producers literally paid buyers to take oil. Unprecedented.",
            cosmicTakeaway: "Taurus reminds us: even the most stable assets can surprise.",
            zodiacSign: .taurus,
            category: .crash
        ),

        // MAY
        HistoricalMarketEvent(
            month: 5, day: 6, year: 2010,
            headline: "the Flash Crash occurred",
            detail: "The Dow dropped 1,000 points in minutes, then recovered. Algorithms gone wild.",
            cosmicTakeaway: "Taurus stability was tested by digital chaos.",
            zodiacSign: .taurus,
            category: .crash
        ),
        HistoricalMarketEvent(
            month: 5, day: 10, year: 1869,
            headline: "the Transcontinental Railroad was completed",
            detail: "Railroad stocks soared. America was connected coast to coast.",
            cosmicTakeaway: "Taurus builds infrastructure that lasts generations.",
            zodiacSign: .taurus,
            category: .milestone
        ),
        HistoricalMarketEvent(
            month: 5, day: 18, year: 2012,
            headline: "Facebook went public at $38 per share",
            detail: "The IPO was plagued by glitches. The stock dropped 50% before recovering.",
            cosmicTakeaway: "Taurus patience was required for those who held.",
            zodiacSign: .taurus,
            category: .ipo
        ),
        HistoricalMarketEvent(
            month: 5, day: 26, year: 1896,
            headline: "the Dow Jones Industrial Average was first published",
            detail: "Charles Dow created the index with 12 stocks. Only GE remained by 2018.",
            cosmicTakeaway: "Gemini communicates market truth through numbers.",
            zodiacSign: .gemini,
            category: .milestone
        ),

        // JUNE
        HistoricalMarketEvent(
            month: 6, day: 5, year: 2017,
            headline: "Apple announced the HomePod",
            detail: "Entering the smart speaker market against Amazon and Google.",
            cosmicTakeaway: "Gemini adapts to new conversations.",
            zodiacSign: .gemini,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 6, day: 16, year: 1884,
            headline: "the first roller coaster opened at Coney Island",
            detail: "Entertainment stocks would become a legitimate sector.",
            cosmicTakeaway: "Gemini knows markets are a thrill ride.",
            zodiacSign: .gemini,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 6, day: 23, year: 2016,
            headline: "Brexit referendum shocked markets",
            detail: "The pound crashed 10%. Global markets lost $2 trillion overnight.",
            cosmicTakeaway: "Cancer's need for security was challenged.",
            zodiacSign: .cancer,
            category: .crash
        ),
        HistoricalMarketEvent(
            month: 6, day: 29, year: 2007,
            headline: "the first iPhone went on sale",
            detail: "People camped for days. Apple would become the most valuable company ever.",
            cosmicTakeaway: "Cancer nurtures products people love like family.",
            zodiacSign: .cancer,
            category: .innovation
        ),

        // JULY
        HistoricalMarketEvent(
            month: 7, day: 5, year: 1994,
            headline: "Amazon was incorporated",
            detail: "Jeff Bezos started selling books online from his garage.",
            cosmicTakeaway: "Cancer builds from home, then takes over the world.",
            zodiacSign: .cancer,
            category: .milestone
        ),
        HistoricalMarketEvent(
            month: 7, day: 9, year: 1997,
            headline: "Apple announced Steve Jobs would return",
            detail: "The stock was at $3.30. It would eventually reach $180+ (split-adjusted).",
            cosmicTakeaway: "Cancer returns home to save the family.",
            zodiacSign: .cancer,
            category: .recovery
        ),
        HistoricalMarketEvent(
            month: 7, day: 20, year: 1969,
            headline: "Apollo 11 landed on the moon",
            detail: "Aerospace and defense stocks soared. American confidence peaked.",
            cosmicTakeaway: "Cancer's intuition took humanity to new heights.",
            zodiacSign: .cancer,
            category: .milestone
        ),
        HistoricalMarketEvent(
            month: 7, day: 29, year: 2015,
            headline: "Windows 10 was released",
            detail: "Microsoft offered free upgrades, betting on ecosystem lock-in.",
            cosmicTakeaway: "Leo commands attention with generous gestures.",
            zodiacSign: .leo,
            category: .innovation
        ),

        // AUGUST
        HistoricalMarketEvent(
            month: 8, day: 2, year: 2018,
            headline: "Apple became the first $1 trillion company",
            detail: "Four decades from garage startup to historic milestone.",
            cosmicTakeaway: "Leo's ambition knows no ceiling.",
            zodiacSign: .leo,
            category: .milestone
        ),
        HistoricalMarketEvent(
            month: 8, day: 9, year: 1995,
            headline: "Netscape went public",
            detail: "The stock doubled on day one. The internet gold rush began.",
            cosmicTakeaway: "Leo takes center stage in a new era.",
            zodiacSign: .leo,
            category: .ipo
        ),
        HistoricalMarketEvent(
            month: 8, day: 19, year: 2004,
            headline: "Google went public at $85 per share",
            detail: "The unconventional Dutch auction IPO made millionaires of early employees.",
            cosmicTakeaway: "Leo disrupts even how IPOs work.",
            zodiacSign: .leo,
            category: .ipo
        ),
        HistoricalMarketEvent(
            month: 8, day: 24, year: 2015,
            headline: "China's 'Black Monday' crashed global markets",
            detail: "The Dow dropped 1,000 points at open. Fear spread worldwide.",
            cosmicTakeaway: "Virgo's careful analysis was overwhelmed by panic.",
            zodiacSign: .virgo,
            category: .crash
        ),

        // SEPTEMBER
        HistoricalMarketEvent(
            month: 9, day: 4, year: 1998,
            headline: "Google was founded",
            detail: "Larry Page and Sergey Brin incorporated in a Menlo Park garage.",
            cosmicTakeaway: "Virgo organizes the world's information.",
            zodiacSign: .virgo,
            category: .milestone
        ),
        HistoricalMarketEvent(
            month: 9, day: 12, year: 2017,
            headline: "Apple unveiled iPhone X",
            detail: "Face ID and the $999 price point changed smartphone economics.",
            cosmicTakeaway: "Virgo perfects until perfection commands a premium.",
            zodiacSign: .virgo,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 9, day: 15, year: 2008,
            headline: "Lehman Brothers filed for bankruptcy",
            detail: "The largest bankruptcy in US history. The Great Recession had begun.",
            cosmicTakeaway: "Virgo's warnings about risk were ignored.",
            zodiacSign: .virgo,
            category: .crash
        ),
        HistoricalMarketEvent(
            month: 9, day: 29, year: 2008,
            headline: "the Dow dropped 777 points",
            detail: "Congress rejected the first bailout. Largest single-day point drop ever at the time.",
            cosmicTakeaway: "Libra's search for balance found only chaos.",
            zodiacSign: .libra,
            category: .crash
        ),

        // OCTOBER
        HistoricalMarketEvent(
            month: 10, day: 1, year: 1908,
            headline: "the Ford Model T was introduced",
            detail: "At $825, the automobile became accessible to the masses.",
            cosmicTakeaway: "Libra democratizes luxury.",
            zodiacSign: .libra,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 10, day: 19, year: 1987,
            headline: "Black Monday crashed markets 22%",
            detail: "The Dow's largest single-day percentage drop ever. Program trading blamed.",
            cosmicTakeaway: "Libra's scales tipped violently.",
            zodiacSign: .libra,
            category: .crash
        ),
        HistoricalMarketEvent(
            month: 10, day: 24, year: 1929,
            headline: "Black Thursday began the Great Depression",
            detail: "Panic selling erased years of gains. The Roaring Twenties ended.",
            cosmicTakeaway: "Scorpio's intensity can destroy as well as create.",
            zodiacSign: .scorpio,
            category: .crash
        ),
        HistoricalMarketEvent(
            month: 10, day: 27, year: 1997,
            headline: "the Asian financial crisis hit Wall Street",
            detail: "The Dow dropped 554 points. Trading was halted for the first time.",
            cosmicTakeaway: "Scorpio's secrets in Asia became global contagion.",
            zodiacSign: .scorpio,
            category: .crash
        ),

        // NOVEMBER
        HistoricalMarketEvent(
            month: 11, day: 1, year: 2007,
            headline: "Google hit $700 per share",
            detail: "The stock had grown 800% since IPO. Search dominated.",
            cosmicTakeaway: "Scorpio digs deep to find hidden value.",
            zodiacSign: .scorpio,
            category: .milestone
        ),
        HistoricalMarketEvent(
            month: 11, day: 10, year: 2017,
            headline: "Bitcoin hit $7,000",
            detail: "The crypto bull run was just beginning. $20,000 awaited.",
            cosmicTakeaway: "Scorpio loves secrets, and crypto has plenty.",
            zodiacSign: .scorpio,
            category: .bubble
        ),
        HistoricalMarketEvent(
            month: 11, day: 21, year: 1995,
            headline: "Pixar went public",
            detail: "Steve Jobs' 'other' company. The stock rose 77% on day one.",
            cosmicTakeaway: "Sagittarius tells stories that captivate the world.",
            zodiacSign: .sagittarius,
            category: .ipo
        ),
        HistoricalMarketEvent(
            month: 11, day: 28, year: 2005,
            headline: "the Xbox 360 launched",
            detail: "Microsoft's gaming bet paid off. Entertainment became a pillar.",
            cosmicTakeaway: "Sagittarius plays to win.",
            zodiacSign: .sagittarius,
            category: .innovation
        ),

        // DECEMBER
        HistoricalMarketEvent(
            month: 12, day: 5, year: 1933,
            headline: "Prohibition ended",
            detail: "Alcohol stocks surged. A new industry was legitimized.",
            cosmicTakeaway: "Sagittarius celebrates freedom and excess.",
            zodiacSign: .sagittarius,
            category: .regulation
        ),
        HistoricalMarketEvent(
            month: 12, day: 12, year: 1980,
            headline: "Apple went public at $22 per share",
            detail: "Initial investors saw 50,000%+ returns. The archer aimed high.",
            cosmicTakeaway: "Sagittarius shoots for the stars and lands among them.",
            zodiacSign: .sagittarius,
            category: .ipo
        ),
        HistoricalMarketEvent(
            month: 12, day: 17, year: 2017,
            headline: "Bitcoin peaked at nearly $20,000",
            detail: "The crypto bubble burst days later. 80% crash followed.",
            cosmicTakeaway: "Sagittarius optimism needs Capricorn reality checks.",
            zodiacSign: .sagittarius,
            category: .bubble
        ),
        HistoricalMarketEvent(
            month: 12, day: 21, year: 2010,
            headline: "Netflix announced streaming-only plans",
            detail: "The pivot from DVDs. Blockbuster filed for bankruptcy months earlier.",
            cosmicTakeaway: "Capricorn's long-term vision destroys short-term thinkers.",
            zodiacSign: .capricorn,
            category: .innovation
        ),
        HistoricalMarketEvent(
            month: 12, day: 24, year: 2018,
            headline: "the worst Christmas Eve trading day ever",
            detail: "The Dow dropped 653 points. Fear of recession peaked.",
            cosmicTakeaway: "Capricorn endures the darkest days before the light.",
            zodiacSign: .capricorn,
            category: .crash
        ),
        HistoricalMarketEvent(
            month: 12, day: 31, year: 1999,
            headline: "Y2K fears peaked",
            detail: "Markets closed with uncertainty. The world held its breath.",
            cosmicTakeaway: "Capricorn's preparation prevented catastrophe.",
            zodiacSign: .capricorn,
            category: .milestone
        ),
    ]
}

// MARK: - Analytics Events

extension AnalyticsEvent {
    static let onThisDayViewed = AnalyticsEvent(rawValue: "on_this_day_viewed")!
    static let onThisDayShared = AnalyticsEvent(rawValue: "on_this_day_shared")!
}
