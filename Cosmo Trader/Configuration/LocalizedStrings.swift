//
//  LocalizedStrings.swift
//  Cosmo Trader
//
//  Type-safe localized string constants for SwiftUI views.
//  Use these constants instead of hardcoded strings for better
//  compile-time safety and easier refactoring.
//

import SwiftUI

// MARK: - L10n (Localization Constants)

/// Type-safe localized string constants organized by feature area.
///
/// ## Usage in SwiftUI Views
/// ```swift
/// Text(L10n.Onboarding.title)
/// Text(L10n.Tabs.discover)
/// Button(L10n.Common.continue_) { }
/// ```
///
/// ## Why Use This?
/// 1. **Compile-time safety**: Typos in keys cause compiler errors
/// 2. **Autocomplete**: Xcode suggests available strings
/// 3. **Refactoring**: Rename keys in one place
/// 4. **Organization**: Strings grouped by feature
enum L10n {

    // MARK: - Onboarding

    /// Localized strings for the onboarding flow.
    enum Onboarding {
        static let title = LocalizedStringKey("onboarding.welcome.title")
        static let subtitle = LocalizedStringKey("onboarding.welcome.subtitle")
        static let description = LocalizedStringKey("onboarding.welcome.description")
        static let tagline = LocalizedStringKey("onboarding.welcome.tagline")

        static let signTitle = LocalizedStringKey("onboarding.sign.title")
        static let signPrompt = LocalizedStringKey("onboarding.sign.prompt")
        static let signDescription = LocalizedStringKey("onboarding.sign.description")

        static let nameTitle = LocalizedStringKey("onboarding.name.title")
        static let namePrompt = LocalizedStringKey("onboarding.name.prompt")
        static let namePlaceholder = LocalizedStringKey("onboarding.name.placeholder")

        static let stockTitle = LocalizedStringKey("onboarding.stock.title")
        static let stockPrompt = LocalizedStringKey("onboarding.stock.prompt")

        static let disclaimerTitle = LocalizedStringKey("onboarding.disclaimer.title")
        static let disclaimerText = LocalizedStringKey("onboarding.disclaimer.text")
        static let disclaimerAccept = LocalizedStringKey("onboarding.disclaimer.accept")

        static let completeTitle = LocalizedStringKey("onboarding.complete.title")
        static let completeMessage = LocalizedStringKey("onboarding.complete.message")

        static let continue_ = LocalizedStringKey("onboarding.continue")
        static let skip = LocalizedStringKey("onboarding.skip")
        static let back = LocalizedStringKey("onboarding.back")
        static let launch = LocalizedStringKey("onboarding.launch")
    }

    // MARK: - Tabs

    /// Localized strings for the tab bar.
    enum Tabs {
        static let discover = LocalizedStringKey("tabs.discover")
        static let cosmos = LocalizedStringKey("tabs.cosmos")
        static let portfolio = LocalizedStringKey("tabs.portfolio")
        static let profile = LocalizedStringKey("tabs.profile")
    }

    // MARK: - Discover

    /// Localized strings for the Discover tab.
    enum Discover {
        static let title = LocalizedStringKey("discover.title")
        static let subtitle = LocalizedStringKey("discover.subtitle")

        static let emptyTitle = LocalizedStringKey("discover.empty.title")
        static let emptyMessage = LocalizedStringKey("discover.empty.message")
        static let emptyReset = LocalizedStringKey("discover.empty.reset")

        static let swipeHint = LocalizedStringKey("discover.swipe.hint")
        static let swipeLike = LocalizedStringKey("discover.swipe.like")
        static let swipeSkip = LocalizedStringKey("discover.swipe.skip")
        static let swipeDetails = LocalizedStringKey("discover.swipe.details")

        static let filterTitle = LocalizedStringKey("discover.filter.title")
        static let filterElement = LocalizedStringKey("discover.filter.element")
        static let filterSector = LocalizedStringKey("discover.filter.sector")
        static let filterSort = LocalizedStringKey("discover.filter.sort")
        static let filterAll = LocalizedStringKey("discover.filter.all")
        static let filterApply = LocalizedStringKey("discover.filter.apply")
        static let filterReset = LocalizedStringKey("discover.filter.reset")

        static let sortCompatibility = LocalizedStringKey("discover.sort.compatibility")
        static let sortPerformance = LocalizedStringKey("discover.sort.performance")
        static let sortAlphabetical = LocalizedStringKey("discover.sort.alphabetical")
        static let sortPrice = LocalizedStringKey("discover.sort.price")

        static let contrarianTitle = LocalizedStringKey("discover.contrarian.title")
        static let contrarianDescription = LocalizedStringKey("discover.contrarian.description")
    }

    // MARK: - Cosmos

    /// Localized strings for the Cosmos tab (horoscope).
    enum Cosmos {
        static let title = LocalizedStringKey("cosmos.title")
        static let subtitle = LocalizedStringKey("cosmos.subtitle")

        static let greetingMorning = LocalizedStringKey("cosmos.greeting.morning")
        static let greetingAfternoon = LocalizedStringKey("cosmos.greeting.afternoon")
        static let greetingEvening = LocalizedStringKey("cosmos.greeting.evening")

        static let moonTitle = LocalizedStringKey("cosmos.moon.title")
        static let moonNew = LocalizedStringKey("cosmos.moon.new")
        static let moonFull = LocalizedStringKey("cosmos.moon.full")

        static let mercuryRetrograde = LocalizedStringKey("cosmos.mercury.retrograde")
        static let mercuryDirect = LocalizedStringKey("cosmos.mercury.direct")
        static let mercuryWarning = LocalizedStringKey("cosmos.mercury.warning")
        static let mercuryClear = LocalizedStringKey("cosmos.mercury.clear")

        static let vocTitle = LocalizedStringKey("cosmos.voc.title")
        static let vocActive = LocalizedStringKey("cosmos.voc.active")
        static let vocClear = LocalizedStringKey("cosmos.voc.clear")
        static let vocWarning = LocalizedStringKey("cosmos.voc.warning")

        static let signSeasonTitle = LocalizedStringKey("cosmos.signSeason.title")

        static let ritualTitle = LocalizedStringKey("cosmos.ritual.title")
        static let ritualCompleted = LocalizedStringKey("cosmos.ritual.completed")
        static let ritualPending = LocalizedStringKey("cosmos.ritual.pending")
    }

    // MARK: - Portfolio

    /// Localized strings for the Portfolio tab.
    enum Portfolio {
        static let title = LocalizedStringKey("portfolio.title")
        static let subtitle = LocalizedStringKey("portfolio.subtitle")

        static let emptyTitle = LocalizedStringKey("portfolio.empty.title")
        static let emptyMessage = LocalizedStringKey("portfolio.empty.message")
        static let emptyCTA = LocalizedStringKey("portfolio.empty.cta")

        static let total = LocalizedStringKey("portfolio.total")
        static let changeToday = LocalizedStringKey("portfolio.change.today")
        static let changeAllTime = LocalizedStringKey("portfolio.change.allTime")
        static let compatibility = LocalizedStringKey("portfolio.compatibility")
        static let holdings = LocalizedStringKey("portfolio.holdings")
        static let watchlist = LocalizedStringKey("portfolio.watchlist")

        static let addShares = LocalizedStringKey("portfolio.add.shares")
        static let editShares = LocalizedStringKey("portfolio.edit.shares")
        static let sharesLabel = LocalizedStringKey("portfolio.shares.label")
        static let sharesPlaceholder = LocalizedStringKey("portfolio.shares.placeholder")

        static let elementBreakdown = LocalizedStringKey("portfolio.element.breakdown")

        static let importTitle = LocalizedStringKey("portfolio.import.title")
        static let importDescription = LocalizedStringKey("portfolio.import.description")
        static let exportTitle = LocalizedStringKey("portfolio.export.title")
    }

    // MARK: - Stock Detail

    /// Localized strings for stock detail views.
    enum Stock {
        static let price = LocalizedStringKey("stock.price")
        static let change = LocalizedStringKey("stock.change")
        static let changeDay = LocalizedStringKey("stock.change.day")
        static let open = LocalizedStringKey("stock.open")
        static let high = LocalizedStringKey("stock.high")
        static let low = LocalizedStringKey("stock.low")
        static let volume = LocalizedStringKey("stock.volume")
        static let marketCap = LocalizedStringKey("stock.marketCap")
        static let peRatio = LocalizedStringKey("stock.peRatio")
        static let dividend = LocalizedStringKey("stock.dividend")

        static let compatibility = LocalizedStringKey("stock.compatibility")
        static let compatibilityScore = LocalizedStringKey("stock.compatibility.score")

        static let zodiac = LocalizedStringKey("stock.zodiac")

        static let ceo = LocalizedStringKey("stock.ceo")
        static let ceoCompatibility = LocalizedStringKey("stock.ceo.compatibility")
        static let founded = LocalizedStringKey("stock.founded")
        static let sector = LocalizedStringKey("stock.sector")
        static let industry = LocalizedStringKey("stock.industry")
        static let employees = LocalizedStringKey("stock.employees")
        static let headquarters = LocalizedStringKey("stock.headquarters")

        static let addPortfolio = LocalizedStringKey("stock.add.portfolio")
        static let addWatchlist = LocalizedStringKey("stock.add.watchlist")
        static let removePortfolio = LocalizedStringKey("stock.remove.portfolio")
        static let removeWatchlist = LocalizedStringKey("stock.remove.watchlist")
        static let share = LocalizedStringKey("stock.share")

        static let earningsTitle = LocalizedStringKey("stock.earnings.title")
        static let earningsNext = LocalizedStringKey("stock.earnings.next")
        static let earningsPrevious = LocalizedStringKey("stock.earnings.previous")

        static let patternsTitle = LocalizedStringKey("stock.patterns.title")
        static let patternsNone = LocalizedStringKey("stock.patterns.none")
    }

    // MARK: - Search

    /// Localized strings for the search interface.
    enum Search {
        static let title = LocalizedStringKey("search.title")
        static let placeholder = LocalizedStringKey("search.placeholder")
        static let recent = LocalizedStringKey("search.recent")
        static let popular = LocalizedStringKey("search.popular")
        static let trending = LocalizedStringKey("search.trending")
        static let clear = LocalizedStringKey("search.clear")
        static let clearAll = LocalizedStringKey("search.clear.all")
        static let noResults = LocalizedStringKey("search.no.results")
        static let noResultsDescription = LocalizedStringKey("search.no.results.description")
    }

    // MARK: - Profile

    /// Localized strings for the Profile tab.
    enum Profile {
        static let title = LocalizedStringKey("profile.title")
        static let edit = LocalizedStringKey("profile.edit")
        static let save = LocalizedStringKey("profile.save")

        static let name = LocalizedStringKey("profile.name")
        static let birthdate = LocalizedStringKey("profile.birthdate")
        static let sign = LocalizedStringKey("profile.sign")

        static let statsTitle = LocalizedStringKey("profile.stats.title")
        static let statsStocks = LocalizedStringKey("profile.stats.stocks")
        static let statsWatchlist = LocalizedStringKey("profile.stats.watchlist")
        static let statsCompatibility = LocalizedStringKey("profile.stats.compatibility")
        static let statsJoined = LocalizedStringKey("profile.stats.joined")

        static let settings = LocalizedStringKey("profile.settings")
        static let notifications = LocalizedStringKey("profile.notifications")
        static let subscription = LocalizedStringKey("profile.subscription")
        static let appearance = LocalizedStringKey("profile.appearance")
        static let sounds = LocalizedStringKey("profile.sounds")

        static let support = LocalizedStringKey("profile.support")
        static let help = LocalizedStringKey("profile.help")
        static let contact = LocalizedStringKey("profile.contact")
        static let feedback = LocalizedStringKey("profile.feedback")

        static let legal = LocalizedStringKey("profile.legal")
        static let privacy = LocalizedStringKey("profile.privacy")
        static let terms = LocalizedStringKey("profile.terms")
        static let licenses = LocalizedStringKey("profile.licenses")

        static let about = LocalizedStringKey("profile.about")
        static let rate = LocalizedStringKey("profile.rate")
        static let shareApp = LocalizedStringKey("profile.share.app")

        static let danger = LocalizedStringKey("profile.danger")
        static let reset = LocalizedStringKey("profile.reset")
        static let resetConfirm = LocalizedStringKey("profile.reset.confirm")
        static let delete = LocalizedStringKey("profile.delete")
    }

    // MARK: - Subscription

    /// Localized strings for subscription/paywall.
    enum Subscription {
        static let free = LocalizedStringKey("subscription.free")
        static let freeDescription = LocalizedStringKey("subscription.free.description")
        static let premium = LocalizedStringKey("subscription.premium")
        static let premiumDescription = LocalizedStringKey("subscription.premium.description")

        static let upgrade = LocalizedStringKey("subscription.upgrade")
        static let upgradeTitle = LocalizedStringKey("subscription.upgrade.title")
        static let current = LocalizedStringKey("subscription.current")

        static let featureHoroscope = LocalizedStringKey("subscription.feature.horoscope")
        static let featureCompatibility = LocalizedStringKey("subscription.feature.compatibility")
        static let featurePatterns = LocalizedStringKey("subscription.feature.patterns")
        static let featureAlerts = LocalizedStringKey("subscription.feature.alerts")
        static let featureWidgets = LocalizedStringKey("subscription.feature.widgets")
        static let featureThemes = LocalizedStringKey("subscription.feature.themes")

        static let restore = LocalizedStringKey("subscription.restore")
        static let restoreSuccess = LocalizedStringKey("subscription.restore.success")
        static let restoreNone = LocalizedStringKey("subscription.restore.none")

        static let terms = LocalizedStringKey("subscription.terms")
        static let cancel = LocalizedStringKey("subscription.cancel")
        static let manage = LocalizedStringKey("subscription.manage")
    }

    // MARK: - Notifications

    /// Localized strings for notification settings.
    enum Notifications {
        static let title = LocalizedStringKey("notifications.title")
        static let enable = LocalizedStringKey("notifications.enable")
        static let enableDescription = LocalizedStringKey("notifications.enable.description")

        static let dailyHoroscope = LocalizedStringKey("notifications.daily.horoscope")
        static let dailyHoroscopeDescription = LocalizedStringKey("notifications.daily.horoscope.description")
        static let dailyTime = LocalizedStringKey("notifications.daily.time")

        static let mercuryRetrograde = LocalizedStringKey("notifications.mercury.retrograde")
        static let mercuryRetrogradeDescription = LocalizedStringKey("notifications.mercury.retrograde.description")

        static let moonPhase = LocalizedStringKey("notifications.moon.phase")
        static let moonPhaseDescription = LocalizedStringKey("notifications.moon.phase.description")

        static let voc = LocalizedStringKey("notifications.voc")
        static let vocDescription = LocalizedStringKey("notifications.voc.description")

        static let priceAlerts = LocalizedStringKey("notifications.price.alerts")
        static let priceAlertsDescription = LocalizedStringKey("notifications.price.alerts.description")

        static let earnings = LocalizedStringKey("notifications.earnings")
        static let earningsDescription = LocalizedStringKey("notifications.earnings.description")

        static let signSeason = LocalizedStringKey("notifications.sign.season")
        static let signSeasonDescription = LocalizedStringKey("notifications.sign.season.description")
    }

    // MARK: - Errors

    /// Localized strings for error messages.
    enum Error {
        static let title = LocalizedStringKey("error.title")
        static let generic = LocalizedStringKey("error.generic")

        static let network = LocalizedStringKey("error.network")
        static let networkMessage = LocalizedStringKey("error.network.message")

        static let server = LocalizedStringKey("error.server")
        static let serverMessage = LocalizedStringKey("error.server.message")

        static let timeout = LocalizedStringKey("error.timeout")
        static let timeoutMessage = LocalizedStringKey("error.timeout.message")

        static let rateLimit = LocalizedStringKey("error.rate.limit")
        static let rateLimitMessage = LocalizedStringKey("error.rate.limit.message")

        static let invalidSymbol = LocalizedStringKey("error.invalid.symbol")

        static let offline = LocalizedStringKey("error.offline")
        static let offlineMessage = LocalizedStringKey("error.offline.message")

        static let retry = LocalizedStringKey("error.retry")
        static let dismiss = LocalizedStringKey("error.dismiss")
        static let settings = LocalizedStringKey("error.settings")
    }

    // MARK: - Zodiac Signs

    /// Localized zodiac sign names.
    enum Zodiac {
        static let aries = LocalizedStringKey("zodiac.aries")
        static let taurus = LocalizedStringKey("zodiac.taurus")
        static let gemini = LocalizedStringKey("zodiac.gemini")
        static let cancer = LocalizedStringKey("zodiac.cancer")
        static let leo = LocalizedStringKey("zodiac.leo")
        static let virgo = LocalizedStringKey("zodiac.virgo")
        static let libra = LocalizedStringKey("zodiac.libra")
        static let scorpio = LocalizedStringKey("zodiac.scorpio")
        static let sagittarius = LocalizedStringKey("zodiac.sagittarius")
        static let capricorn = LocalizedStringKey("zodiac.capricorn")
        static let aquarius = LocalizedStringKey("zodiac.aquarius")
        static let pisces = LocalizedStringKey("zodiac.pisces")
    }

    // MARK: - Elements

    /// Localized element names.
    enum Element {
        static let fire = LocalizedStringKey("element.fire")
        static let earth = LocalizedStringKey("element.earth")
        static let air = LocalizedStringKey("element.air")
        static let water = LocalizedStringKey("element.water")
    }

    // MARK: - Compatibility

    /// Localized compatibility level strings.
    enum Compatibility {
        static let excellent = LocalizedStringKey("compatibility.excellent")
        static let excellentDescription = LocalizedStringKey("compatibility.excellent.description")
        static let good = LocalizedStringKey("compatibility.good")
        static let goodDescription = LocalizedStringKey("compatibility.good.description")
        static let moderate = LocalizedStringKey("compatibility.moderate")
        static let moderateDescription = LocalizedStringKey("compatibility.moderate.description")
        static let challenging = LocalizedStringKey("compatibility.challenging")
        static let challengingDescription = LocalizedStringKey("compatibility.challenging.description")
        static let difficult = LocalizedStringKey("compatibility.difficult")
        static let difficultDescription = LocalizedStringKey("compatibility.difficult.description")
    }

    // MARK: - Common Actions

    /// Localized strings for common UI actions.
    enum Common {
        static let ok = LocalizedStringKey("common.ok")
        static let cancel = LocalizedStringKey("common.cancel")
        static let done = LocalizedStringKey("common.done")
        static let save = LocalizedStringKey("common.save")
        static let delete = LocalizedStringKey("common.delete")
        static let edit = LocalizedStringKey("common.edit")
        static let add = LocalizedStringKey("common.add")
        static let remove = LocalizedStringKey("common.remove")
        static let close = LocalizedStringKey("common.close")
        static let back = LocalizedStringKey("common.back")
        static let next = LocalizedStringKey("common.next")
        static let confirm = LocalizedStringKey("common.confirm")
        static let continue_ = LocalizedStringKey("common.continue")
        static let skip = LocalizedStringKey("common.skip")
        static let retry = LocalizedStringKey("common.retry")
        static let refresh = LocalizedStringKey("common.refresh")
        static let loading = LocalizedStringKey("common.loading")
        static let share = LocalizedStringKey("common.share")
        static let copy = LocalizedStringKey("common.copy")
        static let search = LocalizedStringKey("common.search")
        static let filter = LocalizedStringKey("common.filter")
        static let sort = LocalizedStringKey("common.sort")
        static let settings = LocalizedStringKey("common.settings")
        static let help = LocalizedStringKey("common.help")
        static let more = LocalizedStringKey("common.more")
        static let less = LocalizedStringKey("common.less")
        static let showAll = LocalizedStringKey("common.show.all")
        static let hide = LocalizedStringKey("common.hide")
        static let select = LocalizedStringKey("common.select")
        static let selected = LocalizedStringKey("common.selected")
        static let none = LocalizedStringKey("common.none")
        static let all = LocalizedStringKey("common.all")
        static let yes = LocalizedStringKey("common.yes")
        static let no = LocalizedStringKey("common.no")
    }

    // MARK: - Accessibility

    /// Localized accessibility labels.
    enum Accessibility {
        static let closeButton = LocalizedStringKey("accessibility.close.button")
        static let backButton = LocalizedStringKey("accessibility.back.button")
        static let menuButton = LocalizedStringKey("accessibility.menu.button")
        static let searchButton = LocalizedStringKey("accessibility.search.button")
        static let filterButton = LocalizedStringKey("accessibility.filter.button")
        static let refreshButton = LocalizedStringKey("accessibility.refresh.button")
        static let shareButton = LocalizedStringKey("accessibility.share.button")
        static let likeButton = LocalizedStringKey("accessibility.like.button")
        static let skipButton = LocalizedStringKey("accessibility.skip.button")
        static let addButton = LocalizedStringKey("accessibility.add.button")
    }

    // MARK: - Widgets

    /// Localized strings for home screen widgets.
    enum Widget {
        static let portfolioTitle = LocalizedStringKey("widget.portfolio.title")
        static let portfolioDescription = LocalizedStringKey("widget.portfolio.description")
        static let horoscopeTitle = LocalizedStringKey("widget.horoscope.title")
        static let horoscopeDescription = LocalizedStringKey("widget.horoscope.description")
        static let moonTitle = LocalizedStringKey("widget.moon.title")
        static let moonDescription = LocalizedStringKey("widget.moon.description")
        static let compatibilityTitle = LocalizedStringKey("widget.compatibility.title")
        static let compatibilityDescription = LocalizedStringKey("widget.compatibility.description")
    }

    // MARK: - IPO

    /// Localized strings for IPO calendar.
    enum IPO {
        static let title = LocalizedStringKey("ipo.title")
        static let upcoming = LocalizedStringKey("ipo.upcoming")
        static let thisWeek = LocalizedStringKey("ipo.thisWeek")
        static let nextWeek = LocalizedStringKey("ipo.nextWeek")
        static let priced = LocalizedStringKey("ipo.priced")

        static let date = LocalizedStringKey("ipo.date")
        static let priceRange = LocalizedStringKey("ipo.price.range")
        static let shares = LocalizedStringKey("ipo.shares")
        static let exchange = LocalizedStringKey("ipo.exchange")
        static let underwriters = LocalizedStringKey("ipo.underwriters")
    }

    // MARK: - Referral

    /// Localized strings for referral system.
    enum Referral {
        static let title = LocalizedStringKey("referral.title")
        static let code = LocalizedStringKey("referral.code")
        static let codeCopy = LocalizedStringKey("referral.code.copy")
        static let codeShare = LocalizedStringKey("referral.code.share")
        static let enter = LocalizedStringKey("referral.enter")
        static let enterPlaceholder = LocalizedStringKey("referral.enter.placeholder")
        static let apply = LocalizedStringKey("referral.apply")
        static let reward = LocalizedStringKey("referral.reward")
        static let success = LocalizedStringKey("referral.success")
        static let invalid = LocalizedStringKey("referral.invalid")
    }
}
