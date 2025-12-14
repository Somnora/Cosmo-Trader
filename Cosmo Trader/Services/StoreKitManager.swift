import Foundation
import StoreKit

// MARK: - StoreKitManager
// ========================
// Full StoreKit 2 integration for Cosmo Trader subscription management.
// Handles product fetching, purchasing, restoring, and entitlement verification.
// Uses async/await and modern StoreKit 2 APIs.

@MainActor
@Observable
final class StoreKitManager {

    // MARK: - Singleton

    static let shared = StoreKitManager()

    // MARK: - Product Identifiers

    enum ProductID: String, CaseIterable {
        case oracleMonthly = "cosmo.oracle.monthly"
        case oracleYearly = "cosmo.oracle.yearly"

        var displayName: String {
            switch self {
            case .oracleMonthly: return "Oracle Tier Monthly"
            case .oracleYearly: return "Oracle Tier Yearly"
            }
        }
    }

    // MARK: - State

    /// Available products from the App Store
    private(set) var products: [Product] = []

    /// Currently purchased/active subscription
    private(set) var purchasedSubscription: Product?

    /// Whether the user has an active subscription
    private(set) var hasActiveSubscription: Bool = false

    /// Current subscription expiration date
    private(set) var subscriptionExpirationDate: Date?

    /// Whether products are currently loading
    private(set) var isLoading: Bool = false

    /// Last error encountered
    private(set) var lastError: StoreKitError?

    /// Transaction update listener task
    private var transactionListener: Task<Void, Error>?

    // MARK: - Init

    private init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactions()

        // Load products and check entitlements on init
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }

    nonisolated func cleanup() {
        // Note: transactionListener is automatically cancelled when StoreKitManager is deallocated
        // since Task holds a weak reference to self
    }

    // MARK: - Product Loading

    /// Fetch available products from the App Store
    func loadProducts() async {
        isLoading = true
        lastError = nil

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: Set(productIDs))

            // Sort products by price (monthly first, then yearly)
            products = storeProducts.sorted { lhs, rhs in
                // Monthly comes before yearly
                if lhs.id == ProductID.oracleMonthly.rawValue {
                    return true
                }
                if rhs.id == ProductID.oracleMonthly.rawValue {
                    return false
                }
                return lhs.price < rhs.price
            }

            isLoading = false
        } catch {
            lastError = .productLoadFailed(error)
            isLoading = false
            print("[StoreKit] Failed to load products: \(error.localizedDescription)")
        }
    }

    /// Get a specific product by ID
    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    /// Get monthly product
    var monthlyProduct: Product? {
        product(for: .oracleMonthly)
    }

    /// Get yearly product
    var yearlyProduct: Product? {
        product(for: .oracleYearly)
    }

    // MARK: - Purchasing

    /// Purchase a subscription product
    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        lastError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update subscription status
                await checkSubscriptionStatus()

                // Finish the transaction
                await transaction.finish()

                return transaction

            case .userCancelled:
                lastError = .purchaseCancelled
                return nil

            case .pending:
                lastError = .purchasePending
                return nil

            @unknown default:
                lastError = .unknownPurchaseResult
                return nil
            }
        } catch {
            lastError = .purchaseFailed(error)
            throw error
        }
    }

    /// Purchase by product ID
    @discardableResult
    func purchase(productID: ProductID) async throws -> Transaction? {
        guard let product = product(for: productID) else {
            lastError = .productNotFound(productID.rawValue)
            throw StoreKitError.productNotFound(productID.rawValue)
        }
        return try await purchase(product)
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async -> Bool {
        lastError = nil

        do {
            // Sync with App Store
            try await AppStore.sync()

            // Check current entitlements
            await checkSubscriptionStatus()

            return hasActiveSubscription
        } catch {
            lastError = .restoreFailed(error)
            print("[StoreKit] Failed to restore purchases: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Subscription Status

    /// Check current subscription status using Transaction.currentEntitlements
    func checkSubscriptionStatus() async {
        hasActiveSubscription = false
        purchasedSubscription = nil
        subscriptionExpirationDate = nil

        // Iterate through all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is one of our subscription products
                if ProductID.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                    // Check if subscription is still active
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            hasActiveSubscription = true
                            subscriptionExpirationDate = expirationDate

                            // Find the corresponding product
                            purchasedSubscription = products.first { $0.id == transaction.productID }

                            print("[StoreKit] Active subscription found: \(transaction.productID), expires: \(expirationDate)")
                        }
                    }
                }
            } catch {
                print("[StoreKit] Transaction verification failed: \(error)")
            }
        }

        // Notify subscription manager of status change
        await notifySubscriptionManager()
    }

    /// Get subscription renewal info
    func getSubscriptionRenewalInfo() async -> Product.SubscriptionInfo.RenewalInfo? {
        guard let product = purchasedSubscription,
              let subscription = product.subscription else {
            return nil
        }

        do {
            let statuses = try await subscription.status

            for status in statuses {
                switch status.state {
                case .subscribed, .inGracePeriod:
                    if case .verified(let renewalInfo) = status.renewalInfo {
                        return renewalInfo
                    }
                default:
                    continue
                }
            }
        } catch {
            print("[StoreKit] Failed to get renewal info: \(error)")
        }

        return nil
    }

    /// Check if subscription will renew
    func willAutoRenew() async -> Bool {
        guard let renewalInfo = await getSubscriptionRenewalInfo() else {
            return false
        }
        return renewalInfo.willAutoRenew
    }

    // MARK: - Transaction Listener

    /// Listen for transaction updates (purchases, renewals, refunds, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            // Listen for transaction updates
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)

                    // Update subscription status on main actor
                    await self?.checkSubscriptionStatus()

                    // Finish the transaction
                    await transaction?.finish()

                } catch {
                    print("[StoreKit] Transaction update verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Receipt Validation

    /// Verify a transaction result
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            // StoreKit has determined the transaction is invalid
            throw StoreKitError.verificationFailed(error)
        case .verified(let safe):
            return safe
        }
    }

    /// Get the App Store receipt data for server-side validation
    @available(iOS, deprecated: 18.0, message: "Use AppTransaction from StoreKit 2")
    func getReceiptData() -> Data? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: receiptURL.path) else {
            return nil
        }

        do {
            let receiptData = try Data(contentsOf: receiptURL)
            return receiptData
        } catch {
            print("[StoreKit] Failed to read receipt: \(error)")
            return nil
        }
    }

    /// Get Base64 encoded receipt for server validation
    func getReceiptBase64() -> String? {
        guard let receiptData = getReceiptData() else {
            return nil
        }
        return receiptData.base64EncodedString()
    }

    // MARK: - App Store Server Notifications Preparation

    /// Transaction info for server notification handling
    struct TransactionInfo: Codable {
        let productID: String
        let originalTransactionID: String
        let purchaseDate: Date
        let expirationDate: Date?
        let isUpgraded: Bool
        let revocationDate: Date?
        let environment: String
    }

    /// Get current transaction info for server sync
    func getCurrentTransactionInfo() async -> TransactionInfo? {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if ProductID.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                    return TransactionInfo(
                        productID: transaction.productID,
                        originalTransactionID: String(transaction.originalID),
                        purchaseDate: transaction.originalPurchaseDate,
                        expirationDate: transaction.expirationDate,
                        isUpgraded: transaction.isUpgraded,
                        revocationDate: transaction.revocationDate,
                        environment: transaction.environment.rawValue
                    )
                }
            } catch {
                continue
            }
        }
        return nil
    }

    // MARK: - Helper Methods

    /// Notify SubscriptionManager of status changes
    private func notifySubscriptionManager() async {
        if hasActiveSubscription {
            SubscriptionManager.shared.handleSubscriptionActivated()
        } else {
            SubscriptionManager.shared.handleSubscriptionExpired()
        }
    }

    /// Format price for display
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    /// Get subscription period description
    func subscriptionPeriodDescription(for product: Product) -> String {
        guard let subscription = product.subscription else {
            return ""
        }

        let period = subscription.subscriptionPeriod
        switch period.unit {
        case .day:
            return period.value == 1 ? "day" : "\(period.value) days"
        case .week:
            return period.value == 1 ? "week" : "\(period.value) weeks"
        case .month:
            return period.value == 1 ? "month" : "\(period.value) months"
        case .year:
            return period.value == 1 ? "year" : "\(period.value) years"
        @unknown default:
            return ""
        }
    }

    /// Calculate savings percentage for yearly vs monthly
    func yearlySavingsPercentage() -> Int? {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else {
            return nil
        }

        let monthlyYearCost = monthly.price * 12
        let yearlyCost = yearly.price
        let savings = (monthlyYearCost - yearlyCost) / monthlyYearCost * 100

        return Int(truncating: savings as NSDecimalNumber)
    }
}

// MARK: - StoreKit Error

enum StoreKitError: LocalizedError {
    case productLoadFailed(Error)
    case productNotFound(String)
    case purchaseFailed(Error)
    case purchaseCancelled
    case purchasePending
    case unknownPurchaseResult
    case verificationFailed(Error)
    case restoreFailed(Error)
    case noActiveSubscription

    var errorDescription: String? {
        switch self {
        case .productLoadFailed(let error):
            return "Failed to load products: \(error.localizedDescription)"
        case .productNotFound(let id):
            return "Product not found: \(id)"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .unknownPurchaseResult:
            return "Unknown purchase result"
        case .verificationFailed(let error):
            return "Transaction verification failed: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Failed to restore purchases: \(error.localizedDescription)"
        case .noActiveSubscription:
            return "No active subscription found"
        }
    }

    var isUserCancellation: Bool {
        if case .purchaseCancelled = self {
            return true
        }
        return false
    }

    var isPending: Bool {
        if case .purchasePending = self {
            return true
        }
        return false
    }
}

// MARK: - Subscription Status

enum SubscriptionStatus {
    case notSubscribed
    case subscribed(expiresAt: Date)
    case expired
    case inGracePeriod(expiresAt: Date)
    case inBillingRetry
    case revoked

    var isActive: Bool {
        switch self {
        case .subscribed, .inGracePeriod:
            return true
        default:
            return false
        }
    }

    var displayDescription: String {
        switch self {
        case .notSubscribed:
            return "Not subscribed"
        case .subscribed(let date):
            return "Active until \(date.formatted(date: .abbreviated, time: .omitted))"
        case .expired:
            return "Subscription expired"
        case .inGracePeriod(let date):
            return "Grace period until \(date.formatted(date: .abbreviated, time: .omitted))"
        case .inBillingRetry:
            return "Billing retry in progress"
        case .revoked:
            return "Subscription revoked"
        }
    }
}
