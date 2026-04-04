import StoreKit
import SwiftUI

struct PaywallView: View {
    @State private var selectedTier: SubscriptionTier = .premium
    @State private var showAnnual = true
    @State private var products: [Product] = []
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                header
                tierPicker
                planCards
                featureComparison
                ctaButton
                restoreButton
                legalFooter
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.xl)
        }
        .nightlightBackground()
        .task { await loadProducts() }
        .overlay(alignment: .topTrailing) { closeButton }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: MCSpacing.sm) {
            Text("Unlock Full MomCare")
                .font(MCTypography.title1)
                .foregroundStyle(.white)
            Text("Track baby. Care for you. Thrive together.")
                .font(MCTypography.callout)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, MCSpacing.xxl)
    }

    // MARK: - Tier Picker

    private var tierPicker: some View {
        HStack(spacing: 0) {
            tierTab("Premium", tier: .premium)
            tierTab("Premium+", tier: .premiumPlus)
        }
        .background(Color.white.opacity(MCOpacity.whisper))
        .clipShape(Capsule())
    }

    private func tierTab(_ title: String, tier: SubscriptionTier) -> some View {
        Button {
            withAnimation(MCAnimation.quick) { selectedTier = tier }
            MCHaptic.select()
        } label: {
            Text(title)
                .font(MCTypography.button)
                .foregroundStyle(selectedTier == tier ? .white : .white.opacity(0.5))
                .padding(.horizontal, MCSpacing.xl)
                .padding(.vertical, MCSpacing.sm)
                .background(selectedTier == tier ? MCColor.accent.opacity(0.3) : .clear)
                .clipShape(Capsule())
        }
    }

    // MARK: - Plan Cards

    private var planCards: some View {
        VStack(spacing: MCSpacing.md) {
            billingToggle
            if let annual = annualProduct {
                planCard(product: annual, isRecommended: true)
            }
            if let monthly = monthlyProduct {
                planCard(product: monthly, isRecommended: false)
            }
        }
    }

    private var billingToggle: some View {
        HStack {
            Text("Monthly")
                .font(MCTypography.subheadline)
                .foregroundStyle(!showAnnual ? .white : .white.opacity(0.5))
            Toggle("", isOn: $showAnnual)
                .toggleStyle(.switch)
                .tint(MCColor.accent)
                .labelsHidden()
            Text("Annual")
                .font(MCTypography.subheadline)
                .foregroundStyle(showAnnual ? .white : .white.opacity(0.5))
            if showAnnual {
                Text("Save 44%")
                    .font(MCTypography.badge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, MCSpacing.sm)
                    .padding(.vertical, MCSpacing.xs)
                    .background(MCColor.accent)
                    .clipShape(Capsule())
            }
        }
    }

    private func planCard(product: Product, isRecommended: Bool) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text(product.displayName)
                        .font(MCTypography.headline)
                        .foregroundStyle(.white)
                    Text(product.displayPrice + " / " + periodLabel(product))
                        .font(MCTypography.callout)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                if isRecommended {
                    Text("Best Value")
                        .font(MCTypography.badge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, MCSpacing.sm)
                        .padding(.vertical, MCSpacing.xs)
                        .background(MCColor.accent)
                        .clipShape(Capsule())
                }
            }
            if let monthlyEquivalent = monthlyEquivalentPrice(product) {
                Text("That's just \(monthlyEquivalent)/month")
                    .font(MCTypography.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(MCSpacing.lg)
        .background(Color.white.opacity(isRecommended ? MCOpacity.soft : MCOpacity.whisper))
        .clipShape(RoundedRectangle(cornerRadius: MCRadius.lg))
        .overlay(
            isRecommended
                ? RoundedRectangle(cornerRadius: MCRadius.lg).stroke(MCColor.accent, lineWidth: 1.5)
                : nil
        )
    }

    // MARK: - Feature Comparison

    private var featureComparison: some View {
        PaywallFeatureList(tier: selectedTier)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            Task { await handlePurchase() }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text("Start Free Trial")
                        .font(MCTypography.button)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(MCColor.accent)
            .clipShape(RoundedRectangle(cornerRadius: MCRadius.lg))
        }
        .disabled(isPurchasing)

        // Error display
        .overlay(alignment: .bottom) {
            if let errorMessage {
                Text(errorMessage)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColor.error)
                    .padding(.top, MCSpacing.sm)
                    .offset(y: 28)
            }
        }
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await restorePurchases() }
        }
        .font(MCTypography.caption)
        .foregroundStyle(.white.opacity(0.5))
    }

    private var legalFooter: some View {
        Text("Payment will be charged to your Apple ID account at confirmation "
            + "of purchase. Subscription automatically renews unless cancelled at "
            + "least 24 hours before the end of the current period.")
            .font(MCTypography.caption2)
            .foregroundStyle(.white.opacity(0.3))
            .multilineTextAlignment(.center)
    }

    // MARK: - Close

    private var closeButton: some View {
        Button {
            dismiss()
            MCHaptic.tap()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(MCOpacity.whisper))
                .clipShape(Circle())
        }
        .padding(MCSpacing.lg)
    }

    // MARK: - Logic

    private var annualProduct: Product? {
        let id = selectedTier == .premium
            ? StoreProduct.premiumAnnual.rawValue
            : StoreProduct.premiumPlusAnnual.rawValue
        return products.first { $0.id == id }
    }

    private var monthlyProduct: Product? {
        let id = selectedTier == .premium
            ? StoreProduct.premiumMonthly.rawValue
            : StoreProduct.premiumPlusMonthly.rawValue
        return products.first { $0.id == id }
    }

    private func periodLabel(_ product: Product) -> String {
        guard let subscription = product.subscription else { return "" }
        switch subscription.subscriptionPeriod.unit {
        case .month: return "month"
        case .year: return "year"
        default: return ""
        }
    }

    private func monthlyEquivalentPrice(_ product: Product) -> String? {
        guard let subscription = product.subscription,
              subscription.subscriptionPeriod.unit == .year else { return nil }
        let monthly = product.price / 12
        return monthly.formatted(.currency(code: product.priceFormatStyle.currencyCode))
    }

    private func loadProducts() async {
        let store = StoreManager.shared
        await store.loadProducts()
        products = await store.products
    }

    private func handlePurchase() async {
        let product: Product? = showAnnual ? annualProduct : monthlyProduct
        guard let product else { return }
        isPurchasing = true
        errorMessage = nil
        MCHaptic.tap()

        let success = await StoreManager.shared.purchase(product)
        isPurchasing = false

        if success {
            MCHaptic.success()
            dismiss()
        } else {
            errorMessage = await StoreManager.shared.purchaseError
            if errorMessage != nil {
                MCHaptic.error()
            }
        }
    }

    private func restorePurchases() async {
        await StoreManager.shared.restore()
        let tier = await StoreManager.shared.currentTier
        if tier > .free {
            MCHaptic.success()
            dismiss()
        }
    }
}
