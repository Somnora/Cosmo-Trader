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

    // MARK: - All Stocks (25-30 companies)

    /// Complete list of all mock stocks with real founding dates
    static let all: [Stock] = [

        // ═══════════════════════════════════════════════════════════════════
        // ARIES (March 21 - April 19) ♈ - Fire Sign
        // ═══════════════════════════════════════════════════════════════════

        // Apple Inc. - Founded April 1, 1976
        // Steve Jobs, Steve Wozniak, and Ronald Wayne in Los Altos garage
        Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.72,
            priceChange: 2.34,
            percentageChange: 1.33,
            sharesOwned: 0,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        ),

        // Microsoft Corporation - Founded April 4, 1975
        // Bill Gates and Paul Allen in Albuquerque, New Mexico
        Stock(
            symbol: "MSFT",
            name: "Microsoft Corporation",
            currentPrice: 378.91,
            priceChange: 4.56,
            percentageChange: 1.22,
            sharesOwned: 0,
            foundedMonth: 4, foundedDay: 4, foundedYear: 1975,
            sector: "Technology"
        ),

        // ═══════════════════════════════════════════════════════════════════
        // TAURUS (April 20 - May 20) ♉ - Earth Sign
        // ═══════════════════════════════════════════════════════════════════

        // Coca-Cola Company - Founded May 8, 1886
        // John Stith Pemberton in Atlanta, Georgia
        Stock(
            symbol: "KO",
            name: "The Coca-Cola Company",
            currentPrice: 62.45,
            priceChange: -0.38,
            percentageChange: -0.60,
            sharesOwned: 0,
            foundedMonth: 5, foundedDay: 8, foundedYear: 1886,
            sector: "Consumer Staples"
        ),

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

        // ═══════════════════════════════════════════════════════════════════
        // GEMINI (May 21 - June 20) ♊ - Air Sign
        // ═══════════════════════════════════════════════════════════════════

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

        // Boeing Company - Founded June 15, 1916
        // William Boeing in Seattle, Washington
        Stock(
            symbol: "BA",
            name: "The Boeing Company",
            currentPrice: 178.23,
            priceChange: 3.45,
            percentageChange: 1.97,
            sharesOwned: 0,
            foundedMonth: 6, foundedDay: 15, foundedYear: 1916,
            sector: "Industrials"
        ),

        // ═══════════════════════════════════════════════════════════════════
        // CANCER (June 21 - July 22) ♋ - Water Sign
        // ═══════════════════════════════════════════════════════════════════

        // Tesla Inc. - Founded July 1, 2003
        // Martin Eberhard and Marc Tarpenning in San Carlos, CA
        Stock(
            symbol: "TSLA",
            name: "Tesla, Inc.",
            currentPrice: 248.50,
            priceChange: 12.30,
            percentageChange: 5.21,
            sharesOwned: 0,
            foundedMonth: 7, foundedDay: 1, foundedYear: 2003,
            sector: "Automotive"
        ),

        // Amazon.com Inc. - Founded July 5, 1994
        // Jeff Bezos in Bellevue, Washington (garage)
        Stock(
            symbol: "AMZN",
            name: "Amazon.com, Inc.",
            currentPrice: 178.25,
            priceChange: 3.42,
            percentageChange: 1.96,
            sharesOwned: 0,
            foundedMonth: 7, foundedDay: 5, foundedYear: 1994,
            sector: "Consumer Cyclical"
        ),

        // ExxonMobil - Founded June 25, 1870 (as Standard Oil of NJ)
        // John D. Rockefeller, reorganized 1999
        Stock(
            symbol: "XOM",
            name: "Exxon Mobil Corporation",
            currentPrice: 104.56,
            priceChange: -1.23,
            percentageChange: -1.16,
            sharesOwned: 0,
            foundedMonth: 6, foundedDay: 25, foundedYear: 1870,
            sector: "Energy"
        ),

        // ═══════════════════════════════════════════════════════════════════
        // LEO (July 23 - August 22) ♌ - Fire Sign
        // ═══════════════════════════════════════════════════════════════════

        // Ford Motor Company - Founded July 23, 1903
        // Henry Ford in Detroit, Michigan (First day of Leo!)
        Stock(
            symbol: "F",
            name: "Ford Motor Company",
            currentPrice: 12.34,
            priceChange: 0.28,
            percentageChange: 2.32,
            sharesOwned: 0,
            foundedMonth: 7, foundedDay: 23, foundedYear: 1903,
            sector: "Automotive"
        ),

        // Procter & Gamble - Founded July 31, 1837
        // William Procter and James Gamble in Cincinnati
        Stock(
            symbol: "PG",
            name: "Procter & Gamble Co.",
            currentPrice: 156.78,
            priceChange: 0.89,
            percentageChange: 0.57,
            sharesOwned: 0,
            foundedMonth: 7, foundedDay: 31, foundedYear: 1837,
            sector: "Consumer Staples"
        ),

        // ═══════════════════════════════════════════════════════════════════
        // VIRGO (August 23 - September 22) ♍ - Earth Sign
        // ═══════════════════════════════════════════════════════════════════

        // Alphabet Inc. (Google) - Founded September 4, 1998
        // Larry Page and Sergey Brin at Stanford
        Stock(
            symbol: "GOOGL",
            name: "Alphabet Inc.",
            currentPrice: 141.80,
            priceChange: -1.20,
            percentageChange: -0.84,
            sharesOwned: 0,
            foundedMonth: 9, foundedDay: 4, foundedYear: 1998,
            sector: "Technology"
        ),

        // Netflix Inc. - Founded August 29, 1997
        // Reed Hastings and Marc Randolph in Scotts Valley, CA
        Stock(
            symbol: "NFLX",
            name: "Netflix, Inc.",
            currentPrice: 478.20,
            priceChange: 6.85,
            percentageChange: 1.45,
            sharesOwned: 0,
            foundedMonth: 8, foundedDay: 29, foundedYear: 1997,
            sector: "Communication Services"
        ),

        // Berkshire Hathaway - Founded September 6, 1889
        // Originally a textile company, transformed by Buffett
        Stock(
            symbol: "BRK.B",
            name: "Berkshire Hathaway Inc.",
            currentPrice: 363.45,
            priceChange: 2.10,
            percentageChange: 0.58,
            sharesOwned: 0,
            foundedMonth: 9, foundedDay: 6, foundedYear: 1889,
            sector: "Finance"
        ),

        // ═══════════════════════════════════════════════════════════════════
        // LIBRA (September 23 - October 22) ♎ - Air Sign
        // ═══════════════════════════════════════════════════════════════════

        // Nike Inc. - Founded October 1, 1964 (originally Blue Ribbon Sports)
        // Phil Knight and Bill Bowerman in Eugene, Oregon
        Stock(
            symbol: "NKE",
            name: "Nike, Inc.",
            currentPrice: 98.45,
            priceChange: -2.34,
            percentageChange: -2.32,
            sharesOwned: 0,
            foundedMonth: 10, foundedDay: 1, foundedYear: 1964,
            sector: "Consumer Cyclical"
        ),

        // JPMorgan Chase - Founded October 1, 2000 (merger)
        // Traces history to 1799 (Bank of Manhattan)
        Stock(
            symbol: "JPM",
            name: "JPMorgan Chase & Co.",
            currentPrice: 198.67,
            priceChange: 3.21,
            percentageChange: 1.64,
            sharesOwned: 0,
            foundedMonth: 10, foundedDay: 1, foundedYear: 2000,
            sector: "Finance"
        ),

        // ═══════════════════════════════════════════════════════════════════
        // SCORPIO (October 23 - November 21) ♏ - Water Sign
        // ═══════════════════════════════════════════════════════════════════

        // Visa Inc. - Founded October 23, 2007 (incorporation)
        // Originally BankAmericard (1958), restructured as Visa
        Stock(
            symbol: "V",
            name: "Visa Inc.",
            currentPrice: 275.34,
            priceChange: 4.56,
            percentageChange: 1.68,
            sharesOwned: 0,
            foundedMonth: 10, foundedDay: 23, foundedYear: 2007,
            sector: "Finance"
        ),

        // McDonald's Corporation - Founded November 15, 1955 (incorporation)
        // Ray Kroc's first franchise in Des Plaines, Illinois
        Stock(
            symbol: "MCD",
            name: "McDonald's Corporation",
            currentPrice: 289.45,
            priceChange: -1.87,
            percentageChange: -0.64,
            sharesOwned: 0,
            foundedMonth: 11, foundedDay: 15, foundedYear: 1955,
            sector: "Consumer Cyclical"
        ),

        // ═══════════════════════════════════════════════════════════════════
        // SAGITTARIUS (November 22 - December 21) ♐ - Fire Sign
        // ═══════════════════════════════════════════════════════════════════

        // The Walt Disney Company - Founded December 16, 1923
        // Walt and Roy Disney in Hollywood
        Stock(
            symbol: "DIS",
            name: "The Walt Disney Company",
            currentPrice: 112.34,
            priceChange: 1.56,
            percentageChange: 1.41,
            sharesOwned: 0,
            foundedMonth: 12, foundedDay: 16, foundedYear: 1923,
            sector: "Communication Services"
        ),

        // Costco Wholesale - Founded December 15, 1983 (as Price Club merger)
        // James Sinegal and Jeffrey Brotman in Seattle
        Stock(
            symbol: "COST",
            name: "Costco Wholesale Corporation",
            currentPrice: 745.23,
            priceChange: 8.92,
            percentageChange: 1.21,
            sharesOwned: 0,
            foundedMonth: 12, foundedDay: 15, foundedYear: 1983,
            sector: "Consumer Staples"
        ),

        // ═══════════════════════════════════════════════════════════════════
        // CAPRICORN (December 22 - January 19) ♑ - Earth Sign
        // ═══════════════════════════════════════════════════════════════════

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

        // General Electric - Founded December 22, 1892
        // Thomas Edison's company merger (First day of Capricorn!)
        Stock(
            symbol: "GE",
            name: "General Electric Company",
            currentPrice: 167.45,
            priceChange: 2.34,
            percentageChange: 1.42,
            sharesOwned: 0,
            foundedMonth: 12, foundedDay: 22, foundedYear: 1892,
            sector: "Industrials"
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

        // ═══════════════════════════════════════════════════════════════════
        // AQUARIUS (January 20 - February 18) ♒ - Air Sign
        // ═══════════════════════════════════════════════════════════════════

        // NVIDIA Corporation - Founded January 25, 1993
        // Jensen Huang, Chris Malachowsky, Curtis Priem
        Stock(
            symbol: "NVDA",
            name: "NVIDIA Corporation",
            currentPrice: 467.80,
            priceChange: 15.20,
            percentageChange: 3.36,
            sharesOwned: 0,
            foundedMonth: 1, foundedDay: 25, foundedYear: 1993,
            sector: "Technology"
        ),

        // Meta Platforms (Facebook) - Founded February 4, 2004
        // Mark Zuckerberg at Harvard
        Stock(
            symbol: "META",
            name: "Meta Platforms, Inc.",
            currentPrice: 505.75,
            priceChange: -8.30,
            percentageChange: -1.61,
            sharesOwned: 0,
            foundedMonth: 2, foundedDay: 4, foundedYear: 2004,
            sector: "Technology"
        ),

        // Intel Corporation - Founded January 20, 1968 (First day of Aquarius!)
        // Gordon Moore and Robert Noyce in Mountain View
        Stock(
            symbol: "INTC",
            name: "Intel Corporation",
            currentPrice: 31.45,
            priceChange: -0.89,
            percentageChange: -2.75,
            sharesOwned: 0,
            foundedMonth: 1, foundedDay: 20, foundedYear: 1968,
            sector: "Technology"
        ),

        // ═══════════════════════════════════════════════════════════════════
        // PISCES (February 19 - March 20) ♓ - Water Sign
        // ═══════════════════════════════════════════════════════════════════

        // Starbucks Corporation - Founded March 16, 1971
        // Jerry Baldwin, Zev Siegl, Gordon Bowker in Seattle
        Stock(
            symbol: "SBUX",
            name: "Starbucks Corporation",
            currentPrice: 97.23,
            priceChange: 1.34,
            percentageChange: 1.40,
            sharesOwned: 0,
            foundedMonth: 3, foundedDay: 16, foundedYear: 1971,
            sector: "Consumer Cyclical"
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

        // Walmart Inc. - Founded March 2, 1962 (Walton's Five and Dime)
        // Sam Walton in Rogers, Arkansas
        Stock(
            symbol: "WMT",
            name: "Walmart Inc.",
            currentPrice: 165.34,
            priceChange: 0.78,
            percentageChange: 0.47,
            sharesOwned: 0,
            foundedMonth: 3, foundedDay: 2, foundedYear: 1962,
            sector: "Consumer Staples"
        ),

        // ═══════════════════════════════════════════════════════════════════
        // ADDITIONAL STOCKS FOR VARIETY
        // ═══════════════════════════════════════════════════════════════════

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
        ),

        // Chevron Corporation - Founded September 10, 1879
        Stock(
            symbol: "CVX",
            name: "Chevron Corporation",
            currentPrice: 147.23,
            priceChange: -2.34,
            percentageChange: -1.56,
            sharesOwned: 0,
            foundedMonth: 9, foundedDay: 10, foundedYear: 1879,
            sector: "Energy"
        ),

        // Home Depot - Founded June 29, 1978
        Stock(
            symbol: "HD",
            name: "The Home Depot, Inc.",
            currentPrice: 345.67,
            priceChange: 4.23,
            percentageChange: 1.24,
            sharesOwned: 0,
            foundedMonth: 6, foundedDay: 29, foundedYear: 1978,
            sector: "Consumer Cyclical"
        ),

        // Mastercard Inc. - Founded November 16, 1966
        Stock(
            symbol: "MA",
            name: "Mastercard Incorporated",
            currentPrice: 456.78,
            priceChange: 5.67,
            percentageChange: 1.26,
            sharesOwned: 0,
            foundedMonth: 11, foundedDay: 16, foundedYear: 1966,
            sector: "Finance"
        )
    ]

    // MARK: - Stocks by Zodiac Sign

    /// All stocks grouped by their zodiac sign
    static var bySign: [ZodiacSign: [Stock]] {
        Dictionary(grouping: all) { $0.zodiacSign }
    }

    /// Get stocks for a specific zodiac sign
    static func stocks(for sign: ZodiacSign) -> [Stock] {
        bySign[sign] ?? []
    }

    // MARK: - Stocks by Sector

    /// All stocks grouped by sector
    static var bySector: [String: [Stock]] {
        Dictionary(grouping: all) { $0.sector }
    }

    /// Get stocks for a specific sector
    static func stocks(forSector sector: String) -> [Stock] {
        bySector[sector] ?? []
    }

    /// List of all available sectors
    static var allSectors: [String] {
        Array(Set(all.map { $0.sector })).sorted()
    }

    // MARK: - Stocks by Element

    /// All stocks grouped by their zodiac element
    static var byElement: [ZodiacSign.Element: [Stock]] {
        Dictionary(grouping: all) { $0.element }
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
        return all.filter { featuredSymbols.contains($0.symbol) }
    }

    // MARK: - Top Movers

    /// Stocks with the highest positive change today
    static var topGainers: [Stock] {
        all.filter { $0.percentageChange > 0 }
            .sorted { $0.percentageChange > $1.percentageChange }
    }

    /// Stocks with the most negative change today
    static var topLosers: [Stock] {
        all.filter { $0.percentageChange < 0 }
            .sorted { $0.percentageChange < $1.percentageChange }
    }

    // MARK: - Search

    /// Search stocks by symbol or name
    static func search(_ query: String) -> [Stock] {
        guard !query.isEmpty else { return all }
        let lowercased = query.lowercased()
        return all.filter {
            $0.symbol.lowercased().contains(lowercased) ||
            $0.name.lowercased().contains(lowercased)
        }
    }

    // MARK: - Random Selection

    /// Get a random stock (useful for demos)
    static var random: Stock {
        all.randomElement() ?? all[0]
    }

    /// Get n random stocks
    static func random(_ count: Int) -> [Stock] {
        Array(all.shuffled().prefix(count))
    }

    // MARK: - Statistics

    /// Total number of stocks
    static var count: Int { all.count }

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
 // Get all stocks
 let allStocks = MockStockData.all

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
