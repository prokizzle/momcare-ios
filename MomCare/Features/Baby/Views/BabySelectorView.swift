import SwiftUI

@MainActor
struct BabySelectorView: View {
    @Bindable var viewModel: BabyViewModel
    @State private var showAddBaby = false

    var body: some View {
        Menu {
            if viewModel.babies.isEmpty {
                Text("No babies added yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.babies) { baby in
                    Button {
                        viewModel.selectBaby(baby)
                        MCHaptic.select()
                    } label: {
                        Label {
                            Text(baby.name)
                        } icon: {
                            if baby.id == viewModel.selectedBaby?.id {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
            }

            Divider()

            Button {
                showAddBaby = true
                MCHaptic.tap()
            } label: {
                Label("Add Baby", systemImage: "plus")
            }
        } label: {
            HStack(spacing: MCSpacing.xs) {
                if let baby = viewModel.selectedBaby {
                    BabyAvatarView(baby: baby, size: 28)
                    Text(baby.name)
                        .font(MCTypography.title3)
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .accessibilityHidden(true)
                    Text("Add Baby")
                        .font(MCTypography.title3)
                }
            }
        }
        .sheet(isPresented: $showAddBaby) {
            AddBabyView(viewModel: viewModel)
        }
    }
}
