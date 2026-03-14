import SwiftUI

@MainActor
struct FeedingSelectorSheet: View {
    let onSelect: (FeedMethod) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: MCSpacing.xl) {
            Text("How are you feeding?")
                .font(MCTypography.title3)
                .padding(.top, MCSpacing.xl)

            VStack(spacing: MCSpacing.md) {
                feedButton(.left, label: "Left Breast")
                feedButton(.right, label: "Right Breast")
                feedButton(.bottle, label: "Bottle")
            }
            .padding(.horizontal, MCSpacing.lg)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func feedButton(_ method: FeedMethod, label: String) -> some View {
        Button {
            MCHaptic.tap()
            onSelect(method)
            dismiss()
        } label: {
            HStack {
                Image(systemName: method.systemImage)
                    .font(.title2)
                Text(label)
                    .font(MCTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background {
                RoundedRectangle(cornerRadius: MCRadius.lg)
                    .fill(MCElevation.elevated)
            }
        }
        .buttonStyle(.plain)
    }
}
