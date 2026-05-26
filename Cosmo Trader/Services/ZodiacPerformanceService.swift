import Foundation

// MARK: - ZodiacPerformanceService
// =================================
// Tracks and analyzes weekly performance of stocks grouped by zodiac sign.
// Shows cosmic patterns in market performance - which signs are "blessed"
// by the market this week and which are being "tested".

// MARK: - Weekly Performance Model

/// Performance data for stocks of a single zodiac sign
struct ZodiacWeeklyPerformance: Identifiable {
    let id = UUID()
    let sign: ZodiacSign
    let averageReturn: Double           // Percentage
    let topPerformer: Stock?            // Best performing stock in sign
    let bottomPerformer: Stock?         // Worst performing stock in sign
    let stockCount: Int
    let totalMarketCap: Double?         // Combined value if available

    /// Formatted average return string
    var formattedReturn: String {
        let prefix = averageReturn >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", averageReturn))%"
    }

    /// Whether the sign is positive this week
    var isPositive: Bool {
        averageReturn >= 0
    }

    /// Performance rating based on return
    var performanceRating: PerformanceRating {
        switch averageReturn {
        case 5...: return .exceptional
        case 2..<5: return .strong
        case 0..<2: return .modest
        case -2..<0: return .weak
        default: return .struggling
        }
    }

    enum PerformanceRating: String {
        case exceptional = "Exceptional"
        case strong = "Strong"
        case modest = "Modest"
        case weak = "Weak"
        case struggling = "Struggling"

        var sfSymbol: String {
            switch self {
            case .exceptional: return "flame.fill"
            case .strong: return "sparkles"
            case .modest: return "chart.line.uptrend.xyaxis"
            case .weak: return "chart.line.downtrend.xyaxis"
            case .struggling: return "exclamationmark.triangle.fill"
            }
        }
    }
}

// MARK: - Weekly Snapshot (for historical tracking)

/// Snapshot of zodiac performance for a specific week
struct ZodiacPerformanceSnapshot: Codable, Identifiable {
    let id: UUID
    let weekStartDate: Date
    let weekEndDate: Date
    let performances: [SignPerformanceRecord]
    let topSign: String
    let bottomSign: String

    init(weekStartDate: Date, performances: [ZodiacWeeklyPerformance]) {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.weekEndDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        self.performances = performances.map { SignPerformanceRecord(from: $0) }

        let sorted = performances.sorted { $0.averageReturn > $1.averageReturn }
        self.topSign = sorted.first?.sign.rawValue ?? ""
        self.bottomSign = sorted.last?.sign.rawValue ?? ""
    }

    /// Record for a single sign (Codable-friendly)
    struct SignPerformanceRecord: Codable, Identifiable {
        let id: UUID
        let signRawValue: String
        let averageReturn: Double
        let stockCount: Int

        init(from performance: ZodiacWeeklyPerformance) {
            self.id = UUID()
            self.signRawValue = performance.sign.rawValue
            self.averageReturn = performance.averageReturn
            self.stockCount = performance.stockCount
        }

        var sign: ZodiacSign? {
            ZodiacSign(rawValue: signRawValue)
        }
    }
}

// MARK: - Streak Data

/// Tracks winning/losing streaks for a sign
struct ZodiacStreak {
    let sign: ZodiacSign
    let streakType: StreakType
    let weekCount: Int

    enum StreakType {
        case winning    // Positive returns
        case losing     // Negative returns
        case top3       // In top 3 performers
        case bottom3    // In bottom 3 performers
    }

    var description: String {
        switch streakType {
        case .winning:
            return "\(sign.displayName) stocks positive \(weekCount) weeks running"
        case .losing:
            return "\(sign.displayName) stocks negative \(weekCount) weeks running"
        case .top3:
            return "\(sign.displayName) in top 3 for \(weekCount) consecutive weeks"
        case .bottom3:
            return "\(sign.displayName) struggling for \(weekCount) weeks"
        }
    }
}

// MARK: - Service

enum ZodiacPerformanceService {

    // MARK: - Storage Keys

    private static let snapshotsKey = "zodiac_performance_snapshots"
    private static let lastCalculationKey = "zodiac_performance_last_calculation"

    // MARK: - Weekly Performance Calculation

    /// Calculate weekly performance for all zodiac signs
    /// - Parameter stocks: Array of stocks to analyze
    /// - Returns: Array of performance data sorted by return (best first)
    static func calculateWeeklyPerformance(stocks: [Stock]) -> [ZodiacWeeklyPerformance] {
        // Group stocks by zodiac sign
        let grouped = Dictionary(grouping: stocks) { $0.zodiacSign }

        return grouped.map { sign, signStocks in
            // Calculate average return (using percentageChange as proxy for weekly)
            let returns = signStocks.map { $0.percentageChange }
            let avgReturn = returns.isEmpty ? 0 : returns.reduce(0, +) / Double(returns.count)

            // Sort to find top/bottom performers
            let sorted = signStocks.sorted { $0.percentageChange > $1.percentageChange }

            return ZodiacWeeklyPerformance(
                sign: sign,
                averageReturn: avgReturn,
                topPerformer: sorted.first,
                bottomPerformer: sorted.last,
                stockCount: signStocks.count,
                totalMarketCap: nil
            )
        }.sorted { $0.averageReturn > $1.averageReturn }
    }

    // MARK: - Leaderboard Data

    /// Get ranked leaderboard with positions
    static func getLeaderboard(stocks: [Stock]) -> [(rank: Int, performance: ZodiacWeeklyPerformance)] {
        let performances = calculateWeeklyPerformance(stocks: stocks)
        return performances.enumerated().map { index, performance in
            (rank: index + 1, performance: performance)
        }
    }

    // MARK: - Commentary Generation

    /// Generate witty commentary about the week's performance
    static func generateWeeklyCommentary(
        performances: [ZodiacWeeklyPerformance],
        userSign: ZodiacSign
    ) -> String {
        guard let topPerformer = performances.first,
              let bottomPerformer = performances.last else {
            return "More performance data is needed before the zodiac pattern is useful."
        }

        // Find user's sign ranking
        let userRank = performances.firstIndex(where: { $0.sign == userSign }).map { $0 + 1 } ?? 0
        let userPerformance = performances.first(where: { $0.sign == userSign })

        var commentary = ""

        // Top performer commentary
        commentary += topSignCommentary(topPerformer)

        // Add context about bottom performer
        if bottomPerformer.averageReturn < -2 {
            commentary += " Meanwhile, \(bottomPerformer.sign.displayName) stocks face cosmic headwinds."
        }

        // Add user-relevant insight if not top/bottom
        if userRank > 1 && userRank < performances.count {
            if let perf = userPerformance {
                if perf.isPositive {
                    commentary += " Your \(userSign.displayName) holdings are steady at #\(userRank)."
                } else {
                    commentary += " Your \(userSign.displayName) stocks need cosmic patience this week."
                }
            }
        }

        return commentary
    }

    private static func topSignCommentary(_ top: ZodiacWeeklyPerformance) -> String {
        let sign = top.sign

        switch sign.element {
        case .fire:
            return "\(sign.displayName) stocks blaze ahead at \(top.formattedReturn). Fire signs reward the bold this week."
        case .earth:
            return "\(sign.displayName) leads with \(top.formattedReturn). Steady Earth energy wins the week."
        case .air:
            return "\(sign.displayName) stocks soar at \(top.formattedReturn). Air signs carry the market higher."
        case .water:
            return "\(sign.displayName) flows to the top at \(top.formattedReturn). Intuition beats analysis this week."
        }
    }

    /// Generate insight for a specific sign's performance
    static func generateSignInsight(performance: ZodiacWeeklyPerformance, rank: Int) -> String {
        let sign = performance.sign

        if rank == 1 {
            return "\(sign.displayName) leads the zodiac performance board this week."
        } else if rank <= 3 {
            return "Strong week for \(sign.displayName). Market and sign signals are aligned."
        } else if rank <= 6 {
            return "Middle of the pack. \(sign.displayName) holds steady."
        } else if rank <= 9 {
            return "Below average week. \(sign.displayName) may need better timing."
        } else {
            return "Challenging week for \(sign.displayName). Treat it as a risk-control signal."
        }
    }

    // MARK: - Historical Tracking

    /// Save current week's snapshot for historical tracking
    static func saveWeeklySnapshot(performances: [ZodiacWeeklyPerformance]) {
        var snapshots = loadSnapshots()

        // Get start of current week
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return
        }

        // Check if we already have this week
        if snapshots.contains(where: { calendar.isDate($0.weekStartDate, equalTo: weekStart, toGranularity: .weekOfYear) }) {
            // Update existing snapshot
            snapshots.removeAll { calendar.isDate($0.weekStartDate, equalTo: weekStart, toGranularity: .weekOfYear) }
        }

        // Add new snapshot
        let snapshot = ZodiacPerformanceSnapshot(weekStartDate: weekStart, performances: performances)
        snapshots.append(snapshot)

        // Keep only last 12 weeks
        if snapshots.count > 12 {
            snapshots = Array(snapshots.suffix(12))
        }

        saveSnapshots(snapshots)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCalculationKey)
    }

    /// Load historical snapshots
    static func loadSnapshots() -> [ZodiacPerformanceSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: snapshotsKey) else {
            return []
        }
        return (try? JSONDecoder().decode([ZodiacPerformanceSnapshot].self, from: data)) ?? []
    }

    private static func saveSnapshots(_ snapshots: [ZodiacPerformanceSnapshot]) {
        if let data = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(data, forKey: snapshotsKey)
        }
    }

    // MARK: - Streak Detection

    /// Detect winning/losing streaks from historical data
    static func detectStreaks() -> [ZodiacStreak] {
        let snapshots = loadSnapshots()
        guard snapshots.count >= 2 else { return [] }

        var streaks: [ZodiacStreak] = []

        // Check each sign for streaks
        for sign in ZodiacSign.allCases {
            // Check for positive/negative streaks
            var positiveStreak = 0
            var negativeStreak = 0
            var top3Streak = 0
            var bottom3Streak = 0

            // Go through snapshots from most recent
            for snapshot in snapshots.reversed() {
                guard let record = snapshot.performances.first(where: { $0.signRawValue == sign.rawValue }) else {
                    break
                }

                // Check positive/negative
                if record.averageReturn >= 0 {
                    if negativeStreak > 0 { break }
                    positiveStreak += 1
                } else {
                    if positiveStreak > 0 { break }
                    negativeStreak += 1
                }

                // Check ranking
                let sorted = snapshot.performances.sorted { $0.averageReturn > $1.averageReturn }
                if let idx = sorted.firstIndex(where: { $0.signRawValue == sign.rawValue }) {
                    if idx < 3 {
                        top3Streak += 1
                    } else if idx >= sorted.count - 3 {
                        bottom3Streak += 1
                    }
                }
            }

            // Add significant streaks (3+ weeks)
            if positiveStreak >= 3 {
                streaks.append(ZodiacStreak(sign: sign, streakType: .winning, weekCount: positiveStreak))
            }
            if negativeStreak >= 3 {
                streaks.append(ZodiacStreak(sign: sign, streakType: .losing, weekCount: negativeStreak))
            }
            if top3Streak >= 3 {
                streaks.append(ZodiacStreak(sign: sign, streakType: .top3, weekCount: top3Streak))
            }
            if bottom3Streak >= 3 {
                streaks.append(ZodiacStreak(sign: sign, streakType: .bottom3, weekCount: bottom3Streak))
            }
        }

        return streaks.sorted { $0.weekCount > $1.weekCount }
    }

    // MARK: - Element Performance

    /// Calculate performance by element
    static func calculateElementPerformance(from performances: [ZodiacWeeklyPerformance]) -> [(element: ZodiacSign.Element, avgReturn: Double)] {
        var elementReturns: [ZodiacSign.Element: [Double]] = [:]

        for perf in performances {
            elementReturns[perf.sign.element, default: []].append(perf.averageReturn)
        }

        return elementReturns.map { element, returns in
            let avg = returns.isEmpty ? 0 : returns.reduce(0, +) / Double(returns.count)
            return (element: element, avgReturn: avg)
        }.sorted { $0.avgReturn > $1.avgReturn }
    }

    // MARK: - User Sign Context

    /// Get context about user's sign relative to the market
    static func getUserSignContext(
        userSign: ZodiacSign,
        performances: [ZodiacWeeklyPerformance]
    ) -> (rank: Int, insight: String, isOutperforming: Bool) {
        guard let index = performances.firstIndex(where: { $0.sign == userSign }),
              let userPerf = performances.first(where: { $0.sign == userSign }) else {
            return (rank: 0, insight: "No data available", isOutperforming: false)
        }

        let rank = index + 1
        let avgMarket = performances.map { $0.averageReturn }.reduce(0, +) / Double(performances.count)
        let isOutperforming = userPerf.averageReturn > avgMarket

        let insight: String
        if rank == 1 {
            insight = "Your sign leads this week's zodiac board: \(userPerf.formattedReturn)"
        } else if rank <= 3 {
            insight = "Top 3 finish. \(userSign.displayName) is outperforming at \(userPerf.formattedReturn)"
        } else if isOutperforming {
            insight = "\(userSign.displayName) beats the market average at #\(rank)"
        } else {
            insight = "\(userSign.displayName) at #\(rank) - patience is the cleaner read"
        }

        return (rank: rank, insight: insight, isOutperforming: isOutperforming)
    }
}
