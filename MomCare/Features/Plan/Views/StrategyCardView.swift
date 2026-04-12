import SwiftUI

@MainActor
struct StrategyCardView: View {
    let strategy: DevelopmentStrategy
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text(strategy.name)
                        .font(MCTypography.headline)
                    Text(strategy.philosophy)
                        .font(MCTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MCColor.baby)
                        .font(.title2)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                ForEach(strategy.principles, id: \.self) { principle in
                    HStack(alignment: .top, spacing: MCSpacing.xs) {
                        Text("\u{2022}")
                            .foregroundStyle(MCColor.baby)
                        Text(principle)
                            .font(MCTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !isSelected {
                Button {
                    MCHaptic.tap()
                    onSelect()
                } label: {
                    Text("Select")
                        .font(MCTypography.badge)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
                            RoundedRectangle(cornerRadius: MCRadius.sm)
                                .fill(MCColor.baby.opacity(MCOpacity.medium))
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MCSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: MCRadius.lg)
                .fill(MCElevation.surface)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: MCRadius.lg)
                            .strokeBorder(MCColor.baby, lineWidth: 1.5)
                    }
                }
        }
    }
}
