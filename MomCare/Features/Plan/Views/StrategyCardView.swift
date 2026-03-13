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
                        .font(.headline)
                    Text(strategy.philosophy)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MCColor.baby)
                        .font(.title2)
                }
            }

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                ForEach(strategy.principles, id: \.self) { principle in
                    HStack(alignment: .top, spacing: MCSpacing.xs) {
                        Text("\u{2022}")
                            .foregroundStyle(MCColor.baby)
                        Text(principle)
                            .font(.caption)
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
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(MCColor.baby.opacity(0.2))
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MCSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(MCColor.baby, lineWidth: 1.5)
                    }
                }
        }
    }
}
