import Foundation
import Testing
@testable import Cosmo_Trader

struct ComplianceCopyGuardTests {

    @Test("Cosmic event guidance and warnings are compliance safe")
    func cosmicEventMessagesAreComplianceSafe() {
        let messages = MockCosmicEvents.all.flatMap { event in
            [event.description, event.advice, event.warningMessage ?? ""]
        }

        let violations = messages.flatMap(ComplianceCopyScanner.violations)
        if !violations.isEmpty {
            Issue.record("CosmicEvent copy violations: \(violations.map { $0.label }.joined(separator: ", "))")
        }
        #expect(violations.isEmpty)
    }

    @Test("Cosmic pattern generated notes are compliance safe")
    @MainActor
    func cosmicPatternGeneratedNotesAreComplianceSafe() {
        let pattern = DetectedPattern(
            pattern: .goldenCross,
            confidence: 82,
            detectedAt: Date(timeIntervalSince1970: 1_700_000_000),
            priceAtDetection: 100,
            details: "Provider-backed candle context only."
        )
        let insight = CosmicPatternInterpreter.shared.interpret(
            pattern: pattern,
            userSign: .aries,
            stockSign: .taurus
        )
        let messages = [
            insight.headline,
            insight.body,
            insight.retrogradeWarning ?? "",
            insight.moonPhaseNote ?? "",
            insight.compatibilityNote ?? "",
            insight.actionAdvice
        ]

        let violations = messages.flatMap(ComplianceCopyScanner.violations)
        if !violations.isEmpty {
            Issue.record("CosmicPatternInterpreter copy violations: \(violations.map { $0.label }.joined(separator: ", "))")
        }
        #expect(violations.isEmpty)
    }

    @Test("Scanner catches known trading-instruction phrases")
    func scannerCatchesKnownBadPhrases() {
        let unsafeExamples = [
            "Consider reducing position sizes",
            "Avoid starting new high-risk positions",
            "using smaller position sizes",
            "potential contrarian buy/sell signal",
            "take profits",
            "reduce exposure"
        ]

        for example in unsafeExamples {
            #expect(!ComplianceCopyScanner.violations(in: example).isEmpty, "Scanner missed: \(example)")
        }
    }

    @Test("Scanner allows explicit non-advice disclaimers")
    func scannerAllowsExplicitNonAdviceDisclaimers() {
        let safeExamples = [
            "Use this as a market-mood snapshot, not a buy or sell signal.",
            "This is not a buy or sell recommendation.",
            "Historical context only. Correlation does not imply causation and this is not financial advice.",
            "Treat this as context, not a trade signal.",
            "Entertainment lens, not a prediction."
        ]

        for example in safeExamples {
            #expect(ComplianceCopyScanner.violations(in: example).isEmpty, "Scanner rejected safe disclaimer: \(example)")
        }
    }

    @Test("Chart and astro overlay copy snippets stay compliance safe")
    func chartAndAstroOverlayCopySnippetsAreComplianceSafe() {
        let safeExamples = [
            "Loading provider chart data",
            "Historical price data unavailable",
            "Chart will appear when provider data is available.",
            "Refresh provider history before viewing chart context.",
            "Chart context will appear when enough provider-backed candles are available.",
            "Chart context will appear when the provider returns a complete range.",
            "Provider-backed history is required before event-window metrics are shown.",
            "Mixed data freshness. Metric unavailable for this event.",
            "Historical overlay only. Correlation view, not financial advice.",
            "Overlay moon phases, Mercury retrograde, and company birth cycles against historical price action. Explore historical context, including when no pattern appears.",
            "Sample chart mode is labeled for preview only; event-window metrics are hidden.",
            "Historical price view",
            "Provider-backed candles",
            "Line chart with selected astrological overlays",
            "Candle chart with selected astrological overlays",
            "Chart context only. Not a prediction.",
            "Technical lens uses provider-backed historical candles only. Read this as historical context, not financial advice.",
            "Provider-backed complete candles are required before this technical context can show metrics.",
            "Cached candles are stale under the current policy. Refresh provider history to recheck.",
            "Technical lens: above 50D average, RSI balanced.",
            "Load provider-backed history to unlock chart, technical, and cosmic context when enough data is available.",
            "Provider-backed historical prices unavailable. Try again later.",
            "Historical context only. Not financial advice.",
            "Numeric claims remain gated",
            "Needs complete fresh history",
            "Historical astro-technical context only. Not predictive and not financial advice.",
            "Combined context: Full Moon average window +1.2% vs baseline +0.4%.",
            "Technical and cosmic context are mixed. Review as historical context only.",
            "Combined numeric context stays hidden until the cosmic sample and provenance gates pass.",
            "Upcoming cosmic events show calendar context only.",
            "Company-specific events unavailable until verified founding metadata exists.",
            "Calendar context only. Historical and entertainment lens, not predictive and not financial advice.",
            "No market or return claims are shown here.",
            "Portfolio correlation needs usable market value, provider-backed history, 70% usable coverage, and enough event samples before numeric metrics appear.",
            "Cached provider-backed history is stale under the current freshness policy.",
            "Provider returned some history, but the required range is incomplete.",
            "Provider returned too little history for correlation context.",
            "70% usable coverage is met. Portfolio correlation still depends on provider freshness and minimum event sample size.",
            "Refresh history",
            "Daily Market Horoscope",
            "Historical context, source-labeled",
            "Historical context only. No forecast. Not financial advice.",
            "Market Weather unavailable",
            "Portfolio setup needed",
            "Watchlist setup needed",
            "Demo context only, not market data."
        ]

        for example in safeExamples {
            let violations = ComplianceCopyScanner.violations(in: example)
            if !violations.isEmpty {
                Issue.record("Chart copy violation for '\(example)': \(violations.map { $0.label }.joined(separator: ", "))")
            }
            #expect(violations.isEmpty)
        }
    }

    @Test("Cosmic scorecard copy snippets stay compliance safe")
    func cosmicScorecardCopySnippetsAreComplianceSafe() {
        // Every user-facing string on the prediction-ledger surfaces
        // (TodayPredictionCard, CosmicScorecardView) plus the dynamic
        // templates they render. Scored-entertainment framing only: the
        // cosmos "leans", calls are "scored", and nothing instructs.
        let safeExamples = [
            "COSMIC SCORECARD",
            "TODAY'S COSMIC CALL",
            "COSMOS VS. THE CLOSE",
            "LEANS BULLISH",
            "LEANS BEARISH",
            "READS NEUTRAL",
            "HIT",
            "MISS",
            "PUSH",
            "UNSCORED",
            "MKT CLOSED",
            "MARKET (SPY)",
            "PORTFOLIO",
            "COSMOS 7/12",
            "COIN FLIP BASELINE: 50%",
            "SCORED",
            "HITS",
            "PUSHES",
            "STREAK",
            "BY COSMIC DRIVER",
            "CALL HISTORY",
            "FULL SCORECARD",
            "LAST SCORED CLOSE · JUL 6",
            "AFTER CLOSE — NOT SCORED",
            "PENDING",
            "The cosmos abstained today. No market-backed cosmic pattern was active at reading time.",
            "Abstained — no market-backed cosmic pattern was active.",
            "Your first cosmic call records with today's reading. Scores land after the market close.",
            "Recorded after the close — kept for the record, never scored.",
            "No calls recorded yet. The ledger starts with your next Today reading.",
            "Early days — 8 scored calls is too small a sample to mean anything. That is the first lesson of the scorecard.",
            "Full Moon · 62% of past windows up · edge +0.40%",
            "Scored record of past cosmic calls against index closes. Entertainment context only — not predictive and not financial advice.",
            "Scored record of past cosmic calls against index closes. Correlation does not imply causation. Entertainment context only — not predictive and not financial advice."
        ]

        for example in safeExamples {
            let violations = ComplianceCopyScanner.violations(in: example)
            if !violations.isEmpty {
                Issue.record("Scorecard copy violation for '\(example)': \(violations.map { $0.label }.joined(separator: ", "))")
            }
            #expect(violations.isEmpty)
        }
    }

    @Test("Shares editor copy snippets stay compliance safe")
    func sharesEditorCopySnippetsAreComplianceSafe() {
        // Every user-facing string on the manual holdings editor
        // (HoldingSharesEditorView) and the row affordances that open it.
        // Bookkeeping language only: shares, cost basis, remove — nothing
        // that reads as trading instruction.
        let safeExamples = [
            "Edit Shares",
            "Add Holding",
            "SHARES OWNED",
            "COST BASIS / SHARE (OPTIONAL)",
            "10 or 2.5",
            "What you paid per share",
            "Enter a share count above zero.",
            "Enter a dollar amount, or leave this empty.",
            "Fractional shares are fine. Cosmo weights your readings by what you own. If you skip cost basis, P/L shows as unavailable instead of guessing.",
            "Remove from Portfolio",
            "Remove AAPL from your portfolio?",
            "Readings weighted by your holdings stop counting AAPL. You can add it back anytime.",
            "Save",
            "Add",
            "Cancel",
            "Add to Portfolio",
            "12.5 Shares — Edit",
            "AAPL updated: 12.5 shares",
            "AAPL added to your portfolio!",
            "AAPL removed from portfolio",
            "Long-press a holding to edit shares",
            "Long-press a row to remove from watchlist",
            "Remove from Watchlist"
        ]

        for example in safeExamples {
            let violations = ComplianceCopyScanner.violations(in: example)
            if !violations.isEmpty {
                Issue.record("Shares editor copy violation for '\(example)': \(violations.map { $0.label }.joined(separator: ", "))")
            }
            #expect(violations.isEmpty)
        }
    }
}

private enum ComplianceCopyScanner {
    struct Violation {
        let label: String
    }

    struct Rule {
        let label: String
        let pattern: String
    }

    private static let rules = [
        Rule(label: "buy", pattern: #"\bbuy\b"#),
        Rule(label: "sell", pattern: #"\bsell\b"#),
        Rule(label: "hold", pattern: #"\bhold\b"#),
        Rule(label: "avoid", pattern: #"\bavoid\b"#),
        Rule(label: "buy signal", pattern: #"\bbuy\s+signal\b"#),
        Rule(label: "sell signal", pattern: #"\bsell\s+signal\b"#),
        Rule(label: "buying opportunity", pattern: #"\bbuying\s+opportunit(?:y|ies)\b"#),
        Rule(label: "hold current positions", pattern: #"\bhold\s+current\s+positions\b"#),
        Rule(label: "take profits", pattern: #"\btake\s+profits?\b"#),
        Rule(label: "reduce exposure", pattern: #"\breduce\s+exposure\b"#),
        Rule(label: "reduce position", pattern: #"\breduce\s+positions?\b"#),
        Rule(label: "position size", pattern: #"\bposition\s+sizes?\b"#),
        Rule(label: "position sizing", pattern: #"\bposition\s+sizing\b"#),
        Rule(label: "smaller position", pattern: #"\bsmaller\s+positions?\b"#),
        Rule(label: "delay major decisions", pattern: #"\bdelay\s+major\s+decisions\b"#),
        Rule(label: "high-risk positions", pattern: #"\bhigh-risk\s+positions\b"#),
        Rule(label: "guaranteed", pattern: #"\bguaranteed\b"#),
        Rule(label: "prediction", pattern: #"\bprediction\b"#),
        Rule(label: "predicts returns", pattern: #"\bpredicts\s+returns\b"#),
        Rule(label: "expected upside", pattern: #"\bexpected\s+upside\b"#),
        Rule(label: "expected downside", pattern: #"\bexpected\s+downside\b"#),
        Rule(label: "trade signal", pattern: #"\btrade\s+signal\b"#),
        Rule(label: "trading signal", pattern: #"\btrading\s+signal\b"#)
    ]

    static func violations(in copy: String) -> [Violation] {
        let normalized = copy.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return rules.compactMap { rule in
            guard normalized.range(of: rule.pattern, options: [.regularExpression, .caseInsensitive]) != nil else {
                return nil
            }
            return isAllowedSafeDisclaimer(normalized, for: rule) ? nil : Violation(label: rule.label)
        }
    }

    private static func isAllowedSafeDisclaimer(_ copy: String, for rule: Rule) -> Bool {
        let lowercased = copy.lowercased()

        // Keep exemptions narrow: only explicit non-advice disclaimers can mention otherwise banned terms.
        switch rule.label {
        case "buy", "sell", "buy signal", "sell signal":
            return lowercased.contains("not a buy or sell signal")
                || lowercased.contains("not a buy or sell recommendation")
                || lowercased.contains("not a recommendation to buy or sell")
        case "trade signal", "trading signal":
            return lowercased.contains("not a trade signal")
                || lowercased.contains("not a trading signal")
        case "prediction":
            return lowercased.contains("not a prediction")
                || lowercased.contains("not predictive")
        case "guaranteed":
            return lowercased.contains("not guaranteed")
        default:
            return false
        }
    }
}
