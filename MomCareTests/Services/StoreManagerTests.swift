import Testing
import Foundation
@testable import MomCare

@Suite("StoreManager data layer")
struct StoreManagerTests {

    // MARK: - SubscriptionTier Comparison

    @Test("SubscriptionTier ordering: free < premium < premiumPlus")
    func tierOrdering() {
        #expect(SubscriptionTier.free < .premium)
        #expect(SubscriptionTier.premium < .premiumPlus)
        #expect(SubscriptionTier.free < .premiumPlus)
        #expect(!(SubscriptionTier.premium < .free))
        #expect(!(SubscriptionTier.premiumPlus < .premium))
    }

    // MARK: - StoreProduct Tier Mapping

    @Test(
        "StoreProduct.tier maps to correct subscription tier",
        arguments: [
            (StoreProduct.premiumMonthly, SubscriptionTier.premium),
            (StoreProduct.premiumAnnual, SubscriptionTier.premium),
            (StoreProduct.premiumPlusMonthly, SubscriptionTier.premiumPlus),
            (StoreProduct.premiumPlusAnnual, SubscriptionTier.premiumPlus)
        ]
    )
    func tierMapping(product: StoreProduct, expectedTier: SubscriptionTier) {
        #expect(product.tier == expectedTier)
    }

    // MARK: - StoreProduct isAnnual

    @Test(
        "StoreProduct.isAnnual returns correct flag",
        arguments: [
            (StoreProduct.premiumMonthly, false),
            (StoreProduct.premiumAnnual, true),
            (StoreProduct.premiumPlusMonthly, false),
            (StoreProduct.premiumPlusAnnual, true)
        ]
    )
    func isAnnualFlag(product: StoreProduct, expected: Bool) {
        #expect(product.isAnnual == expected)
    }
}
