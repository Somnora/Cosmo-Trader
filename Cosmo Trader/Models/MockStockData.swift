import Foundation

// MARK: - MockStockData
// =====================
// A collection of real companies with verified founding dates.
// These dates determine each company's zodiac sign.
//
// SOURCES FOR FOUNDING DATES:
// - SEC filings (incorporation dates)
// - Official company histories
// - Wikipedia (cross-referenced)
//
// NOTE: Some companies have disputed founding dates. We use the most
// commonly cited incorporation or founding date.

struct MockStockData {

    // MARK: - Mock-Only Stocks

    /// Fallback stocks not already canonically sourced in `Stock.samples`.
    /// If a symbol exists in `Stock.samples`, remove it from this list so the
    /// sourced curated table stays the single source of truth.
    static let all: [Stock] = [

        // Pfizer Inc. - Founded April 25, 1849
        // Charles Pfizer and Charles Erhart in Brooklyn, NY
        Stock(
            symbol: "PFE",
            name: "Pfizer Inc.",
            currentPrice: 28.73,
            priceChange: 0.42,
            percentageChange: 1.48,
            sharesOwned: 0,
            foundedMonth: 4, foundedDay: 25, foundedYear: 1849,
            sector: "Healthcare"
        ),

        // Hewlett-Packard (HP Inc.) - Founded May 24, 1939
        // Bill Hewlett and David Packard in Palo Alto garage
        Stock(
            symbol: "HPQ",
            name: "HP Inc.",
            currentPrice: 29.84,
            priceChange: -0.52,
            percentageChange: -1.71,
            sharesOwned: 0,
            foundedMonth: 5, foundedDay: 24, foundedYear: 1939,
            sector: "Technology"
        ),

        // Berkshire Hathaway - Founded September 6, 1889
        // Originally a textile company, transformed by Buffett
        // CEO: Warren Buffett (born August 30, 1930 - Virgo)
        Stock(
            symbol: "BRK.B",
            name: "Berkshire Hathaway Inc.",
            currentPrice: 363.45,
            priceChange: 2.10,
            percentageChange: 0.58,
            sharesOwned: 0,
            foundedMonth: 9, foundedDay: 6, foundedYear: 1889,
            sector: "Finance",
            ceoName: "Warren Buffett",
            ceoBirthMonth: 8, ceoBirthDay: 30, ceoBirthYear: 1930
        ),

        // AT&T Inc. - Founded January 3, 1885 (American Telephone & Telegraph)
        // Alexander Graham Bell's company
        Stock(
            symbol: "T",
            name: "AT&T Inc.",
            currentPrice: 17.89,
            priceChange: 0.12,
            percentageChange: 0.68,
            sharesOwned: 0,
            foundedMonth: 1, foundedDay: 3, foundedYear: 1885,
            sector: "Communication Services"
        ),

        // Johnson & Johnson - Founded January 5, 1886
        // Robert, James, and Edward Johnson in New Brunswick, NJ
        Stock(
            symbol: "JNJ",
            name: "Johnson & Johnson",
            currentPrice: 156.78,
            priceChange: -0.45,
            percentageChange: -0.29,
            sharesOwned: 0,
            foundedMonth: 1, foundedDay: 5, foundedYear: 1886,
            sector: "Healthcare"
        ),

        // Adobe Inc. - Founded February 26, 1982
        // John Warnock and Charles Geschke
        Stock(
            symbol: "ADBE",
            name: "Adobe Inc.",
            currentPrice: 524.67,
            priceChange: 7.89,
            percentageChange: 1.53,
            sharesOwned: 0,
            foundedMonth: 2, foundedDay: 26, foundedYear: 1982,
            sector: "Technology"
        ),

        // UnitedHealth Group - Founded March 15, 1974
        Stock(
            symbol: "UNH",
            name: "UnitedHealth Group Inc.",
            currentPrice: 527.89,
            priceChange: -4.56,
            percentageChange: -0.86,
            sharesOwned: 0,
            foundedMonth: 3, foundedDay: 15, foundedYear: 1974,
            sector: "Healthcare"
        )
    ]

    /// Full app stock universe: sourced curated symbols first, then mock-only
    /// fallback symbols.
    static var knownStocks: [Stock] {
        Stock.samples + all
    }

    // MARK: - Stocks by Zodiac Sign

    /// All stocks grouped by their zodiac sign
    static var bySign: [ZodiacSign: [Stock]] {
        var groups: [ZodiacSign: [Stock]] = [:]
        for stock in knownStocks {
            guard let sign = stock.zodiacSign else { continue }
            groups[sign, default: []].append(stock)
        }
        return groups
    }

    /// Get stocks for a specific zodiac sign
    static func stocks(for sign: ZodiacSign) -> [Stock] {
        bySign[sign] ?? []
    }

    // MARK: - Stocks by Sector

    /// All stocks grouped by sector
    static var bySector: [String: [Stock]] {
        Dictionary(grouping: knownStocks) { $0.sector }
    }

    /// Get stocks for a specific sector
    static func stocks(forSector sector: String) -> [Stock] {
        bySector[sector] ?? []
    }

    /// List of all available sectors
    static var allSectors: [String] {
        Array(Set(knownStocks.map { $0.sector })).sorted()
    }

    // MARK: - Stocks by Element

    /// All stocks grouped by their zodiac element
    static var byElement: [ZodiacSign.Element: [Stock]] {
        var groups: [ZodiacSign.Element: [Stock]] = [:]
        for stock in knownStocks {
            guard let element = stock.element else { continue }
            groups[element, default: []].append(stock)
        }
        return groups
    }

    /// Get stocks for a specific element
    static func stocks(for element: ZodiacSign.Element) -> [Stock] {
        byElement[element] ?? []
    }

    // MARK: - Featured Stocks

    /// A curated list of 6 popular, well-known companies
    /// Good for showcasing on home screens or onboarding
    static var featured: [Stock] {
        let featuredSymbols = ["AAPL", "TSLA", "GOOGL", "AMZN", "DIS", "NVDA"]
        return knownStocks.filter { featuredSymbols.contains($0.symbol) }
    }

    // MARK: - Top Movers

    /// Stocks with the highest positive change today
    static var topGainers: [Stock] {
        knownStocks.filter { $0.percentageChange > 0 }
            .sorted { $0.percentageChange > $1.percentageChange }
    }

    /// Stocks with the most negative change today
    static var topLosers: [Stock] {
        knownStocks.filter { $0.percentageChange < 0 }
            .sorted { $0.percentageChange < $1.percentageChange }
    }

    // MARK: - Search

    /// Search stocks by symbol or name
    static func search(_ query: String) -> [Stock] {
        guard !query.isEmpty else { return knownStocks }
        let lowercased = query.lowercased()
        return knownStocks.filter {
            $0.symbol.lowercased().contains(lowercased) ||
            $0.name.lowercased().contains(lowercased)
        }
    }

    // MARK: - Random Selection

    /// Get a random stock (useful for demos)
    static var random: Stock {
        knownStocks.randomElement() ?? Stock.sample
    }

    /// Get n random stocks
    static func random(_ count: Int) -> [Stock] {
        Array(knownStocks.shuffled().prefix(count))
    }

    // MARK: - Statistics

    /// Total number of stocks
    static var count: Int { knownStocks.count }

    /// Number of stocks per zodiac sign
    static var signDistribution: [(sign: ZodiacSign, count: Int)] {
        ZodiacSign.allCases.map { sign in
            (sign: sign, count: stocks(for: sign).count)
        }
    }

    /// Verification that all 12 signs are represented
    static var allSignsRepresented: Bool {
        ZodiacSign.allCases.allSatisfy { !stocks(for: $0).isEmpty }
    }
}

// MARK: - Zodiac Sign Distribution Summary
/*
 Sign Distribution (30 stocks total):
 ────────────────────────────────────
 ♈ Aries (Mar 21-Apr 19):      AAPL, MSFT
 ♉ Taurus (Apr 20-May 20):     KO, PFE
 ♊ Gemini (May 21-Jun 20):     HPQ, BA
 ♋ Cancer (Jun 21-Jul 22):     TSLA, AMZN, XOM, HD
 ♌ Leo (Jul 23-Aug 22):        F, PG
 ♍ Virgo (Aug 23-Sep 22):      GOOGL, NFLX, BRK.B, CVX
 ♎ Libra (Sep 23-Oct 22):      NKE, JPM
 ♏ Scorpio (Oct 23-Nov 21):    V, MCD, MA
 ♐ Sagittarius (Nov 22-Dec 21): DIS, COST
 ♑ Capricorn (Dec 22-Jan 19):  T, GE, JNJ
 ♒ Aquarius (Jan 20-Feb 18):   NVDA, META, INTC
 ♓ Pisces (Feb 19-Mar 20):     SBUX, ADBE, WMT, UNH

 Element Distribution:
 ────────────────────
 🔥 Fire (Aries, Leo, Sag):    6 stocks
 🌍 Earth (Taurus, Virgo, Cap): 9 stocks
 💨 Air (Gemini, Libra, Aqua):  7 stocks
 💧 Water (Cancer, Scorpio, Pisces): 8 stocks
*/

// MARK: - Usage Examples
/*
 // Get all known stocks
 let allStocks = MockStockData.knownStocks

 // Get stocks by zodiac sign
 let leoStocks = MockStockData.bySign[.leo]
 let ariesStocks = MockStockData.stocks(for: .aries)

 // Get stocks by sector
 let techStocks = MockStockData.bySector["Technology"]
 let healthcareStocks = MockStockData.stocks(forSector: "Healthcare")

 // Get featured stocks for home screen
 let featured = MockStockData.featured

 // Get top movers
 let gainers = MockStockData.topGainers
 let losers = MockStockData.topLosers

 // Search
 let results = MockStockData.search("apple")

 // Verify all signs represented
 print(MockStockData.allSignsRepresented) // true

 // See distribution
 for (sign, count) in MockStockData.signDistribution {
     print("\(sign.symbol) \(sign.displayName): \(count) stocks")
 }
*/
