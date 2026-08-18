import Foundation
import Testing
@testable import Cosmo_Trader

/// Unit tests for `SignalFramingService`.
///
/// These tests exist because `frameHeadline` and `frameCosmicInsight` used to
/// end their `.balanced` branch with `Bool.random() ? rational : mystical`.
/// `.balanced` was the shipped default, so every default-settings user got copy
/// that changed identity between renders of the same market state, including on
/// Stock Detail and Portfolio where it sits beside real prices.
///
/// The contract these tests enforce:
///
/// 1. Every framing entry point is a pure function of its inputs: identical
///    inputs must produce identical output on every call.
/// 2. `.balanced` resolves to the rational variant, not the mystical one. The
///    installed base has `.balanced` persisted, so this branch is how existing
///    users receive the honesty fix.
/// 3. The shipped default for a new profile is `.leanRational`.
/// 4. `SignalFramingLevel` raw values are stable, because they are
///    Codable-persisted in `UserProfile` on real devices.
@MainActor
struct SignalFramingServiceTests {

    private let service = SignalFramingService.shared

    /// Distinguishable sentinels so a test can tell which side a branch picked.
    private let rationalSample = "RATIONAL_VARIANT"
    private let mysticalSample = "MYSTICAL_VARIANT"

    /// How many extra times each entry point is re-rendered before comparing.
    private let repeatCount = 20

    // MARK: - Determinism

    @Test("Balanced headline framing is identical across repeated renders")
    func balancedHeadlineIsStable() {
        let first = service.frameHeadline(
            rational: rationalSample,
            mystical: mysticalSample,
            level: .balanced
        )

        for _ in 0..<repeatCount {
            let next = service.frameHeadline(
                rational: rationalSample,
                mystical: mysticalSample,
                level: .balanced
            )
            #expect(next == first, "Balanced headline framing changed between identical calls")
        }
    }

    @Test("Balanced cosmic insight framing is identical across repeated renders")
    func balancedCosmicInsightIsStable() {
        let first = service.frameCosmicInsight(
            rational: rationalSample,
            mystical: mysticalSample,
            level: .balanced
        )

        for _ in 0..<repeatCount {
            let next = service.frameCosmicInsight(
                rational: rationalSample,
                mystical: mysticalSample,
                level: .balanced
            )
            #expect(next == first, "Balanced cosmic insight framing changed between identical calls")
        }
    }

    @Test("Every framing entry point is identical across repeated renders at every level")
    func everyEntryPointIsStableAtEveryLevel() {
        for level in SignalFramingLevel.allCases {
            let first = allFramedOutputs(at: level)
            #expect(!first.isEmpty, "\(level.displayName) produced no framed output to compare")

            for _ in 0..<repeatCount {
                #expect(
                    allFramedOutputs(at: level) == first,
                    "\(level.displayName) framing changed between identical calls"
                )
            }
        }
    }

    // MARK: - Which variant balanced resolves to

    @Test("Balanced headline framing resolves to the rational variant")
    func balancedHeadlineResolvesRational() {
        let framed = service.frameHeadline(
            rational: rationalSample,
            mystical: mysticalSample,
            level: .balanced
        )

        #expect(framed == rationalSample)
    }

    @Test("Balanced cosmic insight framing resolves to the rational variant")
    func balancedCosmicInsightResolvesRational() {
        let framed = service.frameCosmicInsight(
            rational: rationalSample,
            mystical: mysticalSample,
            level: .balanced
        )

        #expect(framed == rationalSample)
    }

    @Test("Lean rational, the shipped default, resolves to the rational variant")
    func leanRationalResolvesRational() {
        let headline = service.frameHeadline(
            rational: rationalSample,
            mystical: mysticalSample,
            level: .leanRational
        )
        let insight = service.frameCosmicInsight(
            rational: rationalSample,
            mystical: mysticalSample,
            level: .leanRational
        )

        #expect(headline == rationalSample)
        #expect(insight == rationalSample)
    }

    @Test("Mystical framing still resolves to the mystical variant")
    func mysticalResolvesMystical() {
        let headline = service.frameHeadline(
            rational: rationalSample,
            mystical: mysticalSample,
            level: .mystical
        )
        let insight = service.frameCosmicInsight(
            rational: rationalSample,
            mystical: mysticalSample,
            level: .mystical
        )

        #expect(headline == mysticalSample)
        #expect(insight == mysticalSample)
    }

    // MARK: - Shipped default and persisted raw values

    @Test("A new profile defaults to lean rational framing")
    func newProfileDefaultsToLeanRational() {
        let fromBirthDate = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthDate: Date(timeIntervalSince1970: 0)
        )
        let fromComponents = UserProfile(
            displayName: "Test User",
            email: "test@example.com",
            birthMonth: 8,
            birthDay: 15,
            birthYear: 1990
        )

        #expect(fromBirthDate.signalFramingLevel == .leanRational)
        #expect(fromComponents.signalFramingLevel == .leanRational)
    }

    @Test("SignalFramingLevel raw values stay stable for already-persisted profiles")
    func framingLevelRawValuesAreStable() {
        #expect(SignalFramingLevel.rational.rawValue == 0.0)
        #expect(SignalFramingLevel.leanRational.rawValue == 0.25)
        #expect(SignalFramingLevel.balanced.rawValue == 0.5)
        #expect(SignalFramingLevel.leanMystical.rawValue == 0.75)
        #expect(SignalFramingLevel.mystical.rawValue == 1.0)
        #expect(SignalFramingLevel.allCases.count == 5)
    }

    // MARK: - Helpers

    /// Renders every public framing entry point across its whole input space at
    /// `level`, normalized to strings so one comparison covers the surface.
    private func allFramedOutputs(at level: SignalFramingLevel) -> [String] {
        var outputs: [String] = []

        outputs.append(service.frameHeadline(rational: rationalSample, mystical: mysticalSample, level: level))
        outputs.append(service.frameCosmicInsight(rational: rationalSample, mystical: mysticalSample, level: level))

        for energy in CosmicEnergyLevel.allCases {
            outputs.append(service.getHeadlines(for: energy, level: level).joined(separator: "|"))

            for mercury in MercuryStatus.allCases {
                for moon in MoonPhase.allCases {
                    outputs.append(service.frameConditions(energy: energy, mercury: mercury, moon: moon, level: level))
                }
            }
        }

        for action in SuggestedAction.allCases {
            let framed = service.frameSuggestedAction(action: action, level: level)
            outputs.append("\(framed.title)|\(framed.description)")
        }

        for userSign in ZodiacSign.allCases {
            for stockSign in ZodiacSign.allCases {
                for rating in CompatibilityRating.allCases {
                    outputs.append(
                        service.frameCompatibility(
                            userSign: userSign,
                            stockSign: stockSign,
                            rating: rating,
                            level: level
                        )
                    )
                }
            }
        }

        for sign in ZodiacSign.allCases {
            outputs.append(service.frameZodiacPersonality(sign: sign, level: level))
            outputs.append(service.frameCorporatePersonality(sign: sign, level: level))
            outputs.append(service.frameCEOInsight(ceoName: "Ada Lovelace", ceoSign: sign, level: level))
            outputs.append(service.frameIPOBirth(companyName: "Test Corp", sign: sign, level: level))
            outputs.append(service.frameNewsContext(symbol: "AAPL", change: 5.2, stockSign: sign, level: level) ?? "nil")
            outputs.append(service.frameNewsContext(symbol: "AAPL", change: -4.7, stockSign: sign, level: level) ?? "nil")
        }

        outputs.append(service.frameNewsContext(symbol: "AAPL", change: 5.2, stockSign: nil, level: level) ?? "nil")
        outputs.append(service.frameNewsContext(symbol: "AAPL", change: 0.4, stockSign: nil, level: level) ?? "nil")

        for phase in MoonPhase.allCases {
            outputs.append(service.frameMoonPhase(phase: phase, level: level))
        }

        for status in MercuryStatus.allCases {
            outputs.append(service.frameMercuryRetrograde(status: status, level: level))
        }

        for element in ZodiacSign.Element.allCases {
            outputs.append(service.frameElement(element: element, level: level))
            outputs.append(service.framePortfolioBalance(dominantElement: element, isBalanced: true, level: level))
            outputs.append(service.framePortfolioBalance(dominantElement: element, isBalanced: false, level: level))

            for stockElement in ZodiacSign.Element.allCases {
                outputs.append(
                    service.frameElementDynamic(
                        userElement: element,
                        stockElement: stockElement,
                        level: level
                    )
                )
            }
        }

        return outputs
    }
}
