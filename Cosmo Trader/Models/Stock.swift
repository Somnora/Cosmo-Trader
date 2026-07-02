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

    /// Daily volatility (standard deviation of daily returns)
    /// WHY: Measures how much the stock price typically swings.
    ///      Used for pattern detection and risk assessment.
    /// EXAMPLE: 0.02 means the stock typically moves 2% per day
    var volatility: Double?

    /// Trading volume for today
    /// WHY: High volume confirms price movements; low volume may signal weakness.
    var volume: Int?

    /// Average daily trading volume
    /// WHY: Compares today's activity to normal levels.
    var avgVolume: Int?

    /// Volume compared to average (today's volume / average volume)
    var volumeRatio: Double? {
        guard let vol = volume, let avg = avgVolume, avg > 0 else { return nil }
        return Double(vol) / Double(avg)
    }

    /// Whether today's volume is unusually high (50%+ above average)
    var isUnusualVolume: Bool {
        (volumeRatio ?? 0) > 1.5
    }

    // MARK: - Ownership Properties
    // ============================
    // These track the user's relationship with this stock.

    /// How many shares the user owns (0 if just watching)
    /// WHY: Users need to see their position size.
    /// NOTE: This is a Double, not Int, because fractional shares exist!
    ///       You can own 0.5 shares of Amazon on many platforms.
    var sharesOwned: Double

    /// The average price per share the user paid (cost basis)
    /// WHY: Users need to track their entry point to calculate profit/loss
    /// NOTE: This is optional - nil if not yet purchased or if tracking not enabled
    var purchasePrice: Double?

    /// The date when the user purchased (or first purchased) this stock
    /// WHY: Users want to see how long they've held a position
    /// NOTE: For multiple buys, this represents the first purchase date
    var purchaseDate: Date?

    // MARK: - Company Information
    // ===========================
    // Static information about the company itself.

    /// The date the company was founded/incorporated, when known.
    /// WHY: We use verified dates for company-specific astrological overlays.
    ///      Unknown dates stay nil; callers must not invent a fallback date.
    ///      Just like people have birth signs, companies have "founding signs."
    /// EXAMPLES:
    ///   - Apple: April 1, 1976 (Aries)
    ///   - Microsoft: April 4, 1975 (Aries)
    ///   - Google: September 4, 1998 (Virgo)
    let foundedDate: Date?

    /// The industry sector this company belongs to
    /// WHY: Helps categorize stocks and find related companies.
    /// EXAMPLES: "Technology", "Healthcare", "Finance", "Energy"
    let sector: String

    // MARK: - CEO Information
    // =======================
    // Information about the company's current CEO for cosmic alignment features.

    /// Name of the company's current CEO
    /// WHY: Users can see who leads the company and their cosmic profile.
    /// EXAMPLES: "Tim Cook", "Satya Nadella", "Elon Musk"
    var ceoName: String?

    /// Birth date of the CEO (for zodiac calculation)
    /// WHY: We calculate the CEO's zodiac sign to show user-CEO compatibility.
    /// NOTE: Optional because not all CEO birthdates are publicly known.
    var ceoBirthDate: Date?

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
    var foundedZodiacSign: ZodiacSign? {
        guard let foundedDate else { return nil }
        return ZodiacSign.from(date: foundedDate)
    }

    var foundedElement: ZodiacSign.Element? {
        foundedZodiacSign?.element
    }

    var zodiacSign: ZodiacSign? {
        foundedZodiacSign
    }

    /// Total value of shares owned in USD
    /// WHY: Users want to know "how much is my position worth?"
    /// CALCULATION: price per share × number of shares
    /// EXAMPLE: $178.52 × 10 shares = $1,785.20
    var totalValue: Double {
        currentPrice * sharesOwned
    }

    /// Dollar weight used for portfolio composition analysis.
    /// Falls back to cost basis when live/current price has not been fetched.
    var marketValue: Double {
        let price = currentPrice > 0 ? currentPrice : (purchasePrice ?? 0)
        guard price > 0 else { return 0 }
        return price * sharesOwned
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

    // MARK: - Purchase-Based Profit/Loss
    // ==================================
    // These calculate gains based on user's purchase price (cost basis)

    /// Total cost basis (what the user paid for all shares)
    /// WHY: Users need to know their total investment
    var totalCostBasis: Double? {
        guard let purchasePrice = purchasePrice else { return nil }
        return purchasePrice * sharesOwned
    }

    /// Total profit/loss since purchase (unrealized gain/loss)
    /// WHY: The big question - "Am I up or down on this position?"
    var totalProfitLoss: Double? {
        guard let costBasis = totalCostBasis else { return nil }
        return totalValue - costBasis
    }

    /// Percentage profit/loss since purchase
    /// WHY: Percentage gives context - "$100 profit" means different things on different position sizes
    var totalProfitLossPercent: Double? {
        guard let costBasis = totalCostBasis, costBasis > 0 else { return nil }
        return ((totalValue - costBasis) / costBasis) * 100
    }

    /// Is the position profitable overall?
    /// WHY: Quick check for color coding
    var isProfitable: Bool {
        guard let profitLoss = totalProfitLoss else { return true }
        return profitLoss >= 0
    }

    /// Days held since purchase
    /// WHY: Users want to know their holding period
    var daysHeld: Int? {
        guard let purchaseDate = purchaseDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: purchaseDate, to: Date()).day
    }

    /// Formatted holding period
    /// WHY: Human-readable duration
    var holdingPeriod: String? {
        guard let days = daysHeld else { return nil }
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day"
        } else if days < 30 {
            return "\(days) days"
        } else if days < 365 {
            let months = days / 30
            return months == 1 ? "1 month" : "\(months) months"
        } else {
            let years = days / 365
            return years == 1 ? "1 year" : "\(years) years"
        }
    }

    /// The element of this stock's zodiac sign
    /// WHY: Quick access for UI grouping by element (Fire, Earth, Air, Water)
    var element: ZodiacSign.Element? {
        zodiacSign?.element
    }

    /// The zodiac sign of the CEO based on their birth date
    /// WHY: Shows cosmic alignment between user and company leadership.
    /// Returns nil if CEO birth date is not available.
    var ceoZodiacSign: ZodiacSign? {
        guard let date = ceoBirthDate else { return nil }
        return ZodiacSign.from(date: date)
    }

    /// The element of the CEO's zodiac sign
    var ceoElement: ZodiacSign.Element? {
        ceoZodiacSign?.element
    }

    /// Whether the CEO info is available
    var hasCEOInfo: Bool {
        ceoName != nil && ceoBirthDate != nil
    }

    /// Provider-backed price history is not stored on `Stock`.
    ///
    /// Production UI must use `HistoricalPriceService` or another provider-backed
    /// source for charts. Returning an empty array prevents silent fake sparklines
    /// from appearing when no real historical data has been loaded.
    var priceHistory: [Double] {
        []
    }

    /// Provider-backed chart points are not generated on the model.
    ///
    /// This intentionally returns no data so production chart surfaces cannot
    /// mistake model-generated samples for market history. Preview/test fixtures
    /// should construct explicit sample points instead.
    /// - Parameter timeframe: The timeframe for the chart data
    /// - Returns: Empty array. Use `HistoricalPriceService` for real data.
    func chartData(for timeframe: ChartTimeframe) -> [PricePoint] {
        []
    }

    /// Provider-backed key statistics are not stored on `Stock`.
    ///
    /// Production UI must show unavailable states until provider fundamentals
    /// are available. This prevents random or generated facts from appearing as
    /// real market data.
    var keyStats: StockKeyStats? {
        nil
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
        volatility: Double? = nil,
        volume: Int? = nil,
        avgVolume: Int? = nil,
        sharesOwned: Double = 0,
        purchasePrice: Double? = nil,
        purchaseDate: Date? = nil,
        foundedDate: Date?,
        sector: String,
        ceoName: String? = nil,
        ceoBirthDate: Date? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.percentageChange = percentageChange
        self.volatility = volatility
        self.volume = volume
        self.avgVolume = avgVolume
        self.sharesOwned = sharesOwned
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.foundedDate = foundedDate
        self.sector = sector
        self.ceoName = ceoName
        self.ceoBirthDate = ceoBirthDate
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
        volatility: Double? = nil,
        volume: Int? = nil,
        avgVolume: Int? = nil,
        sharesOwned: Double = 0,
        purchasePrice: Double? = nil,
        purchaseDate: Date? = nil,
        foundedMonth: Int,
        foundedDay: Int,
        foundedYear: Int,
        sector: String,
        ceoName: String? = nil,
        ceoBirthMonth: Int? = nil,
        ceoBirthDay: Int? = nil,
        ceoBirthYear: Int? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.percentageChange = percentageChange
        self.volatility = volatility
        self.volume = volume
        self.avgVolume = avgVolume
        self.sharesOwned = sharesOwned
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.sector = sector
        self.ceoName = ceoName

        // Create a Date from the founding date components
        var components = DateComponents()
        components.month = foundedMonth
        components.day = foundedDay
        components.year = foundedYear
        self.foundedDate = Calendar.current.date(from: components)

        // Create CEO birth date if all components provided
        if let month = ceoBirthMonth, let day = ceoBirthDay, let year = ceoBirthYear {
            var ceoComponents = DateComponents()
            ceoComponents.month = month
            ceoComponents.day = day
            ceoComponents.year = year
            self.ceoBirthDate = Calendar.current.date(from: ceoComponents)
        } else {
            self.ceoBirthDate = nil
        }
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

    // MARK: - Purchase Tracking Formatters

    /// Format the purchase price
    var formattedPurchasePrice: String? {
        guard let purchasePrice = purchasePrice else { return nil }
        return Self.formatCurrency(purchasePrice)
    }

    /// Format total cost basis
    var formattedCostBasis: String? {
        guard let costBasis = totalCostBasis else { return nil }
        return Self.formatCurrency(costBasis)
    }

    /// Format total profit/loss with sign
    var formattedTotalProfitLoss: String? {
        guard let profitLoss = totalProfitLoss else { return nil }
        let sign = profitLoss >= 0 ? "+" : ""
        return sign + Self.formatCurrency(profitLoss)
    }

    /// Format total profit/loss percentage
    var formattedTotalProfitLossPercent: String? {
        guard let percent = totalProfitLossPercent else { return nil }
        let sign = percent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, percent)
    }

    /// Format purchase date
    var formattedPurchaseDate: String? {
        guard let purchaseDate = purchaseDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: purchaseDate)
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
        guard let zodiacSign else { return false }
        return userSign.isCompatible(with: zodiacSign)
    }

    /// Check if this stock shares the same element as the user
    /// WHY: Same-element stocks might resonate with the user's trading style
    func sharesElement(with userSign: ZodiacSign) -> Bool {
        zodiacSign?.element == userSign.element
    }
}

// MARK: - Sample Data
// ===================
// Real company data for testing and previews.
// These use actual founding dates!

extension Stock {

    /// ETFs track baskets and have fund inception dates, not company founding dates.
    /// They must not generate company-specific natal/founding overlay events.
    static let companyEventExcludedSymbols: Set<String> = ["SPY", "QQQ", "VTI"]

    var supportsCompanyOverlayEvents: Bool {
        foundedDate != nil && !Self.companyEventExcludedSymbols.contains(symbol.uppercased())
    }

    /// Sample/curated stocks with verified founding or IPO dates.
    static let samples: [Stock] = [
        // Source: https://en.wikipedia.org/wiki/Apple_Inc. - founded April 1, 1976.
        Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.52,
            priceChange: 2.34,
            percentageChange: 1.33,
            sharesOwned: 10,
            purchasePrice: 150.00,
            purchaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 15)),
            foundedMonth: 4, foundedDay: 1, foundedYear: 1976,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Alphabet_Inc. - Google founded September 4, 1998.
        Stock(
            symbol: "GOOGL",
            name: "Alphabet Inc.",
            currentPrice: 141.80,
            priceChange: -1.20,
            percentageChange: -0.84,
            sharesOwned: 5,
            purchasePrice: 135.00,
            purchaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 10)),
            foundedMonth: 9, foundedDay: 4, foundedYear: 1998,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Tesla,_Inc. - founded July 1, 2003.
        Stock(
            symbol: "TSLA",
            name: "Tesla Inc.",
            currentPrice: 248.50,
            priceChange: 12.30,
            percentageChange: 5.21,
            sharesOwned: 3,
            purchasePrice: 200.00,
            purchaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 1)),
            foundedMonth: 7, foundedDay: 1, foundedYear: 2003,
            sector: "Automotive"
        ),

        // Source: https://en.wikipedia.org/wiki/Microsoft - founded April 4, 1975.
        Stock(
            symbol: "MSFT",
            name: "Microsoft Corp.",
            currentPrice: 378.91,
            priceChange: 4.56,
            percentageChange: 1.22,
            sharesOwned: 8,
            purchasePrice: 350.00,
            purchaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 20)),
            foundedMonth: 4, foundedDay: 4, foundedYear: 1975,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Amazon_(company) - founded July 5, 1994.
        Stock(
            symbol: "AMZN",
            name: "Amazon.com Inc.",
            currentPrice: 178.25,
            priceChange: 3.42,
            percentageChange: 1.96,
            sharesOwned: 0,
            foundedMonth: 7, foundedDay: 5, foundedYear: 1994,
            sector: "Consumer Cyclical"
        ),

        // Source: https://en.wikipedia.org/wiki/Nvidia - founded April 5, 1993.
        Stock(
            symbol: "NVDA",
            name: "NVIDIA Corp.",
            currentPrice: 467.80,
            priceChange: 15.20,
            percentageChange: 3.36,
            sharesOwned: 2,
            purchasePrice: 300.00,
            purchaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 5)),
            foundedMonth: 4, foundedDay: 5, foundedYear: 1993,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Meta_Platforms - Facebook founded February 4, 2004.
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

        // Source: https://en.wikipedia.org/wiki/Netflix - founded August 29, 1997.
        Stock(
            symbol: "NFLX",
            name: "Netflix Inc.",
            currentPrice: 478.20,
            priceChange: 6.85,
            percentageChange: 1.45,
            sharesOwned: 4,
            purchasePrice: 450.00,
            purchaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 5, day: 12)),
            foundedMonth: 8, foundedDay: 29, foundedYear: 1997,
            sector: "Communication Services"
        ),

        // Source: https://en.wikipedia.org/wiki/Oracle_Corporation - founded June 16, 1977.
        Stock(
            symbol: "ORCL",
            name: "Oracle Corp.",
            currentPrice: 120.15,
            priceChange: 1.34,
            percentageChange: 1.13,
            foundedMonth: 6, foundedDay: 16, foundedYear: 1977,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Advanced_Micro_Devices - founded May 1, 1969.
        Stock(
            symbol: "AMD",
            name: "Advanced Micro Devices Inc.",
            currentPrice: 164.20,
            priceChange: 3.18,
            percentageChange: 1.97,
            foundedMonth: 5, foundedDay: 1, foundedYear: 1969,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Intel - founded July 18, 1968.
        Stock(
            symbol: "INTC",
            name: "Intel Corp.",
            currentPrice: 31.45,
            priceChange: -0.89,
            percentageChange: -2.75,
            foundedMonth: 7, foundedDay: 18, foundedYear: 1968,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Cisco - founded December 10, 1984.
        Stock(
            symbol: "CSCO",
            name: "Cisco Systems Inc.",
            currentPrice: 49.85,
            priceChange: 0.42,
            percentageChange: 0.85,
            foundedMonth: 12, foundedDay: 10, foundedYear: 1984,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Salesforce - founded February 3, 1999.
        Stock(
            symbol: "CRM",
            name: "Salesforce Inc.",
            currentPrice: 287.50,
            priceChange: 2.75,
            percentageChange: 0.97,
            foundedMonth: 2, foundedDay: 3, foundedYear: 1999,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/IBM - founded June 16, 1911.
        Stock(
            symbol: "IBM",
            name: "IBM",
            currentPrice: 187.30,
            priceChange: 1.20,
            percentageChange: 0.64,
            foundedMonth: 6, foundedDay: 16, foundedYear: 1911,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Uber - IPO May 10, 2019.
        Stock(
            symbol: "UBER",
            name: "Uber Technologies Inc.",
            currentPrice: 68.75,
            priceChange: 1.62,
            percentageChange: 2.41,
            foundedMonth: 5, foundedDay: 10, foundedYear: 2019,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Airbnb - IPO December 10, 2020.
        Stock(
            symbol: "ABNB",
            name: "Airbnb Inc.",
            currentPrice: 145.20,
            priceChange: -1.85,
            percentageChange: -1.26,
            foundedMonth: 12, foundedDay: 10, foundedYear: 2020,
            sector: "Consumer Cyclical"
        ),

        // Source: https://en.wikipedia.org/wiki/Palantir_Technologies - direct listing September 30, 2020.
        Stock(
            symbol: "PLTR",
            name: "Palantir Technologies Inc.",
            currentPrice: 24.40,
            priceChange: 1.10,
            percentageChange: 4.72,
            foundedMonth: 9, foundedDay: 30, foundedYear: 2020,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Coinbase - direct listing April 14, 2021.
        Stock(
            symbol: "COIN",
            name: "Coinbase Global Inc.",
            currentPrice: 228.60,
            priceChange: 7.15,
            percentageChange: 3.23,
            foundedMonth: 4, foundedDay: 14, foundedYear: 2021,
            sector: "Crypto"
        ),

        // Source: https://en.wikipedia.org/wiki/GameStop - IPO February 13, 2002.
        Stock(
            symbol: "GME",
            name: "GameStop Corp.",
            currentPrice: 22.35,
            priceChange: 0.85,
            percentageChange: 3.95,
            foundedMonth: 2, foundedDay: 13, foundedYear: 2002,
            sector: "Consumer Cyclical"
        ),

        // Source: https://en.wikipedia.org/wiki/AMC_Theatres - IPO December 18, 2013.
        Stock(
            symbol: "AMC",
            name: "AMC Entertainment Holdings Inc.",
            currentPrice: 4.35,
            priceChange: -0.18,
            percentageChange: -3.97,
            foundedMonth: 12, foundedDay: 18, foundedYear: 2013,
            sector: "Consumer Cyclical"
        ),

        // Source: https://en.wikipedia.org/wiki/Snowflake_Inc. - IPO September 16, 2020.
        Stock(
            symbol: "SNOW",
            name: "Snowflake Inc.",
            currentPrice: 154.80,
            priceChange: 2.10,
            percentageChange: 1.38,
            foundedMonth: 9, foundedDay: 16, foundedYear: 2020,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Shopify - IPO May 21, 2015.
        Stock(
            symbol: "SHOP",
            name: "Shopify Inc.",
            currentPrice: 76.90,
            priceChange: 1.95,
            percentageChange: 2.60,
            foundedMonth: 5, foundedDay: 21, foundedYear: 2015,
            sector: "Technology"
        ),

        // Source: https://en.wikipedia.org/wiki/Block,_Inc. - IPO November 19, 2015.
        Stock(
            symbol: "SQ",
            name: "Block Inc.",
            currentPrice: 74.25,
            priceChange: 0.95,
            percentageChange: 1.30,
            foundedMonth: 11, foundedDay: 19, foundedYear: 2015,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/Roblox_Corporation - direct listing March 10, 2021.
        Stock(
            symbol: "RBLX",
            name: "Roblox Corp.",
            currentPrice: 38.65,
            priceChange: 0.72,
            percentageChange: 1.90,
            foundedMonth: 3, foundedDay: 10, foundedYear: 2021,
            sector: "Communication Services"
        ),

        // Source: https://en.wikipedia.org/wiki/Rivian - IPO November 10, 2021.
        Stock(
            symbol: "RIVN",
            name: "Rivian Automotive Inc.",
            currentPrice: 11.85,
            priceChange: 0.31,
            percentageChange: 2.69,
            foundedMonth: 11, foundedDay: 10, foundedYear: 2021,
            sector: "Automotive"
        ),

        // Source: https://en.wikipedia.org/wiki/Robinhood_Markets - IPO July 29, 2021.
        Stock(
            symbol: "HOOD",
            name: "Robinhood Markets Inc.",
            currentPrice: 20.15,
            priceChange: 0.44,
            percentageChange: 2.23,
            foundedMonth: 7, foundedDay: 29, foundedYear: 2021,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/Visa_Inc. - IPO March 19, 2008.
        Stock(
            symbol: "V",
            name: "Visa Inc.",
            currentPrice: 275.34,
            priceChange: 4.56,
            percentageChange: 1.68,
            foundedMonth: 3, foundedDay: 19, foundedYear: 2008,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/Mastercard - IPO May 25, 2006.
        Stock(
            symbol: "MA",
            name: "Mastercard Inc.",
            currentPrice: 456.78,
            priceChange: 5.67,
            percentageChange: 1.26,
            foundedMonth: 5, foundedDay: 25, foundedYear: 2006,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/JPMorgan_Chase - formed December 1, 2000.
        Stock(
            symbol: "JPM",
            name: "JPMorgan Chase & Co.",
            currentPrice: 198.67,
            priceChange: 3.21,
            percentageChange: 1.64,
            foundedMonth: 12, foundedDay: 1, foundedYear: 2000,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/Bank_of_America - Bank of Italy founded October 17, 1904.
        Stock(
            symbol: "BAC",
            name: "Bank of America Corp.",
            currentPrice: 37.10,
            priceChange: 0.42,
            percentageChange: 1.14,
            foundedMonth: 10, foundedDay: 17, foundedYear: 1904,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/American_Express - founded March 18, 1850.
        Stock(
            symbol: "AXP",
            name: "American Express Co.",
            currentPrice: 235.40,
            priceChange: 2.35,
            percentageChange: 1.01,
            foundedMonth: 3, foundedDay: 18, foundedYear: 1850,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/Wells_Fargo - founded March 18, 1852.
        Stock(
            symbol: "WFC",
            name: "Wells Fargo & Co.",
            currentPrice: 58.20,
            priceChange: 0.51,
            percentageChange: 0.88,
            foundedMonth: 3, foundedDay: 18, foundedYear: 1852,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/Goldman_Sachs - IPO May 4, 1999.
        Stock(
            symbol: "GS",
            name: "Goldman Sachs Group Inc.",
            currentPrice: 440.75,
            priceChange: 3.80,
            percentageChange: 0.87,
            foundedMonth: 5, foundedDay: 4, foundedYear: 1999,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/Morgan_Stanley - founded September 16, 1935.
        Stock(
            symbol: "MS",
            name: "Morgan Stanley",
            currentPrice: 97.30,
            priceChange: 1.22,
            percentageChange: 1.27,
            foundedMonth: 9, foundedDay: 16, foundedYear: 1935,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/Citibank - City Bank of New York founded June 16, 1812.
        Stock(
            symbol: "C",
            name: "Citigroup Inc.",
            currentPrice: 61.15,
            priceChange: 0.74,
            percentageChange: 1.22,
            foundedMonth: 6, foundedDay: 16, foundedYear: 1812,
            sector: "Finance"
        ),

        // Source: https://en.wikipedia.org/wiki/Walmart - founded July 2, 1962.
        Stock(
            symbol: "WMT",
            name: "Walmart Inc.",
            currentPrice: 165.34,
            priceChange: 0.78,
            percentageChange: 0.47,
            foundedMonth: 7, foundedDay: 2, foundedYear: 1962,
            sector: "Consumer Staples"
        ),

        // Source: https://en.wikipedia.org/wiki/Costco - first warehouse opened September 15, 1983.
        Stock(
            symbol: "COST",
            name: "Costco Wholesale Corp.",
            currentPrice: 745.23,
            priceChange: 8.92,
            percentageChange: 1.21,
            foundedMonth: 9, foundedDay: 15, foundedYear: 1983,
            sector: "Consumer Staples"
        ),

        // Source: https://en.wikipedia.org/wiki/The_Home_Depot - founded February 6, 1978.
        Stock(
            symbol: "HD",
            name: "The Home Depot Inc.",
            currentPrice: 345.67,
            priceChange: 4.23,
            percentageChange: 1.24,
            foundedMonth: 2, foundedDay: 6, foundedYear: 1978,
            sector: "Consumer Cyclical"
        ),

        // Source: https://en.wikipedia.org/wiki/Lowe%27s - founded March 25, 1921.
        Stock(
            symbol: "LOW",
            name: "Lowe's Companies Inc.",
            currentPrice: 228.40,
            priceChange: 1.42,
            percentageChange: 0.63,
            foundedMonth: 3, foundedDay: 25, foundedYear: 1921,
            sector: "Consumer Cyclical"
        ),

        // Source: https://en.wikipedia.org/wiki/Target_Corporation - founded June 24, 1902.
        Stock(
            symbol: "TGT",
            name: "Target Corp.",
            currentPrice: 151.20,
            priceChange: -0.85,
            percentageChange: -0.56,
            foundedMonth: 6, foundedDay: 24, foundedYear: 1902,
            sector: "Consumer Cyclical"
        ),

        // Source: https://en.wikipedia.org/wiki/Nike,_Inc. - founded January 25, 1964.
        Stock(
            symbol: "NKE",
            name: "Nike Inc.",
            currentPrice: 98.45,
            priceChange: -2.34,
            percentageChange: -2.32,
            foundedMonth: 1, foundedDay: 25, foundedYear: 1964,
            sector: "Consumer Cyclical"
        ),

        // Source: https://en.wikipedia.org/wiki/Starbucks - founded March 30, 1971.
        Stock(
            symbol: "SBUX",
            name: "Starbucks Corp.",
            currentPrice: 97.23,
            priceChange: 1.34,
            percentageChange: 1.40,
            foundedMonth: 3, foundedDay: 30, foundedYear: 1971,
            sector: "Consumer Cyclical"
        ),

        // Source: https://en.wikipedia.org/wiki/McDonald%27s - corporation founded April 15, 1955.
        Stock(
            symbol: "MCD",
            name: "McDonald's Corp.",
            currentPrice: 289.45,
            priceChange: -1.87,
            percentageChange: -0.64,
            foundedMonth: 4, foundedDay: 15, foundedYear: 1955,
            sector: "Consumer Cyclical"
        ),

        // Source: https://en.wikipedia.org/wiki/The_Coca-Cola_Company - incorporated January 29, 1892.
        Stock(
            symbol: "KO",
            name: "The Coca-Cola Company",
            currentPrice: 62.45,
            priceChange: -0.38,
            percentageChange: -0.60,
            foundedMonth: 1, foundedDay: 29, foundedYear: 1892,
            sector: "Consumer Staples"
        ),

        // Source: https://en.wikipedia.org/wiki/Procter_%26_Gamble - founded October 31, 1837.
        Stock(
            symbol: "PG",
            name: "Procter & Gamble Co.",
            currentPrice: 156.78,
            priceChange: 0.89,
            percentageChange: 0.57,
            foundedMonth: 10, foundedDay: 31, foundedYear: 1837,
            sector: "Consumer Staples"
        ),

        // Source: https://en.wikipedia.org/wiki/The_Walt_Disney_Company - founded October 16, 1923.
        Stock(
            symbol: "DIS",
            name: "The Walt Disney Company",
            currentPrice: 112.34,
            priceChange: 1.56,
            percentageChange: 1.41,
            foundedMonth: 10, foundedDay: 16, foundedYear: 1923,
            sector: "Communication Services"
        ),

        // Source: https://en.wikipedia.org/wiki/Comcast - founded June 28, 1963.
        Stock(
            symbol: "CMCSA",
            name: "Comcast Corp.",
            currentPrice: 39.80,
            priceChange: -0.21,
            percentageChange: -0.52,
            foundedMonth: 6, foundedDay: 28, foundedYear: 1963,
            sector: "Communication Services"
        ),

        // Source: https://en.wikipedia.org/wiki/Verizon - formed June 30, 2000.
        Stock(
            symbol: "VZ",
            name: "Verizon Communications Inc.",
            currentPrice: 40.25,
            priceChange: 0.14,
            percentageChange: 0.35,
            foundedMonth: 6, foundedDay: 30, foundedYear: 2000,
            sector: "Communication Services"
        ),

        // Source: https://en.wikipedia.org/wiki/General_Motors - founded September 16, 1908.
        Stock(
            symbol: "GM",
            name: "General Motors Co.",
            currentPrice: 44.10,
            priceChange: 0.88,
            percentageChange: 2.04,
            foundedMonth: 9, foundedDay: 16, foundedYear: 1908,
            sector: "Automotive"
        ),

        // Source: https://en.wikipedia.org/wiki/Ford_Motor_Company - founded June 16, 1903.
        Stock(
            symbol: "F",
            name: "Ford Motor Company",
            currentPrice: 12.34,
            priceChange: 0.28,
            percentageChange: 2.32,
            foundedMonth: 6, foundedDay: 16, foundedYear: 1903,
            sector: "Automotive"
        ),

        // Source: https://en.wikipedia.org/wiki/Boeing - founded July 15, 1916.
        Stock(
            symbol: "BA",
            name: "The Boeing Company",
            currentPrice: 178.23,
            priceChange: 3.45,
            percentageChange: 1.97,
            foundedMonth: 7, foundedDay: 15, foundedYear: 1916,
            sector: "Industrials"
        ),

        // Source: https://en.wikipedia.org/wiki/Caterpillar_Inc. - founded April 15, 1925.
        Stock(
            symbol: "CAT",
            name: "Caterpillar Inc.",
            currentPrice: 346.70,
            priceChange: 2.15,
            percentageChange: 0.62,
            foundedMonth: 4, foundedDay: 15, foundedYear: 1925,
            sector: "Industrials"
        ),

        // Source: https://en.wikipedia.org/wiki/General_Electric - founded April 15, 1892.
        Stock(
            symbol: "GE",
            name: "General Electric Company",
            currentPrice: 167.45,
            priceChange: 2.34,
            percentageChange: 1.42,
            foundedMonth: 4, foundedDay: 15, foundedYear: 1892,
            sector: "Industrials"
        ),

        // Source: https://en.wikipedia.org/wiki/AbbVie - spun off as a public company January 1, 2013.
        Stock(
            symbol: "ABBV",
            name: "AbbVie Inc.",
            currentPrice: 168.40,
            priceChange: 1.18,
            percentageChange: 0.71,
            foundedMonth: 1, foundedDay: 1, foundedYear: 2013,
            sector: "Healthcare"
        ),

        // Source: https://en.wikipedia.org/wiki/Eli_Lilly_and_Company - founded May 10, 1876.
        Stock(
            symbol: "LLY",
            name: "Eli Lilly and Company",
            currentPrice: 770.25,
            priceChange: 6.30,
            percentageChange: 0.82,
            foundedMonth: 5, foundedDay: 10, foundedYear: 1876,
            sector: "Healthcare"
        ),

        // Source: https://en.wikipedia.org/wiki/ExxonMobil - Exxon Mobil merger completed November 30, 1999.
        Stock(
            symbol: "XOM",
            name: "Exxon Mobil Corp.",
            currentPrice: 104.56,
            priceChange: -1.23,
            percentageChange: -1.16,
            foundedMonth: 11, foundedDay: 30, foundedYear: 1999,
            sector: "Energy"
        ),

        // Source: https://en.wikipedia.org/wiki/Chevron_Corporation - Pacific Coast Oil founded September 10, 1879.
        Stock(
            symbol: "CVX",
            name: "Chevron Corp.",
            currentPrice: 147.23,
            priceChange: -2.34,
            percentageChange: -1.56,
            foundedMonth: 9, foundedDay: 10, foundedYear: 1879,
            sector: "Energy"
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
        var groups: [ZodiacSign.Element: [Stock]] = [:]
        for stock in samples {
            guard let element = stock.element else { continue }
            groups[element, default: []].append(stock)
        }
        return groups
    }
}

// MARK: - Seeded Random Generator
// ================================
// For generating consistent pseudo-random price history

struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // Simple linear congruential generator
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Price Point Model
// =========================
// Data point for chart display with date and price.

struct PricePoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}

// MARK: - Chart Timeframe
// =======================
// Available timeframes for stock charts.

enum ChartTimeframe: String, CaseIterable, Identifiable, Hashable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonth = "3M"
    case sixMonth = "6M"
    case year = "1Y"
    case twoYear = "2Y"
    case all = "ALL"

    var id: String { rawValue }

    static let stockDetailHistoricalCases: [ChartTimeframe] = [
        .month,
        .threeMonth,
        .sixMonth,
        .year,
        .twoYear
    ]

    /// Human-readable description
    var description: String {
        switch self {
        case .day: return "Today"
        case .week: return "Past Week"
        case .month: return "Past Month"
        case .threeMonth: return "Past 3 Months"
        case .sixMonth: return "Past 6 Months"
        case .year: return "Past Year"
        case .twoYear: return "Past 2 Years"
        case .all: return "All Time"
        }
    }

    /// Number of trading days in timeframe
    var tradingDays: Int {
        switch self {
        case .day: return 1
        case .week: return 5
        case .month: return 22
        case .threeMonth: return 66
        case .sixMonth: return 126
        case .year: return 252
        case .twoYear: return 504
        case .all: return 1260  // 5 years
        }
    }
}

// MARK: - Stock Key Stats
// =======================
// Key statistics for stock detail view.

struct StockKeyStats: Equatable {
    enum Field: String, CaseIterable {
        case open
        case marketCap
        case dayRange
        case week52Range
        case volume
        case avgVolume
        case peRatio
        case dividendYield
    }

    let open: Double?
    let dayHigh: Double?
    let dayLow: Double?
    let volume: Int?
    let avgVolume: Int?
    let marketCap: Double?
    let peRatio: Double?
    let weekHigh52: Double?
    let weekLow52: Double?
    let dividendYield: Double?
    let fieldProvenance: [Field: FinancialDataProvenance]

    var hasAnyAvailableField: Bool {
        open != nil || dayHigh != nil || dayLow != nil || volume != nil ||
        avgVolume != nil || marketCap != nil || peRatio != nil ||
        weekHigh52 != nil || weekLow52 != nil || dividendYield != nil
    }

    /// Format volume for display (e.g., "15.2M")
    var formattedVolume: String {
        guard let volume else { return "Unavailable" }
        return formatLargeNumber(Double(volume))
    }

    /// Format average volume for display
    var formattedAvgVolume: String {
        guard let avgVolume else { return "Unavailable" }
        return formatLargeNumber(Double(avgVolume))
    }

    /// Format market cap for display (e.g., "$2.8T")
    var formattedMarketCap: String {
        guard let marketCap else { return "Unavailable" }
        return formatLargeNumber(marketCap, prefix: "$")
    }

    /// Format P/E ratio
    var formattedPERatio: String {
        guard let peRatio else { return "Unavailable" }
        return String(format: "%.2f", peRatio)
    }

    /// Format dividend yield
    var formattedDividendYield: String {
        guard let dividendYield else { return "Unavailable" }
        return String(format: "%.2f%%", dividendYield)
    }

    /// Format 52-week range
    var formattedWeek52Range: String {
        guard let weekLow52, let weekHigh52 else { return "Unavailable" }
        return String(format: "$%.2f - $%.2f", weekLow52, weekHigh52)
    }

    /// Format day range
    var formattedDayRange: String {
        guard let dayLow, let dayHigh else { return "Unavailable" }
        return String(format: "$%.2f - $%.2f", dayLow, dayHigh)
    }

    /// Format open price
    var formattedOpen: String {
        guard let open else { return "Unavailable" }
        return String(format: "$%.2f", open)
    }

    func provenance(for field: Field) -> FinancialDataProvenance {
        fieldProvenance[field] ?? .unavailable(reason: "Provider field unavailable")
    }

    private func formatLargeNumber(_ value: Double, prefix: String = "") -> String {
        if value >= 1_000_000_000_000 {
            return String(format: "%@%.2fT", prefix, value / 1_000_000_000_000)
        } else if value >= 1_000_000_000 {
            return String(format: "%@%.2fB", prefix, value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "%@%.2fM", prefix, value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%@%.2fK", prefix, value / 1_000)
        } else {
            return String(format: "%@%.0f", prefix, value)
        }
    }
}

#if DEBUG
extension StockKeyStats {
    /// Explicit preview fixture. Production UI must not synthesize key stats.
    static let previewSample = StockKeyStats(
        open: 175.30,
        dayHigh: 178.80,
        dayLow: 174.10,
        volume: 48_000_000,
        avgVolume: 61_000_000,
        marketCap: 2_850_000_000_000,
        peRatio: 28.4,
        weekHigh52: 199.62,
        weekLow52: 164.08,
        dividendYield: 0.52,
        fieldProvenance: Dictionary(
            uniqueKeysWithValues: StockKeyStats.Field.allCases.map {
                ($0, FinancialDataProvenance.sample(reason: "Preview fixture"))
            }
        )
    )
}
#endif

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
 print(apple.zodiacSign?.displayName ?? "Unknown")  // "Aries"
 print(apple.zodiacSign?.symbol ?? "?")             // "♈"
 print(apple.element?.sfSymbol ?? "questionmark")   // "flame.fill" (Fire)

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
