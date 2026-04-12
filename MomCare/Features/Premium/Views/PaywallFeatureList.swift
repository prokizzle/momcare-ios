import SwiftUI

struct PaywallFeatureList: View {
    let tier: SubscriptionTier

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("What's Included")
                .font(MCTypography.title3)
                .foregroundStyle(.white)

            if tier == .premium {
                premiumFeatures
            } else {
                premiumPlusFeatures
            }
        }
    }

    private var premiumFeatures: some View {
        Group {
            featureRow("Unlimited tracking history", included: true)
            featureRow("Weekly and monthly trend insights", included: true)
            featureRow("Partner sharing (1 partner)", included: true)
            featureRow("PDF export for pediatrician visits", included: true)
            featureRow("Self-care streaks and reminders", included: true)
            featureRow("Up to 3 children", included: true)
            featureRow("EPDS depression screening", included: false)
            featureRow("AI-powered pattern predictions", included: false)
        }
    }

    private var premiumPlusFeatures: some View {
        Group {
            featureRow("Everything in Premium", included: true)
            featureRow("EPDS postpartum depression screening", included: true)
            featureRow("AI-powered pattern predictions", included: true)
            featureRow("Unlimited partner/caregiver sharing", included: true)
            featureRow("Unlimited children", included: true)
            featureRow("Priority support", included: true)
            featureRow("Early access to new features", included: true)
        }
    }

    private func featureRow(_ text: String, included: Bool) -> some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(included ? MCColor.accent : .white.opacity(0.3))
                .font(MCTypography.callout)
            Text(text)
                .font(MCTypography.subheadline)
                .foregroundStyle(included ? .white : .white.opacity(0.4))
        }
    }
}
