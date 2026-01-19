import Foundation
import SwiftUI

// MARK: - NetworkError

/// Errors that can occur during network operations with the Finnhub API.
///
/// `NetworkError` provides structured error handling for all API operations,
/// with user-friendly cosmic-themed messages and actionable suggestions.
///
/// ## Usage
///
/// ```swift
/// do {
///     let quote = try await StockAPIService.shared.getQuote(symbol: "AAPL")
/// } catch let error as NetworkError {
///     // Show themed error message
///     showAlert(error.cosmicMessage)
///
///     // Optionally retry if appropriate
///     if error.isRetryable {
///         retryButton.isEnabled = true
///     }
/// }
/// ```
///
/// ## Error Categories
///
/// | Category | Cases | Retryable |
/// |----------|-------|-----------|
/// | Connectivity | ``noConnection``, ``timeout`` | Yes |
/// | Server | ``serverError(statusCode:)``, ``rateLimited`` | Varies |
/// | Client | ``invalidSymbol(_:)``, ``invalidResponse`` | No |
/// | Config | ``apiKeyMissing`` | No |
enum NetworkError: Error, LocalizedError, Equatable {
    /// Device has no internet connection.
    case noConnection

    /// Request exceeded the configured timeout interval.
    case timeout

    /// Server returned an HTTP error status code (5xx).
    /// - Parameter statusCode: The HTTP status code received.
    case serverError(statusCode: Int)

    /// API rate limit has been exceeded (60 requests/minute on free tier).
    case rateLimited

    /// Server response was malformed or unexpected.
    case invalidResponse

    /// JSON decoding of the response failed.
    case decodingError

    /// The requested stock symbol was not found.
    /// - Parameter symbol: The symbol that wasn't found.
    case invalidSymbol(String)

    /// Finnhub API key is not configured.
    case apiKeyMissing

    /// An unexpected error occurred.
    /// - Parameter message: Description of the error.
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .rateLimited:
            return "Rate limit exceeded"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to process data"
        case .invalidSymbol(let symbol):
            return "Invalid stock symbol: \(symbol)"
        case .apiKeyMissing:
            return "API key not configured"
        case .unknown(let message):
            return message
        }
    }

    // MARK: - Cosmic Messages

    /// User-friendly cosmic-themed message
    var cosmicMessage: String {
        switch self {
        case .noConnection:
            return "The cosmic signals are blocked. Check your connection to the universe."
        case .timeout:
            return "The stars are taking too long to align. Please try again."
        case .serverError:
            return "The celestial servers are experiencing turbulence."
        case .rateLimited:
            return "You've consulted the cosmos too frequently. Wait a moment before asking again."
        case .invalidResponse:
            return "The astral transmission was unclear. Try again."
        case .decodingError:
            return "We couldn't interpret the cosmic data. Something got lost in translation."
        case .invalidSymbol(let symbol):
            return "We couldn't find '\(symbol)' in our galaxy of stocks."
        case .apiKeyMissing:
            return "The cosmic gateway requires configuration."
        case .unknown:
            return "An unexpected disturbance in the cosmic field occurred."
        }
    }

    /// Suggested action for the user
    var suggestedAction: String {
        switch self {
        case .noConnection:
            return "Check your internet connection"
        case .timeout:
            return "Try again"
        case .serverError:
            return "Wait and try again"
        case .rateLimited:
            return "Refreshing soon..."
        case .invalidResponse, .decodingError:
            return "Pull to refresh"
        case .invalidSymbol:
            return "Check the symbol"
        case .apiKeyMissing:
            return "Contact support"
        case .unknown:
            return "Try again"
        }
    }

    /// Icon for the error type
    var icon: String {
        switch self {
        case .noConnection:
            return "wifi.slash"
        case .timeout:
            return "clock.badge.exclamationmark"
        case .serverError:
            return "exclamationmark.icloud"
        case .rateLimited:
            return "hourglass"
        case .invalidResponse, .decodingError:
            return "questionmark.circle"
        case .invalidSymbol:
            return "magnifyingglass"
        case .apiKeyMissing:
            return "key.slash"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }

    /// Whether this error should allow retry
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError, .invalidResponse, .unknown:
            return true
        case .rateLimited:
            return false // Should auto-retry after delay
        case .decodingError, .invalidSymbol, .apiKeyMissing:
            return false
        }
    }

    /// Color theme for error display
    var themeColor: Color {
        switch self {
        case .noConnection, .timeout:
            return .orange
        case .serverError, .rateLimited:
            return .yellow
        case .invalidSymbol, .invalidResponse, .decodingError:
            return .blue
        case .apiKeyMissing, .unknown:
            return .red
        }
    }
}

// MARK: - DataError

/// Errors that can occur during local data persistence operations.
///
/// `DataError` covers failures in reading, writing, and validating
/// locally stored data such as user profiles and portfolios.
enum DataError: Error, LocalizedError {
    /// Stored data is corrupted and cannot be recovered.
    case corruptedData

    /// A required field is missing from the stored data.
    /// - Parameter field: Name of the missing field.
    case missingRequiredField(String)

    /// Failed to encode data for storage.
    case encodingFailed

    /// Failed to decode stored data.
    case decodingFailed

    /// Device storage is full; cannot save data.
    case storageFull

    /// Data format is invalid or unsupported.
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .corruptedData:
            return "Data corruption detected"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .encodingFailed:
            return "Failed to save data"
        case .decodingFailed:
            return "Failed to read data"
        case .storageFull:
            return "Storage is full"
        case .invalidFormat:
            return "Invalid data format"
        }
    }

    var cosmicMessage: String {
        switch self {
        case .corruptedData:
            return "Your cosmic data has experienced interference. Resetting to restore harmony."
        case .missingRequiredField:
            return "Some essential cosmic information is missing."
        case .encodingFailed:
            return "We couldn't record your cosmic journey."
        case .decodingFailed:
            return "Your cosmic history couldn't be retrieved."
        case .storageFull:
            return "The cosmic vault is full."
        case .invalidFormat:
            return "The cosmic records are in an unexpected format."
        }
    }
}

// MARK: - ValidationError

/// Errors that can occur when validating user input.
///
/// `ValidationError` is used to provide clear feedback when user-entered
/// data doesn't meet requirements, such as during onboarding or profile editing.
enum ValidationError: Error, LocalizedError, Equatable {
    /// User name is empty or contains only whitespace.
    case emptyName

    /// User name exceeds the maximum allowed length.
    /// - Parameter maxLength: The maximum allowed characters.
    case nameTooLong(maxLength: Int)

    /// User name contains disallowed characters.
    case invalidCharacters

    /// Birth date is in the future.
    case futureBirthDate

    /// Birth date is impossibly old (e.g., before 1900).
    case unreasonableBirthDate

    /// Search query is invalid (too short or contains only special chars).
    case invalidSearchQuery

    /// Share amount is not a valid positive number.
    case invalidShareAmount

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Name cannot be empty"
        case .nameTooLong(let max):
            return "Name exceeds \(max) characters"
        case .invalidCharacters:
            return "Name contains invalid characters"
        case .futureBirthDate:
            return "Birth date cannot be in the future"
        case .unreasonableBirthDate:
            return "Birth date is unreasonable"
        case .invalidSearchQuery:
            return "Invalid search query"
        case .invalidShareAmount:
            return "Invalid share amount"
        }
    }

    var cosmicMessage: String {
        switch self {
        case .emptyName:
            return "Every celestial being needs a name."
        case .nameTooLong:
            return "Your cosmic identity is a bit too long for our star charts."
        case .invalidCharacters:
            return "Your name contains characters unknown to our cosmic alphabet."
        case .futureBirthDate:
            return "Time travel hasn't been invented yet!"
        case .unreasonableBirthDate:
            return "That birth date seems to be from another dimension."
        case .invalidSearchQuery:
            return "The cosmic search engine doesn't understand that query."
        case .invalidShareAmount:
            return "The number of shares must be a positive cosmic value."
        }
    }
}

// MARK: - AppError

/// Unified error type that wraps all error categories in the app.
///
/// `AppError` provides a single type for error handling across the app,
/// allowing consistent error display regardless of the error source.
///
/// ## Usage
///
/// ```swift
/// let errorState = ErrorState()
///
/// do {
///     try await someOperation()
/// } catch let error as NetworkError {
///     errorState.show(.network(error))
/// } catch let error as DataError {
///     errorState.show(.data(error))
/// }
/// ```
enum AppError: Error {
    /// A network-related error occurred.
    case network(NetworkError)

    /// A local data persistence error occurred.
    case data(DataError)

    /// A user input validation error occurred.
    case validation(ValidationError)

    var cosmicMessage: String {
        switch self {
        case .network(let error):
            return error.cosmicMessage
        case .data(let error):
            return error.cosmicMessage
        case .validation(let error):
            return error.cosmicMessage
        }
    }

    var underlyingError: Error {
        switch self {
        case .network(let error):
            return error
        case .data(let error):
            return error
        case .validation(let error):
            return error
        }
    }
}

// MARK: - Result Extensions
// =========================

extension Result where Failure == Error {
    /// Convert any error to an AppError
    var appError: AppError? {
        if case .failure(let error) = self {
            if let networkError = error as? NetworkError {
                return .network(networkError)
            } else if let dataError = error as? DataError {
                return .data(dataError)
            } else if let validationError = error as? ValidationError {
                return .validation(validationError)
            }
        }
        return nil
    }
}

// MARK: - ErrorState

/// Observable state object for managing error display in views.
///
/// `ErrorState` provides a centralized way to show and dismiss errors
/// in SwiftUI views. It handles animation timing and provides convenience
/// methods for different error types.
///
/// ## Usage
///
/// ```swift
/// struct ContentView: View {
///     @State private var errorState = ErrorState()
///
///     var body: some View {
///         MyContent()
///             .errorBanner(errorState)
///     }
/// }
/// ```
@Observable
class ErrorState {
    /// The current error being displayed, if any.
    var currentError: AppError?

    /// Whether an error banner/sheet should be visible.
    var isShowingError: Bool = false

    /// When the current error was shown (for timeout purposes).
    var errorTimestamp: Date?

    /// Shows an error with the standard error UI.
    ///
    /// - Parameter error: The ``AppError`` to display.
    func show(_ error: AppError) {
        currentError = error
        isShowingError = true
        errorTimestamp = Date()
    }

    /// Convenience method to show a network error.
    ///
    /// - Parameter error: The ``NetworkError`` to display.
    func showNetwork(_ error: NetworkError) {
        show(.network(error))
    }

    /// Convenience method to show a data error.
    ///
    /// - Parameter error: The ``DataError`` to display.
    func showData(_ error: DataError) {
        show(.data(error))
    }

    /// Convenience method to show a validation error.
    ///
    /// - Parameter error: The ``ValidationError`` to display.
    func showValidation(_ error: ValidationError) {
        show(.validation(error))
    }

    /// Dismisses the error with animation.
    ///
    /// The error reference is kept briefly for dismiss animations.
    func dismiss() {
        isShowingError = false
        // Keep the error around briefly for animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if self?.isShowingError == false {
                self?.currentError = nil
            }
        }
    }

    /// Clears all error state immediately without animation.
    func clear() {
        currentError = nil
        isShowingError = false
        errorTimestamp = nil
    }
}

// MARK: - Retry Logic
// ===================

struct RetryConfiguration: Sendable {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double

    static nonisolated let `default` = RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )

    static nonisolated let aggressive = RetryConfiguration(
        maxAttempts: 5,
        initialDelay: 0.5,
        maxDelay: 30.0,
        multiplier: 2.0
    )

    func delay(for attempt: Int) -> TimeInterval {
        let delay = initialDelay * pow(multiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

/// Execute an async operation with retry logic
func withRetry<T>(
    config: RetryConfiguration = .default,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 1...config.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error

            // Check if error is retryable
            if let networkError = error as? NetworkError, !networkError.isRetryable {
                throw error
            }

            // Don't delay after last attempt
            if attempt < config.maxAttempts {
                let delay = config.delay(for: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw lastError ?? NetworkError.unknown("Unknown error after retries")
}
