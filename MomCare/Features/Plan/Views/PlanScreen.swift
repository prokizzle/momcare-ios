import SwiftUI

@MainActor
struct PlanScreen: View {
    @AppStorage("selectedStrategyId") private var selectedStrategyId: String = ""

    var selectedStrategy: DevelopmentStrategy? {
        DevelopmentStrategy.all.first { $0.id == selectedStrategyId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                if let selected = selectedStrategy {
                    activeStrategyHeader(selected)
                }

                VStack(alignment: .leading, spacing: MCSpacing.md) {
                    Text(selectedStrategy == nil ? "Choose a strategy" : "All Strategies")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, MCSpacing.xs)

                    ForEach(DevelopmentStrategy.all) { strategy in
                        StrategyCardView(
                            strategy: strategy,
                            isSelected: strategy.id == selectedStrategyId
                        ) {
                            selectedStrategyId = strategy.id
                        }
                    }
                }
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .navigationTitle("Plan")
    }

    @ViewBuilder
    private func activeStrategyHeader(_ strategy: DevelopmentStrategy) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Active Strategy")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text(strategy.name)
                        .font(.headline)
                    Text("Suggestions on Now are influenced by this strategy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(MCColor.baby)
            }
            .padding(MCSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}
