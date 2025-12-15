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
    var element: ZodiacSign.Element {
        zodiacSign.element
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

    /// Simulated price history for sparkline display
    /// WHY: Generates consistent pseudo-random price history based on stock symbol
    ///      for visual trend representation in portfolio rows.
    /// NOTE: In production, this would come from real historical API data.
    var priceHistory: [Double] {
        // Generate deterministic pseudo-random history based on symbol hash
        var history: [Double] = []
        let seed = symbol.hashValue
        var generator = SeededRandomGenerator(seed: UInt64(abs(seed)))

        // Start from a base price (current price minus recent change extrapolated)
        let basePrice = currentPrice - (priceChange * 5)
        var price = max(basePrice, currentPrice * 0.9) // Don't go below 90% of current

        // Generate 15 data points for sparkline
        for i in 0..<15 {
            // Progress toward end (0.0 to 1.0)
            let progress = Double(i) / 14.0

            // Drift toward current price, stronger as we approach the end
            let targetDrift = (currentPrice - price) * (0.1 + progress * 0.1)

            // Add some noise based on the stock's volatility (percentageChange as proxy)
            let volatility = max(abs(percentageChange), 0.5) * 0.5
            let noise = (Double.random(in: -1...1, using: &generator)) * volatility

            price += targetDrift + noise
            price = max(price, currentPrice * 0.85) // Keep within reasonable bounds
            price = min(price, currentPrice * 1.15)

            history.append(price)
        }

        // Ensure last point is current price
        history[history.count - 1] = currentPrice

        return history
    }

    /// Generate detailed price history with dates for chart display
    /// - Parameter timeframe: The timeframe for the chart data
    /// - Returns: Array of PricePoint with date and price
    func chartData(for timeframe: ChartTimeframe) -> [PricePoint] {
        let calendar = Calendar.current
        let now = Date()
        let seed = symbol.hashValue + timeframe.hashValue
        var generator = SeededRandomGenerator(seed: UInt64(abs(seed)))

        // Determine number of points and interval based on timeframe
        let (pointCount, component, interval): (Int, Calendar.Component, Int) = {
            switch timeframe {
            case .day: return (78, .minute, 5)      // 5-min intervals for trading day (9:30-4:00)
            case .week: return (35, .hour, 4)       // 4-hour intervals
            case .month: return (30, .day, 1)       // Daily
            case .threeMonth: return (90, .day, 1)  // Daily
            case .year: return (52, .weekOfYear, 1) // Weekly
            case .all: return (60, .month, 1)       // Monthly (5 years)
            }
        }()

        var points: [PricePoint] = []

        // Calculate starting price based on timeframe performance
        let timeframeReturn = timeframePerformance(for: timeframe, generator: &generator)
        let startPrice = currentPrice / (1 + timeframeReturn / 100)

        var price = startPrice

        for i in 0..<pointCount {
            // Calculate date going backwards from now
            let pointsFromEnd = pointCount - 1 - i
            let date: Date
            if component == .minute {
                // For intraday, start from market open today
                let marketOpen = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: now) ?? now
                date = calendar.date(byAdding: component, value: i * interval, to: marketOpen) ?? now
            } else {
                date = calendar.date(byAdding: component, value: -pointsFromEnd * interval, to: now) ?? now
            }

            // Progress toward current price
            let progress = Double(i) / Double(pointCount - 1)

            // Base volatility varies by timeframe
            let baseVolatility: Double = {
                switch timeframe {
                case .day: return 0.002    // 0.2% per 5 minutes
                case .week: return 0.005   // 0.5% per 4 hours
                case .month: return 0.015  // 1.5% per day
                case .threeMonth: return 0.02
                case .year: return 0.025
                case .all: return 0.04
                }
            }()

            // Add trend drift toward current price
            let targetDrift = (currentPrice - price) * (0.02 + progress * 0.08)

            // Add realistic volatility with some momentum
            let noise = Double.random(in: -1...1, using: &generator) * baseVolatility * price

            price += targetDrift + noise
            price = max(price, currentPrice * 0.5)  // Floor at 50% of current
            price = min(price, currentPrice * 2.0)  // Cap at 200% of current

            points.append(PricePoint(date: date, price: price))
        }

        // Ensure last point is current price
        if !points.isEmpty {
            points[points.count - 1] = PricePoint(date: now, price: currentPrice)
        }

        return points
    }

    /// Simulated timeframe performance percentage
    private func timeframePerformance(for timeframe: ChartTimeframe, generator: inout SeededRandomGenerator) -> Double {
        // Base on current percentageChange with some variation
        let dailyChange = percentageChange

        switch timeframe {
        case .day:
            return dailyChange
        case .week:
            return dailyChange * (3 + Double.random(in: -1...1, using: &generator))
        case .month:
            return dailyChange * (8 + Double.random(in: -3...3, using: &generator))
        case .threeMonth:
            return dailyChange * (15 + Double.random(in: -5...5, using: &generator))
        case .year:
            return dailyChange * (40 + Double.random(in: -15...15, using: &generator))
        case .all:
            return dailyChange * (80 + Double.random(in: -30...30, using: &generator))
        }
    }

    /// Key statistics for the stock
    var keyStats: StockKeyStats {
        let seed = symbol.hashValue
        var generator = SeededRandomGenerator(seed: UInt64(abs(seed)))

        // Generate realistic mock stats
        let dayHigh = currentPrice * (1 + Double.random(in: 0.005...0.025, using: &generator))
        let dayLow = currentPrice * (1 - Double.random(in: 0.005...0.025, using: &generator))
        let open = currentPrice - priceChange + Double.random(in: -0.5...0.5, using: &generator)

        // Volume based on price level (higher price = lower volume typically)
        let baseVolume = 50_000_000 / sqrt(currentPrice)
        let volume = Int(baseVolume * Double.random(in: 0.7...1.5, using: &generator))

        // Market cap (mock based on price)
        let sharesOutstanding = Double.random(in: 500_000_000...5_000_000_000, using: &generator)
        let marketCap = currentPrice * sharesOutstanding

        // 52-week range
        let yearHigh = currentPrice * Double.random(in: 1.1...1.4, using: &generator)
        let yearLow = currentPrice * Double.random(in: 0.6...0.9, using: &generator)

        // P/E ratio (realistic range)
        let peRatio = Double.random(in: 10...50, using: &generator)

        // Dividend yield (0-4%)
        let dividendYield = Double.random(in: 0...0.04, using: &generator)

        return StockKeyStats(
            open: open,
            dayHigh: dayHigh,
            dayLow: dayLow,
            volume: volume,
            avgVolume: Int(Double(volume) * Double.random(in: 0.8...1.2, using: &generator)),
            marketCap: marketCap,
            peRatio: peRatio,
            weekHigh52: yearHigh,
            weekLow52: yearLow,
            dividendYield: dividendYield
        )
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
        purchasePrice: Double? = nil,
        purchaseDate: Date? = nil,
        foundedDate: Date,
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
        self.foundedDate = Calendar.current.date(from: components) ?? Date()

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

    /// Sample stocks with REAL founding dates and purchase tracking data
    static let samples: [Stock] = [
        // Apple - Founded April 1, 1976 (ARIES - Fire sign)
        // Purchased at $150 in March 2024
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

        // Google/Alphabet - Founded September 4, 1998 (VIRGO - Earth sign)
        // Purchased at $135 in January 2024
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

        // Tesla - Founded July 1, 2003 (CANCER - Water sign)
        // Purchased at $200 in June 2024
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

        // Microsoft - Founded April 4, 1975 (ARIES - Fire sign)
        // Purchased at $350 in February 2024
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

        // Amazon - Founded July 5, 1994 (CANCER - Water sign)
        // Watchlist only - no purchase data
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

        // NVIDIA - Founded January 25, 1993 (AQUARIUS - Air sign)
        // Purchased at $300 in April 2024 - big winner!
        Stock(
            symbol: "NVDA",
            name: "NVIDIA Corp.",
            currentPrice: 467.80,
            priceChange: 15.20,
            percentageChange: 3.36,
            sharesOwned: 2,
            purchasePrice: 300.00,
            purchaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 5)),
            foundedMonth: 1, foundedDay: 25, foundedYear: 1993,
            sector: "Technology"
        ),

        // Meta (Facebook) - Founded February 4, 2004 (AQUARIUS - Air sign)
        // Watchlist only - no purchase data
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
        // Purchased at $450 in May 2024
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
    case year = "1Y"
    case all = "ALL"

    var id: String { rawValue }

    /// Human-readable description
    var description: String {
        switch self {
        case .day: return "Today"
        case .week: return "Past Week"
        case .month: return "Past Month"
        case .threeMonth: return "Past 3 Months"
        case .year: return "Past Year"
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
        case .year: return 252
        case .all: return 1260  // 5 years
        }
    }
}

// MARK: - Stock Key Stats
// =======================
// Key statistics for stock detail view.

struct StockKeyStats {
    let open: Double
    let dayHigh: Double
    let dayLow: Double
    let volume: Int
    let avgVolume: Int
    let marketCap: Double
    let peRatio: Double
    let weekHigh52: Double
    let weekLow52: Double
    let dividendYield: Double

    /// Format volume for display (e.g., "15.2M")
    var formattedVolume: String {
        formatLargeNumber(Double(volume))
    }

    /// Format average volume for display
    var formattedAvgVolume: String {
        formatLargeNumber(Double(avgVolume))
    }

    /// Format market cap for display (e.g., "$2.8T")
    var formattedMarketCap: String {
        formatLargeNumber(marketCap, prefix: "$")
    }

    /// Format P/E ratio
    var formattedPERatio: String {
        String(format: "%.2f", peRatio)
    }

    /// Format dividend yield
    var formattedDividendYield: String {
        String(format: "%.2f%%", dividendYield * 100)
    }

    /// Format 52-week range
    var formattedWeek52Range: String {
        String(format: "$%.2f - $%.2f", weekLow52, weekHigh52)
    }

    /// Format day range
    var formattedDayRange: String {
        String(format: "$%.2f - $%.2f", dayLow, dayHigh)
    }

    /// Format open price
    var formattedOpen: String {
        String(format: "$%.2f", open)
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
