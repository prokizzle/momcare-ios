import SwiftUI

@MainActor
struct SelfCareScreen: View {
    var viewModel: SelfCareViewModel?

    @State private var showDetailSheet = false
    @State private var detailActionType: SelfCareActionType?
    @State private var didLoad = false

    var body: some View {
        Group {
            if let viewModel {
                loadedView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Self-Care")
    }

    @ViewBuilder
    private func loadedView(viewModel: SelfCareViewModel) -> some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                affirmationHero
                    .padding(.horizontal, MCSpacing.lg)

                waterCard(viewModel: viewModel)
                    .padding(.horizontal, MCSpacing.lg)

                ActionGridView(
                    gridItems: viewModel.visibleGridItems,
                    recentlyTapped: { viewModel.isRecentlyTapped($0) },
                    waterCount: viewModel.waterCountToday,
                    onTap: { actionType in
                        Task { await viewModel.logAction(actionType) }
                    },
                    onLongPress: { actionType in
                        detailActionType = actionType
                        showDetailSheet = true
                    }
                )

                CardFeedView(
                    cards: viewModel.cards,
                    onDismiss: { viewModel.dismissCard($0) }
                )
            }
            .padding(.vertical, MCSpacing.lg)
        }
        .ambientBackground()
        .task {
            guard !didLoad else { return }
            didLoad = true
            await viewModel.loadDay(.now)
            await viewModel.handleEvent(.appOpened)
        }
        .sheet(isPresented: $showDetailSheet) {
            if let actionType = detailActionType {
                LogDetailSheet(actionType: actionType) { detail in
                    Task { await viewModel.logAction(actionType, detail: detail) }
                }
            }
        }
    }

    private var affirmationHero: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Today")
                .mcBadge()
                .foregroundStyle(MCColor.selfCare)
            Text("You showed up today, and that is enough.")
                .font(MCTypography.affirmation)
                .foregroundStyle(MCColor.Foreground.level1)
        }
        .padding(MCSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.xl)
                .fill(MCElevation.elevated)
                .overlay {
                    RoundedRectangle(cornerRadius: MCRadius.xl)
                        .stroke(MCColor.selfCare.opacity(MCOpacity.soft), lineWidth: 1)
                }
                .shadow(color: MCColor.selfCare.opacity(MCOpacity.soft), radius: 24)
        }
    }

    private func waterCard(viewModel: SelfCareViewModel) -> some View {
        HStack(alignment: .center, spacing: MCSpacing.md) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text("Water")
                    .mcBadge()
                    .foregroundStyle(MCColor.feeding)
                HStack(alignment: .firstTextBaseline, spacing: MCSpacing.xs) {
                    Text("\(viewModel.waterCountToday)")
                        .font(MCTypography.display)
                        .foregroundStyle(MCColor.Foreground.level1)
                        .monospacedDigit()
                    Text("of 8")
                        .font(MCTypography.title3)
                        .foregroundStyle(MCColor.Foreground.level3)
                }
            }

            Spacer(minLength: 0)
            waterMeter(count: viewModel.waterCountToday)
            Button {
                MCHaptic.tap()
                Task { await viewModel.logAction(.water, detail: .water(glasses: 1)) }
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(MCColor.feeding)
                    .frame(width: 44, height: 44)
                    .background(MCColor.feeding.opacity(MCOpacity.soft), in: Circle())
            }
            .accessibilityLabel("Log water")
        }
        .padding(MCSpacing.lg)
        .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.lg))
    }

    private func waterMeter(count: Int) -> some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(index < count ? MCColor.feeding : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(MCColor.feeding.opacity(index < count ? 1 : MCOpacity.medium), lineWidth: 1.5)
                    }
                    .shadow(color: index < count ? MCColor.feeding.opacity(MCOpacity.strong) : .clear, radius: 4)
                    .frame(width: 12, height: 22)
            }
        }
        .accessibilityHidden(true)
    }
}
