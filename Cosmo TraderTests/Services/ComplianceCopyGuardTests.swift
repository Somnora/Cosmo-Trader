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
