import Foundation
import StoreKit

/// Business logic for the paywall screen. Separated from the view
/// to enable isolated testing and keep PaywallView as pure UI.
@Observable
@MainActor
final class PaywallViewModel {

    // MARK: - State

    var products: [Product] = []
    var selectedTier: SubscriptionTier = .premium
    var showAnnual = true
    var isPurchasing = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let storeManager: any StoreManagerProtocol

    init(storeManager: any StoreManagerProtocol = StoreManager.shared) {
        self.storeManager = storeManager
    }

    // MARK: - Computed Properties

    var annualProduct: Product? {
        let id = selectedTier == .premium
            ? StoreProduct.premiumAnnual.rawValue
            : StoreProduct.premiumPlusAnnual.rawValue
        return products.first { $0.id == id }
    }

    var monthlyProduct: Product? {
        let id = selectedTier == .premium
            ? StoreProduct.premiumMonthly.rawValue
            : StoreProduct.premiumPlusMonthly.rawValue
        return products.first { $0.id == id }
    }

    var annualSavingsText: String? {
        guard let monthly = monthlyProduct,
              let annual = annualProduct else { return nil }
        let yearlyFromMonthly = monthly.price * Decimal(12)
        guard yearlyFromMonthly > 0 else { return nil }
        let savings = (yearlyFromMonthly - annual.price) / yearlyFromMonthly * Decimal(100)
        let percent = NSDecimalNumber(decimal: savings).intValue
        guard percent > 0 else { return nil }
        return "Save \(percent)%"
    }

    // MARK: - Actions

    func loadProducts() async {
        await storeManager.loadProducts()
        products = await storeManager.products
    }

    /// Returns `true` when the purchase completes successfully.
    func handlePurchase() async -> Bool {
        let product: Product? = showAnnual ? annualProduct : monthlyProduct
        guard let product else { return false }
        isPurchasing = true
        errorMessage = nil
        MCHaptic.tap()

        let success = await storeManager.purchase(product)
        isPurchasing = false

        if success {
            MCHaptic.success()
            return true
        } else {
            errorMessage = await storeManager.purchaseError
            if errorMessage != nil {
                MCHaptic.error()
            }
            return false
        }
    }

    /// Returns `true` when the restore reveals an active subscription.
    func restorePurchases() async -> Bool {
        await storeManager.restore()
        let tier = await storeManager.currentTier
        if tier > .free {
            MCHaptic.success()
            return true
        }
        return false
    }
}
