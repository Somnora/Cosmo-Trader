import Foundation
import SwiftUI

// MARK: - Cosmic Ticker Service
// ==============================
// Generates ticker tape items mixing stock data with cosmic commentary.
//
// "AAPL +1.2% | TSLA -0.4% | MOON IN SCORPIO | GOOGL +0.8% | VOC ENDS 2PM"
//
// WHY IT WORKS: Bloomberg meets mysticism. Constantly engaging. Premium feel.

@MainActor
@Observable
final class CosmicTickerService {

    // MARK: - Singleton

    static let shared = CosmicTickerService()

    // MARK: - Dependencies

    private let moonService: MoonPhaseService
    private let vocService: VoidOfCourseMoonService
    private let astroService: AstroAlertService
    private let retrogradeService: MercuryRetrogradeService
    private let seasonService: SignSeasonService

    // MARK: - State

    /// Current ticker items
    private(set) var tickerItems: [TickerItem] = []

    /// Stocks supplied by a caller that fetched provider-backed quotes.
    /// The ticker never invents stock data (see production_mock_guard);
    /// this is the only path by which price items appear, and the 30s
    /// cosmic refresh preserves it.
    private var providerBackedStocks: [Stock] = []

    /// Refresh timer
    @ObservationIgnored
    private var refreshTimer: Timer?

    // MARK: - Configuration

    /// How often cosmic items appear (1 in N items)
    private let cosmicFrequency: Int = 4

    /// Maximum cosmic items in ticker at once
    private let maxCosmicItems: Int = 3

    // MARK: - Initialization

    private init() {
        self.moonService = MoonPhaseService.shared
        self.vocService = VoidOfCourseMoonService.shared
        self.astroService = AstroAlertService.shared
        self.retrogradeService = MercuryRetrogradeService.shared
        self.seasonService = SignSeasonService.shared
        refreshTicker()
        // Timer will be started by App when scene becomes active
    }

    // MARK: - Public Methods

    /// Refresh ticker with current data
    func refreshTicker() {
        tickerItems = generateTickerItems(for: providerBackedStocks.isEmpty ? nil : providerBackedStocks)
    }

    /// Supply stocks whose quote fields were just refreshed from a
    /// provider-backed source. Pass an empty array to drop stock items
    /// (e.g. quotes became unavailable) — the tape falls back to
    /// cosmic-only content with its data-unavailable quips.
    func updateProviderBackedStocks(_ stocks: [Stock]) {
        providerBackedStocks = stocks
        refreshTicker()
    }

    /// Generate ticker items for specific stocks
    func generateTickerItems(for stocks: [Stock]? = nil) -> [TickerItem] {
        var items: [TickerItem] = []

        // Only render stock ticker items when a caller supplies provider-backed
        // or explicitly labeled data. Falling back to MockStockData here made
        // sample price movement look live in production.
        let stocksToShow = stocks ?? []

        // Cosmic-only tape: no provider-backed quotes were supplied, so run
        // the full cosmic set and always disclose that market data is
        // absent. The disclosure is deterministic, never a random quip.
        if stocksToShow.isEmpty {
            var items = generateCosmicMessages()
            items.append(TickerItem(type: .cosmic(.quip), text: "MARKET DATA UNAVAILABLE", color: .cyan))
            return items
        }

        // Build ticker with interspersed cosmic items
        var cosmicItemsAdded = 0
        let cosmicMessages = generateCosmicMessages()

        for (index, stock) in stocksToShow.enumerated() {
            // Add stock item
            items.append(TickerItem(
                type: .stock(stock),
                text: formatStockTicker(stock),
                color: stock.percentageChange >= 0 ? CosmicTheme.positive : CosmicTheme.negative
            ))

            // Occasionally inject cosmic item
            if (index + 1) % cosmicFrequency == 0 && cosmicItemsAdded < maxCosmicItems {
                if let cosmicMessage = cosmicMessages[safe: cosmicItemsAdded] {
                    items.append(cosmicMessage)
                    cosmicItemsAdded += 1
                }
            }
        }

        // Ensure at least one cosmic item at the end if none added
        if cosmicItemsAdded == 0, let firstCosmic = cosmicMessages.first {
            items.append(firstCosmic)
        }

        return items
    }

    // MARK: - Stock Formatting

    private func formatStockTicker(_ stock: Stock) -> String {
        let change = stock.percentageChange
        let sign = change >= 0 ? "+" : ""
        return "\(stock.symbol) \(sign)\(String(format: "%.1f", change))%"
    }

    // MARK: - Cosmic Message Generation

    private func generateCosmicMessages() -> [TickerItem] {
        var messages: [TickerItem] = []

        // 1. Moon phase and sign
        let lunarData = moonService.getCurrentLunarData()
        messages.append(TickerItem(
            type: .cosmic(.moon),
            text: "MOON IN \(lunarData.moonSign.displayName.uppercased())",
            color: lunarData.moonSign.element.color
        ))

        // 2. VOC status (if active or ending soon)
        if vocService.isCurrentlyVOC {
            if let endTime = vocService.currentVOCPeriod?.endTime {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mma"
                let endString = formatter.string(from: endTime).lowercased()
                messages.append(TickerItem(
                    type: .cosmic(.voc),
                    text: "VOC ENDS \(endString.uppercased())",
                    color: .orange
                ))
            }
        } else if let nextVOC = vocService.upcomingVOCPeriods.first(where: { $0.startTime > Date() }) {
            let calendar = Calendar.current
            let hoursUntil = calendar.dateComponents([.hour], from: Date(), to: nextVOC.startTime).hour ?? 0
            if hoursUntil <= 4 && hoursUntil > 0 {
                messages.append(TickerItem(
                    type: .cosmic(.voc),
                    text: "VOC IN \(hoursUntil)H",
                    color: .yellow
                ))
            }
        }

        // 3. Mercury Retrograde
        if retrogradeService.isRetrograde {
            messages.append(TickerItem(
                type: .cosmic(.retrograde),
                text: "MERCURY RX DAY \(retrogradeService.currentDayOfRetrograde)",
                color: .orange
            ))
        } else if retrogradeService.daysUntilNext <= 7 && retrogradeService.daysUntilNext > 0 {
            messages.append(TickerItem(
                type: .cosmic(.retrograde),
                text: "MERCURY RX IN \(retrogradeService.daysUntilNext)D",
                color: .yellow
            ))
        }

        // 4. Active cosmic events
        if let activeEvent = astroService.primaryActiveEvent {
            messages.append(TickerItem(
                type: .cosmic(.event),
                text: "[\(activeEvent.type.rawValue)] \(activeEvent.title.uppercased())",
                color: activeEvent.themeColor
            ))
        }

        // 5. Sign season
        let currentSign = seasonService.getCurrentSign()
        messages.append(TickerItem(
            type: .cosmic(.season),
            text: "\(currentSign.displayName.uppercased()) SEASON",
            color: currentSign.element.color
        ))

        // 6. Random cosmic quip (variety)
        let quips = generateCosmicQuips()
        if let quip = quips.randomElement() {
            messages.append(quip)
        }

        return messages.shuffled()
    }

    private func generateCosmicQuips() -> [TickerItem] {
        let lunarData = moonService.getCurrentLunarData()
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())

        var quips: [TickerItem] = []

        // Moon phase specific
        switch lunarData.phase {
        case .fullMoon:
            quips.append(TickerItem(
                type: .cosmic(.quip),
                text: "FULL MOON: COSMIC CONTEXT",
                color: .white
            ))
        case .newMoon:
            quips.append(TickerItem(
                type: .cosmic(.quip),
                text: "NEW MOON: RESET WINDOW",
                color: CosmicTheme.textSecondary
            ))
        case .waxingCrescent, .waxingGibbous, .firstQuarter:
            quips.append(TickerItem(
                type: .cosmic(.quip),
                text: "WAXING MOON: ENERGY BUILDING",
                color: CosmicTheme.positive
            ))
        case .waningCrescent, .waningGibbous, .lastQuarter:
            quips.append(TickerItem(
                type: .cosmic(.quip),
                text: "WANING MOON: REVIEW WINDOW",
                color: CosmicTheme.textSecondary
            ))
        }

        // Day-specific quips
        switch dayOfWeek {
        case 2: // Monday
            quips.append(TickerItem(
                type: .cosmic(.quip),
                text: "MOON DAY: SENTIMENT FOCUS",
                color: .white
            ))
        case 3: // Tuesday
            quips.append(TickerItem(
                type: .cosmic(.quip),
                text: "MARS DAY: RISK APPETITE",
                color: .red
            ))
        case 4: // Wednesday
            quips.append(TickerItem(
                type: .cosmic(.quip),
                text: "MERCURY DAY: EXECUTION RISK",
                color: .orange
            ))
        case 5: // Thursday
            quips.append(TickerItem(
                type: .cosmic(.quip),
                text: "JUPITER DAY: EXPANSION BIAS",
                color: CosmicTheme.accentBlue
            ))
        case 6: // Friday
            quips.append(TickerItem(
                type: .cosmic(.quip),
                text: "VENUS DAY: VALUE DISCIPLINE",
                color: CosmicTheme.gold
            ))
        default:
            break
        }

        // General cosmic wisdom. Data-availability quips deliberately do not
        // live in this random pool: the cosmic-only branch of
        // generateTickerItems discloses unavailability deterministically, and
        // an unavailability quip must never scroll next to live quotes.
        quips.append(TickerItem(type: .cosmic(.quip), text: "COSMIC CONTEXT ONLY", color: CosmicTheme.gold))

        return quips
    }

    // MARK: - Timer Management

    @objc private func handleRefreshTimer() {
        refreshTicker()
    }

    /// Start the refresh timer (called when app becomes active)
    func startRefreshTimer() {
        // Prevent duplicate timers
        stopRefreshTimer()

        // Refresh every 30 seconds
        refreshTimer = Timer.scheduledTimer(
            timeInterval: 30,
            target: self,
            selector: #selector(handleRefreshTimer),
            userInfo: nil,
            repeats: true
        )
    }

    /// Stop the refresh timer (called when app goes to background)
    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Ticker Item

struct TickerItem: Identifiable, Equatable {
    let id = UUID()
    let type: TickerItemType
    let text: String
    let color: Color

    static func == (lhs: TickerItem, rhs: TickerItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum TickerItemType: Equatable {
    case stock(Stock)
    case cosmic(CosmicTickerType)

    static func == (lhs: TickerItemType, rhs: TickerItemType) -> Bool {
        switch (lhs, rhs) {
        case (.stock(let s1), .stock(let s2)):
            return s1.symbol == s2.symbol
        case (.cosmic(let c1), .cosmic(let c2)):
            return c1 == c2
        default:
            return false
        }
    }
}

enum CosmicTickerType: String, CaseIterable {
    case moon = "Moon"
    case voc = "VOC"
    case retrograde = "Retrograde"
    case event = "Event"
    case season = "Season"
    case quip = "Quip"
}
