import Foundation

// MARK: - InputValidator
// ======================
// Centralized input validation for user data.
// Returns specific errors with cosmic-themed messages.

struct InputValidator {

    // MARK: - Name Validation

    /// Validates a display name
    /// - Returns: nil if valid, ValidationError if invalid
    static func validateName(_ name: String) -> ValidationError? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for empty
        if trimmed.isEmpty {
            return .emptyName
        }

        // Check minimum length (at least 2 characters)
        if trimmed.count < 2 {
            return .emptyName
        }

        // Check maximum length
        let maxLength = 50
        if trimmed.count > maxLength {
            return .nameTooLong(maxLength: maxLength)
        }

        // Check for invalid characters (allow letters, spaces, hyphens, apostrophes)
        let allowedCharacterSet = CharacterSet.letters
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-'"))

        if trimmed.unicodeScalars.contains(where: { !allowedCharacterSet.contains($0) }) {
            return .invalidCharacters
        }

        return nil
    }

    /// Validates and sanitizes a name, returning a clean version
    static func sanitizeName(_ name: String) -> String {
        var sanitized = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove multiple consecutive spaces
        while sanitized.contains("  ") {
            sanitized = sanitized.replacingOccurrences(of: "  ", with: " ")
        }

        // Capitalize first letter of each word
        sanitized = sanitized.capitalized

        // Limit length
        if sanitized.count > 50 {
            sanitized = String(sanitized.prefix(50))
        }

        return sanitized
    }

    // MARK: - Birth Date Validation

    /// Validates a birth date
    /// - Returns: nil if valid, ValidationError if invalid
    static func validateBirthDate(_ date: Date) -> ValidationError? {
        let now = Date()

        // Future date check
        if date > now {
            return .futureBirthDate
        }

        // Reasonable age check (must be at least 13, no more than 120 years old)
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: now)
        let age = ageComponents.year ?? 0

        if age < 0 {
            return .futureBirthDate
        }

        if age < 13 {
            // Too young
            return .unreasonableBirthDate
        }

        if age > 120 {
            // Unreasonably old
            return .unreasonableBirthDate
        }

        // Check for dates before 1900
        let yearComponents = calendar.dateComponents([.year], from: date)
        if let year = yearComponents.year, year < 1900 {
            return .unreasonableBirthDate
        }

        return nil
    }

    /// Returns a valid date range for birth dates
    static var validBirthDateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()

        // Oldest: 120 years ago
        let oldest = calendar.date(byAdding: .year, value: -120, to: now) ?? now

        // Youngest: 13 years ago
        let youngest = calendar.date(byAdding: .year, value: -13, to: now) ?? now

        return oldest...youngest
    }

    // MARK: - Search Query Validation

    /// Validates a search query
    /// - Returns: nil if valid, ValidationError if invalid
    static func validateSearchQuery(_ query: String) -> ValidationError? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty queries are allowed (will show all results)
        if trimmed.isEmpty {
            return nil
        }

        // Check for minimum meaningful length
        if trimmed.count < 1 {
            return .invalidSearchQuery
        }

        // Check for dangerous characters (prevent injection-like inputs)
        let dangerousCharacters = CharacterSet(charactersIn: "<>{}[]|\\^~`")
        if trimmed.unicodeScalars.contains(where: { dangerousCharacters.contains($0) }) {
            return .invalidSearchQuery
        }

        return nil
    }

    /// Sanitizes a search query
    static func sanitizeSearchQuery(_ query: String) -> String {
        var sanitized = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Convert to uppercase for stock symbols
        sanitized = sanitized.uppercased()

        // Remove problematic characters
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces)
        sanitized = sanitized.unicodeScalars
            .filter { allowedCharacters.contains($0) }
            .map { String($0) }
            .joined()

        // Limit length
        if sanitized.count > 50 {
            sanitized = String(sanitized.prefix(50))
        }

        return sanitized
    }

    // MARK: - Share Amount Validation

    /// Validates a share amount
    /// - Returns: nil if valid, ValidationError if invalid
    static func validateShareAmount(_ amount: Double) -> ValidationError? {
        // Must be positive
        if amount <= 0 {
            return .invalidShareAmount
        }

        // Must be finite
        if amount.isNaN || amount.isInfinite {
            return .invalidShareAmount
        }

        // Maximum reasonable amount (prevents overflow)
        if amount > 1_000_000_000 {
            return .invalidShareAmount
        }

        return nil
    }

    /// Parses a string to a valid share amount
    static func parseShareAmount(_ string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle empty
        guard !trimmed.isEmpty else { return nil }

        // Try to parse
        guard let amount = Double(trimmed) else { return nil }

        // Validate
        if validateShareAmount(amount) != nil {
            return nil
        }

        // Round to reasonable precision (4 decimal places for fractional shares)
        return (amount * 10000).rounded() / 10000
    }

    // MARK: - Stock Symbol Validation

    /// Validates a stock symbol
    /// - Returns: true if valid format
    static func isValidSymbolFormat(_ symbol: String) -> Bool {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Length check (1-5 characters typically)
        guard trimmed.count >= 1 && trimmed.count <= 6 else {
            return false
        }

        // Only letters allowed
        let letterSet = CharacterSet.uppercaseLetters
        return trimmed.unicodeScalars.allSatisfy { letterSet.contains($0) }
    }

    /// Sanitizes a stock symbol
    static func sanitizeSymbol(_ symbol: String) -> String {
        symbol
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .filter { $0.isLetter }
    }

    // MARK: - Email Validation (for future use)

    /// Validates an email address format
    static func validateEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Basic format check
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: trimmed)
    }
}

// MARK: - Validation Result Type
// ==============================

enum ValidationResult<T> {
    case valid(T)
    case invalid(ValidationError)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var value: T? {
        if case .valid(let v) = self { return v }
        return nil
    }

    var error: ValidationError? {
        if case .invalid(let e) = self { return e }
        return nil
    }
}

// MARK: - String Extensions
// =========================

extension String {
    /// Validates this string as a name
    var isValidName: Bool {
        InputValidator.validateName(self) == nil
    }

    /// Validates this string as a search query
    var isValidSearchQuery: Bool {
        InputValidator.validateSearchQuery(self) == nil
    }

    /// Validates this string as a stock symbol
    var isValidSymbol: Bool {
        InputValidator.isValidSymbolFormat(self)
    }

    /// Returns a sanitized version for use as a name
    var sanitizedAsName: String {
        InputValidator.sanitizeName(self)
    }

    /// Returns a sanitized version for use as a search query
    var sanitizedAsSearchQuery: String {
        InputValidator.sanitizeSearchQuery(self)
    }

    /// Returns a sanitized version for use as a stock symbol
    var sanitizedAsSymbol: String {
        InputValidator.sanitizeSymbol(self)
    }
}

// MARK: - Date Extensions
// =======================

extension Date {
    /// Validates this date as a birth date
    var isValidBirthDate: Bool {
        InputValidator.validateBirthDate(self) == nil
    }
}

// MARK: - UserDefaults Data Validation
// ====================================

struct DataValidator {

    /// Validates UserProfile data integrity
    static func validateUserProfile(_ profile: UserProfile) -> DataError? {
        // Check required fields
        if profile.displayName.isEmpty {
            return .missingRequiredField("displayName")
        }

        // Validate birth date
        if InputValidator.validateBirthDate(profile.birthDate) != nil {
            return .invalidFormat
        }

        // Validate portfolio stocks
        for stock in profile.portfolio {
            if stock.symbol.isEmpty {
                return .missingRequiredField("stock.symbol")
            }
            if stock.name.isEmpty {
                return .missingRequiredField("stock.name")
            }
            if stock.sharesOwned < 0 {
                return .invalidFormat
            }
        }

        return nil
    }

    /// Attempts to repair common data issues
    static func repairUserProfile(_ profile: inout UserProfile) {
        // Sanitize display name
        if !profile.displayName.isEmpty {
            profile.displayName = InputValidator.sanitizeName(profile.displayName)
        }

        // Remove invalid portfolio entries
        profile.portfolio = profile.portfolio.filter { stock in
            !stock.symbol.isEmpty && !stock.name.isEmpty && stock.sharesOwned >= 0
        }

        // Remove duplicates from watchlist
        profile.watchlist = Array(Set(profile.watchlist))

        // Remove duplicates from skipped
        profile.skippedStocks = Array(Set(profile.skippedStocks))
    }
}
