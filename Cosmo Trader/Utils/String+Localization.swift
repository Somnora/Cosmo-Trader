//
//  String+Localization.swift
//  Cosmo Trader
//
//  Extension to simplify string localization throughout the app.
//

import Foundation

// MARK: - String Localization Extension

extension String {

    /// Returns the localized version of this string.
    ///
    /// Uses `NSLocalizedString` to look up the translation in the appropriate
    /// `Localizable.strings` file based on the user's language settings.
    ///
    /// ## Usage
    /// ```swift
    /// let title = "onboarding.welcome.title".localized
    /// // Returns "COSMO TRADER" in English
    /// ```
    ///
    /// - Returns: The localized string, or the key itself if no translation is found.
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns the localized string with format arguments.
    ///
    /// Use this for strings that contain placeholders like `%@`, `%d`, etc.
    ///
    /// ## Usage
    /// ```swift
    /// let message = "stock.compatibility.description".localized(with: "Aries")
    /// // Returns "Based on your Aries sign"
    /// ```
    ///
    /// - Parameter arguments: The values to substitute into the format placeholders.
    /// - Returns: The formatted localized string.
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }

    /// Returns the localized string from a specific table.
    ///
    /// Use this when you have multiple `.strings` files for different purposes.
    ///
    /// - Parameters:
    ///   - table: The name of the strings table (without the `.strings` extension).
    ///   - bundle: The bundle containing the strings file. Defaults to `.main`.
    /// - Returns: The localized string.
    func localized(from table: String, bundle: Bundle = .main) -> String {
        NSLocalizedString(self, tableName: table, bundle: bundle, comment: "")
    }

    /// Returns the localized string with a specific comment for translators.
    ///
    /// The comment provides context to translators about where and how the string is used.
    ///
    /// - Parameter comment: Context for translators.
    /// - Returns: The localized string.
    func localized(comment: String) -> String {
        NSLocalizedString(self, comment: comment)
    }
}

// MARK: - Localization Helpers

/// Convenience function for localization with a shorter syntax.
///
/// ## Usage
/// ```swift
/// let title = L("onboarding.welcome.title")
/// ```
///
/// - Parameter key: The localization key.
/// - Returns: The localized string.
func L(_ key: String) -> String {
    key.localized
}

/// Convenience function for localization with format arguments.
///
/// ## Usage
/// ```swift
/// let message = L("stock.compatibility.description", "Aries")
/// ```
///
/// - Parameters:
///   - key: The localization key.
///   - arguments: The values to substitute into the format placeholders.
/// - Returns: The formatted localized string.
func L(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: key.localized, arguments: arguments)
}
