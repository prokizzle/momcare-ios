import SwiftUI

@MainActor
struct DashboardActionDeck: View {
    let babyId: UUID?
    var sleepViewModel: SleepViewModel?
    var selfCareViewModel: SelfCareViewModel?

    @Environment(BabyActivityEngine.self) private var engine
    @State private var showSleepTimer = false

    private let babyColumns = Array(repeating: GridItem(.flexible(), spacing: MCSpacing.sm), count: 3)
    private let momColumns = Array(repeating: GridItem(.flexible(), spacing: MCSpacing.sm), count: 4)
    private let momActions: [SelfCareActionType] = [.water, .meal, .breathingExercise, .meditate]

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            actionHeader
            babyActions
            momActionsGrid
        }
        .padding(MCSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.xl)
                .fill(MCElevation.elevated)
                .overlay {
                    RoundedRectangle(cornerRadius: MCRadius.xl)
                        .stroke(MCColor.baby.opacity(MCOpacity.soft), lineWidth: 1)
                }
        }
        .navigationDestination(isPresented: $showSleepTimer) {
            if let babyId {
                SleepTimerView(babyId: babyId) { quality, location in
                    if let sleepViewModel {
                        sleepViewModel.selectedQuality = quality
                        sleepViewModel.selectedLocation = location
                        await sleepViewModel.endSleep(babyId: babyId)
                        guard sleepViewModel.error == nil else { return }
                    }
                    await engine.endNap(babyId: babyId)
                }
            }
        }
    }

    private var actionHeader: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("Quick actions")
                .mcBadge()
                .foregroundStyle(MCColor.baby)
            Text("Baby and mom tracking, right where the day starts.")
                .font(MCTypography.footnote)
                .foregroundStyle(MCColor.Foreground.level3)
        }
    }

    @ViewBuilder
    private var babyActions: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Baby")
                .font(MCTypography.caption)
                .foregroundStyle(MCColor.Foreground.level3)

            if let babyId {
                LazyVGrid(columns: babyColumns, spacing: MCSpacing.sm) {
                    BabyActionCard(
                        cardType: .feeding,
                        babyId: babyId
                    )
                    BabyActionCard(
                        cardType: .nap,
                        babyId: babyId,
                        sleepViewModel: sleepViewModel,
                        onSleepTimerRequested: {
                            showSleepTimer = true
                        }
                    )
                    BabyActionCard(
                        cardType: .diaper,
                        babyId: babyId
                    )
                }
            } else {
                Text("Select a baby to log feedings, naps, and diapers.")
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColor.Foreground.level3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(MCSpacing.md)
                    .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.lg))
            }
        }
    }

    @ViewBuilder
    private var momActionsGrid: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Mom")
                .font(MCTypography.caption)
                .foregroundStyle(MCColor.Foreground.level3)

            LazyVGrid(columns: momColumns, spacing: MCSpacing.sm) {
                ForEach(momActions, id: \.self) { actionType in
                    DashboardMomActionButton(
                        actionType: actionType,
                        isRecentlyTapped: selfCareViewModel?.isRecentlyTapped(actionType) ?? false,
                        waterCount: actionType == .water ? selfCareViewModel?.waterCountToday : nil,
                        isEnabled: selfCareViewModel != nil,
                        onTap: {
                            Task {
                                await logMomAction(actionType)
                            }
                        }
                    )
                }
            }
        }
    }

    private func logMomAction(_ actionType: SelfCareActionType) async {
        guard let selfCareViewModel else { return }
        let detail: LogDetail? = switch actionType {
        case .water:
            .water(glasses: 1)
        default:
            nil
        }
        await selfCareViewModel.logAction(actionType, detail: detail)
    }
}

private struct DashboardMomActionButton: View {
    let actionType: SelfCareActionType
    let isRecentlyTapped: Bool
    let waterCount: Int?
    let isEnabled: Bool
    let onTap: () -> Void

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            guard isEnabled else { return }
            MCHaptic.tap()
            withAnimation(reduceMotion ? nil : MCAnimation.quick) {
                isAnimating = true
            }
            onTap()
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                isAnimating = false
            }
        } label: {
            VStack(spacing: MCSpacing.xs) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: actionType.systemImage)
                        .font(.headline)
                        .frame(width: 34, height: 34)
                        .foregroundStyle(actionType == .water ? MCColor.feeding : MCColor.selfCare)
                        .background(
                            (actionType == .water ? MCColor.feeding : MCColor.selfCare).opacity(MCOpacity.soft),
                            in: Circle()
                        )
                        .accessibilityHidden(true)

                    if let waterCount, waterCount > 0 {
                        Text("x\(waterCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(MCColor.Foreground.level2)
                            .offset(x: 8, y: -4)
                    }
                }

                Text(shortLabel)
                    .font(MCTypography.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background {
                RoundedRectangle(cornerRadius: MCRadius.lg)
                    .fill(MCElevation.surface)
                    .overlay {
                        if isRecentlyTapped {
                            RoundedRectangle(cornerRadius: MCRadius.lg)
                                .fill(MCColor.selfCare.opacity(MCOpacity.medium))
                        }
                    }
            }
            .opacity(isEnabled ? 1 : MCOpacity.strong)
            .scaleEffect(isAnimating ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("Log \(actionType.label)")
        .accessibilityHint(accessibilityHint)
    }

    private var shortLabel: String {
        switch actionType {
        case .breathingExercise: "Breathe"
        default: actionType.label
        }
    }

    private var accessibilityHint: String {
        if !isEnabled { return "Disabled" }
        return isRecentlyTapped ? "Logged recently" : "Tap to log"
    }
}
