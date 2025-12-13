import Foundation
import SwiftUI

// MARK: - Karmic Ledger Service
// ==============================
// Tracks and reframes investment losses as "cosmic lessons."
//
// FEATURE: Karmic Ledger
// When user sells at a loss, record it in the "Karmic Ledger"
// Each loss gets a lesson generated based on cosmic conditions at sale time.
//
// "Lost $340 on RIVN. Lesson: Fire sign stocks during Water moon cycles
//  require patience. The cosmos noted this."
//
// Total "tuition paid to the universe": $X
//
// WHY IT WORKS: Reframes losses psychologically. Dark humor. Memorable.

@MainActor
@Observable
final class KarmicLedgerService {

    // MARK: - Singleton

    static let shared = KarmicLedgerService()

    // MARK: - Storage Keys

    private enum StorageKeys {
        static let karmicEntries = "karmicLedger_entries"
    }

    // MARK: - State

    /// All karmic lessons learned
    private(set) var entries: [KarmicEntry] = []

    /// Total tuition paid to the universe
    var totalTuition: Double {
        entries.reduce(0) { $0 + $1.lossAmount }
    }

    /// Formatted total tuition
    var formattedTotalTuition: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalTuition)) ?? "$0.00"
    }

    /// Number of lessons learned
    var lessonsLearned: Int {
        entries.count
    }

    /// Most expensive lesson
    var biggestLesson: KarmicEntry? {
        entries.max(by: { $0.lossAmount < $1.lossAmount })
    }

    /// Most recent lesson
    var latestLesson: KarmicEntry? {
        entries.sorted(by: { $0.saleDate > $1.saleDate }).first
    }

    /// Lessons grouped by element
    var lessonsByElement: [ZodiacSign.Element: [KarmicEntry]] {
        Dictionary(grouping: entries) { $0.stockSign.element }
    }

    /// Most problematic element (highest total losses)
    var troublesomeElement: (element: ZodiacSign.Element, total: Double)? {
        let totals = lessonsByElement.mapValues { entries in
            entries.reduce(0) { $0 + $1.lossAmount }
        }
        guard let max = totals.max(by: { $0.value < $1.value }) else { return nil }
        return (max.key, max.value)
    }

    // MARK: - Initialization

    private init() {
        loadEntries()
    }

    // MARK: - Public Methods

    /// Record a new karmic lesson when selling at a loss
    func recordLoss(
        stock: Stock,
        salePrice: Double,
        sharesSold: Double,
        purchasePrice: Double
    ) {
        let lossPerShare = purchasePrice - salePrice
        guard lossPerShare > 0 else { return } // Not a loss

        let totalLoss = lossPerShare * sharesSold

        // Get current cosmic conditions
        let moonData = MoonPhaseService.shared.getCurrentLunarData()
        let isRetrograde = AstroAlertService.shared.isMercuryRetrograde

        // Generate the cosmic lesson
        let lesson = generateLesson(
            stock: stock,
            lossAmount: totalLoss,
            moonPhase: moonData.phase,
            moonSign: moonData.moonSign,
            isMercuryRetrograde: isRetrograde
        )

        let entry = KarmicEntry(
            stockSymbol: stock.symbol,
            stockName: stock.name,
            stockSign: stock.zodiacSign,
            lossAmount: totalLoss,
            sharesSold: sharesSold,
            purchasePrice: purchasePrice,
            salePrice: salePrice,
            saleDate: Date(),
            moonPhase: moonData.phase,
            moonSign: moonData.moonSign,
            isMercuryRetrograde: isRetrograde,
            lesson: lesson
        )

        entries.append(entry)
        saveEntries()

        // Track analytics
        AnalyticsService.shared.track(.karmicLessonRecorded)
    }

    /// Record a loss with just the basic info (for manual entry)
    func recordManualLoss(
        symbol: String,
        name: String,
        sign: ZodiacSign,
        lossAmount: Double,
        saleDate: Date = Date()
    ) {
        let moonData = MoonPhaseService.shared.getLunarData(for: saleDate)
        let isRetrograde = AstroAlertService.shared.isMercuryRetrograde

        // Create a temporary stock for lesson generation
        let tempStock = Stock(
            symbol: symbol,
            name: name,
            currentPrice: 0,
            priceChange: 0,
            percentageChange: 0,
            foundedDate: sign.typicalStartDate,
            sector: "Unknown"
        )

        let lesson = generateLesson(
            stock: tempStock,
            lossAmount: lossAmount,
            moonPhase: moonData.phase,
            moonSign: moonData.moonSign,
            isMercuryRetrograde: isRetrograde
        )

        let entry = KarmicEntry(
            stockSymbol: symbol,
            stockName: name,
            stockSign: sign,
            lossAmount: lossAmount,
            sharesSold: 0,
            purchasePrice: 0,
            salePrice: 0,
            saleDate: saleDate,
            moonPhase: moonData.phase,
            moonSign: moonData.moonSign,
            isMercuryRetrograde: isRetrograde,
            lesson: lesson
        )

        entries.append(entry)
        saveEntries()
    }

    /// Delete an entry
    func deleteEntry(_ entry: KarmicEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    /// Clear all entries
    func clearAllEntries() {
        entries.removeAll()
        saveEntries()
    }

    /// Get karmic wisdom summary
    func getKarmicWisdom() -> KarmicWisdom {
        let elementLosses = lessonsByElement.mapValues { entries in
            entries.reduce(0) { $0 + $1.lossAmount }
        }

        // Find patterns
        var patterns: [String] = []

        if let troublesome = troublesomeElement {
            patterns.append("Your \(troublesome.element.displayName) sector has cost you \(formatCurrency(troublesome.total)). The universe is sending a message.")
        }

        let retrogradeEntries = entries.filter { $0.isMercuryRetrograde }
        if retrogradeEntries.count > 2 {
            let retroLosses = retrogradeEntries.reduce(0) { $0 + $1.lossAmount }
            patterns.append("You've lost \(formatCurrency(retroLosses)) during Mercury retrograde periods. Consider cosmic timing.")
        }

        // Count moon phase losses
        let moonPhaseCounts = Dictionary(grouping: entries) { $0.moonPhase }
        if let worstMoonPhase = moonPhaseCounts.max(by: { $0.value.count < $1.value.count }),
           worstMoonPhase.value.count > 2 {
            patterns.append("The \(worstMoonPhase.key.rawValue) has witnessed \(worstMoonPhase.value.count) of your lessons. Note this pattern.")
        }

        return KarmicWisdom(
            totalTuition: totalTuition,
            lessonsLearned: lessonsLearned,
            elementBreakdown: elementLosses,
            patterns: patterns,
            overallWisdom: generateOverallWisdom()
        )
    }

    // MARK: - Lesson Generation

    private func generateLesson(
        stock: Stock,
        lossAmount: Double,
        moonPhase: MoonPhase,
        moonSign: ZodiacSign,
        isMercuryRetrograde: Bool
    ) -> String {
        let stockElement = stock.zodiacSign.element
        let moonElement = moonSign.element

        var lessons: [String] = []

        // Element conflict lessons
        if !areElementsCompatible(stockElement, moonElement) {
            lessons.append(contentsOf: [
                "\(stockElement.displayName) sign stocks during \(moonElement.displayName) moon cycles require patience.",
                "The \(stockElement.displayName)-\(moonElement.displayName) tension was working against you.",
                "\(stock.zodiacSign.displayName) energy clashes with \(moonSign.displayName) moon. Timing matters.",
                "Selling \(stockElement.displayName) positions under a \(moonElement.displayName) moon rarely ends well."
            ])
        }

        // Moon phase lessons
        switch moonPhase {
        case .newMoon:
            lessons.append(contentsOf: [
                "New moons favor new beginnings, not exits. The cosmos noted your impatience.",
                "You sold during lunar darkness. Sometimes we need to wait for illumination."
            ])
        case .fullMoon:
            lessons.append(contentsOf: [
                "Full moon emotions led this decision. The tides of regret follow.",
                "Selling at full moon can feel right but rarely is. Clarity comes later."
            ])
        case .waxingCrescent, .firstQuarter, .waxingGibbous:
            lessons.append(contentsOf: [
                "You sold during a waxing moon — as energy was building, not releasing.",
                "The moon was still growing. Perhaps your position needed more time too."
            ])
        case .waningGibbous, .lastQuarter, .waningCrescent:
            lessons.append(contentsOf: [
                "The waning moon approves of release, but not at any price.",
                "Letting go during the waning phase is natural. The loss less so."
            ])
        }

        // Mercury retrograde lessons
        if isMercuryRetrograde {
            lessons.append(contentsOf: [
                "Mercury was retrograde. Communication with the market was compromised.",
                "Selling during Mercury retrograde? The cosmos tried to warn you.",
                "Mercury's backward dance rarely favors financial decisions."
            ])
        }

        // Stock sign specific lessons
        switch stock.zodiacSign {
        case .aries, .leo, .sagittarius:
            lessons.append("Fire sign stocks burn bright but demand patience through volatility.")
        case .taurus, .virgo, .capricorn:
            lessons.append("Earth sign stocks reward those who hold through temporary tremors.")
        case .gemini, .libra, .aquarius:
            lessons.append("Air sign stocks shift like wind. Conviction weathers the gusts.")
        case .cancer, .scorpio, .pisces:
            lessons.append("Water sign stocks flow with emotion. Don't let yours override strategy.")
        }

        // General wisdom
        lessons.append(contentsOf: [
            "The universe collects tuition from all students of the market.",
            "Every loss is a deposit into your cosmic education fund.",
            "The stars remember this lesson so you don't have to repeat it.",
            "Pain is the universe's invoice. Wisdom is the receipt."
        ])

        // Pick a random lesson
        let selectedLesson = lessons.randomElement() ?? "The cosmos noted this."

        return selectedLesson + " The cosmos noted this."
    }

    private func generateOverallWisdom() -> String {
        guard lessonsLearned > 0 else {
            return "Your karmic ledger is clean. For now."
        }

        if totalTuition < 100 {
            return "Minor tuition fees. The universe considers you a promising student."
        } else if totalTuition < 500 {
            return "Moderate cosmic education expenses. The lessons are taking shape."
        } else if totalTuition < 1000 {
            return "Significant tuition paid. You're earning your degree in market humility."
        } else if totalTuition < 5000 {
            return "Advanced studies in cosmic loss recovery. The PhD is in sight."
        } else {
            return "You've funded an endowment to the universe. True enlightenment awaits."
        }
    }

    private func areElementsCompatible(_ e1: ZodiacSign.Element, _ e2: ZodiacSign.Element) -> Bool {
        switch (e1, e2) {
        case (.fire, .air), (.air, .fire): return true
        case (.earth, .water), (.water, .earth): return true
        case (.fire, .fire), (.earth, .earth), (.air, .air), (.water, .water): return true
        default: return false
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    // MARK: - Persistence

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: StorageKeys.karmicEntries)
        }
    }

    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.karmicEntries),
           let decoded = try? JSONDecoder().decode([KarmicEntry].self, from: data) {
            entries = decoded
        }
    }
}

// MARK: - Karmic Entry

struct KarmicEntry: Identifiable, Codable {
    let id: UUID
    let stockSymbol: String
    let stockName: String
    let stockSign: ZodiacSign
    let lossAmount: Double
    let sharesSold: Double
    let purchasePrice: Double
    let salePrice: Double
    let saleDate: Date
    let moonPhaseRaw: String  // Store as String for Codable
    let moonSign: ZodiacSign
    let isMercuryRetrograde: Bool
    let lesson: String

    /// Get the MoonPhase from stored raw value
    var moonPhase: MoonPhase {
        MoonPhase(rawValue: moonPhaseRaw) ?? .newMoon
    }

    init(
        id: UUID = UUID(),
        stockSymbol: String,
        stockName: String,
        stockSign: ZodiacSign,
        lossAmount: Double,
        sharesSold: Double,
        purchasePrice: Double,
        salePrice: Double,
        saleDate: Date,
        moonPhase: MoonPhase,
        moonSign: ZodiacSign,
        isMercuryRetrograde: Bool,
        lesson: String
    ) {
        self.id = id
        self.stockSymbol = stockSymbol
        self.stockName = stockName
        self.stockSign = stockSign
        self.lossAmount = lossAmount
        self.sharesSold = sharesSold
        self.purchasePrice = purchasePrice
        self.salePrice = salePrice
        self.saleDate = saleDate
        self.moonPhaseRaw = moonPhase.rawValue
        self.moonSign = moonSign
        self.isMercuryRetrograde = isMercuryRetrograde
        self.lesson = lesson
    }

    /// Formatted loss amount
    var formattedLoss: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: lossAmount)) ?? "$0.00"
    }

    /// Formatted sale date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: saleDate)
    }

    /// Short formatted date
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: saleDate)
    }

    /// Element of the stock
    var element: ZodiacSign.Element {
        stockSign.element
    }

    /// Cosmic conditions summary
    var cosmicConditions: String {
        var conditions: [String] = []
        conditions.append("\(moonPhase.rawValue)")
        conditions.append("Moon in \(moonSign.displayName)")
        if isMercuryRetrograde {
            conditions.append("Mercury Retrograde")
        }
        return conditions.joined(separator: " · ")
    }
}

// MARK: - Karmic Wisdom

struct KarmicWisdom {
    let totalTuition: Double
    let lessonsLearned: Int
    let elementBreakdown: [ZodiacSign.Element: Double]
    let patterns: [String]
    let overallWisdom: String

    /// Formatted total tuition
    var formattedTuition: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalTuition)) ?? "$0.00"
    }
}

// MARK: - ZodiacSign Extension

extension ZodiacSign {
    /// A typical start date for this sign (for creating temp stocks)
    var typicalStartDate: Date {
        let startInfo = self.startDate
        var components = DateComponents()
        components.month = startInfo.month
        components.day = startInfo.day
        components.year = 2000
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - Analytics Events

extension AnalyticsEvent {
    static let karmicLessonRecorded = AnalyticsEvent(rawValue: "karmic_lesson_recorded")!
    static let karmicLedgerViewed = AnalyticsEvent(rawValue: "karmic_ledger_viewed")!
    static let karmicWisdomViewed = AnalyticsEvent(rawValue: "karmic_wisdom_viewed")!
}
