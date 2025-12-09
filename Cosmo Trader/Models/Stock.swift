import Foundation

// MARK: - Stock Model
// ===================
// Represents a publicly traded company's stock.
//
// WHY IS THIS A STRUCT (not a class)?
// -----------------------------------
// 1. VALUE TYPE: Stocks are data - when you copy one, you get a separate copy
// 2. IMMUTABLE BY DEFAULT: Properties are let/var, not reference-shared
// 3. THREAD SAFE: Value types don't have data race issues
// 4. PERFORMANCE: Structs are stack-allocated, faster than heap-allocated classes
//
// PROTOCOLS WE CONFORM TO:
// ------------------------
// - Identifiable: Required by SwiftUI for lists (needs a unique `id`)
// - Codable: Allows encoding/decoding to JSON for persistence or API calls
// - Equatable: Lets us compare two stocks (stock1 == stock2)

struct Stock: Identifiable, Codable, Equatable, Hashable {

    // MARK: - Identity Properties
    // ===========================
    // These properties uniquely identify the stock and never change.

    /// Unique identifier for SwiftUI lists
    /// WHY: SwiftUI's ForEach needs to track which item is which when the list updates.
    ///      Without this, animations and updates would break.
    let id: UUID

    /// Stock ticker symbol (e.g., "AAPL" for Apple)
    /// WHY: This is the universal identifier used by exchanges worldwide.
    ///      It's how traders, APIs, and databases reference stocks.
    /// EXAMPLES: "AAPL", "GOOGL", "TSLA", "MSFT"
    let symbol: String

    /// Full company name (e.g., "Apple Inc.")
    /// WHY: Users need to see the human-readable name, not just ticker symbols.
    ///      Not everyone knows that "NVDA" means NVIDIA.
    let name: String

    // MARK: - Price Properties
    // ========================
    // These properties change frequently as the market moves.
    // They're `var` because we'll update them with live data.

    /// Current price per share in USD
    /// WHY: The most important number! This is what one share costs right now.
    /// EXAMPLE: 178.52 means $178.52 per share
    var currentPrice: Double

    /// Absolute price change from previous close (can be negative)
    /// WHY: Shows how much the price moved in dollars.
    /// EXAMPLE: 2.34 means the stock is up $2.34 from yesterday
    /// EXAMPLE: -1.50 means the stock is down $1.50 from yesterday
    var priceChange: Double

    /// Percentage change from previous close
    /// WHY: Percentage is often more meaningful than absolute change.
    ///      A $2 move on a $20 stock (10%) is huge.
    ///      A $2 move on a $200 stock (1%) is small.
    /// EXAMPLE: 1.33 means up 1.33%
    /// EXAMPLE: -0.84 means down 0.84%
    var percentageChange: Double

    // MARK: - Ownership Properties
    // ============================
    // These track the user's relationship with this stock.

    /// How many shares the user owns (0 if just watching)
    /// WHY: Users need to see their position size.
    /// NOTE: This is a Double, not Int, because fractional shares exist!
    ///       You can own 0.5 shares of Amazon on many platforms.
    var sharesOwned: Double

    // MARK: - Company Information
    // ===========================
    // Static information about the company itself.

    /// The date the company was founded/incorporated
    /// WHY: We use this to calculate the company's zodiac sign!
    ///      Just like people have birth signs, companies have "founding signs."
    /// EXAMPLES:
    ///   - Apple: April 1, 1976 (Aries)
    ///   - Microsoft: April 4, 1975 (Aries)
    ///   - Google: September 4, 1998 (Virgo)
    let foundedDate: Date

    /// The industry sector this company belongs to
    /// WHY: Helps categorize stocks and find related companies.
    /// EXAMPLES: "Technology", "Healthcare", "Finance", "Energy"
    let sector: String

    // MARK: - Computed Properties
    // ===========================
    // These are calculated from other properties - not stored directly.
    // They update automatically when underlying data changes.

    /// The zodiac sign of the company based on its founding date
    /// WHY: This is our cosmic twist! Every company has an astrological sign.
    ///
    /// HOW IT WORKS:
    /// 1. Take the company's foundedDate
    /// 2. Pass it to ZodiacSign.from(date:)
    /// 3. Get back the zodiac sign for that date
    ///
    /// This is a COMPUTED PROPERTY (not stored) because:
    /// - It's derived from foundedDate, so storing it would be redundant
    /// - If foundedDate somehow changed, zodiacSign updates automatically
    /// - Computed properties don't take up memory
    var zodiacSign: ZodiacSign {
        ZodiacSign.from(date: foundedDate)
    }

    /// Total value of shares owned in USD
    /// WHY: Users want to know "how much is my position worth?"
    /// CALCULATION: price per share × number of shares
    /// EXAMPLE: $178.52 × 10 shares = $1,785.20
    var totalValue: Double {
        currentPrice * sharesOwned
    }

    /// Total profit/loss on this position today
    /// WHY: Shows how much money the user made/lost TODAY on this stock.
    /// CALCULATION: price change per share × number of shares
    /// EXAMPLE: +$2.34 × 10 shares = +$23.40 profit today
    var todaysProfitLoss: Double {
        priceChange * sharesOwned
    }

    /// Is the stock up today? (price change >= 0)
    /// WHY: Used to determine color coding (green for up, red for down).
    /// NOTE: We use >= 0, so unchanged (0) is considered "positive"
    var isPositive: Bool {
        priceChange >= 0
    }

    /// Does the user own any shares of this stock?
    /// WHY: Distinguishes between "my holdings" and "watchlist" items.
    var isOwned: Bool {
        sharesOwned > 0
    }

    /// The element of this stock's zodiac sign
    /// WHY: Quick access for UI grouping by element (Fire, Earth, Air, Water)
    var element: ZodiacSign.Element {
        zodiacSign.element
    }

    // MARK: - Initializers
    // ====================

    /// Full initializer with all parameters
    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        currentPrice: Double,
        priceChange: Double,
        percentageChange: Double,
        sharesOwned: Double = 0,
        foundedDate: Date,
        sector: String
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.percentageChange = percentageChange
        self.sharesOwned = sharesOwned
        self.foundedDate = foundedDate
        self.sector = sector
    }

    /// Convenience initializer using month/day/year for founding date
    /// WHY: Easier than creating Date objects manually
    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        currentPrice: Double,
        priceChange: Double,
        percentageChange: Double,
        sharesOwned: Double = 0,
        foundedMonth: Int,
        foundedDay: Int,
        foundedYear: Int,
        sector: String
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.percentageChange = percentageChange
        self.sharesOwned = sharesOwned
        self.sector = sector

        // Create a Date from the components
        var components = DateComponents()
        components.month = foundedMonth
        components.day = foundedDay
        components.year = foundedYear
        self.foundedDate = Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - Formatting Helpers
// ==========================
// Extension with methods for displaying formatted values in the UI.

extension Stock {

    /// Format the current price as currency (e.g., "$178.52")
    var formattedPrice: String {
        Self.formatCurrency(currentPrice)
    }

    /// Format the price change with sign (e.g., "+$2.34" or "-$1.50")
    var formattedPriceChange: String {
        let sign = priceChange >= 0 ? "+" : ""
        return sign + Self.formatCurrency(priceChange)
    }

    /// Format the percentage change (e.g., "+1.33%" or "-0.84%")
    var formattedPercentageChange: String {
        let sign = percentageChange >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, percentageChange)
    }

    /// Format the total value as currency
    var formattedTotalValue: String {
        Self.formatCurrency(totalValue)
    }

    /// Format today's P/L with sign
    var formattedTodaysProfitLoss: String {
        let sign = todaysProfitLoss >= 0 ? "+" : ""
        return sign + Self.formatCurrency(todaysProfitLoss)
    }

    /// Format shares owned (handles fractional shares nicely)
    var formattedSharesOwned: String {
        if sharesOwned == floor(sharesOwned) {
            // Whole number - show without decimals
            return String(format: "%.0f", sharesOwned)
        } else {
            // Fractional - show up to 4 decimal places
            return String(format: "%.4f", sharesOwned).trimmingCharacters(in: CharacterSet(charactersIn: "0")).trimmingCharacters(in: CharacterSet(charactersIn: "."))
        }
    }

    /// Helper to format any value as USD currency
    private static func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Compatibility Check
// ===========================
// Extension for cosmic compatibility features.

extension Stock {

    /// Check if this stock is cosmically compatible with a user's sign
    /// WHY: Fun feature - "This stock aligns with your energy!"
    func isCompatible(with userSign: ZodiacSign) -> Bool {
        userSign.isCompatible(with: zodiacSign)
    }

    /// Check if this stock shares the same element as the user
    /// WHY: Same-element stocks might resonate with the user's trading style
    func sharesElement(with userSign: ZodiacSign) -> Bool {
        zodiacSign.element == userSign.element
    }
}

// MARK: - Sample Data
// ===================
// Real company data for testing and previews.
// These use actual founding dates!

extension Stock {

    /// Sample stocks with REAL founding dates for accurate zodiac signs
    static let samples: [Stock] = [
        // Apple - Founded April 1, 1976 (ARIES - Fire sign)
        // Steve Jobs, Steve Wozniak, and Ronald Wayne started in a garage
        Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            sharesOwned: 10,
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        ),

        // Google/Alphabet - Founded September 4, 1998 (VIRGO - Earth sign)
        // Larry Page and Sergey Brin started in a Stanford dorm room
        Stock(
            symbol: "GOOGL",
            name: "Alphabet Inc.",
            currentPrice: 141.80,
            priceChange: -1.20,
            percentageChange: -0.84,
            sharesOwned: 5,
            foundedMonth: 9, foundedDay: 4, foundedYear: 1998,
            sector: "Technology"
        ),

        // Tesla - Founded July 1, 2003 (CANCER - Water sign)
        // Martin Eberhard and Marc Tarpenning founded it (Elon joined later)
        Stock(
            symbol: "TSLA",
            name: "Tesla Inc.",
            currentPrice: 248.50,
            priceChange: 12.30,
            percentageChange: 5.21,
            sharesOwned: 3,
            foundedMonth: 7, foundedDay: 1, foundedYear: 2003,
            sector: "Automotive"
        ),

        // Microsoft - Founded April 4, 1975 (ARIES - Fire sign)
        // Bill Gates and Paul Allen started it in Albuquerque, NM
        Stock(
            symbol: "MSFT",
            name: "Microsoft Corp.",
            currentPrice: 378.91,
            priceChange: 4.56,
            percentageChange: 1.22,
            sharesOwned: 8,
            foundedMonth: 4, foundedDay: 4, foundedYear: 1975,
            sector: "Technology"
        ),

        // Amazon - Founded July 5, 1994 (CANCER - Water sign)
        // Jeff Bezos started it as an online bookstore in his garage
        Stock(
            symbol: "AMZN",
            name: "Amazon.com Inc.",
            currentPrice: 178.25,
            priceChange: 3.42,
            percentageChange: 1.96,
            sharesOwned: 0, // Watchlist only
            foundedMonth: 7, foundedDay: 5, foundedYear: 1994,
            sector: "Consumer Cyclical"
        ),

        // NVIDIA - Founded January 25, 1993 (AQUARIUS - Air sign)
        // Jensen Huang, Chris Malachowsky, and Curtis Priem founded it
        Stock(
            symbol: "NVDA",
            name: "NVIDIA Corp.",
            currentPrice: 467.80,
            priceChange: 15.20,
            percentageChange: 3.36,
            sharesOwned: 2,
            foundedMonth: 1, foundedDay: 25, foundedYear: 1993,
            sector: "Technology"
        ),

        // Meta (Facebook) - Founded February 4, 2004 (AQUARIUS - Air sign)
        // Mark Zuckerberg founded it in his Harvard dorm
        Stock(
            symbol: "META",
            name: "Meta Platforms Inc.",
            currentPrice: 505.75,
            priceChange: -8.30,
            percentageChange: -1.61,
            sharesOwned: 0,
            foundedMonth: 2, foundedDay: 4, foundedYear: 2004,
            sector: "Technology"
        ),

        // Netflix - Founded August 29, 1997 (VIRGO - Earth sign)
        // Reed Hastings and Marc Randolph started as a DVD rental service
        Stock(
            symbol: "NFLX",
            name: "Netflix Inc.",
            currentPrice: 478.20,
            priceChange: 6.85,
            percentageChange: 1.45,
            sharesOwned: 4,
            foundedMonth: 8, foundedDay: 29, foundedYear: 1997,
            sector: "Communication Services"
        )
    ]

    /// Get a single sample stock for quick previews
    static var sample: Stock {
        samples[0] // Apple
    }

    /// Get only stocks the user owns (for portfolio view)
    static var ownedSamples: [Stock] {
        samples.filter { $0.isOwned }
    }

    /// Get stocks the user doesn't own (for discover/watchlist)
    static var watchlistSamples: [Stock] {
        samples.filter { !$0.isOwned }
    }

    /// Group sample stocks by their zodiac element
    static var samplesByElement: [ZodiacSign.Element: [Stock]] {
        Dictionary(grouping: samples) { $0.element }
    }
}

// MARK: - Usage Examples
// ======================
/*
 EXAMPLE 1: Create a stock and get its zodiac sign
 -------------------------------------------------
 let apple = Stock(
     symbol: "AAPL",
     name: "Apple Inc.",
     currentPrice: 178.52,
     priceChange: 2.34,
     percentageChange: 1.33,
     foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
     sector: "Technology"
 )
 print(apple.zodiacSign.displayName)  // "Aries"
 print(apple.zodiacSign.symbol)       // "♈"
 print(apple.element.emoji)           // "🔥" (Fire)

 EXAMPLE 2: Check compatibility with user's sign
 -----------------------------------------------
 let userSign = ZodiacSign.leo
 if apple.isCompatible(with: userSign) {
     print("Apple aligns with your cosmic energy!")
 }
 // Output: "Apple aligns with your cosmic energy!"
 // (Aries and Leo are both Fire signs - highly compatible!)

 EXAMPLE 3: Get formatted values for UI
 --------------------------------------
 print(apple.formattedPrice)            // "$178.52"
 print(apple.formattedPriceChange)      // "+$2.34"
 print(apple.formattedPercentageChange) // "+1.33%"
 print(apple.formattedTotalValue)       // "$1,785.20"
*/
