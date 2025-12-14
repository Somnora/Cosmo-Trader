import Foundation

// MARK: - UserProfile Model
// =========================
// Represents the user's astrological investor profile.
//
// This is the central model for the logged-in user, containing:
// - Personal information (name, birthdate)
// - Astrological data (sun sign, computed from birthdate)
// - Portfolio (stocks they own)
// - Account information (when they joined, etc.)
//
// WHY SEPARATE FROM "User"?
// -------------------------
// We renamed from "User" to "UserProfile" because:
// 1. More descriptive - it's specifically their PROFILE data
// 2. Avoids confusion with authentication User types
// 3. Emphasizes this contains display/personalization info

struct UserProfile: Identifiable, Codable, Equatable {

    // MARK: - Identity
    // ================

    /// Unique identifier for this user
    /// WHY: Required by SwiftUI and useful for database storage
    let id: UUID

    /// User's display name
    /// WHY: What we show in the UI - "Hello, Sarah!"
    /// NOTE: This is var because users can change their display name
    var displayName: String

    /// User's email address
    /// WHY: Used for account identification and communication
    var email: String

    // MARK: - Astrological Data
    // =========================
    // The cosmic heart of our app!

    /// User's birth date
    /// WHY: This is the KEY to their astrological profile!
    ///      From this date, we calculate their sun sign.
    /// NOTE: We only use month/day for zodiac, but storing full date
    ///       allows for birthday features and age verification
    let birthDate: Date

    /// User's time of birth (optional)
    /// WHY: Enables more precise astrological calculations:
    ///      - Rising sign (ascendant) - requires exact time
    ///      - Moon sign - more accurate with time
    ///      - Planetary houses - require time and location
    /// NOTE: Optional because many users don't know their exact birth time
    var timeOfBirth: Date?

    /// User's birth location (optional, city name)
    /// WHY: Combined with time of birth, enables:
    ///      - Accurate rising sign calculation (requires timezone)
    ///      - Precise planetary positions
    /// NOTE: Future use - full birth chart calculations
    var birthLocation: String?

    /// Whether the user has provided their birth time
    var hasBirthTime: Bool {
        timeOfBirth != nil
    }

    /// User's sun sign - COMPUTED from their birth date
    /// WHY: This is the "main" zodiac sign people know
    ///      "What's your sign?" → This is that sign!
    ///
    /// HOW IT WORKS:
    /// 1. Take the user's birthDate
    /// 2. Extract month and day
    /// 3. Use ZodiacSign.from(date:) to calculate
    ///
    /// COMPUTED vs STORED:
    /// We compute this instead of storing because:
    /// - It's derived data (birthDate is the source of truth)
    /// - If we stored it, it could get out of sync
    /// - Computed properties are automatically correct
    var sunSign: ZodiacSign {
        ZodiacSign.from(date: birthDate)
    }

    // MARK: - Portfolio
    // =================
    // The user's stock holdings

    /// Array of stocks the user owns
    /// WHY: This IS the portfolio - the stocks they've invested in
    /// NOTE: This is var because it changes as they buy/sell
    var portfolio: [Stock]

    /// Watchlist of stock symbols the user is interested in
    /// WHY: "Dating app for stocks" - stocks they've swiped right on
    var watchlist: [String]

    /// Symbols of stocks the user has dismissed/skipped
    /// WHY: Don't show them the same stocks again
    var skippedStocks: [String]

    // MARK: - Account Info
    // ====================

    /// When the user created their account
    /// WHY: For "Member since" display and account age features
    let memberSince: Date

    /// User's preferred currency (for future internationalization)
    /// WHY: Not everyone uses USD - future-proofing
    var preferredCurrency: String

    // MARK: - Computed Properties
    // ===========================

    /// The element of the user's sun sign
    /// WHY: Quick access for element-based features
    var element: ZodiacSign.Element {
        sunSign.element
    }

    /// User's trading style based on their element
    /// WHY: Personalized advice based on astrological profile
    var suggestedTradingStyle: String {
        sunSign.element.tradingStyle
    }

    /// Total portfolio value across all stocks
    /// WHY: The big number users care about most!
    /// CALCULATION: Sum of (price × shares) for each stock
    var totalPortfolioValue: Double {
        portfolio.reduce(0) { total, stock in
            total + stock.totalValue
        }
    }

    /// Total daily change across all positions
    /// WHY: "How much did I make/lose TODAY?"
    var totalDailyChange: Double {
        portfolio.reduce(0) { total, stock in
            total + stock.todaysProfitLoss
        }
    }

    /// Percentage change of total portfolio today
    /// WHY: Percentage is more meaningful than absolute dollars
    var totalDailyChangePercent: Double {
        let previousValue = totalPortfolioValue - totalDailyChange
        guard previousValue > 0 else { return 0 }
        return (totalDailyChange / previousValue) * 100
    }

    /// Is the portfolio up overall today?
    var isPortfolioPositive: Bool {
        totalDailyChange >= 0
    }

    /// Number of different stocks owned
    var numberOfHoldings: Int {
        portfolio.filter { $0.sharesOwned > 0 }.count
    }

    /// Stocks in portfolio that are compatible with user's sign
    /// WHY: "Cosmically aligned" stocks for fun personalization
    var compatibleStocks: [Stock] {
        portfolio.filter { $0.isCompatible(with: sunSign) }
    }

    /// Stocks in portfolio that share the user's element
    /// WHY: Same element = similar energy
    var sameElementStocks: [Stock] {
        portfolio.filter { $0.sharesElement(with: sunSign) }
    }

    /// The user's age in years
    /// WHY: Might be useful for age-appropriate features
    var age: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: Date())
        return components.year ?? 0
    }

    /// How long the user has been a member
    /// WHY: For loyalty features and "Member since" display
    var membershipDuration: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: memberSince, to: Date())

        if let years = components.year, years > 0 {
            return years == 1 ? "1 year" : "\(years) years"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1 month" : "\(months) months"
        } else {
            return "New member"
        }
    }

    // MARK: - Initializers
    // ====================

    /// Full initializer
    init(
        id: UUID = UUID(),
        displayName: String,
        email: String,
        birthDate: Date,
        timeOfBirth: Date? = nil,
        birthLocation: String? = nil,
        portfolio: [Stock] = [],
        watchlist: [String] = [],
        skippedStocks: [String] = [],
        memberSince: Date = Date(),
        preferredCurrency: String = "USD"
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.birthDate = birthDate
        self.timeOfBirth = timeOfBirth
        self.birthLocation = birthLocation
        self.portfolio = portfolio
        self.watchlist = watchlist
        self.skippedStocks = skippedStocks
        self.memberSince = memberSince
        self.preferredCurrency = preferredCurrency
    }

    /// Convenience initializer with birth date components
    /// WHY: Easier than creating Date objects manually
    init(
        id: UUID = UUID(),
        displayName: String,
        email: String,
        birthMonth: Int,
        birthDay: Int,
        birthYear: Int,
        birthHour: Int? = nil,
        birthMinute: Int? = nil,
        birthLocation: String? = nil,
        portfolio: [Stock] = [],
        watchlist: [String] = [],
        skippedStocks: [String] = [],
        memberSince: Date = Date(),
        preferredCurrency: String = "USD"
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.birthLocation = birthLocation
        self.portfolio = portfolio
        self.watchlist = watchlist
        self.skippedStocks = skippedStocks
        self.memberSince = memberSince
        self.preferredCurrency = preferredCurrency

        // Create birth date from components
        var components = DateComponents()
        components.month = birthMonth
        components.day = birthDay
        components.year = birthYear
        self.birthDate = Calendar.current.date(from: components) ?? Date()

        // Create time of birth if provided
        if let hour = birthHour, let minute = birthMinute {
            var timeComponents = DateComponents()
            timeComponents.hour = hour
            timeComponents.minute = minute
            self.timeOfBirth = Calendar.current.date(from: timeComponents)
        } else {
            self.timeOfBirth = nil
        }
    }
}

// MARK: - Formatting Helpers
// ==========================

extension UserProfile {

    /// Formatted total portfolio value
    var formattedPortfolioValue: String {
        formatCurrency(totalPortfolioValue)
    }

    /// Formatted daily change with sign
    var formattedDailyChange: String {
        let sign = totalDailyChange >= 0 ? "+" : ""
        return sign + formatCurrency(totalDailyChange)
    }

    /// Formatted daily change percentage
    var formattedDailyChangePercent: String {
        let sign = totalDailyChangePercent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, totalDailyChangePercent)
    }

    /// Formatted birth date (e.g., "March 15, 1990")
    var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: birthDate)
    }

    /// Formatted time of birth (e.g., "2:30 PM" or "Unknown")
    var formattedTimeOfBirth: String {
        guard let time = timeOfBirth else {
            return "Unknown"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    /// Full formatted birth info (date and time if known)
    var formattedFullBirthInfo: String {
        if let time = timeOfBirth {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(formattedBirthDate) at \(formatter.string(from: time))"
        }
        return formattedBirthDate
    }

    /// Formatted member since date
    var formattedMemberSince: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: memberSince)
    }

    /// Currency formatter helper
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = preferredCurrency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Portfolio Management
// ============================

extension UserProfile {

    /// Add a stock to the portfolio
    /// WHY: When user buys a new stock
    mutating func addStock(_ stock: Stock) {
        // Check if we already own this stock
        if let index = portfolio.firstIndex(where: { $0.symbol == stock.symbol }) {
            // Update existing position
            portfolio[index].sharesOwned += stock.sharesOwned
        } else {
            // Add new stock
            portfolio.append(stock)
        }
    }

    /// Remove a stock from the portfolio
    /// WHY: When user sells all shares of a stock
    mutating func removeStock(symbol: String) {
        portfolio.removeAll { $0.symbol == symbol }
    }

    /// Update shares owned for a stock
    /// WHY: When user buys or sells some shares
    mutating func updateShares(symbol: String, newAmount: Double) {
        if let index = portfolio.firstIndex(where: { $0.symbol == symbol }) {
            portfolio[index].sharesOwned = newAmount
        }
    }

    /// Get stocks grouped by their zodiac element
    /// WHY: For element-based portfolio views
    var portfolioByElement: [ZodiacSign.Element: [Stock]] {
        Dictionary(grouping: portfolio) { $0.element }
    }

    /// Get stocks grouped by their zodiac sign
    /// WHY: For sign-based portfolio views
    var portfolioBySign: [ZodiacSign: [Stock]] {
        Dictionary(grouping: portfolio) { $0.zodiacSign }
    }

    // MARK: - Watchlist Management

    /// Add a stock to the watchlist
    mutating func addToWatchlist(_ symbol: String) {
        guard !watchlist.contains(symbol) else { return }
        watchlist.append(symbol)
        // Remove from skipped if it was there
        skippedStocks.removeAll { $0 == symbol }
    }

    /// Remove a stock from the watchlist
    mutating func removeFromWatchlist(_ symbol: String) {
        watchlist.removeAll { $0 == symbol }
    }

    /// Skip/dismiss a stock
    mutating func skipStock(_ symbol: String) {
        guard !skippedStocks.contains(symbol) else { return }
        skippedStocks.append(symbol)
        // Remove from watchlist if it was there
        watchlist.removeAll { $0 == symbol }
    }

    /// Check if a stock is in the watchlist
    func isInWatchlist(_ symbol: String) -> Bool {
        watchlist.contains(symbol)
    }

    /// Check if a stock has been skipped
    func isSkipped(_ symbol: String) -> Bool {
        skippedStocks.contains(symbol)
    }

    /// Reset skipped stocks to see them again
    mutating func resetSkippedStocks() {
        skippedStocks.removeAll()
    }
}

// MARK: - Cosmic Insights
// =======================
// Fun astrological features for the user

extension UserProfile {

    /// Generate a personalized cosmic insight
    /// WHY: Fun, personalized content for the horoscope section
    var cosmicInsight: String {
        let compatCount = compatibleStocks.count
        let totalCount = portfolio.count

        if totalCount == 0 {
            return "Your cosmic portfolio awaits! Start investing to align with the stars."
        }

        let compatibility = Double(compatCount) / Double(totalCount) * 100

        if compatibility >= 75 {
            return "Stellar alignment! \(Int(compatibility))% of your portfolio resonates with your \(sunSign.displayName) energy."
        } else if compatibility >= 50 {
            return "Good cosmic balance. Consider adding more \(sunSign.element.displayName) sign stocks."
        } else {
            return "Your portfolio ventures beyond your comfort zone. The stars encourage exploration!"
        }
    }

    /// Suggest a stock element based on user's sign
    /// WHY: Playful recommendations
    var recommendedElement: ZodiacSign.Element {
        sunSign.element
    }

    /// Signs that would make good "investment partners"
    var compatibleInvestorSigns: [ZodiacSign] {
        sunSign.compatibleSigns
    }
}

// MARK: - Sample Data
// ===================

extension UserProfile {

    /// Sample user for previews and testing
    /// Born August 15, 1990 → LEO (Fire sign)
    static let sample = UserProfile(
        displayName: "Sarah Chen",
        email: "sarah@cosmictrader.com",
        birthMonth: 8,
        birthDay: 15,
        birthYear: 1990,
        portfolio: Stock.ownedSamples,
        memberSince: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    )

    /// Another sample user - different sign
    /// Born January 25, 1985 → AQUARIUS (Air sign)
    static let sampleAquarius = UserProfile(
        displayName: "Marcus Johnson",
        email: "marcus@cosmictrader.com",
        birthMonth: 1,
        birthDay: 25,
        birthYear: 1985,
        portfolio: Stock.samples,
        memberSince: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    )

    /// New user with empty portfolio
    static let newUser = UserProfile(
        displayName: "New Trader",
        email: "newbie@cosmictrader.com",
        birthMonth: 4,
        birthDay: 10,
        birthYear: 2000,
        portfolio: []
    )
}

// MARK: - Usage Examples
// ======================
/*
 EXAMPLE 1: Create a user and get their sun sign
 -----------------------------------------------
 let user = UserProfile(
     displayName: "Sarah",
     email: "sarah@example.com",
     birthMonth: 8,
     birthDay: 15,
     birthYear: 1990
 )
 print(user.sunSign.displayName)  // "Leo"
 print(user.sunSign.symbol)       // "♌"
 print(user.element.emoji)        // "🔥" (Fire)

 EXAMPLE 2: Check portfolio compatibility
 ----------------------------------------
 let user = UserProfile.sample
 print("Compatible stocks: \(user.compatibleStocks.count)")
 print("Same element stocks: \(user.sameElementStocks.count)")

 EXAMPLE 3: Get cosmic insight
 -----------------------------
 print(user.cosmicInsight)
 // "Stellar alignment! 75% of your portfolio resonates with your Leo energy."

 EXAMPLE 4: Portfolio totals
 ---------------------------
 print(user.formattedPortfolioValue)      // "$12,345.67"
 print(user.formattedDailyChange)         // "+$234.56"
 print(user.formattedDailyChangePercent)  // "+1.94%"

 EXAMPLE 5: How the zodiac calculation flows
 -------------------------------------------
 User's birthDate: August 15, 1990
     ↓
 ZodiacSign.from(date: birthDate)
     ↓
 Extracts: month = 8, day = 15
     ↓
 dateValue = 8 * 100 + 15 = 815
     ↓
 Checks: 815 >= 723 (Leo start) AND 815 <= 822 (Leo end)
     ↓
 Returns: .leo
     ↓
 user.sunSign = .leo
*/
