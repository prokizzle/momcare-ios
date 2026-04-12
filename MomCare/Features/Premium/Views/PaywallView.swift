import StoreKit
import SwiftUI

struct PaywallView: View {
    @State private var viewModel = PaywallViewModel()
    @State private var pulseOpacity = false

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
        .task { await viewModel.loadProducts() }
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
            withAnimation(MCAnimation.quick) { viewModel.selectedTier = tier }
            MCHaptic.select()
        } label: {
            Text(title)
                .font(MCTypography.button)
                .foregroundStyle(viewModel.selectedTier == tier ? .white : .white.opacity(0.5))
                .padding(.horizontal, MCSpacing.xl)
                .padding(.vertical, MCSpacing.sm)
                .background(viewModel.selectedTier == tier ? MCColor.accent.opacity(0.3) : .clear)
                .clipShape(Capsule())
        }
    }

    // MARK: - Plan Cards

    private var planCards: some View {
        VStack(spacing: MCSpacing.md) {
            billingToggle
            if let annual = viewModel.annualProduct {
                planCard(product: annual, isRecommended: true)
            }
            if let monthly = viewModel.monthlyProduct {
                planCard(product: monthly, isRecommended: false)
            }
        }
    }

    private var billingToggle: some View {
        HStack {
            Text("Monthly")
                .font(MCTypography.subheadline)
                .foregroundStyle(!viewModel.showAnnual ? .white : .white.opacity(0.5))
            Toggle("", isOn: $viewModel.showAnnual)
                .toggleStyle(.switch)
                .tint(MCColor.accent)
                .labelsHidden()
                .accessibilityLabel("Billing period")
                .accessibilityValue(viewModel.showAnnual ? "Annual" : "Monthly")
            Text("Annual")
                .font(MCTypography.subheadline)
                .foregroundStyle(viewModel.showAnnual ? .white : .white.opacity(0.5))
            if viewModel.showAnnual, let savingsText = viewModel.annualSavingsText {
                Text(savingsText)
                    .font(MCTypography.badge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, MCSpacing.sm)
                    .padding(.vertical, MCSpacing.xs)
                    .background(MCColor.accent)
                    .clipShape(Capsule())
            }
        }
        .onChange(of: viewModel.showAnnual) { _, _ in
            MCHaptic.toggle()
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
        PaywallFeatureList(tier: viewModel.selectedTier)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            Task {
                let success = await viewModel.handlePurchase()
                if success { dismiss() }
            }
        } label: {
            Group {
                if viewModel.isPurchasing {
                    Text("Processing...")
                        .font(MCTypography.button)
                        .opacity(pulseOpacity ? 0.4 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: pulseOpacity
                        )
                        .onAppear { pulseOpacity = true }
                        .onDisappear { pulseOpacity = false }
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
        .disabled(viewModel.isPurchasing || viewModel.isLoading)

        // Error display
        .overlay(alignment: .bottom) {
            if let errorMessage = viewModel.errorMessage {
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
            MCHaptic.tap()
            Task {
                let restored = await viewModel.restorePurchases()
                if restored { dismiss() }
            }
        }
        .font(MCTypography.caption)
        .foregroundStyle(.white.opacity(0.5))
        .frame(minHeight: 44)
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
                .font(MCTypography.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(MCOpacity.whisper))
                .clipShape(Circle())
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .padding(MCSpacing.lg)
    }
}

// MARK: - Helpers

private extension PaywallView {

    func periodLabel(_ product: Product) -> String {
        guard let subscription = product.subscription else { return "" }
        switch subscription.subscriptionPeriod.unit {
        case .month: return "month"
        case .year: return "year"
        default: return ""
        }
    }

    func monthlyEquivalentPrice(_ product: Product) -> String? {
        guard let subscription = product.subscription,
              subscription.subscriptionPeriod.unit == .year else { return nil }
        let monthly = product.price / Decimal(12)
        let code = product.priceFormatStyle.currencyCode
        let currencyCode = code.isEmpty ? "USD" : code
        return monthly.formatted(.currency(code: currencyCode))
    }
}
