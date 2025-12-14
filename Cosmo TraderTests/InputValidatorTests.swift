//
//  InputValidatorTests.swift
//  Cosmo TraderTests
//
//  Comprehensive tests for InputValidator including name, birth date,
//  share amount, and search query validation.
//

import Testing
import Foundation
@testable import Cosmo_Trader

// MARK: - Name Validation Tests

struct InputValidatorNameTests {

    @Test("Valid name returns nil error")
    func validNameReturnsNil() {
        let result = InputValidator.validateName("John Doe")
        #expect(result == nil)
    }

    @Test("Single character name returns empty error")
    func singleCharacterNameReturnsError() {
        let result = InputValidator.validateName("J")
        #expect(result == .emptyName)
    }

    @Test("Empty name returns empty error")
    func emptyNameReturnsError() {
        let result = InputValidator.validateName("")
        #expect(result == .emptyName)
    }

    @Test("Whitespace only name returns empty error")
    func whitespaceOnlyNameReturnsError() {
        let result = InputValidator.validateName("   ")
        #expect(result == .emptyName)
    }

    @Test("Name over 50 characters returns too long error")
    func nameTooLongReturnsError() {
        let longName = String(repeating: "a", count: 51)
        let result = InputValidator.validateName(longName)
        if case .nameTooLong(let maxLength) = result {
            #expect(maxLength == 50)
        } else {
            Issue.record("Expected nameTooLong error")
        }
    }

    @Test("Name exactly 50 characters is valid")
    func nameExactly50CharsValid() {
        let exactName = String(repeating: "a", count: 50)
        let result = InputValidator.validateName(exactName)
        #expect(result == nil)
    }

    @Test("Name with numbers returns invalid characters error")
    func nameWithNumbersReturnsError() {
        let result = InputValidator.validateName("John123")
        #expect(result == .invalidCharacters)
    }

    @Test("Name with special characters returns error")
    func nameWithSpecialCharsReturnsError() {
        let result = InputValidator.validateName("John@Doe")
        #expect(result == .invalidCharacters)
    }

    @Test("Name with hyphen is valid")
    func nameWithHyphenValid() {
        let result = InputValidator.validateName("Mary-Jane")
        #expect(result == nil)
    }

    @Test("Name with apostrophe is valid")
    func nameWithApostropheValid() {
        let result = InputValidator.validateName("O'Brien")
        #expect(result == nil)
    }

    @Test("Name with spaces is valid")
    func nameWithSpacesValid() {
        let result = InputValidator.validateName("John David Doe")
        #expect(result == nil)
    }

    @Test("Unicode letters are valid")
    func unicodeLettersValid() {
        let result = InputValidator.validateName("Müller")
        #expect(result == nil)
    }
}

// MARK: - Name Sanitization Tests

struct InputValidatorNameSanitizationTests {

    @Test("Sanitize removes leading/trailing whitespace")
    func sanitizeRemovesWhitespace() {
        let result = InputValidator.sanitizeName("  John Doe  ")
        #expect(result == "John Doe")
    }

    @Test("Sanitize collapses multiple spaces")
    func sanitizeCollapsesSpaces() {
        let result = InputValidator.sanitizeName("John    Doe")
        #expect(result == "John Doe")
    }

    @Test("Sanitize capitalizes words")
    func sanitizeCapitalizes() {
        let result = InputValidator.sanitizeName("john doe")
        #expect(result == "John Doe")
    }

    @Test("Sanitize limits length to 50")
    func sanitizeLimitsLength() {
        let longName = String(repeating: "a", count: 100)
        let result = InputValidator.sanitizeName(longName)
        #expect(result.count == 50)
    }
}

// MARK: - Birth Date Validation Tests

struct InputValidatorBirthDateTests {

    @Test("Valid birth date returns nil")
    func validBirthDateReturnsNil() {
        var components = DateComponents()
        components.year = 1990
        components.month = 8
        components.day = 15
        let date = Calendar.current.date(from: components)!

        let result = InputValidator.validateBirthDate(date)
        #expect(result == nil)
    }

    @Test("Future date returns future error")
    func futureDateReturnsError() {
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

        let result = InputValidator.validateBirthDate(futureDate)
        #expect(result == .futureBirthDate)
    }

    @Test("Date too young (under 13) returns unreasonable error")
    func dateTooYoungReturnsError() {
        let youngDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())!

        let result = InputValidator.validateBirthDate(youngDate)
        #expect(result == .unreasonableBirthDate)
    }

    @Test("Date exactly 13 years ago is valid")
    func dateExactly13YearsAgoValid() {
        let thirteenYearsAgo = Calendar.current.date(byAdding: .year, value: -13, to: Date())!

        let result = InputValidator.validateBirthDate(thirteenYearsAgo)
        #expect(result == nil)
    }

    @Test("Date over 120 years returns unreasonable error")
    func dateTooOldReturnsError() {
        var components = DateComponents()
        components.year = 1850
        components.month = 1
        components.day = 1
        let oldDate = Calendar.current.date(from: components)!

        let result = InputValidator.validateBirthDate(oldDate)
        #expect(result == .unreasonableBirthDate)
    }

    @Test("Date before 1900 returns unreasonable error")
    func dateBefore1900ReturnsError() {
        var components = DateComponents()
        components.year = 1899
        components.month = 12
        components.day = 31
        let oldDate = Calendar.current.date(from: components)!

        let result = InputValidator.validateBirthDate(oldDate)
        #expect(result == .unreasonableBirthDate)
    }

    @Test("Valid date range exists")
    func validDateRangeExists() {
        let range = InputValidator.validBirthDateRange
        #expect(range.lowerBound < range.upperBound)
    }
}

// MARK: - Share Amount Validation Tests

struct InputValidatorShareAmountTests {

    @Test("Positive amount is valid")
    func positiveAmountValid() {
        let result = InputValidator.validateShareAmount(10.0)
        #expect(result == nil)
    }

    @Test("Zero amount returns error")
    func zeroAmountReturnsError() {
        let result = InputValidator.validateShareAmount(0)
        #expect(result == .invalidShareAmount)
    }

    @Test("Negative amount returns error")
    func negativeAmountReturnsError() {
        let result = InputValidator.validateShareAmount(-5.0)
        #expect(result == .invalidShareAmount)
    }

    @Test("Very small positive amount is valid")
    func verySmallPositiveValid() {
        let result = InputValidator.validateShareAmount(0.0001)
        #expect(result == nil)
    }

    @Test("NaN returns error")
    func nanReturnsError() {
        let result = InputValidator.validateShareAmount(Double.nan)
        #expect(result == .invalidShareAmount)
    }

    @Test("Infinity returns error")
    func infinityReturnsError() {
        let result = InputValidator.validateShareAmount(Double.infinity)
        #expect(result == .invalidShareAmount)
    }

    @Test("Amount over 1 billion returns error")
    func overBillionReturnsError() {
        let result = InputValidator.validateShareAmount(1_000_000_001)
        #expect(result == .invalidShareAmount)
    }

    @Test("Amount exactly 1 billion is valid")
    func exactlyBillionValid() {
        let result = InputValidator.validateShareAmount(1_000_000_000)
        #expect(result == nil)
    }
}

// MARK: - Share Amount Parsing Tests

struct InputValidatorShareParsingTests {

    @Test("Parse valid integer string")
    func parseValidInteger() {
        let result = InputValidator.parseShareAmount("10")
        #expect(result == 10.0)
    }

    @Test("Parse valid decimal string")
    func parseValidDecimal() {
        let result = InputValidator.parseShareAmount("10.5")
        #expect(result == 10.5)
    }

    @Test("Parse empty string returns nil")
    func parseEmptyReturnsNil() {
        let result = InputValidator.parseShareAmount("")
        #expect(result == nil)
    }

    @Test("Parse non-numeric string returns nil")
    func parseNonNumericReturnsNil() {
        let result = InputValidator.parseShareAmount("abc")
        #expect(result == nil)
    }

    @Test("Parse negative string returns nil")
    func parseNegativeReturnsNil() {
        let result = InputValidator.parseShareAmount("-5")
        #expect(result == nil)
    }

    @Test("Parse with whitespace works")
    func parseWithWhitespace() {
        let result = InputValidator.parseShareAmount("  10  ")
        #expect(result == 10.0)
    }
}

// MARK: - Search Query Validation Tests

struct InputValidatorSearchQueryTests {

    @Test("Valid search query returns nil")
    func validQueryReturnsNil() {
        let result = InputValidator.validateSearchQuery("AAPL")
        #expect(result == nil)
    }

    @Test("Empty query is valid (shows all results)")
    func emptyQueryValid() {
        let result = InputValidator.validateSearchQuery("")
        #expect(result == nil)
    }

    @Test("Query with dangerous characters returns error")
    func dangerousCharsReturnsError() {
        let result = InputValidator.validateSearchQuery("<script>")
        #expect(result == .invalidSearchQuery)
    }

    @Test("Query with pipe returns error")
    func pipeCharReturnsError() {
        let result = InputValidator.validateSearchQuery("AAPL|GOOGL")
        #expect(result == .invalidSearchQuery)
    }

    @Test("Sanitize query converts to uppercase")
    func sanitizeConvertsToUppercase() {
        let result = InputValidator.sanitizeSearchQuery("aapl")
        #expect(result == "AAPL")
    }

    @Test("Sanitize query removes special chars")
    func sanitizeRemovesSpecialChars() {
        let result = InputValidator.sanitizeSearchQuery("AAPL@#$")
        #expect(result == "AAPL")
    }
}

// MARK: - Stock Symbol Validation Tests

struct InputValidatorSymbolTests {

    @Test("Valid 4-letter symbol is valid")
    func validFourLetterSymbol() {
        let result = InputValidator.isValidSymbolFormat("AAPL")
        #expect(result == true)
    }

    @Test("Valid 1-letter symbol is valid")
    func validOneLetterSymbol() {
        let result = InputValidator.isValidSymbolFormat("A")
        #expect(result == true)
    }

    @Test("Valid 5-letter symbol is valid")
    func validFiveLetterSymbol() {
        let result = InputValidator.isValidSymbolFormat("GOOGL")
        #expect(result == true)
    }

    @Test("7+ letter symbol is invalid")
    func sevenLetterSymbolInvalid() {
        let result = InputValidator.isValidSymbolFormat("ABCDEFG")
        #expect(result == false)
    }

    @Test("Empty symbol is invalid")
    func emptySymbolInvalid() {
        let result = InputValidator.isValidSymbolFormat("")
        #expect(result == false)
    }

    @Test("Symbol with numbers is invalid")
    func symbolWithNumbersInvalid() {
        let result = InputValidator.isValidSymbolFormat("AAP1")
        #expect(result == false)
    }

    @Test("Sanitize symbol converts to uppercase")
    func sanitizeSymbolUppercase() {
        let result = InputValidator.sanitizeSymbol("aapl")
        #expect(result == "AAPL")
    }

    @Test("Sanitize symbol removes non-letters")
    func sanitizeSymbolRemovesNonLetters() {
        let result = InputValidator.sanitizeSymbol("AAPL123")
        #expect(result == "AAPL")
    }
}

// MARK: - Email Validation Tests

struct InputValidatorEmailTests {

    @Test("Valid email returns true")
    func validEmailReturnsTrue() {
        let result = InputValidator.validateEmail("test@example.com")
        #expect(result == true)
    }

    @Test("Email without @ is invalid")
    func emailWithoutAtInvalid() {
        let result = InputValidator.validateEmail("testexample.com")
        #expect(result == false)
    }

    @Test("Email without domain is invalid")
    func emailWithoutDomainInvalid() {
        let result = InputValidator.validateEmail("test@")
        #expect(result == false)
    }

    @Test("Email with subdomain is valid")
    func emailWithSubdomainValid() {
        let result = InputValidator.validateEmail("test@mail.example.com")
        #expect(result == true)
    }
}

// MARK: - String Extension Tests

struct StringValidationExtensionTests {

    @Test("isValidName extension works")
    func isValidNameExtension() {
        #expect("John Doe".isValidName == true)
        #expect("".isValidName == false)
    }

    @Test("isValidSymbol extension works")
    func isValidSymbolExtension() {
        #expect("AAPL".isValidSymbol == true)
        #expect("".isValidSymbol == false)
    }

    @Test("sanitizedAsName extension works")
    func sanitizedAsNameExtension() {
        #expect("  john doe  ".sanitizedAsName == "John Doe")
    }

    @Test("sanitizedAsSymbol extension works")
    func sanitizedAsSymbolExtension() {
        #expect("aapl".sanitizedAsSymbol == "AAPL")
    }
}

// MARK: - Date Extension Tests

struct DateValidationExtensionTests {

    @Test("isValidBirthDate extension works")
    func isValidBirthDateExtension() {
        var components = DateComponents()
        components.year = 1990
        components.month = 8
        components.day = 15
        let validDate = Calendar.current.date(from: components)!

        #expect(validDate.isValidBirthDate == true)

        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        #expect(futureDate.isValidBirthDate == false)
    }
}
