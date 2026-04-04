import Foundation
import StoreKit

// MARK: - Product Identifiers

enum StoreProduct: String, CaseIterable, Sendable {
    case premiumMonthly = "com.feelingmindful.momcare.premium.monthly"
    case premiumAnnual = "com.feelingmindful.momcare.premium.annual"
    case premiumPlusMonthly = "com.feelingmindful.momcare.premiumplus.monthly"
    case premiumPlusAnnual = "com.feelingmindful.momcare.premiumplus.annual"

    var tier: SubscriptionTier {
        switch self {
        case .premiumMonthly, .premiumAnnual: return .premium
        case .premiumPlusMonthly, .premiumPlusAnnual: return .premiumPlus
        }
    }

    var isAnnual: Bool {
        switch self {
        case .premiumAnnual, .premiumPlusAnnual: return true
        case .premiumMonthly, .premiumPlusMonthly: return false
        }
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Comparable, Sendable {
    case free
    case premium
    case premiumPlus

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        let order: [SubscriptionTier] = [.free, .premium, .premiumPlus]
        let lhsIndex = order.firstIndex(of: lhs) ?? 0
        let rhsIndex = order.firstIndex(of: rhs) ?? 0
        return lhsIndex < rhsIndex
    }
}

// MARK: - Store Manager

/// Manages StoreKit 2 subscriptions. Actor-isolated for thread safety.
///
/// Listens for `Transaction.updates` to handle renewals, expirations, and
/// external purchases (Family Sharing, App Store refunds).
actor StoreManager {

    static let shared = StoreManager()

    // MARK: - Published State

    private(set) var products: [Product] = []
    private(set) var currentTier: SubscriptionTier = .free
    private(set) var purchaseError: String?

    private var updateTask: Task<Void, Never>?

    // MARK: - Lifecycle

    func startObservingTransactions() {
        guard updateTask == nil else { return }
        updateTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? result.payloadValue {
                    await self.handleTransaction(transaction)
                }
            }
        }
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let ids = Set(StoreProduct.allCases.map(\.rawValue))
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            purchaseError = "Unable to load products. Please try again."
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = "Purchase failed. Please try again."
            return false
        }
    }

    // MARK: - Restore

    func restore() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseError = "Unable to restore purchases. Please try again."
        }
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var highestTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? result.payloadValue,
                  transaction.revocationDate == nil else { continue }

            if let storeProduct = StoreProduct(rawValue: transaction.productID) {
                let tier = storeProduct.tier
                if tier > highestTier {
                    highestTier = tier
                }
            }
        }

        currentTier = highestTier
    }

    // MARK: - Helpers

    func product(for identifier: StoreProduct) -> Product? {
        products.first { $0.id == identifier.rawValue }
    }

    func premiumProducts() -> [Product] {
        let premiumIds = Set([StoreProduct.premiumMonthly, .premiumAnnual].map(\.rawValue))
        return products.filter { premiumIds.contains($0.id) }
    }

    func premiumPlusProducts() -> [Product] {
        let ids = Set([StoreProduct.premiumPlusMonthly, .premiumPlusAnnual].map(\.rawValue))
        return products.filter { ids.contains($0.id) }
    }

    // MARK: - Private

    private func handleTransaction(_ transaction: Transaction) async {
        await transaction.finish()
        await refreshEntitlements()
    }
}
