import SwiftUI

@MainActor
struct BabyScreen: View {
    let babyId: UUID?
    var sleepViewModel: SleepViewModel?

    var body: some View {
        ScrollView {
            if let babyId {
                VStack(spacing: MCSpacing.lg) {
                    BabyCardGrid(babyId: babyId, sleepViewModel: sleepViewModel)

                    if let sleepViewModel {
                        NavigationLink {
                            SleepHistoryView(viewModel: sleepViewModel, babyId: babyId)
                        } label: {
                            HStack {
                                Image(systemName: "moon.stars.fill")
                                    .foregroundStyle(MCColor.baby)
                                Text("Sleep History")
                                    .font(MCTypography.cardTitle)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(MCSpacing.md)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, MCSpacing.lg)
                .padding(.vertical, MCSpacing.lg)
            } else {
                Text("Select a baby to get started")
                    .foregroundStyle(.secondary)
                    .padding(.top, MCSpacing.xl)
            }
        }
        .navigationTitle("Baby")
    }
}

@MainActor
private struct BabyCardGrid: View {
    let babyId: UUID
    var sleepViewModel: SleepViewModel?
    private let columns = [
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: MCSpacing.sm) {
            BabyActionCard(cardType: .nap, babyId: babyId, sleepViewModel: sleepViewModel)
            BabyActionCard(cardType: .feeding, babyId: babyId)
            BabyActionCard(cardType: .diaper, babyId: babyId)
        }
    }
}
