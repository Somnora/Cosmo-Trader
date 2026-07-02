import SwiftUI

// MARK: - Launch Content Generator
// =================================
// Ready-to-copy marketing content for social media launch.
// Access via LaunchContentView in Xcode previews or build a debug menu.

struct LaunchContentGenerator {

    // MARK: - App Store Link (Update when live)
    static let appStoreLink = "https://somnora.app/cosmo-trader"
    static let placeholderLink = "https://somnora.app/cosmo-trader"

    // MARK: - Twitter/X Launch Thread

    static let twitterThread: [String] = [
        // Tweet 1: Hook
        """
        What if your stock portfolio had a birth chart?

        What if Apple being an Aries explained why it's so aggressive?

        I built an app that's either genius or unhinged. Probably both.

        🧵 Thread:
        """,

        // Tweet 2: What it is
        """
        Introducing Cosmo Trader ✨

        It's a portfolio tracker that assigns zodiac signs to stocks based on their founding date.

        Tesla? Cancer. ♋
        Google? Virgo. ♍
        Microsoft? Aries. ♈

        Then it tells you if they're cosmically compatible with YOU.
        """,

        // Tweet 3: Key Features 1
        """
        Key features:

        📱 Swipe-to-discover stocks (like Tinder, but for investing)
        🌙 Moon phase "market sentiment" tracker
        ♈ Zodiac compatibility scores
        📊 Actual portfolio tracking with real data

        It's Bloomberg Terminal meets Co-Star.
        """,

        // Tweet 4: Key Features 2
        """
        The feature everyone's talking about: THE COSMIC ROAST 🔥

        Get absolutely destroyed based on your zodiac sign and trading behavior.

        "You're a Sagittarius who bought crypto at the top. The universe isn't surprised."

        Share your roast. Watch your friends question their life choices.
        """,

        // Tweet 5: The Joke/Tone
        """
        Does astrology actually predict stock performance?

        Absolutely not. Zero scientific evidence.

        But does it make checking your portfolio more fun?

        Yes. Significantly yes.

        (Not financial advice. The stars aren't financial advisors either.)
        """,

        // Tweet 6: CTA
        """
        Cosmo Trader is live on the App Store 🚀

        Free to download. Premium tier if you want unlimited cosmic roasts.

        Whether you're a Capricorn who loves index funds or a Gemini who can't pick a strategy—there's something for you.

        \(placeholderLink)

        The stars are aligning. (They always are. That's what stars do.)
        """
    ]

    // MARK: - Instagram

    static let instagramShort = """
    Your portfolio has a birth chart now. ✨

    Cosmo Trader assigns zodiac signs to stocks based on when they were founded—then tells you if they vibe with your energy.

    Is it financial advice? Absolutely not.
    Is it fun? Absolutely yes.

    Link in bio 🔗
    """

    static let instagramLong = """
    POV: You just found out your investment portfolio is cosmically incompatible with you 💀

    I built Cosmo Trader because I wanted to know what zodiac sign Tesla is. (It's Cancer, btw. Founded July 1, 2003.)

    The app lets you:
    ✨ Track your portfolio with zodiac compatibility scores
    ✨ Swipe through stocks like a dating app
    ✨ Get roasted by the universe based on your sign
    ✨ Check moon phases for "market vibes"

    Is any of this scientifically valid? No.
    Did I build it anyway? Obviously.

    It's giving ✨financial entertainment✨

    Not financial advice. Just financial chaos with a cosmic twist.

    Link in bio to download 🔗
    """

    static let instagramHashtags = """
    #astrology #zodiac #stockmarket #investing #astrologytok #zodiacsigns #aries #taurus #gemini #cancer #leo #virgo #libra #scorpio #sagittarius #capricorn #aquarius #pisces #horoscope #birthchart #portfolio #fintech #appstore #newapp #indiedev #cosmotrader #financialliteracy #stocks #trading #moonphase
    """

    // MARK: - Reddit Posts

    static let redditAstrology = """
    **Title:** I built an app that gives stocks zodiac signs based on their founding date

    **Body:**

    Hey r/astrology!

    I'm a developer who's also into astrology, and I had a weird shower thought: companies have birthdays too. What if we calculated their zodiac signs?

    So I built Cosmo Trader.

    Every publicly traded company gets a zodiac sign based on when it was founded:
    - Apple (April 1, 1976) = Aries ♈
    - Google (September 4, 1998) = Virgo ♍
    - Tesla (July 1, 2003) = Cancer ♋
    - Meta (February 4, 2004) = Aquarius ♒

    The app calculates compatibility between YOUR sign and the stocks in your portfolio. You can see which holdings align with your cosmic energy and which ones... don't.

    Other features:
    - Moon phase tracker (does the moon affect markets? no. but it looks cool)
    - Daily horoscopes that reference your actual holdings
    - "Cosmic Roast" - get roasted based on your sign and trading behavior
    - IPO calendar with "birth chart predictions" for new companies

    **Important disclaimer:** This is 100% for entertainment. I'm not claiming astrology predicts markets. It's just a fun lens to view your portfolio through.

    Would love to hear what you think! Especially curious - does your portfolio vibe with your sign?

    \(appStoreLink)
    """

    static let redditStocks = """
    **Title:** I built a portfolio tracker with a weird twist - it assigns zodiac signs to stocks

    **Body:**

    Hey r/stocks,

    Before you roast me - yes, I know astrology doesn't predict markets. Hear me out.

    I built a portfolio tracker called Cosmo Trader. It does everything you'd expect:
    - Track holdings and performance
    - Real-time(ish) price data via Finnhub API
    - Daily P&L, sparklines, the works

    But here's the twist: every stock gets assigned a zodiac sign based on the company's founding date.

    Why? Because it's fun, and because my girlfriend asked "what sign is Tesla?" and I realized I had to find out. (It's Cancer. Founded July 1, 2003.)

    The app shows "compatibility" between your sign and your holdings. It's completely meaningless from an investment perspective, but it adds a layer of entertainment to the daily portfolio check.

    There's also a "Cosmic Roast" feature that roasts you based on your zodiac and trading behavior. My Sagittarius friend who bought GME at $400 did not appreciate his roast.

    **Disclaimers everywhere:** The app is crystal clear this is entertainment, not advice. Multiple NFA disclaimers. I'm not trying to get anyone to trade based on horoscopes.

    Curious what this sub thinks. Is there room for "fun" in finance apps, or should portfolio trackers stay serious?

    \(appStoreLink)
    """

    static let redditSideProject = """
    **Title:** I launched my side project: A portfolio tracker that assigns zodiac signs to stocks

    **Body:**

    Hey r/SideProject!

    After 3 months of nights and weekends, I finally shipped Cosmo Trader.

    **The idea:** What if stocks had zodiac signs based on when the company was founded? What if you could see your portfolio's "cosmic compatibility"?

    **Tech stack:**
    - SwiftUI (iOS native)
    - Finnhub API for market data
    - Local storage (no backend needed)
    - StoreKit 2 for subscriptions

    **Features:**
    - Portfolio tracking with zodiac badges
    - Swipe-to-discover stocks (Tinder-style UI)
    - Compatibility scores (your sign vs stock's sign)
    - "Cosmic Roast" - shareable roasts based on your sign/trading
    - Moon phase tracker
    - IPO calendar with "birth charts"

    **Monetization:**
    - Free tier with daily limits
    - "Oracle Tier" subscription ($4.99/mo) for unlimited access

    **Lessons learned:**
    1. Scope creep is real - the roast feature alone took 2 weeks
    2. SwiftUI animations are *chef's kiss* but debugging them is pain
    3. Legal disclaimers for finance-adjacent apps are intense
    4. The App Store review process is... an experience

    **What went well:**
    - The "cosmic roast" feature is getting shared a lot in beta
    - The dark OLED theme looks premium
    - People actually use it daily (even if just for entertainment)

    **What I'd do differently:**
    - Start with fewer features, add more polish
    - Build the sharing/viral features earlier
    - Actually plan the data model before coding (lol)

    Would love feedback! And if you try it, let me know your sign and most compatible stock 😄

    \(appStoreLink)
    """

    // MARK: - Product Hunt

    static let productHuntTagline = "Your stock portfolio's birth chart 🌟" // 38 chars

    static let productHuntShort = """
    Cosmo Trader assigns zodiac signs to stocks based on founding dates, then shows your cosmic compatibility. Track your portfolio, swipe to discover new stocks, get roasted by the universe, and check moon phases. It's Bloomberg Terminal meets Co-Star. For entertainment—not financial advice.
    """ // 289 chars - trim if needed

    static let productHuntFull = """
    **What is Cosmo Trader?**

    A portfolio tracker that assigns zodiac signs to every stock based on the company's founding date. Apple is an Aries (April 1, 1976). Tesla is a Cancer (July 1, 2003). Google is a Virgo (September 4, 1998).

    Then it tells you how cosmically compatible each stock is with YOUR zodiac sign.

    **Key Features:**

    🔮 **Zodiac Compatibility** - See which stocks align with your cosmic energy

    👆 **Swipe to Discover** - Tinder-style stock discovery. Swipe right to add to watchlist.

    🔥 **Cosmic Roast** - Get absolutely roasted based on your sign and trading behavior. Share the pain.

    🌙 **Moon Phases** - Track lunar cycles and their (totally unscientific) effect on market vibes

    📈 **Real Portfolio Tracking** - Actual market data, real P&L, proper charts

    🚀 **IPO Calendar** - Upcoming IPOs with "birth chart" predictions

    **Is this financial advice?**

    Absolutely not. Zero percent. The app has more disclaimers than a pharmaceutical commercial. Astrology doesn't predict markets. We know this. You know this.

    But it DOES make checking your portfolio more entertaining.

    **Who's it for?**

    - People who check their horoscope AND their stocks
    - Anyone who wants their portfolio tracker to have personality
    - Your friend who blames Mercury retrograde for red days
    - Indie hackers who appreciate weird niche apps

    **Pricing:**

    Free tier with daily limits. Oracle Tier ($4.99/mo) for unlimited cosmic chaos.

    Built with SwiftUI. Data from Finnhub. Cosmic wisdom from the universe.

    The stars are aligning. (They're always aligning. That's literally what stars do.)
    """

    // MARK: - Press Pitch

    static let pressPitchTech = """
    **PRESS PITCH - Tech/App Blogs**

    Cosmo Trader is a new iOS app that combines portfolio tracking with astrology—assigning zodiac signs to stocks based on company founding dates. Users can see their "cosmic compatibility" with holdings, swipe through stocks Tinder-style, and get shareable "Cosmic Roasts" based on their sign and trading behavior. Built by an indie developer as a side project, the app sits in the unexpected intersection of fintech and mysticism, explicitly positioning itself as entertainment rather than financial advice. With astrology apps like Co-Star seeing massive Gen Z adoption, and retail trading at all-time highs, Cosmo Trader bets there's an audience that wants both—with a heavy dose of self-awareness. Available now on the App Store.
    """

    static let pressPitchFinance = """
    **PRESS PITCH - Finance/Investing**

    What if your portfolio had a birth chart? Cosmo Trader is a new portfolio tracking app with a twist: it calculates zodiac signs for every stock based on company founding dates (Apple is Aries, Tesla is Cancer, Google is Virgo) and shows users their "cosmic compatibility." The app includes standard portfolio features—real-time data via Finnhub, P&L tracking, watchlists—alongside astrology-themed additions like moon phase tracking and shareable "Cosmic Roasts." Heavily disclaimered as entertainment rather than financial advice, the app targets the growing overlap between retail investors and astrology enthusiasts. It's either a clever niche play or a sign of how weird fintech has gotten. Possibly both.
    """

    static let pressPitchAstrology = """
    **PRESS PITCH - Astrology/Lifestyle**

    Your Co-Star notifications now have competition—from Wall Street. Cosmo Trader is a new app that brings astrology to investing, calculating zodiac signs for publicly traded companies based on their founding dates. Tesla, founded July 1, 2003? Cancer. Apple, founded April 1, 1976? Aries. Users can track their portfolios while seeing cosmic compatibility scores, get daily horoscopes that reference their actual holdings, and share brutally honest "Cosmic Roasts" based on their sign and trading behavior. The app tracks moon phases (for "market vibes"), offers IPO predictions based on upcoming companies' birth charts, and maintains a dark, premium aesthetic that feels like a Bloomberg terminal designed by an astrologer. It's explicitly entertainment—packed with disclaimers—but for anyone who's ever blamed Mercury retrograde for a red portfolio day, it's also kind of perfect.
    """
}

// MARK: - Launch Content View

struct LaunchContentView: View {

    @State private var selectedTab = 0
    @State private var copiedText: String?

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                twitterTab
                    .tabItem { Label("Twitter", systemImage: "bird") }
                    .tag(0)

                instagramTab
                    .tabItem { Label("Instagram", systemImage: "camera") }
                    .tag(1)

                redditTab
                    .tabItem { Label("Reddit", systemImage: "bubble.left.and.bubble.right") }
                    .tag(2)

                productHuntTab
                    .tabItem { Label("Product Hunt", systemImage: "cat") }
                    .tag(3)

                pressTab
                    .tabItem { Label("Press", systemImage: "newspaper") }
                    .tag(4)
            }
            .navigationTitle("Launch Content")
            .overlay(alignment: .top) {
                if copiedText != nil {
                    copiedBanner
                }
            }
        }
    }

    // MARK: - Twitter Tab

    private var twitterTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Array(LaunchContentGenerator.twitterThread.enumerated()), id: \.offset) { index, tweet in
                    ContentCard(
                        title: "Tweet \(index + 1)\(index == 0 ? " (Hook)" : index == 5 ? " (CTA)" : "")",
                        content: tweet,
                        charCount: tweet.count,
                        charLimit: 280,
                        onCopy: { copyToClipboard(tweet) }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Instagram Tab

    private var instagramTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ContentCard(
                    title: "Short Caption (Carousel)",
                    content: LaunchContentGenerator.instagramShort,
                    charCount: LaunchContentGenerator.instagramShort.count,
                    onCopy: { copyToClipboard(LaunchContentGenerator.instagramShort) }
                )

                ContentCard(
                    title: "Long Caption (Reels)",
                    content: LaunchContentGenerator.instagramLong,
                    charCount: LaunchContentGenerator.instagramLong.count,
                    onCopy: { copyToClipboard(LaunchContentGenerator.instagramLong) }
                )

                ContentCard(
                    title: "Hashtags (30)",
                    content: LaunchContentGenerator.instagramHashtags,
                    charCount: LaunchContentGenerator.instagramHashtags.count,
                    onCopy: { copyToClipboard(LaunchContentGenerator.instagramHashtags) }
                )
            }
            .padding()
        }
    }

    // MARK: - Reddit Tab

    private var redditTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ContentCard(
                    title: "r/astrology",
                    content: LaunchContentGenerator.redditAstrology,
                    onCopy: { copyToClipboard(LaunchContentGenerator.redditAstrology) }
                )

                ContentCard(
                    title: "r/stocks",
                    content: LaunchContentGenerator.redditStocks,
                    onCopy: { copyToClipboard(LaunchContentGenerator.redditStocks) }
                )

                ContentCard(
                    title: "r/SideProject",
                    content: LaunchContentGenerator.redditSideProject,
                    onCopy: { copyToClipboard(LaunchContentGenerator.redditSideProject) }
                )
            }
            .padding()
        }
    }

    // MARK: - Product Hunt Tab

    private var productHuntTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ContentCard(
                    title: "Tagline (60 chars max)",
                    content: LaunchContentGenerator.productHuntTagline,
                    charCount: LaunchContentGenerator.productHuntTagline.count,
                    charLimit: 60,
                    onCopy: { copyToClipboard(LaunchContentGenerator.productHuntTagline) }
                )

                ContentCard(
                    title: "Short Description (260 chars)",
                    content: LaunchContentGenerator.productHuntShort,
                    charCount: LaunchContentGenerator.productHuntShort.count,
                    charLimit: 260,
                    onCopy: { copyToClipboard(LaunchContentGenerator.productHuntShort) }
                )

                ContentCard(
                    title: "Full Description",
                    content: LaunchContentGenerator.productHuntFull,
                    onCopy: { copyToClipboard(LaunchContentGenerator.productHuntFull) }
                )
            }
            .padding()
        }
    }

    // MARK: - Press Tab

    private var pressTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ContentCard(
                    title: "Tech/App Blogs",
                    content: LaunchContentGenerator.pressPitchTech,
                    onCopy: { copyToClipboard(LaunchContentGenerator.pressPitchTech) }
                )

                ContentCard(
                    title: "Finance/Investing",
                    content: LaunchContentGenerator.pressPitchFinance,
                    onCopy: { copyToClipboard(LaunchContentGenerator.pressPitchFinance) }
                )

                ContentCard(
                    title: "Astrology/Lifestyle",
                    content: LaunchContentGenerator.pressPitchAstrology,
                    onCopy: { copyToClipboard(LaunchContentGenerator.pressPitchAstrology) }
                )
            }
            .padding()
        }
    }

    // MARK: - Copied Banner

    private var copiedBanner: some View {
        Text("Copied!")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.green))
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(), value: copiedText)
    }

    // MARK: - Helpers

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        withAnimation {
            copiedText = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                copiedText = nil
            }
        }
    }
}

// MARK: - Content Card

struct ContentCard: View {
    let title: String
    let content: String
    var charCount: Int?
    var charLimit: Int?
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                if let count = charCount {
                    HStack(spacing: 4) {
                        Text("\(count)")
                            .foregroundColor(isOverLimit ? .red : .secondary)
                        if let limit = charLimit {
                            Text("/ \(limit)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                }

                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
            }

            // Content
            Text(content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    private var isOverLimit: Bool {
        guard let count = charCount, let limit = charLimit else { return false }
        return count > limit
    }
}

// MARK: - Previews

#Preview("Launch Content") {
    LaunchContentView()
}

#Preview("Twitter Thread") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(LaunchContentGenerator.twitterThread.enumerated()), id: \.offset) { index, tweet in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tweet \(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(tweet)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    Text("\(tweet.count)/280")
                        .font(.caption2)
                        .foregroundColor(tweet.count > 280 ? .red : .secondary)
                }
            }
        }
        .padding()
    }
}
