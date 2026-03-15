import SwiftUI

@MainActor
struct BabyScreen: View {
    let babyId: UUID?
    var dateOfBirth: Date?
    var biologicalSex: Baby.BiologicalSex?
    var sleepViewModel: SleepViewModel?
    var growthViewModel: GrowthViewModel?
    @Environment(BabyActivityEngine.self) private var engine
    @State private var showSleepTimer = false

    var body: some View {
        ScrollView {
            if let babyId {
                VStack(spacing: MCSpacing.lg) {
                    BabyCardGrid(babyId: babyId, sleepViewModel: sleepViewModel) {
                        showSleepTimer = true
                    }

                    if sleepViewModel != nil {
                        NavigationLink(value: BabyRoute.sleepHistory) {
                            HStack {
                                Image(systemName: "moon.stars.fill")
                                    .foregroundStyle(MCColor.baby)
                                Text("Sleep History")
                                    .font(MCTypography.title3)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(MCSpacing.md)
                            .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.md))
                        }
                        .buttonStyle(.plain)
                    }

                    if growthViewModel != nil {
                        NavigationLink(value: BabyRoute.growth) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundStyle(MCColor.baby)
                                Text("Growth Charts")
                                    .font(MCTypography.title3)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(MCSpacing.md)
                            .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.md))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, MCSpacing.xl)
                .padding(.vertical, MCSpacing.lg)
            } else {
                Text("Select a baby to get started")
                    .foregroundStyle(.secondary)
                    .padding(.top, MCSpacing.xl)
            }
        }
        .navigationTitle("Baby")
        .navigationDestination(for: BabyRoute.self) { route in
            switch route {
            case .sleepHistory:
                if let sleepViewModel {
                    SleepHistoryView(viewModel: sleepViewModel, babyId: babyId!)
                }
            case .sleepTimer:
                if let babyId {
                    SleepTimerView(babyId: babyId)
                }
            case .growth:
                if let growthViewModel, let babyId, let dateOfBirth {
                    GrowthScreen(
                        babyId: babyId,
                        dateOfBirth: dateOfBirth,
                        biologicalSex: biologicalSex,
                        viewModel: growthViewModel
                    )
                }
            }
        }
        .navigationDestination(isPresented: $showSleepTimer) {
            if let babyId {
                SleepTimerView(babyId: babyId) { quality, location in
                    guard let sleepViewModel else { return }
                    sleepViewModel.selectedQuality = quality
                    sleepViewModel.selectedLocation = location
                    await sleepViewModel.endSleep(babyId: babyId)
                    await engine.endNap(babyId: babyId)
                }
            }
        }
    }
}

@MainActor
private struct BabyCardGrid: View {
    let babyId: UUID
    var sleepViewModel: SleepViewModel?
    var onSleepTimerRequested: (() -> Void)?
    private let columns = [
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: MCSpacing.sm) {
            BabyActionCard(
                cardType: .nap,
                babyId: babyId,
                sleepViewModel: sleepViewModel,
                onSleepTimerRequested: onSleepTimerRequested
            )
            BabyActionCard(cardType: .feeding, babyId: babyId)
            BabyActionCard(cardType: .diaper, babyId: babyId)
        }
    }
}
