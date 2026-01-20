import Foundation

// MARK: - Log
// ============
// Debug-only logging utility that compiles to no-ops in Release builds.
// All print statements in the app should use this wrapper to prevent
// log output from appearing in production builds.
//
// Usage:
//   Log.debug("Simple message")
//   Log.debug("[ServiceName] Operation completed: \(result)")
//   Log.error("[ServiceName] Failed to load: \(error)")

enum Log {

    /// General debug logging - stripped in Release builds
    static func debug(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        #if DEBUG
        print(message())
        #endif
    }

    /// Error logging - stripped in Release builds
    static func error(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        #if DEBUG
        print("ERROR: \(message())")
        #endif
    }

    /// Warning logging - stripped in Release builds
    static func warning(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        #if DEBUG
        print("WARNING: \(message())")
        #endif
    }

    /// Verbose logging for detailed debugging - stripped in Release builds
    static func verbose(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        #if DEBUG
        print(message())
        #endif
    }
}
