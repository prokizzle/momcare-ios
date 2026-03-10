import SwiftUI

struct BabySelectorView: View {
    @Bindable var viewModel: BabyViewModel
    @State private var showAddBaby = false

    var body: some View {
        Menu {
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
                        .font(MCTypography.cardTitle)
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Add Baby")
                        .font(MCTypography.cardTitle)
                }
            }
        }
        .sheet(isPresented: $showAddBaby) {
            AddBabyView(viewModel: viewModel)
        }
    }
}
