import Pow
import SwiftUI

enum PermissionKind {
    case notifications
    case healthKit

    var icon: String {
        switch self {
        case .notifications: "bell.badge.fill"
        case .healthKit: "heart.text.clipboard.fill"
        }
    }

    var title: String {
        switch self {
        case .notifications: "Stay in the loop"
        case .healthKit: "Connect your health data"
        }
    }

    var subtitle: String {
        switch self {
        case .notifications:
            "Get timely reminders for feedings, naps, and self-care moments."
        case .healthKit:
            "Sync sleep and activity data for a complete picture."
        }
    }

    var benefits: [String] {
        switch self {
        case .notifications:
            [
                "Feeding reminders",
                "Sleep alerts",
                "Self-care nudges"
            ]
        case .healthKit:
            [
                "Growth tracking with WHO curves",
                "Mom's sleep and steps sync"
            ]
        }
    }

    var buttonTitle: String {
        switch self {
        case .notifications: "Enable Notifications"
        case .healthKit: "Connect HealthKit"
        }
    }
}

@MainActor
struct PermissionStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    let kind: PermissionKind
    @State private var appeared = false

    var body: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer()

            // Lottie placeholder - will be replaced with notification bell or health/heart animation
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .frame(height: 200)
                .overlay {
                    Image(systemName: kind.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(MCColor.accent)
                        .conditionalEffect(.repeat(.pulse(shape: Circle()), every: 2), condition: appeared)
                }
                .accessibilityHidden(true)

            Text(kind.title)
                .font(.title.bold())
                .foregroundStyle(.white)

            Text(kind.subtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: MCSpacing.lg) {
                ForEach(kind.benefits, id: \.self) { benefit in
                    HStack(spacing: MCSpacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(MCColor.accent)
                        Text(benefit)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, MCSpacing.lg)

            Spacer()

            Button {
                MCHaptic.tap()
                Task {
                    switch kind {
                    case .notifications:
                        await viewModel.requestNotificationPermission()
                    case .healthKit:
                        await viewModel.requestHealthKitPermission()
                    }
                }
            } label: {
                Text(kind.buttonTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(MCColor.accent, in: RoundedRectangle(cornerRadius: 16))
            }

            Button {
                MCHaptic.tap()
                switch kind {
                case .notifications:
                    viewModel.skipNotifications()
                case .healthKit:
                    viewModel.skipHealthKit()
                }
            } label: {
                Text("Not now")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, MCSpacing.xl)
        .padding(.bottom, MCSpacing.section)
        .onAppear { appeared = true }
    }
}
